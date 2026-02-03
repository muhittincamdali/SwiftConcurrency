// DeadlineTask.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A task that must complete by a specific deadline.
///
/// `DeadlineTask` provides a way to run async operations with an absolute
/// deadline, automatically cancelling if the deadline passes.
///
/// ## Overview
///
/// Use `DeadlineTask` when you need operations to complete by a specific
/// time rather than within a relative duration.
///
/// ```swift
/// let deadline = Date().addingTimeInterval(30) // 30 seconds from now
/// let result = try await DeadlineTask.run(deadline: deadline) {
///     try await fetchData()
/// }
/// ```
///
/// ## Topics
///
/// ### Running Tasks with Deadlines
/// - ``run(deadline:operation:)``
/// - ``run(deadline:priority:operation:)``
///
/// ### Deadline Errors
/// - ``DeadlineError``
public struct DeadlineTask<Success: Sendable>: Sendable {
    
    // MARK: - Types
    
    /// Errors that can occur with deadline tasks.
    public enum DeadlineError: Error, Sendable {
        /// The deadline has already passed.
        case deadlinePassed
        /// The operation was cancelled due to deadline.
        case deadlineExceeded
        /// The operation was manually cancelled.
        case cancelled
    }
    
    // MARK: - Static Methods
    
    /// Runs an operation with an absolute deadline.
    ///
    /// - Parameters:
    ///   - deadline: The absolute time by which the operation must complete.
    ///   - operation: The async operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: `DeadlineError.deadlineExceeded` if the deadline passes,
    ///           or any error thrown by the operation.
    @discardableResult
    public static func run(
        deadline: Date,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        try await run(deadline: deadline, priority: nil, operation: operation)
    }
    
    /// Runs an operation with an absolute deadline and priority.
    ///
    /// - Parameters:
    ///   - deadline: The absolute time by which the operation must complete.
    ///   - priority: The task priority.
    ///   - operation: The async operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: `DeadlineError` if the deadline passes or the operation fails.
    @discardableResult
    public static func run(
        deadline: Date,
        priority: TaskPriority?,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        let timeRemaining = deadline.timeIntervalSinceNow
        
        guard timeRemaining > 0 else {
            throw DeadlineError.deadlinePassed
        }
        
        return try await withThrowingTaskGroup(of: TaskResult.self) { group in
            // Main operation task
            group.addTask(priority: priority) {
                do {
                    let result = try await operation()
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            }
            
            // Deadline monitoring task
            group.addTask(priority: .low) {
                try await Task.sleep(for: .seconds(timeRemaining))
                return .timeout
            }
            
            // Wait for first result
            guard let firstResult = try await group.next() else {
                throw DeadlineError.cancelled
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            
            switch firstResult {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            case .timeout:
                throw DeadlineError.deadlineExceeded
            }
        }
    }
    
    /// Runs an operation with a deadline computed from now.
    ///
    /// - Parameters:
    ///   - duration: Time until deadline.
    ///   - operation: The async operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: `DeadlineError` if the deadline passes.
    @discardableResult
    public static func run(
        after duration: Duration,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        let (seconds, attoseconds) = duration.components
        let interval = Double(seconds) + Double(attoseconds) / 1e18
        let deadline = Date().addingTimeInterval(interval)
        return try await run(deadline: deadline, operation: operation)
    }
    
    // MARK: - Internal Types
    
    /// Internal result type for task group.
    private enum TaskResult: Sendable {
        case success(Success)
        case failure(Error)
        case timeout
    }
}

// MARK: - Scheduled Task

/// A task scheduled to run at a specific time.
///
/// `ScheduledTask` allows scheduling async operations to run at a future
/// point in time.
public actor ScheduledTask<Success: Sendable> {
    
    // MARK: - Types
    
    /// The state of the scheduled task.
    public enum State: Sendable, Equatable {
        case pending
        case running
        case completed
        case failed
        case cancelled
    }
    
    // MARK: - Properties
    
    /// The scheduled execution time.
    public let scheduledTime: Date
    
    /// The operation to perform.
    private let operation: @Sendable () async throws -> Success
    
    /// The current state.
    private var state: State = .pending
    
    /// The underlying task.
    private var task: Task<Success, Error>?
    
    /// Continuations waiting for the result.
    private var waiters: [CheckedContinuation<Success, Error>] = []
    
    /// The result once completed.
    private var result: Result<Success, Error>?
    
    // MARK: - Initialization
    
    /// Creates a scheduled task.
    ///
    /// - Parameters:
    ///   - time: When to execute the task.
    ///   - operation: The operation to perform.
    public init(
        at time: Date,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.scheduledTime = time
        self.operation = operation
    }
    
    /// Creates a scheduled task with a delay.
    ///
    /// - Parameters:
    ///   - delay: Time to wait before execution.
    ///   - operation: The operation to perform.
    public init(
        after delay: Duration,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        let (seconds, attoseconds) = delay.components
        let interval = Double(seconds) + Double(attoseconds) / 1e18
        self.scheduledTime = Date().addingTimeInterval(interval)
        self.operation = operation
    }
    
    // MARK: - Public Methods
    
    /// Starts the scheduled task.
    public func start() {
        guard state == .pending else { return }
        
        let delay = scheduledTime.timeIntervalSinceNow
        
        task = Task {
            if delay > 0 {
                try await Task.sleep(for: .seconds(delay))
            }
            
            await updateState(.running)
            
            do {
                let value = try await operation()
                await complete(with: .success(value))
                return value
            } catch {
                await complete(with: .failure(error))
                throw error
            }
        }
    }
    
    /// Updates the state.
    private func updateState(_ newState: State) {
        state = newState
    }
    
    /// Completes the task.
    private func complete(with taskResult: Result<Success, Error>) {
        result = taskResult
        
        switch taskResult {
        case .success:
            state = .completed
        case .failure(let error):
            state = error is CancellationError ? .cancelled : .failed
        }
        
        let currentWaiters = waiters
        waiters.removeAll()
        
        for waiter in currentWaiters {
            switch taskResult {
            case .success(let value):
                waiter.resume(returning: value)
            case .failure(let error):
                waiter.resume(throwing: error)
            }
        }
    }
    
    /// Cancels the scheduled task.
    public func cancel() {
        guard state == .pending else { return }
        state = .cancelled
        task?.cancel()
        
        for waiter in waiters {
            waiter.resume(throwing: CancellationError())
        }
        waiters.removeAll()
    }
    
    /// Waits for the task to complete.
    ///
    /// - Returns: The result of the task.
    /// - Throws: Any error from the task or cancellation.
    public func wait() async throws -> Success {
        if let result = result {
            return try result.get()
        }
        
        if state == .cancelled {
            throw CancellationError()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// The current state of the task.
    public var currentState: State {
        state
    }
    
    /// Time remaining until execution.
    public var timeRemaining: Duration {
        let interval = scheduledTime.timeIntervalSinceNow
        return .seconds(max(0, interval))
    }
}
