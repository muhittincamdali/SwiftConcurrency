// TaskScheduler.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A scheduler for managing timed and recurring async tasks.
///
/// `TaskScheduler` provides a centralized system for scheduling tasks
/// to run at specific times, with delays, or on recurring schedules.
///
/// ## Overview
///
/// Use `TaskScheduler` when you need to manage multiple scheduled tasks,
/// including one-time delayed tasks and recurring operations.
///
/// ```swift
/// let scheduler = TaskScheduler()
///
/// // Schedule a one-time task
/// let task = await scheduler.schedule(after: .seconds(5)) {
///     print("Hello after 5 seconds!")
/// }
///
/// // Schedule a recurring task
/// let recurring = await scheduler.scheduleRepeating(
///     interval: .minutes(1)
/// ) {
///     print("Every minute!")
/// }
///
/// // Later: cancel tasks
/// await scheduler.cancel(task)
/// await scheduler.cancelAll()
/// ```
public actor TaskScheduler {
    
    // MARK: - Types
    
    /// A handle to a scheduled task.
    public struct ScheduledTask: Identifiable, Sendable {
        /// Unique identifier for this task.
        public let id: UUID
        /// The scheduled execution time.
        public let scheduledTime: Date
        /// Whether this is a repeating task.
        public let isRepeating: Bool
        /// The repeat interval (if repeating).
        public let repeatInterval: Duration?
        
        /// Creates a scheduled task handle.
        internal init(
            id: UUID = UUID(),
            scheduledTime: Date,
            isRepeating: Bool = false,
            repeatInterval: Duration? = nil
        ) {
            self.id = id
            self.scheduledTime = scheduledTime
            self.isRepeating = isRepeating
            self.repeatInterval = repeatInterval
        }
    }
    
    /// Common cron-like patterns.
    public enum CronPattern: Sendable {
        case everyMinute
        case everyHour
        case everyDay
        case everyWeek
        case custom(Duration)
        
        var interval: Duration {
            switch self {
            case .everyMinute: return .seconds(60)
            case .everyHour: return .seconds(3600)
            case .everyDay: return .seconds(86400)
            case .everyWeek: return .seconds(604800)
            case .custom(let duration): return duration
            }
        }
    }
    
    // MARK: - Properties
    
    /// The scheduler label for debugging.
    public let label: String
    
    /// Active scheduled tasks.
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    /// Task metadata.
    private var taskMetadata: [UUID: ScheduledTask] = [:]
    
    /// Execution counts for repeating tasks.
    private var executionCounts: [UUID: Int] = [:]
    
    /// Whether the scheduler is running.
    private var isRunning = true
    
    // MARK: - Initialization
    
    /// Creates a task scheduler.
    ///
    /// - Parameter label: A label for debugging.
    public init(label: String = "TaskScheduler") {
        self.label = label
    }
    
    // MARK: - Scheduling
    
    /// Schedules a task to run after a delay.
    ///
    /// - Parameters:
    ///   - delay: Time to wait before execution.
    ///   - priority: Task priority.
    ///   - operation: The operation to perform.
    /// - Returns: A handle to the scheduled task.
    @discardableResult
    public func schedule(
        after delay: Duration,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduledTask {
        let scheduledTime = Date().addingTimeInterval(durationToInterval(delay))
        return scheduleInternal(
            at: scheduledTime,
            priority: priority,
            isRepeating: false,
            repeatInterval: nil,
            operation: operation
        )
    }
    
    /// Schedules a task to run at a specific time.
    ///
    /// - Parameters:
    ///   - time: When to execute the task.
    ///   - priority: Task priority.
    ///   - operation: The operation to perform.
    /// - Returns: A handle to the scheduled task.
    @discardableResult
    public func schedule(
        at time: Date,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduledTask {
        scheduleInternal(
            at: time,
            priority: priority,
            isRepeating: false,
            repeatInterval: nil,
            operation: operation
        )
    }
    
    /// Schedules a repeating task.
    ///
    /// - Parameters:
    ///   - interval: Time between executions.
    ///   - startImmediately: Whether to run immediately.
    ///   - priority: Task priority.
    ///   - operation: The operation to perform.
    /// - Returns: A handle to the scheduled task.
    @discardableResult
    public func scheduleRepeating(
        interval: Duration,
        startImmediately: Bool = false,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduledTask {
        let firstRun = startImmediately ? Date() : Date().addingTimeInterval(durationToInterval(interval))
        return scheduleInternal(
            at: firstRun,
            priority: priority,
            isRepeating: true,
            repeatInterval: interval,
            operation: operation
        )
    }
    
    /// Schedules a task using cron-like syntax.
    ///
    /// - Parameters:
    ///   - pattern: The schedule pattern.
    ///   - operation: The operation to perform.
    /// - Returns: A handle to the scheduled task.
    @discardableResult
    public func schedule(
        cron pattern: CronPattern,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduledTask {
        let interval = pattern.interval
        return scheduleRepeating(
            interval: interval,
            startImmediately: false,
            operation: operation
        )
    }
    
    // MARK: - Management
    
    /// Cancels a scheduled task.
    ///
    /// - Parameter task: The task to cancel.
    public func cancel(_ task: ScheduledTask) {
        cancel(id: task.id)
    }
    
    /// Cancels a task by ID.
    ///
    /// - Parameter id: The task ID.
    public func cancel(id: UUID) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
        taskMetadata.removeValue(forKey: id)
        executionCounts.removeValue(forKey: id)
    }
    
    /// Cancels all scheduled tasks.
    public func cancelAll() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        taskMetadata.removeAll()
        executionCounts.removeAll()
    }
    
    /// Pauses the scheduler.
    public func pause() {
        isRunning = false
    }
    
    /// Resumes the scheduler.
    public func resume() {
        isRunning = true
    }
    
    /// Returns the number of active tasks.
    public var activeTaskCount: Int {
        activeTasks.count
    }
    
    /// Returns all active task handles.
    public var scheduledTasks: [ScheduledTask] {
        Array(taskMetadata.values)
    }
    
    // MARK: - Private Methods
    
    /// Converts Duration to TimeInterval.
    private func durationToInterval(_ duration: Duration) -> TimeInterval {
        let (seconds, attoseconds) = duration.components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
    
    /// Internal scheduling implementation.
    private func scheduleInternal(
        at time: Date,
        priority: TaskPriority?,
        isRepeating: Bool,
        repeatInterval: Duration?,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduledTask {
        let taskHandle = ScheduledTask(
            scheduledTime: time,
            isRepeating: isRepeating,
            repeatInterval: repeatInterval
        )
        
        taskMetadata[taskHandle.id] = taskHandle
        executionCounts[taskHandle.id] = 0
        
        let task = Task(priority: priority) { [weak self] in
            guard let self = self else { return }
            await self.runTask(taskHandle, operation: operation)
        }
        
        activeTasks[taskHandle.id] = task
        
        return taskHandle
    }
    
    /// Runs a scheduled task.
    private func runTask(
        _ handle: ScheduledTask,
        operation: @escaping @Sendable () async -> Void
    ) async {
        var nextRunTime = handle.scheduledTime
        
        while !Task.isCancelled {
            // Wait until scheduled time
            let delay = nextRunTime.timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            
            guard !Task.isCancelled, isRunning else { break }
            
            // Execute operation
            executionCounts[handle.id, default: 0] += 1
            await operation()
            
            // Handle repeating
            if handle.isRepeating, let interval = handle.repeatInterval {
                nextRunTime = Date().addingTimeInterval(durationToInterval(interval))
            } else {
                break
            }
        }
        
        // Cleanup
        activeTasks.removeValue(forKey: handle.id)
        taskMetadata.removeValue(forKey: handle.id)
        executionCounts.removeValue(forKey: handle.id)
    }
}
