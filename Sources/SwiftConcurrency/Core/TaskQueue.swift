// TaskQueue.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - TaskQueue

/// A priority-based task queue that manages concurrent task execution.
///
/// `TaskQueue` provides a sophisticated queuing mechanism for async tasks,
/// supporting priority levels, cancellation, and backpressure handling.
///
/// ## Overview
///
/// Use `TaskQueue` when you need to manage a large number of tasks with
/// different priorities and want fine-grained control over execution order.
///
/// ```swift
/// let queue = TaskQueue<Int>(maxConcurrency: 4)
///
/// // Enqueue tasks with different priorities
/// let result1 = try await queue.enqueue(priority: .high) {
///     await computeExpensiveValue()
/// }
///
/// let result2 = try await queue.enqueue(priority: .low) {
///     await fetchRemoteData()
/// }
/// ```
public actor TaskQueue<Result: Sendable> {
    
    // MARK: - Types
    
    /// Priority levels for queued tasks.
    public enum Priority: Int, Comparable, Sendable {
        case background = 0
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4
        
        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    /// State of a queued task.
    public enum TaskState: Sendable {
        case pending
        case running
        case completed
        case cancelled
        case failed(Error)
    }
    
    /// A handle to a queued task.
    public struct TaskHandle: Sendable, Identifiable {
        public let id: UUID
        public let priority: Priority
        public let createdAt: ContinuousClock.Instant
        
        init(priority: Priority) {
            self.id = UUID()
            self.priority = priority
            self.createdAt = .now
        }
    }
    
    /// Internal representation of a queued task.
    private struct QueuedTask {
        let handle: TaskHandle
        let operation: @Sendable () async throws -> Result
        var continuation: CheckedContinuation<Result, Error>?
        var state: TaskState = .pending
    }
    
    // MARK: - Properties
    
    /// Maximum number of concurrent tasks.
    private let maxConcurrency: Int
    
    /// Current number of running tasks.
    private var runningCount: Int = 0
    
    /// Pending tasks sorted by priority.
    private var pendingTasks: [QueuedTask] = []
    
    /// Map of task handles to their states.
    private var taskStates: [UUID: TaskState] = [:]
    
    /// Queue statistics.
    private var statistics = Statistics()
    
    /// Whether the queue is paused.
    private var isPaused = false
    
    /// Whether the queue is draining (no new tasks).
    private var isDraining = false
    
    /// Continuation for drain completion.
    private var drainContinuation: CheckedContinuation<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates a task queue with the specified concurrency limit.
    ///
    /// - Parameter maxConcurrency: Maximum concurrent tasks. Defaults to 4.
    public init(maxConcurrency: Int = 4) {
        precondition(maxConcurrency > 0, "Max concurrency must be positive")
        self.maxConcurrency = maxConcurrency
    }
    
    // MARK: - Public Methods
    
    /// Enqueues a task for execution.
    ///
    /// - Parameters:
    ///   - priority: Task priority. Defaults to `.normal`.
    ///   - operation: The async operation to execute.
    /// - Returns: The result of the operation.
    /// - Throws: `TaskQueueError` if the queue is draining or the task fails.
    @discardableResult
    public func enqueue(
        priority: Priority = .normal,
        operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        guard !isDraining else {
            throw TaskQueueError.queueDraining
        }
        
        let handle = TaskHandle(priority: priority)
        taskStates[handle.id] = .pending
        statistics.totalEnqueued += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            var task = QueuedTask(
                handle: handle,
                operation: operation,
                continuation: continuation
            )
            task.continuation = continuation
            
            insertTask(task)
            processQueue()
        }
    }
    
    /// Enqueues multiple tasks and returns all results.
    ///
    /// - Parameters:
    ///   - priority: Priority for all tasks.
    ///   - operations: Array of operations to execute.
    /// - Returns: Array of results in the same order as operations.
    public func enqueueBatch(
        priority: Priority = .normal,
        operations: [@Sendable () async throws -> Result]
    ) async throws -> [Result] {
        try await withThrowingTaskGroup(of: (Int, Result).self) { group in
            for (index, operation) in operations.enumerated() {
                group.addTask {
                    let result = try await self.enqueue(
                        priority: priority,
                        operation: operation
                    )
                    return (index, result)
                }
            }
            
            var results: [Int: Result] = [:]
            for try await (index, result) in group {
                results[index] = result
            }
            
            return operations.indices.map { results[$0]! }
        }
    }
    
    /// Cancels a specific task.
    ///
    /// - Parameter handle: The handle of the task to cancel.
    /// - Returns: `true` if the task was cancelled.
    @discardableResult
    public func cancel(handle: TaskHandle) -> Bool {
        if let index = pendingTasks.firstIndex(where: { $0.handle.id == handle.id }) {
            var task = pendingTasks.remove(at: index)
            task.state = .cancelled
            taskStates[handle.id] = .cancelled
            task.continuation?.resume(throwing: TaskQueueError.cancelled)
            statistics.totalCancelled += 1
            return true
        }
        return false
    }
    
    /// Cancels all pending tasks.
    ///
    /// - Returns: The number of cancelled tasks.
    @discardableResult
    public func cancelAll() -> Int {
        let count = pendingTasks.count
        for var task in pendingTasks {
            task.state = .cancelled
            taskStates[task.handle.id] = .cancelled
            task.continuation?.resume(throwing: TaskQueueError.cancelled)
        }
        pendingTasks.removeAll()
        statistics.totalCancelled += count
        return count
    }
    
    /// Pauses the queue.
    public func pause() {
        isPaused = true
    }
    
    /// Resumes the queue.
    public func resume() {
        isPaused = false
        processQueue()
    }
    
    /// Drains the queue, executing remaining tasks but accepting no new ones.
    public func drain() async {
        isDraining = true
        
        if pendingTasks.isEmpty && runningCount == 0 {
            isDraining = false
            return
        }
        
        await withCheckedContinuation { continuation in
            drainContinuation = continuation
        }
        
        isDraining = false
    }
    
    /// Gets the state of a task.
    ///
    /// - Parameter handle: The task handle.
    /// - Returns: The current state, or `nil` if not found.
    public func state(for handle: TaskHandle) -> TaskState? {
        taskStates[handle.id]
    }
    
    /// The number of pending tasks.
    public var pendingCount: Int {
        pendingTasks.count
    }
    
    /// The number of currently running tasks.
    public var currentRunningCount: Int {
        runningCount
    }
    
    /// Whether the queue is currently paused.
    public var currentlyPaused: Bool {
        isPaused
    }
    
    /// Returns current queue statistics.
    public func getStatistics() -> Statistics {
        statistics
    }
    
    // MARK: - Private Methods
    
    /// Inserts a task in priority order.
    private func insertTask(_ task: QueuedTask) {
        let insertIndex = pendingTasks.firstIndex { existing in
            task.handle.priority > existing.handle.priority
        } ?? pendingTasks.endIndex
        
        pendingTasks.insert(task, at: insertIndex)
    }
    
    /// Processes the queue, starting tasks if capacity allows.
    private func processQueue() {
        guard !isPaused else { return }
        
        while runningCount < maxConcurrency && !pendingTasks.isEmpty {
            var task = pendingTasks.removeFirst()
            task.state = .running
            taskStates[task.handle.id] = .running
            runningCount += 1
            
            Task {
                await executeTask(task)
            }
        }
    }
    
    /// Executes a single task.
    private func executeTask(_ task: QueuedTask) async {
        let startTime = ContinuousClock.now
        
        do {
            let result = try await task.operation()
            taskStates[task.handle.id] = .completed
            statistics.totalCompleted += 1
            statistics.totalExecutionTime += ContinuousClock.now - startTime
            task.continuation?.resume(returning: result)
        } catch {
            taskStates[task.handle.id] = .failed(error)
            statistics.totalFailed += 1
            task.continuation?.resume(throwing: error)
        }
        
        runningCount -= 1
        
        if let continuation = drainContinuation,
           pendingTasks.isEmpty && runningCount == 0 {
            drainContinuation = nil
            continuation.resume()
        } else {
            processQueue()
        }
    }
}

