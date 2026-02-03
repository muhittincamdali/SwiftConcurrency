// TaskPool.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - TaskPool

/// A reusable pool of workers for executing async tasks.
///
/// `TaskPool` manages a fixed number of worker tasks that process
/// submitted work items, providing efficient resource utilization
/// for high-throughput scenarios.
///
/// ## Overview
///
/// Use `TaskPool` when you need to process many similar tasks with
/// controlled parallelism and want to avoid the overhead of creating
/// new Task instances for each work item.
///
/// ```swift
/// let pool = TaskPool<Data, ProcessedData>(workers: 8) { data in
///     await processData(data)
/// }
///
/// await pool.start()
///
/// for data in dataItems {
///     let result = try await pool.submit(data)
///     handleResult(result)
/// }
///
/// await pool.shutdown()
/// ```
public actor TaskPool<Input: Sendable, Output: Sendable> {
    
    // MARK: - Types
    
    /// State of the task pool.
    public enum State: Sendable {
        case idle
        case running
        case shuttingDown
        case shutdown
    }
    
    /// Configuration for the task pool.
    public struct Configuration: Sendable {
        /// Number of worker tasks.
        public let workerCount: Int
        
        /// Maximum pending work items.
        public let maxPendingWork: Int
        
        /// Whether to drain pending work on shutdown.
        public let drainOnShutdown: Bool
        
        /// Timeout for graceful shutdown.
        public let shutdownTimeout: Duration
        
        /// Creates a configuration.
        public init(
            workerCount: Int = 4,
            maxPendingWork: Int = 1000,
            drainOnShutdown: Bool = true,
            shutdownTimeout: Duration = .seconds(30)
        ) {
            precondition(workerCount > 0)
            precondition(maxPendingWork > 0)
            self.workerCount = workerCount
            self.maxPendingWork = maxPendingWork
            self.drainOnShutdown = drainOnShutdown
            self.shutdownTimeout = shutdownTimeout
        }
        
        /// Default configuration.
        public static var `default`: Configuration {
            Configuration()
        }
    }
    
    /// A work item submitted to the pool.
    private struct WorkItem {
        let input: Input
        let continuation: CheckedContinuation<Output, Error>
    }
    
    /// Statistics about pool operations.
    public struct Statistics: Sendable {
        /// Total items submitted.
        public var totalSubmitted: Int = 0
        
        /// Total items completed successfully.
        public var totalCompleted: Int = 0
        
        /// Total items that failed.
        public var totalFailed: Int = 0
        
        /// Current pending count.
        public var currentPending: Int = 0
        
        /// Current running count.
        public var currentRunning: Int = 0
        
        /// Average processing time.
        public var averageProcessingTime: Duration = .zero
        
        /// Total processing time.
        public var totalProcessingTime: Duration = .zero
        
        /// Peak concurrent running count.
        public var peakConcurrent: Int = 0
    }
    
    // MARK: - Properties
    
    /// Configuration.
    private let configuration: Configuration
    
    /// The work processing function.
    private let processor: @Sendable (Input) async throws -> Output
    
    /// Current state.
    private var state: State = .idle
    
    /// Pending work items.
    private var workQueue: [WorkItem] = []
    
    /// Waiters for space in the queue.
    private var spaceWaiters: [CheckedContinuation<Void, Never>] = []
    
    /// Worker tasks.
    private var workers: [Task<Void, Never>] = []
    
    /// Statistics.
    private var statistics = Statistics()
    
    /// Signal for new work.
    private var workAvailable: [CheckedContinuation<WorkItem?, Never>] = []
    
    /// Shutdown completion.
    private var shutdownContinuation: CheckedContinuation<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates a task pool.
    ///
    /// - Parameters:
    ///   - configuration: Pool configuration.
    ///   - processor: Function to process each input.
    public init(
        configuration: Configuration = .default,
        processor: @escaping @Sendable (Input) async throws -> Output
    ) {
        self.configuration = configuration
        self.processor = processor
    }
    
    /// Convenience initializer with worker count.
    ///
    /// - Parameters:
    ///   - workers: Number of worker tasks.
    ///   - processor: Function to process each input.
    public init(
        workers: Int,
        processor: @escaping @Sendable (Input) async throws -> Output
    ) {
        self.configuration = Configuration(workerCount: workers)
        self.processor = processor
    }
    
    // MARK: - Lifecycle
    
    /// Starts the pool.
    ///
    /// Creates worker tasks that begin processing submitted work.
    public func start() {
        guard state == .idle else { return }
        state = .running
        
        for index in 0..<configuration.workerCount {
            let worker = Task {
                await workerLoop(id: index)
            }
            workers.append(worker)
        }
    }
    
    /// Shuts down the pool.
    ///
    /// - Parameter force: If true, cancels pending work immediately.
    public func shutdown(force: Bool = false) async {
        guard state == .running else { return }
        state = .shuttingDown
        
        if force || !configuration.drainOnShutdown {
            // Cancel pending work
            for item in workQueue {
                item.continuation.resume(throwing: TaskPoolError.shutdown)
            }
            workQueue.removeAll()
            
            // Cancel workers
            for worker in workers {
                worker.cancel()
            }
            
            // Signal waiting workers
            for waiter in workAvailable {
                waiter.resume(returning: nil)
            }
            workAvailable.removeAll()
            
            // Signal space waiters
            for waiter in spaceWaiters {
                waiter.resume()
            }
            spaceWaiters.removeAll()
            
            state = .shutdown
        } else {
            // Graceful shutdown - wait for pending work
            if workQueue.isEmpty && workAvailable.count == configuration.workerCount {
                // All workers idle, shutdown immediately
                for waiter in workAvailable {
                    waiter.resume(returning: nil)
                }
                workAvailable.removeAll()
                state = .shutdown
            } else {
                // Wait for drain
                await withCheckedContinuation { continuation in
                    shutdownContinuation = continuation
                }
            }
        }
        
        // Wait for workers to finish
        for worker in workers {
            _ = await worker.result
        }
        workers.removeAll()
    }
    
    // MARK: - Submission
    
    /// Submits work to the pool.
    ///
    /// - Parameter input: The input to process.
    /// - Returns: The processed output.
    /// - Throws: `TaskPoolError` if the pool is not running.
    public func submit(_ input: Input) async throws -> Output {
        guard state == .running else {
            throw TaskPoolError.notRunning
        }
        
        // Backpressure: wait for space
        while workQueue.count >= configuration.maxPendingWork {
            await withCheckedContinuation { continuation in
                spaceWaiters.append(continuation)
            }
            
            // Re-check state after waiting
            guard state == .running else {
                throw TaskPoolError.notRunning
            }
        }
        
        statistics.totalSubmitted += 1
        statistics.currentPending += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            let item = WorkItem(input: input, continuation: continuation)
            workQueue.append(item)
            
            // Wake a waiting worker
            if let waiter = workAvailable.first {
                workAvailable.removeFirst()
                waiter.resume(returning: workQueue.removeFirst())
            }
        }
    }
    
    /// Submits multiple items and returns results.
    ///
    /// - Parameter inputs: Array of inputs to process.
    /// - Returns: Array of outputs in corresponding order.
    public func submitBatch(_ inputs: [Input]) async throws -> [Output] {
        try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            for (index, input) in inputs.enumerated() {
                group.addTask {
                    let output = try await self.submit(input)
                    return (index, output)
                }
            }
            
            var results: [Int: Output] = [:]
            for try await (index, output) in group {
                results[index] = output
            }
            
            return inputs.indices.map { results[$0]! }
        }
    }
    
    /// Submits work without waiting for result.
    ///
    /// - Parameter input: The input to process.
    public func submitFireAndForget(_ input: Input) {
        Task {
            try? await submit(input)
        }
    }
    
    // MARK: - Status
    
    /// Current pool state.
    public var currentState: State {
        state
    }
    
    /// Current statistics.
    public func getStatistics() -> Statistics {
        var stats = statistics
        stats.currentPending = workQueue.count
        return stats
    }
    
    /// Number of pending items.
    public var pendingCount: Int {
        workQueue.count
    }
    
    /// Whether the pool is running.
    public var isRunning: Bool {
        state == .running
    }
    
    // MARK: - Private Methods
    
    /// Worker loop.
    private func workerLoop(id: Int) async {
        while !Task.isCancelled {
            // Get next work item
            let item = await getNextWorkItem()
            
            guard let item = item else {
                break // Shutdown signal
            }
            
            statistics.currentPending -= 1
            statistics.currentRunning += 1
            statistics.peakConcurrent = max(statistics.peakConcurrent, statistics.currentRunning)
            
            let startTime = ContinuousClock.now
            
            do {
                let output = try await processor(item.input)
                statistics.totalCompleted += 1
                item.continuation.resume(returning: output)
            } catch {
                statistics.totalFailed += 1
                item.continuation.resume(throwing: error)
            }
            
            let elapsed = ContinuousClock.now - startTime
            await updateProcessingTime(elapsed)
            
            statistics.currentRunning -= 1
            
            // Signal space waiter
            if let waiter = spaceWaiters.first {
                spaceWaiters.removeFirst()
                waiter.resume()
            }
            
            // Check for shutdown completion
            await checkShutdownCompletion()
        }
    }
    
    /// Gets the next work item, waiting if necessary.
    private func getNextWorkItem() async -> WorkItem? {
        if state == .shutdown || Task.isCancelled {
            return nil
        }
        
        if let item = workQueue.first {
            workQueue.removeFirst()
            return item
        }
        
        // Wait for work
        return await withCheckedContinuation { continuation in
            if state == .shuttingDown && workQueue.isEmpty {
                continuation.resume(returning: nil)
            } else {
                workAvailable.append(continuation)
            }
        }
    }
    
    /// Updates average processing time.
    private func updateProcessingTime(_ elapsed: Duration) {
        statistics.totalProcessingTime += elapsed
        let total = statistics.totalCompleted + statistics.totalFailed
        if total > 0 {
            statistics.averageProcessingTime = statistics.totalProcessingTime / total
        }
    }
    
    /// Checks if shutdown is complete.
    private func checkShutdownCompletion() {
        if state == .shuttingDown && workQueue.isEmpty && statistics.currentRunning == 0 {
            state = .shutdown
            
            // Signal remaining workers to stop
            for waiter in workAvailable {
                waiter.resume(returning: nil)
            }
            workAvailable.removeAll()
            
            // Complete shutdown
            shutdownContinuation?.resume()
            shutdownContinuation = nil
        }
    }
}

