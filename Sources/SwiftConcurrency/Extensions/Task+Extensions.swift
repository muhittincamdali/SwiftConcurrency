// Task+Extensions.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - Task Sleep Extensions

extension Task where Success == Never, Failure == Never {

    /// Sleeps for the given duration, throwing `CancellationError` if cancelled.
    ///
    /// Provides a checked sleep that verifies cancellation both before and after sleeping.
    ///
    /// - Parameter duration: The duration to sleep.
    /// - Throws: `CancellationError` if the task is cancelled.
    public static func sleepChecked(for duration: Duration) async throws {
        try Task.checkCancellation()
        try await Task.sleep(for: duration)
        try Task.checkCancellation()
    }

    /// Sleeps until the specified deadline.
    ///
    /// - Parameter deadline: The instant to sleep until.
    /// - Throws: `CancellationError` if the task is cancelled.
    public static func sleepUntil(deadline: ContinuousClock.Instant) async throws {
        let now = ContinuousClock.now
        guard deadline > now else { return }
        let duration = deadline - now
        try await Task.sleep(for: duration)
    }
    
    /// Sleeps for the specified number of seconds.
    ///
    /// - Parameter seconds: Duration in seconds.
    /// - Throws: `CancellationError` if the task is cancelled.
    public static func sleep(seconds: Double) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }
    
    /// Sleeps for the specified number of milliseconds.
    ///
    /// - Parameter milliseconds: Duration in milliseconds.
    /// - Throws: `CancellationError` if the task is cancelled.
    public static func sleep(milliseconds: Int) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
    }
}

// MARK: - Task Creation Extensions

extension Task where Failure == Never {

    /// Creates a detached task with the specified priority.
    ///
    /// - Parameters:
    ///   - priority: The task priority.
    ///   - operation: The async closure to execute.
    /// - Returns: The created task handle.
    @discardableResult
    public static func detachedWithPriority(
        _ priority: TaskPriority,
        operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        Task.detached(priority: priority) {
            await operation()
        }
    }
}

extension Task where Failure == Error {

    /// Creates a detached throwing task with the specified priority.
    ///
    /// - Parameters:
    ///   - priority: The task priority.
    ///   - operation: The async throwing closure to execute.
    /// - Returns: The created task handle.
    @discardableResult
    public static func detachedThrowingWithPriority(
        _ priority: TaskPriority,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        Task.detached(priority: priority) {
            try await operation()
        }
    }
}

// MARK: - Task Coordination

/// Runs multiple tasks concurrently and returns all results.
///
/// - Parameter tasks: The tasks to run.
/// - Returns: Array of results in the same order as input tasks.
public func awaitAll<T: Sendable>(_ tasks: [Task<T, Never>]) async -> [T] {
    var results: [T] = []
    results.reserveCapacity(tasks.count)
    
    for task in tasks {
        results.append(await task.value)
    }
    
    return results
}

/// Runs multiple throwing tasks concurrently.
///
/// - Parameter tasks: The tasks to run.
/// - Returns: Array of results.
/// - Throws: The first error encountered.
public func awaitAll<T: Sendable>(_ tasks: [Task<T, Error>]) async throws -> [T] {
    var results: [T] = []
    results.reserveCapacity(tasks.count)
    
    for task in tasks {
        results.append(try await task.value)
    }
    
    return results
}

/// Runs multiple tasks and returns the first to complete.
///
/// - Parameter tasks: The tasks to race.
/// - Returns: The result of the first completing task.
public func race<T: Sendable>(_ tasks: [Task<T, Never>]) async -> T {
    await withTaskGroup(of: T.self) { group in
        for task in tasks {
            group.addTask {
                await task.value
            }
        }
        
        let result = await group.next()!
        group.cancelAll()
        return result
    }
}

/// Runs multiple throwing tasks and returns the first to complete successfully.
///
/// - Parameter tasks: The tasks to race.
/// - Returns: The result of the first successful task.
/// - Throws: If all tasks fail.
public func race<T: Sendable>(_ tasks: [Task<T, Error>]) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        for task in tasks {
            group.addTask {
                try await task.value
            }
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

// MARK: - Task Priority Extensions

extension TaskPriority {
    
    /// Returns a higher priority than the current one.
    public var raised: TaskPriority {
        switch self {
        case .background:
            return .low
        case .low:
            return .medium
        case .medium:
            return .high
        case .high:
            return .high
        case .userInitiated:
            return .userInitiated
        default:
            return self
        }
    }
    
    /// Returns a lower priority than the current one.
    public var lowered: TaskPriority {
        switch self {
        case .background:
            return .background
        case .low:
            return .background
        case .medium:
            return .low
        case .high:
            return .medium
        case .userInitiated:
            return .high
        default:
            return self
        }
    }
}