// MARK: - Statistics

extension TaskQueue {
    
    /// Statistics about queue operations.
    public struct Statistics: Sendable {
        /// Total tasks enqueued.
        public var totalEnqueued: Int = 0
        
        /// Total tasks completed successfully.
        public var totalCompleted: Int = 0
        
        /// Total tasks that failed.
        public var totalFailed: Int = 0
        
        /// Total tasks cancelled.
        public var totalCancelled: Int = 0
        
        /// Total execution time of all completed tasks.
        public var totalExecutionTime: Duration = .zero
        
        /// Average execution time per task.
        public var averageExecutionTime: Duration {
            guard totalCompleted > 0 else { return .zero }
            return totalExecutionTime / totalCompleted
        }
        
        /// Success rate (0.0 to 1.0).
        public var successRate: Double {
            let total = totalCompleted + totalFailed
            guard total > 0 else { return 1.0 }
            return Double(totalCompleted) / Double(total)
        }
    }
}

// MARK: - TaskQueueError

/// Errors that can occur in task queue operations.
public enum TaskQueueError: Error, Sendable {
    /// The task was cancelled.
    case cancelled
    
    /// The queue is draining and not accepting new tasks.
    case queueDraining
    
    /// The queue has been disposed.
    case disposed
    
    /// The task timed out.
    case timeout
}

