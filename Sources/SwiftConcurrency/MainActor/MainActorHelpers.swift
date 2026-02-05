// MainActorHelpers.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - MainActor Utilities

/// Utilities for working with MainActor in async contexts.
@MainActor
public enum MainActorHelpers {
    
    /// Ensures code runs on MainActor, yielding if necessary.
    ///
    /// Unlike `@MainActor` annotation, this can be called from any context
    /// and will properly yield to the main thread.
    ///
    /// ```swift
    /// await MainActorHelpers.run {
    ///     updateUI()
    /// }
    /// ```
    @discardableResult
    public static func run<T: Sendable>(
        _ operation: @MainActor () throws -> T
    ) async rethrows -> T {
        try operation()
    }
    
    /// Runs multiple UI operations in sequence.
    ///
    /// - Parameter operations: Array of operations to run.
    public static func runSequence(
        _ operations: [@MainActor @Sendable () -> Void]
    ) async {
        for operation in operations {
            operation()
        }
    }
    
    /// Runs an operation with an optional animation.
    ///
    /// - Parameters:
    ///   - animated: Whether to animate.
    ///   - duration: Animation duration.
    ///   - operation: The UI operation.
    public static func runAnimated(
        _ animated: Bool = true,
        duration: Duration = .milliseconds(250),
        operation: @MainActor @Sendable () -> Void
    ) async {
        // Platform-agnostic animation wrapper
        operation()
    }
}

// MARK: - MainActorValue

/// A property wrapper for values that must be accessed on MainActor.
///
/// ```swift
/// @MainActorValue var count = 0
///
/// // Access on main actor
/// await $count.update { $0 += 1 }
/// ```
@MainActor
@propertyWrapper
public struct MainActorValue<Value: Sendable>: Sendable {
    
    private let storage: MainActorStorage<Value>
    
    /// Creates a main actor value.
    public init(wrappedValue: Value) {
        self.storage = MainActorStorage(wrappedValue)
    }
    
    /// The wrapped value (main actor access only).
    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }
    
    /// Projected value for async access.
    public nonisolated var projectedValue: MainActorAccessor<Value> {
        MainActorAccessor(storage: storage)
    }
}

/// Storage for MainActorValue.
@MainActor
final class MainActorStorage<Value: Sendable>: Sendable {
    var value: Value
    
    nonisolated init(_ value: sending Value) {
        self.value = value
    }
}

/// Async accessor for MainActorValue.
public struct MainActorAccessor<Value: Sendable>: Sendable {
    
    let storage: MainActorStorage<Value>
    
    /// Gets the value asynchronously.
    public func get() async -> Value {
        await storage.value
    }
    
    /// Sets the value asynchronously.
    public func set(_ newValue: Value) async {
        await MainActor.run {
            storage.value = newValue
        }
    }
    
    /// Updates the value with a transform.
    public func update(_ transform: @Sendable (inout Value) -> Void) async {
        await MainActor.run {
            transform(&storage.value)
        }
    }
}

// MARK: - MainActorStream

/// An AsyncSequence that delivers elements on MainActor.
///
/// Wraps any async sequence and ensures all elements are received
/// on the main actor.
public struct MainActorStream<Base: AsyncSequence>: AsyncSequence, Sendable
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    
    /// Creates a main actor stream.
    public init(_ base: Base) {
        self.base = base
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeAsyncIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        
        init(base: Base.AsyncIterator) {
            self.iterator = base
        }
        
        @MainActor
        public mutating func next() async throws -> Element? {
            try await iterator.next()
        }
    }
}

// MARK: - MainActorRelay

/// Relays values to subscribers on MainActor.
///
/// Useful for bridging background async streams to UI updates.
@MainActor
public final class MainActorRelay<Element: Sendable> {
    
    /// Handler type for received values.
    public typealias Handler = @MainActor (Element) -> Void
    
    private var handlers: [UUID: Handler] = [:]
    private var latestValue: Element?
    private var task: Task<Void, Never>?
    
    /// The most recently relayed value.
    public var latest: Element? { latestValue }
    
    /// Creates a relay.
    public init() {}
    
    /// Subscribes to values.
    ///
    /// - Parameter handler: Called on MainActor for each value.
    /// - Returns: Token for unsubscribing.
    @discardableResult
    public func subscribe(_ handler: @escaping Handler) -> UUID {
        let id = UUID()
        handlers[id] = handler
        
        // Deliver latest value immediately
        if let value = latestValue {
            handler(value)
        }
        
        return id
    }
    
    /// Unsubscribes.
    public func unsubscribe(_ id: UUID) {
        handlers.removeValue(forKey: id)
    }
    