// MARK: - TaskPoolError

/// Errors that can occur in task pool operations.
public enum TaskPoolError: Error, Sendable {
    /// The pool is not running.
    case notRunning
    
    /// The pool is shutting down.
    case shutdown
    
    /// The work queue is full.
    case queueFull
}

// MARK: - DynamicTaskPool

/// A task pool with dynamic worker scaling.
///
/// Automatically adjusts the number of workers based on load.
public actor DynamicTaskPool<Input: Sendable, Output: Sendable> {
    
    // MARK: - Types
    
    /// Scaling configuration.
    public struct ScalingConfig: Sendable {
        /// Minimum workers.
        public let minWorkers: Int
        
        /// Maximum workers.
        public let maxWorkers: Int
        
        /// Scale up when queue exceeds this size per worker.
        public let scaleUpThreshold: Int
        
        /// Scale down when workers are idle for this duration.
        public let scaleDownDelay: Duration
        
        /// Creates scaling configuration.
        public init(
            minWorkers: Int = 1,
            maxWorkers: Int = 16,
            scaleUpThreshold: Int = 10,
            scaleDownDelay: Duration = .seconds(30)
        ) {
            precondition(minWorkers > 0)
            precondition(maxWorkers >= minWorkers)
            self.minWorkers = minWorkers
            self.maxWorkers = maxWorkers
            self.scaleUpThreshold = scaleUpThreshold
            self.scaleDownDelay = scaleDownDelay
        }
    }
    
    // MARK: - Properties
    
    private let scalingConfig: ScalingConfig
    private let processor: @Sendable (Input) async throws -> Output
    
    private var workers: [UUID: Task<Void, Never>] = [:]
    private var workerLastActive: [UUID: ContinuousClock.Instant] = [:]
    private var workQueue: [(Input, CheckedContinuation<Output, Error>)] = []
    private var workAvailable: [UUID: CheckedContinuation<(Input, CheckedContinuation<Output, Error>)?, Never>] = [:]
    
    private var isRunning = false
    private var scalingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates a dynamic task pool.
    public init(
        scaling: ScalingConfig = ScalingConfig(),
        processor: @escaping @Sendable (Input) async throws -> Output
    ) {
        self.scalingConfig = scaling
        self.processor = processor
    }
    
    // MARK: - Lifecycle
    
    /// Starts the pool with minimum workers.
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        for _ in 0..<scalingConfig.minWorkers {
            spawnWorker()
        }
        
        scalingTask = Task {
            await scalingLoop()
        }
    }
    
    /// Shuts down the pool.
    public func shutdown() async {
        isRunning = false
        scalingTask?.cancel()
        
        for (_, task) in workers {
            task.cancel()
        }
        
        for (_, waiter) in workAvailable {
            waiter.resume(returning: nil)
        }
        
        for (_, continuation) in workQueue {
            continuation.resume(throwing: TaskPoolError.shutdown)
        }
        
        workers.removeAll()
        workQueue.removeAll()
        workAvailable.removeAll()
    }
    
    // MARK: - Submission
    
    /// Submits work.
    public func submit(_ input: Input) async throws -> Output {
        guard isRunning else {
            throw TaskPoolError.notRunning
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Try to give directly to waiting worker
            if let (id, waiter) = workAvailable.first {
                workAvailable.removeValue(forKey: id)
                workerLastActive[id] = .now
                waiter.resume(returning: (input, continuation))
            } else {
                workQueue.append((input, continuation))
            }
        }
    }
    
    /// Current worker count.
    public var workerCount: Int {
        workers.count
    }
    
    /// Pending work count.
    public var pendingCount: Int {
        workQueue.count
    }
    
    // MARK: - Private Methods
    
    private func spawnWorker() {
        let id = UUID()
        let task = Task {
            await workerLoop(id: id)
        }
        workers[id] = task
        workerLastActive[id] = .now
    }
    
    private func removeWorker(id: UUID) {
        workers[id]?.cancel()
        workers.removeValue(forKey: id)
        workerLastActive.removeValue(forKey: id)
        workAvailable.removeValue(forKey: id)
    }
    
    private func workerLoop(id: UUID) async {
        while !Task.isCancelled && isRunning {
            let work = await getWork(for: id)
            
            guard let (input, continuation) = work else {
                break
            }
            
            do {
                let output = try await processor(input)
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: error)
            }
            
            workerLastActive[id] = .now
        }
    }
    
    private func getWork(for id: UUID) async -> (Input, CheckedContinuation<Output, Error>)? {
        if let work = workQueue.first {
            workQueue.removeFirst()
            return work
        }
        
        return await withCheckedContinuation { continuation in
            workAvailable[id] = continuation
        }
    }
    
    private func scalingLoop() async {
        while !Task.isCancelled && isRunning {
            try? await Task.sleep(for: .seconds(1))
            
            await adjustWorkers()
        }
    }
    
    private func adjustWorkers() {
        let currentWorkers = workers.count
        let pendingWork = workQueue.count
        
        // Scale up if needed
        let targetForLoad = (pendingWork / scalingConfig.scaleUpThreshold) + 1
        if targetForLoad > currentWorkers && currentWorkers < scalingConfig.maxWorkers {
            let toAdd = min(targetForLoad - currentWorkers, scalingConfig.maxWorkers - currentWorkers)
            for _ in 0..<toAdd {
                spawnWorker()
            }
        }
        
        // Scale down idle workers
        if currentWorkers > scalingConfig.minWorkers {
            let now = ContinuousClock.now
            for (id, lastActive) in workerLastActive {
                if now - lastActive > scalingConfig.scaleDownDelay && workers.count > scalingConfig.minWorkers {
                    removeWorker(id: id)
                }
            }
        }
    }
}