// MARK: - BoundedTaskQueue

/// A task queue with backpressure support via a bounded buffer.
///
/// When the queue reaches capacity, enqueue operations will suspend
/// until space becomes available.
public actor BoundedTaskQueue<Result: Sendable> {
    
    // MARK: - Properties
    
    /// Maximum pending tasks before applying backpressure.
    private let maxPending: Int
    
    /// Maximum concurrent tasks.
    private let maxConcurrency: Int
    
    /// Current pending count.
    private var pendingCount: Int = 0
    
    /// Running task count.
    private var runningCount: Int = 0
    
    /// Waiters for space in the queue.
    private var spaceWaiters: [CheckedContinuation<Void, Never>] = []
    
    /// The underlying task queue.
    private let innerQueue: TaskQueue<Result>
    
    // MARK: - Initialization
    
    /// Creates a bounded task queue.
    ///
    /// - Parameters:
    ///   - maxPending: Maximum pending tasks.
    ///   - maxConcurrency: Maximum concurrent tasks.
    public init(maxPending: Int, maxConcurrency: Int = 4) {
        precondition(maxPending > 0, "Max pending must be positive")
        self.maxPending = maxPending
        self.maxConcurrency = maxConcurrency
        self.innerQueue = TaskQueue(maxConcurrency: maxConcurrency)
    }
    
    // MARK: - Public Methods
    
    /// Enqueues a task, potentially waiting for space.
    ///
    /// - Parameters:
    ///   - priority: Task priority.
    ///   - operation: The operation to execute.
    /// - Returns: The result of the operation.
    @discardableResult
    public func enqueue(
        priority: TaskQueue<Result>.Priority = .normal,
        operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        // Wait for space if at capacity
        while pendingCount >= maxPending {
            await withCheckedContinuation { continuation in
                spaceWaiters.append(continuation)
            }
        }
        
        pendingCount += 1
        
        defer {
            pendingCount -= 1
            if let waiter = spaceWaiters.first {
                spaceWaiters.removeFirst()
                waiter.resume()
            }
        }
        
        return try await innerQueue.enqueue(priority: priority, operation: operation)
    }
    
    /// Available space in the queue.
    public var availableSpace: Int {
        max(0, maxPending - pendingCount)
    }
    
    /// Whether the queue is at capacity.
    public var isAtCapacity: Bool {
        pendingCount >= maxPending
    }
}

// MARK: - PriorityTaskQueue

