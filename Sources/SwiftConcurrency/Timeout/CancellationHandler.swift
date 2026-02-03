// CancellationHandler.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// Utilities for handling task cancellation.
///
/// `CancellationHandler` provides tools for managing cancellation in
/// async operations, including cleanup handlers and cancellation scopes.
///
/// ## Overview
///
/// Use cancellation handlers to ensure proper cleanup when tasks are
/// cancelled, and cancellation scopes to manage groups of related tasks.
///
/// ```swift
/// try await withCancellationHandler {
///     try await performOperation()
/// } onCancel: {
///     cleanup()
/// }
/// ```
///
/// ## Topics
///
/// ### Cancellation Scopes
/// - ``CancellationScope``
///
/// ### Cooperative Cancellation
/// - ``checkCancellation()``
/// - ``throwIfCancelled()``
public enum CancellationHandler {
    
    // MARK: - Cancellation Checking
    
    /// Throws if the current task is cancelled.
    ///
    /// Use this at cancellation points in your async code.
    ///
    /// ```swift
    /// for item in items {
    ///     try CancellationHandler.throwIfCancelled()
    ///     await process(item)
    /// }
    /// ```
    ///
    /// - Throws: `CancellationError` if cancelled.
    public static func throwIfCancelled() throws {
        try Task.checkCancellation()
    }
    
    /// Checks if the current task is cancelled.
    ///
    /// - Returns: `true` if cancelled.
    public static func isCancelled() -> Bool {
        Task.isCancelled
    }
    
    /// Performs an operation with a cancellation handler.
    ///
    /// The `onCancel` handler is called when the task is cancelled,
    /// even if the operation has already started.
    ///
    /// - Parameters:
    ///   - operation: The main operation to perform.
    ///   - onCancel: Handler called on cancellation.
    /// - Returns: The result of the operation.
    /// - Throws: Any error from the operation.
    public static func withHandler<T: Sendable>(
        operation: @Sendable () async throws -> T,
        onCancel: @Sendable () -> Void
    ) async rethrows -> T {
        try await withTaskCancellationHandler {
            try await operation()
        } onCancel: {
            onCancel()
        }
    }
}

// MARK: - Cancellation Scope

/// A scope for managing cancellation of related tasks.
///
/// `CancellationScope` provides a way to cancel multiple related tasks
/// together and track their cancellation state.
///
/// ```swift
/// let scope = CancellationScope()
///
/// await withTaskGroup(of: Void.self) { group in
///     group.addTask {
///         try await scope.run {
///             await task1()
///         }
///     }
///     group.addTask {
///         try await scope.run {
///             await task2()
///         }
///     }
/// }
///
/// // Cancel all tasks in the scope
/// scope.cancel()
/// ```
public actor CancellationScope {
    
    // MARK: - Properties
    
    /// Whether the scope is cancelled.
    private var isCancelled: Bool = false
    
    /// Registered tasks.
    private var tasks: [Task<Void, Never>] = []
    
    /// Cancellation handlers.
    private var handlers: [@Sendable () -> Void] = []
    
    // MARK: - Initialization
    
    /// Creates a cancellation scope.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Runs an operation within this scope.
    ///
    /// The operation will be cancelled if the scope is cancelled.
    ///
    /// - Parameter operation: The operation to run.
    /// - Returns: The result of the operation.
    /// - Throws: `CancellationError` if the scope is cancelled.
    public func run<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        guard !isCancelled else {
            throw CancellationError()
        }
        
        return try await withTaskCancellationHandler {
            try await operation()
        } onCancel: { [weak self] in
            Task {
                await self?.notifyCancellation()
            }
        }
    }
    
    /// Registers a task with this scope.
    ///
    /// The task will be cancelled when the scope is cancelled.
    ///
    /// - Parameter task: The task to register.
    public func register(_ task: Task<Void, Never>) {
        if isCancelled {
            task.cancel()
        } else {
            tasks.append(task)
        }
    }
    
    /// Registers a cancellation handler.
    ///
    /// - Parameter handler: The handler to call on cancellation.
    public func onCancel(_ handler: @escaping @Sendable () -> Void) {
        if isCancelled {
            handler()
        } else {
            handlers.append(handler)
        }
    }
    
    /// Cancels all tasks in this scope.
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        
        // Cancel all registered tasks
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
        
        // Call all handlers
        for handler in handlers {
            handler()
        }
        handlers.removeAll()
    }
    
    /// Whether the scope is cancelled.
    public var cancelled: Bool {
        isCancelled
    }
    
    // MARK: - Private Methods
    
    /// Notifies about cancellation.
    private func notifyCancellation() {
        cancel()
    }
}

// MARK: - Cancellation Token

/// A token for checking cancellation state.
///
/// `CancellationToken` provides a way to pass cancellation state
/// between tasks and closures.
public final class CancellationToken: Sendable {
    
    /// The cancellation state.
    private let state: ManagedAtomic<Bool>
    
    /// Creates a cancellation token.
    public init() {
        self.state = ManagedAtomic(false)
    }
    
    /// Whether the token is cancelled.
    public var isCancelled: Bool {
        state.load()
    }
    
    /// Cancels the token.
    public func cancel() {
        state.store(true)
    }
    
    /// Throws if cancelled.
    ///
    /// - Throws: `CancellationError` if cancelled.
    public func throwIfCancelled() throws {
        if isCancelled {
            throw CancellationError()
        }
    }
}

/// A simple atomic boolean for thread-safe cancellation state.
private final class ManagedAtomic<Value: Sendable>: @unchecked Sendable {
    
    private var value: Value
    private let lock = NSLock()
    
    init(_ initialValue: Value) {
        self.value = initialValue
    }
    
    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    
    func store(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}

// MARK: - Linked Cancellation

/// Links cancellation between multiple scopes.
///
/// When any linked scope is cancelled, all other linked scopes
/// are also cancelled.
public actor LinkedCancellation {
    
    /// The linked scopes.
    private var scopes: [CancellationScope] = []
    
    /// Whether already cancelled.
    private var isCancelled = false
    
    /// Creates a linked cancellation.
    public init() {}
    
    /// Links a scope to this group.
    ///
    /// - Parameter scope: The scope to link.
    public func link(_ scope: CancellationScope) async {
        if isCancelled {
            await scope.cancel()
        } else {
            scopes.append(scope)
            await scope.onCancel { [weak self] in
                Task {
                    await self?.cancelAll()
                }
            }
        }
    }
    
    /// Cancels all linked scopes.
    public func cancelAll() async {
        guard !isCancelled else { return }
        isCancelled = true
        
        for scope in scopes {
            await scope.cancel()
        }
        scopes.removeAll()
    }
}
