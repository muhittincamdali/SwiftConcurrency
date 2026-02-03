// DelayedTask.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A task that executes after a specified delay.
///
/// `DelayedTask` provides a simple way to defer execution of async
/// operations with support for cancellation and rescheduling.
///
/// ## Overview
///
/// Use `DelayedTask` when you need to delay an operation and potentially
/// cancel or reschedule it before execution.
///
/// ```swift
/// // Create and start a delayed task
/// let task = DelayedTask(delay: .seconds(5)) {
///     print("Executed after 5 seconds")
/// }
/// await task.start()
///
/// // Cancel if needed
/// await task.cancel()
///
/// // Or reschedule
/// await task.reschedule(delay: .seconds(10))
/// ```
///
/// ## Topics
///
/// ### Creating Delayed Tasks
/// - ``init(delay:operation:)``
///
/// ### Task Control
/// - ``start()``
/// - ``cancel()``
/// - ``reschedule(delay:)``
public actor DelayedTask<Success: Sendable> {
    
    // MARK: - Types
    
    /// The state of the delayed task.
    public enum State: Sendable, Equatable {
        /// Task is created but not started.
        case idle
        /// Task is waiting to execute.
        case scheduled
        /// Task is currently executing.
        case executing
        /// Task completed successfully.
        case completed
        /// Task was cancelled.
        case cancelled
        /// Task failed with an error.
        case failed
    }
    
    // MARK: - Properties
    
    /// The delay before execution.
    private var delay: Duration
    
    /// The operation to perform.
    private let operation: @Sendable () async throws -> Success
    
    /// The underlying task.
    private var task: Task<Success, Error>?
    
    /// The current state.
    private var _state: State = .idle
    
    /// Completion handlers.
    private var completionHandlers: [@Sendable (Result<Success, Error>) -> Void] = []
    
    // MARK: - Initialization
    
    /// Creates a delayed task.
    ///
    /// - Parameters:
    ///   - delay: Time to wait before execution.
    ///   - operation: The operation to perform.
    public init(
        delay: Duration,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.delay = delay
        self.operation = operation
    }
    
    // MARK: - Public Methods
    
    /// The current state of the task.
    public var state: State {
        _state
    }
    
    /// Starts the delayed task.
    ///
    /// If already started, this has no effect.
    public func start() {
        guard _state == .idle || _state == .cancelled else {
            return
        }
        _state = .scheduled
        
        task = Task { [weak self] in
            guard let self = self else { throw CancellationError() }
            
            try await Task.sleep(for: await self.delay)
            
            await self.updateState(.executing)
            
            do {
                let result = try await self.operation()
                await self.complete(with: .success(result))
                return result
            } catch {
                await self.complete(with: .failure(error))
                throw error
            }
        }
    }
    
    /// Updates the internal state.
    private func updateState(_ newState: State) {
        _state = newState
    }
    
    /// Completes the task with a result.
    private func complete(with result: Result<Success, Error>) {
        switch result {
        case .success:
            _state = .completed
        case .failure(let error):
            _state = error is CancellationError ? .cancelled : .failed
        }
        
        let handlers = completionHandlers
        completionHandlers.removeAll()
        
        for handler in handlers {
            handler(result)
        }
    }
    
    /// Cancels the task.
    public func cancel() {
        guard _state == .scheduled || _state == .executing else {
            return
        }
        _state = .cancelled
        task?.cancel()
    }
    
    /// Reschedules the task with a new delay.
    ///
    /// If executing or completed, this has no effect.
    ///
    /// - Parameter newDelay: The new delay.
    public func reschedule(delay newDelay: Duration) {
        guard _state == .idle || _state == .scheduled || _state == .cancelled else {
            return
        }
        
        delay = newDelay
        _state = .idle
        
        task?.cancel()
        task = nil
        
        start()
    }
    
    /// Waits for the task to complete.
    ///
    /// - Returns: The result of the operation.
    /// - Throws: Any error from the operation or cancellation.
    public func wait() async throws -> Success {
        guard let task = task else {
            throw CancellationError()
        }
        return try await task.value
    }
    
    /// Adds a completion handler.
    ///
    /// - Parameter handler: Called when the task completes.
    public func onCompletion(_ handler: @escaping @Sendable (Result<Success, Error>) -> Void) {
        completionHandlers.append(handler)
    }
    
    /// Time remaining until execution.
    public var timeRemaining: Duration {
        _state == .scheduled ? delay : .zero
    }
}

// MARK: - Debounced Task