/// A specialized queue optimized for priority-based scheduling.
///
/// Uses a heap-based priority queue for O(log n) enqueue/dequeue operations.
public actor PriorityTaskQueue<Result: Sendable> {
    
    // MARK: - Types
    
    /// Priority with custom comparable value.
    public struct CustomPriority: Comparable, Sendable {
        public let value: Int
        public let tiebreaker: UInt64
        
        public static func < (lhs: CustomPriority, rhs: CustomPriority) -> Bool {
            if lhs.value != rhs.value {
                return lhs.value < rhs.value
            }
            return lhs.tiebreaker > rhs.tiebreaker // Earlier tasks win ties
        }
        
        public init(value: Int) {
            self.value = value
            self.tiebreaker = 0
        }
        
        init(value: Int, tiebreaker: UInt64) {
            self.value = value
            self.tiebreaker = tiebreaker
        }
    }
    
    private struct HeapEntry: Comparable {
        let priority: CustomPriority
        let operation: @Sendable () async throws -> Result
        let continuation: CheckedContinuation<Result, Error>
        
        static func < (lhs: HeapEntry, rhs: HeapEntry) -> Bool {
            lhs.priority < rhs.priority
        }
        
        static func == (lhs: HeapEntry, rhs: HeapEntry) -> Bool {
            lhs.priority == rhs.priority
        }
    }
    
    // MARK: - Properties
    
    private var heap: [HeapEntry] = []
    private var nextTiebreaker: UInt64 = 0
    private var runningCount: Int = 0
    private let maxConcurrency: Int
    
    // MARK: - Initialization
    
    /// Creates a priority task queue.
    ///
    /// - Parameter maxConcurrency: Maximum concurrent tasks.
    public init(maxConcurrency: Int = 4) {
        precondition(maxConcurrency > 0)
        self.maxConcurrency = maxConcurrency
    }
    
    // MARK: - Public Methods
    
    /// Enqueues a task with custom priority.
    ///
    /// - Parameters:
    ///   - priority: Custom priority value (higher = more priority).
    ///   - operation: The operation to execute.
    /// - Returns: The operation result.
    @discardableResult
    public func enqueue(
        priority: Int,
        operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        let tiebreaker = nextTiebreaker
        nextTiebreaker += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            let entry = HeapEntry(
                priority: CustomPriority(value: priority, tiebreaker: tiebreaker),
                operation: operation,
                continuation: continuation
            )
            heapInsert(entry)
            processHeap()
        }
    }
    
    /// The number of pending tasks.
    public var count: Int {
        heap.count
    }
    
    // MARK: - Private Methods
    
    private func heapInsert(_ entry: HeapEntry) {
        heap.append(entry)
        siftUp(heap.count - 1)
    }
    
    private func heapExtractMax() -> HeapEntry? {
        guard !heap.isEmpty else { return nil }
        
        if heap.count == 1 {
            return heap.removeLast()
        }
        
        let max = heap[0]
        heap[0] = heap.removeLast()
        siftDown(0)
        return max
    }
    
    private func siftUp(_ index: Int) {
        var current = index
        while current > 0 {
            let parent = (current - 1) / 2
            if heap[current] > heap[parent] {
                heap.swapAt(current, parent)
                current = parent
            } else {
                break
            }
        }
    }
    
    private func siftDown(_ index: Int) {
        var current = index
        let count = heap.count
        
        while true {
            let left = 2 * current + 1
            let right = 2 * current + 2
            var largest = current
            
            if left < count && heap[left] > heap[largest] {
                largest = left
            }
            if right < count && heap[right] > heap[largest] {
                largest = right
            }
            
            if largest == current {
                break
            }
            
            heap.swapAt(current, largest)
            current = largest
        }
    }
    
    private func processHeap() {
        while runningCount < maxConcurrency, let entry = heapExtractMax() {
            runningCount += 1
            
            Task {
                do {
                    let result = try await entry.operation()
                    entry.continuation.resume(returning: result)
                } catch {
                    entry.continuation.resume(throwing: error)
                }
                
                await self.taskCompleted()
            }
        }
    }
    
    private func taskCompleted() {
        runningCount -= 1
        processHeap()
    }
}

// MARK: - DelayedTaskQueue