    /// Sends a value to all subscribers.
    public func send(_ value: Element) {
        latestValue = value
        for handler in handlers.values {
            handler(value)
        }
    }
    
    /// Connects to an async sequence.
    public func connect<S: AsyncSequence>(
        to sequence: S
    ) where S.Element == Element, S: Sendable {
        task?.cancel()
        task = Task { [weak self] in
            do {
                for try await element in sequence {
                    guard let self = self else { break }
                    self.send(element)
                }
            } catch {
                // Sequence ended
            }
        }
    }
    
    /// Disconnects from the current sequence.
    public func disconnect() {
        task?.cancel()
        task = nil
    }
    
    deinit {
        task?.cancel()
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Ensures elements are received on MainActor.
    ///
    /// ```swift
    /// for await update in stream.onMainActor() {
    ///     updateUI(with: update)
    /// }
    /// ```
    public func onMainActor() -> MainActorStream<Self> {
        MainActorStream(self)
    }
}

// MARK: - Task Extensions

extension Task where Success: Sendable, Failure == Never {
    
    /// Creates a task that runs on MainActor.
    ///
    /// - Parameter operation: The operation to perform.
    /// - Returns: The task.
    @MainActor
    @discardableResult
    public static func onMainActor(
        priority: TaskPriority? = nil,
        operation: @MainActor @escaping @Sendable () async -> Success
    ) -> Task<Success, Never> {
        Task(priority: priority) { @MainActor in
            await operation()
        }
    }
}

extension Task where Success: Sendable, Failure == Error {
    
    /// Creates a throwing task that runs on MainActor.
    @MainActor
    @discardableResult
    public static func onMainActor(
        priority: TaskPriority? = nil,
        operation: @MainActor @escaping @Sendable () async throws -> Success
    ) -> Task<Success, Error> {
        Task(priority: priority) { @MainActor in
            try await operation()
        }
    }
}

// MARK: - Debounced MainActor

/// Debounces calls to a MainActor function.
///
/// Useful for rate-limiting UI updates from rapid async events.
@MainActor
public final class DebouncedMainActor<Input: Sendable> {
    
    private let action: @MainActor (Input) -> Void
    private let delay: Duration
    private var pendingTask: Task<Void, Never>?
    private var pendingValue: Input?
    
    /// Creates a debounced action.
    ///
    /// - Parameters:
    ///   - delay: Debounce delay.
    ///   - action: The action to debounce.
    public init(
        delay: Duration,
        action: @escaping @MainActor (Input) -> Void
    ) {
        self.delay = delay
        self.action = action
    }
    
    /// Triggers the debounced action.
    public func callAsFunction(_ input: Input) {
        pendingValue = input
        pendingTask?.cancel()
        
        pendingTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            do {
                try await Task.sleep(for: self.delay)
                if let value = self.pendingValue {
                    self.action(value)
                    self.pendingValue = nil
                }
            } catch {
                // Cancelled
            }
        }
    }
    
    /// Executes immediately without waiting.
    public func executeNow() {
        pendingTask?.cancel()
        if let value = pendingValue {
            action(value)
            pendingValue = nil
        }
    }
    
    /// Cancels any pending execution.
    public func cancel() {
        pendingTask?.cancel()
        pendingValue = nil
    }
}

// MARK: - Throttled MainActor

/// Throttles calls to a MainActor function.
@MainActor
public final class ThrottledMainActor<Input: Sendable> {
    
    private let action: @MainActor (Input) -> Void
    private let interval: Duration
    private var lastExecuted: ContinuousClock.Instant?
    private var pendingValue: Input?
    private var pendingTask: Task<Void, Never>?
    
    /// Creates a throttled action.
    public init(
        interval: Duration,
        action: @escaping @MainActor (Input) -> Void
    ) {
        self.interval = interval
        self.action = action
    }
    
    /// Triggers the throttled action.
    public func callAsFunction(_ input: Input) {
        let now = ContinuousClock.now
        
        if let last = lastExecuted {
            let elapsed = now - last
            if elapsed >= interval {
                // Enough time passed, execute
                lastExecuted = now
                action(input)
            } else {
                // Schedule for later
                pendingValue = input
                if pendingTask == nil {
                    let remaining = interval - elapsed
                    pendingTask = Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        do {
                            try await Task.sleep(for: remaining)
                            if let value = self.pendingValue {
                                self.lastExecuted = .now
                                self.action(value)
                                self.pendingValue = nil
                            }
                            self.pendingTask = nil
                        } catch {
                            // Cancelled
                        }
                    }
                }
            }
        } else {
            // First call
            lastExecuted = now
            action(input)
        }
    }
}