/// A task that debounces rapid calls.
///
/// `DebouncedTask` delays execution until a quiet period has passed,
/// cancelling pending executions when new calls arrive.
public actor DebouncedTask<Success: Sendable> {
    
    /// The debounce delay.
    private let delay: Duration
    
    /// The operation to perform.
    private let operation: @Sendable () async throws -> Success
    
    /// The current pending task.
    private var pendingTask: Task<Success, Error>?
    
    /// Creates a debounced task.
    ///
    /// - Parameters:
    ///   - delay: The debounce delay.
    ///   - operation: The operation to perform.
    public init(
        delay: Duration,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.delay = delay
        self.operation = operation
    }
    
    /// Triggers the debounced operation.
    ///
    /// Cancels any pending execution and schedules a new one.
    ///
    /// - Returns: The result when execution completes.
    /// - Throws: Any error from the operation.
    @discardableResult
    public func trigger() async throws -> Success {
        // Cancel existing pending task
        pendingTask?.cancel()
        
        // Create new task
        let task = Task {
            try await Task.sleep(for: delay)
            return try await operation()
        }
        
        pendingTask = task
        return try await task.value
    }
    
    /// Cancels any pending execution.
    public func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }
    
    /// Whether there's a pending execution.
    public var isPending: Bool {
        pendingTask != nil && !Task.isCancelled
    }
}

// MARK: - Throttled Task

/// A task that throttles execution to a maximum rate.
///
/// `ThrottledTask` ensures operations execute at most once per
/// specified time period.
public actor ThrottledTask<Success: Sendable> {
    
    /// The minimum interval between executions.
    private let interval: Duration
    
    /// The operation to perform.
    private let operation: @Sendable () async throws -> Success
    
    /// When the last execution occurred.
    private var lastExecution: Date?
    
    /// The pending result.
    private var pendingResult: Success?
    
    /// Creates a throttled task.
    ///
    /// - Parameters:
    ///   - interval: Minimum time between executions.
    ///   - operation: The operation to perform.
    public init(
        interval: Duration,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.interval = interval
        self.operation = operation
    }
    
    /// Executes the operation if not throttled.
    ///
    /// - Parameter forceExecute: If true, ignores throttling.
    /// - Returns: The result of the operation.
    /// - Throws: Any error from the operation.
    @discardableResult
    public func execute(forceExecute: Bool = false) async throws -> Success {
        let now = Date()
        
        // Check if throttled
        if let last = lastExecution, !forceExecute {
            let elapsed = now.timeIntervalSince(last)
            let intervalSeconds = Double(interval.components.seconds) + 
                                  Double(interval.components.attoseconds) / 1e18
            
            if elapsed < intervalSeconds {
                // Still throttled, return cached result if available
                if let cached = pendingResult {
                    return cached
                }
                // Wait for the remaining time
                let remaining = intervalSeconds - elapsed
                try await Task.sleep(for: .seconds(remaining))
            }
        }
        
        // Execute
        lastExecution = Date()
        let result = try await operation()
        pendingResult = result
        return result
    }
    
    /// Resets the throttle timer.
    public func reset() {
        lastExecution = nil
        pendingResult = nil
    }
}

// MARK: - Coalescing Task

/// A task that coalesces multiple rapid calls into one execution.
///
/// While a coalescing task is executing, additional triggers queue up
/// and result in a single additional execution after completion.
public actor CoalescingTask<Success: Sendable> {
    
    /// The operation to perform.
    private let operation: @Sendable () async throws -> Success
    
    /// Whether currently executing.
    private var isExecuting = false
    
    /// Whether another execution is queued.
    private var isQueued = false
    
    /// The last result.
    private var lastResult: Success?
    
    /// Creates a coalescing task.
    ///
    /// - Parameter operation: The operation to perform.
    public init(operation: @escaping @Sendable () async throws -> Success) {
        self.operation = operation
    }
    
    /// Triggers execution, coalescing with pending executions.
    ///
    /// - Returns: The result of the operation.
    /// - Throws: Any error from the operation.
    @discardableResult
    public func trigger() async throws -> Success {
        if isExecuting {
            isQueued = true
            // Return last result if available, otherwise wait
            if let result = lastResult {
                return result
            }
        }
        
        isExecuting = true
        defer { isExecuting = false }
        
        repeat {
            isQueued = false
            let result = try await operation()
            lastResult = result
            
            if !isQueued {
                return result
            }
        } while isQueued
        
        return lastResult!
    }
    
    /// Resets the coalescing state.
    public func reset() {
        isQueued = false
        lastResult = nil
    }
}