/// A queue that supports delayed task execution.
public actor DelayedTaskQueue<Result: Sendable> {
    
    // MARK: - Types
    
    private struct DelayedTask: Comparable {
        let id: UUID
        let executeAt: ContinuousClock.Instant
        let operation: @Sendable () async throws -> Result
        let continuation: CheckedContinuation<Result, Error>
        
        static func < (lhs: DelayedTask, rhs: DelayedTask) -> Bool {
            lhs.executeAt < rhs.executeAt
        }
        
        static func == (lhs: DelayedTask, rhs: DelayedTask) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Properties
    
    private var tasks: [DelayedTask] = []
    private var processingTask: Task<Void, Never>?
    private let maxConcurrency: Int
    private var runningCount: Int = 0
    
    // MARK: - Initialization
    
    /// Creates a delayed task queue.
    ///
    /// - Parameter maxConcurrency: Maximum concurrent tasks.
    public init(maxConcurrency: Int = 4) {
        precondition(maxConcurrency > 0)
        self.maxConcurrency = maxConcurrency
    }
    
    // MARK: - Public Methods
    
    /// Schedules a task for delayed execution.
    ///
    /// - Parameters:
    ///   - delay: Delay before execution.
    ///   - operation: The operation to execute.
    /// - Returns: The operation result after the delay.
    @discardableResult
    public func schedule(
        delay: Duration,
        operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        let executeAt = ContinuousClock.now + delay
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = DelayedTask(
                id: UUID(),
                executeAt: executeAt,
                operation: operation,
                continuation: continuation
            )
            
            insertSorted(task)
            startProcessingIfNeeded()
        }
    }
    
    /// Schedules a task for execution at a specific time.
    ///
    /// - Parameters:
    ///   - at: The time to execute.
    ///   - operation: The operation to execute.
    /// - Returns: The operation result.
    @discardableResult
    public func schedule(
        at executeAt: ContinuousClock.Instant,
        operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            let task = DelayedTask(
                id: UUID(),
                executeAt: executeAt,
                operation: operation,
                continuation: continuation
            )
            
            insertSorted(task)
            startProcessingIfNeeded()
        }
    }
    
    /// The number of scheduled tasks.
    public var scheduledCount: Int {
        tasks.count
    }
    
    /// Cancels all scheduled tasks.
    public func cancelAll() {
        for task in tasks {
            task.continuation.resume(throwing: TaskQueueError.cancelled)
        }
        tasks.removeAll()
        processingTask?.cancel()
        processingTask = nil
    }
    
    // MARK: - Private Methods
    
    private func insertSorted(_ task: DelayedTask) {
        let index = tasks.firstIndex { $0.executeAt > task.executeAt } ?? tasks.endIndex
        tasks.insert(task, at: index)
    }
    
    private func startProcessingIfNeeded() {
        guard processingTask == nil else { return }
        
        processingTask = Task {
            await processLoop()
        }
    }
    
    private func processLoop() async {
        while !tasks.isEmpty {
            guard !Task.isCancelled else { break }
            
            let now = ContinuousClock.now
            
            // Execute all ready tasks
            while runningCount < maxConcurrency,
                  let first = tasks.first,
                  first.executeAt <= now {
                tasks.removeFirst()
                runningCount += 1
                
                Task {
                    await executeTask(first)
                }
            }
            
            // Wait for next task or check interval
            if let first = tasks.first {
                let waitTime = first.executeAt - now
                if waitTime > .zero {
                    try? await Task.sleep(for: min(waitTime, .milliseconds(100)))
                }
            } else {
                break
            }
        }
        
        processingTask = nil
    }
    
    private func executeTask(_ task: DelayedTask) async {
        do {
            let result = try await task.operation()
            task.continuation.resume(returning: result)
        } catch {
            task.continuation.resume(throwing: error)
        }
        
        runningCount -= 1
    }
}

// MARK: - Convenience Extensions

extension TaskQueue where Result == Void {
    
    /// Enqueues a fire-and-forget task.
    ///
    /// - Parameters:
    ///   - priority: Task priority.
    ///   - operation: The operation to execute.
    public func enqueueFireAndForget(
        priority: Priority = .normal,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        Task {
            try? await enqueue(priority: priority, operation: operation)
        }
    }
}
