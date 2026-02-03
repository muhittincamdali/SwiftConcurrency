// OrderedTaskGroup.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A task group that preserves the order of results matching the input order.
///
/// Unlike regular `TaskGroup` which returns results in completion order,
/// `OrderedTaskGroup` ensures results maintain their original submission order.
///
/// ## Overview
///
/// Use `OrderedTaskGroup` when you need parallel execution but require
/// results in a deterministic order matching your input sequence.
///
/// ```swift
/// let urls = [url1, url2, url3]
/// let results = try await withOrderedTaskGroup(of: Data.self) { group in
///     for (index, url) in urls.enumerated() {
///         group.addTask(index: index) {
///             try await URLSession.shared.data(from: url).0
///         }
///     }
///     return try await group.collectOrdered()
/// }
/// // results[0] corresponds to url1, results[1] to url2, etc.
/// ```
///
/// ## Topics
///
/// ### Creating Ordered Task Groups
/// - ``withOrderedTaskGroup(of:returning:body:)``
/// - ``withThrowingOrderedTaskGroup(of:returning:body:)``
///
/// ### Managing Tasks
/// - ``OrderedTaskGroupBuilder/addTask(index:priority:operation:)``
/// - ``OrderedTaskGroupBuilder/collectOrdered()``

// MARK: - Configuration

/// Configuration options for ordered task groups.
public struct OrderedTaskGroupConfiguration: Sendable {
    /// Maximum concurrent tasks. `nil` means unlimited.
    public var maxConcurrency: Int?
    /// Whether to cancel remaining tasks on first failure.
    public var cancelOnFailure: Bool
    
    /// Default configuration with unlimited concurrency.
    public static var `default`: OrderedTaskGroupConfiguration {
        OrderedTaskGroupConfiguration(
            maxConcurrency: nil,
            cancelOnFailure: true
        )
    }
    
    /// Creates a configuration with specified options.
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent tasks.
    ///   - cancelOnFailure: Whether to cancel on failure.
    public init(maxConcurrency: Int? = nil, cancelOnFailure: Bool = true) {
        self.maxConcurrency = maxConcurrency
        self.cancelOnFailure = cancelOnFailure
    }
}

// MARK: - Public API

/// Executes tasks in parallel while preserving result order.
///
/// Results are returned in the same order as tasks were added,
/// regardless of completion order.
///
/// - Parameters:
///   - elementType: The type of values produced by tasks.
///   - returnType: The return type of the body closure.
///   - body: A closure that adds tasks to the group.
/// - Returns: The value returned by the body closure.
public func withOrderedTaskGroup<Success: Sendable, GroupResult>(
    of elementType: Success.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    body: @Sendable (inout OrderedTaskGroupBuilder<Success>) async -> GroupResult
) async -> GroupResult {
    var builder = OrderedTaskGroupBuilder<Success>()
    return await body(&builder)
}

/// Executes throwing tasks in parallel while preserving result order.
///
/// - Parameters:
///   - elementType: The type of values produced by tasks.
///   - returnType: The return type of the body closure.
///   - body: A closure that adds tasks to the group.
/// - Returns: The value returned by the body closure.
/// - Throws: Any error thrown by tasks or the body closure.
public func withThrowingOrderedTaskGroup<Success: Sendable, GroupResult>(
    of elementType: Success.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    body: @Sendable (inout ThrowingOrderedTaskGroupBuilder<Success>) async throws -> GroupResult
) async rethrows -> GroupResult {
    var builder = ThrowingOrderedTaskGroupBuilder<Success>()
    return try await body(&builder)
}

/// A builder for creating ordered task groups.
public struct OrderedTaskGroupBuilder<Success: Sendable>: Sendable {
    
    /// Storage for pending tasks.
    private let pendingTasks: PendingTasksStorage<Success>
    
    /// Creates a new builder.
    internal init() {
        self.pendingTasks = PendingTasksStorage()
    }
    
    /// Adds a task with a specified index.
    /// - Parameters:
    ///   - index: The position index for this task's result.
    ///   - priority: The task priority.
    ///   - operation: The async operation to perform.
    public func addTask(
        index: Int,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Success
    ) {
        Task {
            await pendingTasks.add(index: index, priority: priority, operation: operation)
        }
    }
    