// MARK: - WorkStealingPool

/// A work-stealing task pool for better load balancing.
///
/// Workers can steal work from other workers' queues when idle.
public actor WorkStealingPool<Input: Sendable, Output: Sendable> {
    
    // MARK: - Types
    
    private struct WorkerQueue {
        var items: [(Input, CheckedContinuation<Output, Error>)] = []
        var waiter: CheckedContinuation<(Input, CheckedContinuation<Output, Error>)?, Never>?
    }
    
    // MARK: - Properties
    
    private let workerCount: Int
    private let processor: @Sendable (Input) async throws -> Output
    
    private var queues: [Int: WorkerQueue] = [:]
    private var workers: [Task<Void, Never>] = []
    private var nextQueue = 0
    private var isRunning = false
    
    // MARK: - Initialization
    
    /// Creates a work-stealing pool.
    public init(
        workers: Int = 4,
        processor: @escaping @Sendable (Input) async throws -> Output
    ) {
        precondition(workers > 0)
        self.workerCount = workers
        self.processor = processor
    }
    
    // MARK: - Lifecycle
    
    /// Starts the pool.
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        for i in 0..<workerCount {
            queues[i] = WorkerQueue()
            let worker = Task {
                await workerLoop(id: i)
            }
            workers.append(worker)
        }
    }
    
    /// Shuts down the pool.
    public func shutdown() async {
        isRunning = false
        
        for worker in workers {
            worker.cancel()
        }
        
        for (_, queue) in queues {
            queue.waiter?.resume(returning: nil)
            for (_, continuation) in queue.items {
                continuation.resume(throwing: TaskPoolError.shutdown)
            }
        }
        
        workers.removeAll()
        queues.removeAll()
    }
    
    // MARK: - Submission
    
    /// Submits work using round-robin distribution.
    public func submit(_ input: Input) async throws -> Output {
        guard isRunning else {
            throw TaskPoolError.notRunning
        }
        
        let queueId = nextQueue
        nextQueue = (nextQueue + 1) % workerCount
        
        return try await withCheckedThrowingContinuation { continuation in
            if var queue = queues[queueId] {
                if let waiter = queue.waiter {
                    queue.waiter = nil
                    queues[queueId] = queue
                    waiter.resume(returning: (input, continuation))
                } else {
                    queue.items.append((input, continuation))
                    queues[queueId] = queue
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func workerLoop(id: Int) async {
        while !Task.isCancelled && isRunning {
            let work = await getWork(for: id)
            
            guard let (input, continuation) = work else {
                break
            }
            
            do {
                let output = try await processor(input)
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func getWork(for id: Int) async -> (Input, CheckedContinuation<Output, Error>)? {
        // Try own queue
        if var queue = queues[id], !queue.items.isEmpty {
            let work = queue.items.removeFirst()
            queues[id] = queue
            return work
        }
        
        // Try stealing from others
        for otherId in 0..<workerCount where otherId != id {
            if var queue = queues[otherId], !queue.items.isEmpty {
                let work = queue.items.removeFirst()
                queues[otherId] = queue
                return work
            }
        }
        
        // Wait for work on own queue
        return await withCheckedContinuation { continuation in
            if var queue = queues[id] {
                queue.waiter = continuation
                queues[id] = queue
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