    /// Collects all results in order.
    /// - Returns: Array of results sorted by their index.
    public func collectOrdered() async -> [Success] {
        await pendingTasks.executeAndCollect()
    }
}

/// A builder for creating throwing ordered task groups.
public struct ThrowingOrderedTaskGroupBuilder<Success: Sendable>: Sendable {
    
    /// Storage for pending tasks.
    private let pendingTasks: ThrowingPendingTasksStorage<Success>
    
    /// Creates a new builder.
    internal init() {
        self.pendingTasks = ThrowingPendingTasksStorage()
    }
    
    /// Adds a throwing task with a specified index.
    /// - Parameters:
    ///   - index: The position index for this task's result.
    ///   - priority: The task priority.
    ///   - operation: The async throwing operation to perform.
    public func addTask(
        index: Int,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        Task {
            await pendingTasks.add(index: index, priority: priority, operation: operation)
        }
    }
    
    /// Collects all results in order.
    /// - Returns: Array of results sorted by their index.
    /// - Throws: Any error thrown by the tasks.
    public func collectOrdered() async throws -> [Success] {
        try await pendingTasks.executeAndCollect()
    }
}

/// Actor for storing pending non-throwing tasks.
internal actor PendingTasksStorage<Success: Sendable> {
    
    /// Pending task descriptors.
    private var tasks: [(index: Int, priority: TaskPriority?, operation: @Sendable () async -> Success)] = []
    
    /// Adds a pending task.
    func add(index: Int, priority: TaskPriority?, operation: @escaping @Sendable () async -> Success) {
        tasks.append((index, priority, operation))
    }
    
    /// Executes all tasks and collects results in order.
    func executeAndCollect() async -> [Success] {
        let tasksCopy = tasks
        return await withTaskGroup(of: (Int, Success).self) { group in
            for (index, priority, operation) in tasksCopy {
                group.addTask(priority: priority) {
                    let result = await operation()
                    return (index, result)
                }
            }
            
            var results: [Int: Success] = [:]
            for await (index, result) in group {
                results[index] = result
            }
            
            return (0..<tasksCopy.count).compactMap { results[$0] }
        }
    }
}

/// Actor for storing pending throwing tasks.
internal actor ThrowingPendingTasksStorage<Success: Sendable> {
    
    /// Pending task descriptors.
    private var tasks: [(index: Int, priority: TaskPriority?, operation: @Sendable () async throws -> Success)] = []
    
    /// Adds a pending task.
    func add(index: Int, priority: TaskPriority?, operation: @escaping @Sendable () async throws -> Success) {
        tasks.append((index, priority, operation))
    }
    
    /// Executes all tasks and collects results in order.
    func executeAndCollect() async throws -> [Success] {
        let tasksCopy = tasks
        return try await withThrowingTaskGroup(of: (Int, Success).self) { group in
            for (index, priority, operation) in tasksCopy {
                group.addTask(priority: priority) {
                    let result = try await operation()
                    return (index, result)
                }
            }
            
            var results: [Int: Success] = [:]
            for try await (index, result) in group {
                results[index] = result
            }
            
            return (0..<tasksCopy.count).compactMap { results[$0] }
        }
    }
}

// MARK: - Convenience Extensions

extension Sequence where Element: Sendable {
    
    /// Concurrently maps while preserving order.
    ///
    /// - Parameter transform: The transform to apply to each element.
    /// - Returns: Array of transformed elements in original order.
    public func orderedConcurrentMap<T: Sendable>(
        _ transform: @escaping @Sendable (Element) async -> T
    ) async -> [T] {
        let items = Array(self)
        return await withOrderedTaskGroup(of: T.self) { group in
            for (index, item) in items.enumerated() {
                group.addTask(index: index) {
                    await transform(item)
                }
            }
            return await group.collectOrdered()
        }
    }
    
    /// Concurrently maps while preserving order (throwing).
    ///
    /// - Parameter transform: The throwing transform to apply.
    /// - Returns: Array of transformed elements in original order.
    /// - Throws: Any error from the transform.
    public func orderedConcurrentMap<T: Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] {
        let items = Array(self)
        return try await withThrowingOrderedTaskGroup(of: T.self) { group in
            for (index, item) in items.enumerated() {
                group.addTask(index: index) {
                    try await transform(item)
                }
            }
            return try await group.collectOrdered()
        }
    }
}
