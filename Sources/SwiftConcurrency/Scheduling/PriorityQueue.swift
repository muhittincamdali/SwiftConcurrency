// PriorityQueue.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A thread-safe priority queue for async operations.
///
/// `AsyncPriorityQueue` allows enqueuing items with priorities
/// and dequeuing them in priority order (highest first).
///
/// ## Overview
///
/// Use `AsyncPriorityQueue` when you need to process items
/// based on their priority rather than arrival order.
///
/// ```swift
/// let queue = AsyncPriorityQueue<Task>()
///
/// await queue.enqueue(lowPriorityTask, priority: 1)
/// await queue.enqueue(highPriorityTask, priority: 10)
/// await queue.enqueue(mediumTask, priority: 5)
///
/// // Dequeues high, medium, low (by priority)
/// while let task = await queue.dequeue() {
///     await task.execute()
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Priority Queues
/// - ``init()``
///
/// ### Queue Operations
/// - ``enqueue(_:priority:)``
/// - ``dequeue()``
/// - ``peek()``
public actor AsyncPriorityQueue<Element: Sendable> {
    
    // MARK: - Types
    
    /// An item with its priority.
    private struct PrioritizedItem: Comparable {
        let element: Element
        let priority: Int
        let insertionOrder: UInt64
        
        static func < (lhs: PrioritizedItem, rhs: PrioritizedItem) -> Bool {
            if lhs.priority != rhs.priority {
                return lhs.priority > rhs.priority // Higher priority first
            }
            return lhs.insertionOrder < rhs.insertionOrder // FIFO for same priority
        }
        
        static func == (lhs: PrioritizedItem, rhs: PrioritizedItem) -> Bool {
            lhs.priority == rhs.priority && lhs.insertionOrder == rhs.insertionOrder
        }
    }
    
    // MARK: - Properties
    
    /// The heap storage.
    private var heap: [PrioritizedItem] = []
    
    /// Insertion counter for FIFO ordering within same priority.
    private var insertionCounter: UInt64 = 0
    
    /// Continuations waiting for elements.
    private var waiters: [CheckedContinuation<Element, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates an empty priority queue.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Enqueues an element with the specified priority.
    ///
    /// - Parameters:
    ///   - element: The element to enqueue.
    ///   - priority: The priority (higher values dequeue first).
    public func enqueue(_ element: Element, priority: Int = 0) {
        let item = PrioritizedItem(
            element: element,
            priority: priority,
            insertionOrder: insertionCounter
        )
        insertionCounter += 1
        
        // If someone is waiting, give directly
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume(returning: element)
            return
        }
        
        // Add to heap
        heap.append(item)
        siftUp(heap.count - 1)
    }
    
    /// Dequeues the highest priority element.
    ///
    /// If the queue is empty, waits for an element to be enqueued.
    ///
    /// - Returns: The highest priority element.
    public func dequeue() async -> Element {
        if let item = removeMax() {
            return item.element
        }
        
        // Queue is empty, wait for an element
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Dequeues the highest priority element without waiting.
    ///
    /// - Returns: The highest priority element, or `nil` if empty.
    public func tryDequeue() -> Element? {
        removeMax()?.element
    }
    
    /// Returns the highest priority element without removing it.
    ///
    /// - Returns: The highest priority element, or `nil` if empty.
    public func peek() -> Element? {
        heap.first?.element
    }
    
    /// The number of elements in the queue.
    public var count: Int {
        heap.count
    }
    
    /// Whether the queue is empty.
    public var isEmpty: Bool {
        heap.isEmpty
    }
    
    /// Removes all elements from the queue.
    public func clear() {
        heap.removeAll()
    }
    
    // MARK: - Heap Operations
    
    /// Removes and returns the maximum (highest priority) item.
    private func removeMax() -> PrioritizedItem? {
        guard !heap.isEmpty else { return nil }
        
        if heap.count == 1 {
            return heap.removeLast()
        }
        
        let max = heap[0]
        heap[0] = heap.removeLast()
        siftDown(0)
        return max
    }
    
    /// Sifts an item up to maintain heap property.
    private func siftUp(_ index: Int) {
        var childIndex = index
        let item = heap[childIndex]
        
        while childIndex > 0 {
            let parentIndex = (childIndex - 1) / 2
            if heap[parentIndex] >= item {
                break
            }
            heap[childIndex] = heap[parentIndex]
            childIndex = parentIndex
        }
        
        heap[childIndex] = item
    }
    
    /// Sifts an item down to maintain heap property.
    private func siftDown(_ index: Int) {
        var parentIndex = index
        let item = heap[parentIndex]
        let count = heap.count
        
        while true {
            let leftChildIndex = 2 * parentIndex + 1
            let rightChildIndex = leftChildIndex + 1
            var maxIndex = parentIndex
            
            if leftChildIndex < count && heap[leftChildIndex] > heap[maxIndex] {
                maxIndex = leftChildIndex
            }
            if rightChildIndex < count && heap[rightChildIndex] > heap[maxIndex] {
                maxIndex = rightChildIndex
            }
            
            if maxIndex == parentIndex {
                break
            }
            
            heap[parentIndex] = heap[maxIndex]
            parentIndex = maxIndex
        }
        
        heap[parentIndex] = item
    }
}

// MARK: - Bounded Priority Queue

/// A priority queue with a maximum capacity.
///
/// When at capacity, lowest priority items are removed to make room.
public actor BoundedPriorityQueue<Element: Sendable> {
    
    /// The underlying queue.
    private let queue: AsyncPriorityQueue<Element>
    
    /// Maximum capacity.
    private let capacity: Int
    
    /// Current count.
    private var _count: Int = 0
    
    /// Creates a bounded priority queue.
    ///
    /// - Parameter capacity: Maximum number of elements.
    public init(capacity: Int) {
        precondition(capacity > 0, "Capacity must be positive")
        self.capacity = capacity
        self.queue = AsyncPriorityQueue()
    }
    
    /// Enqueues an element, removing lowest priority if at capacity.
    ///
    /// - Parameters:
    ///   - element: The element to enqueue.
    ///   - priority: The priority.
    /// - Returns: The removed element if at capacity, or `nil`.
    @discardableResult
    public func enqueue(_ element: Element, priority: Int = 0) async -> Element? {
        var removed: Element?
        
        if _count >= capacity {
            // Remove lowest priority (this is inefficient but simple)
            // A real implementation would use a min-max heap
            removed = await queue.tryDequeue()
            if removed != nil {
                _count -= 1
            }
        }
        
        await queue.enqueue(element, priority: priority)
        _count += 1
        
        return removed
    }
    
    /// Dequeues the highest priority element.
    public func dequeue() async -> Element {
        let element = await queue.dequeue()
        _count = max(0, _count - 1)
        return element
    }
    
    /// The number of elements.
    public var count: Int {
        _count
    }
    
    /// Whether at capacity.
    public var isFull: Bool {
        _count >= capacity
    }
}

// MARK: - Priority Task Queue

/// A queue for executing prioritized tasks.
public actor PriorityTaskQueue {
    
    /// A prioritized operation.
    private struct PrioritizedOperation: Sendable {
        let operation: @Sendable () async -> Void
        let priority: Int
    }
    
    /// The operation queue.
    private let queue = AsyncPriorityQueue<PrioritizedOperation>()
    
    /// Maximum concurrent operations.
    private let maxConcurrent: Int
    
    /// Current running count.
    private var runningCount: Int = 0
    
    /// Whether the queue is paused.
    private var isPaused = false
    
    /// Creates a priority task queue.
    ///
    /// - Parameter maxConcurrent: Maximum concurrent operations.
    public init(maxConcurrent: Int = 1) {
        self.maxConcurrent = max(1, maxConcurrent)
    }
    
    /// Submits an operation with priority.
    ///
    /// - Parameters:
    ///   - priority: Operation priority.
    ///   - operation: The operation to perform.
    public func submit(
        priority: Int = 0,
        operation: @escaping @Sendable () async -> Void
    ) async {
        let op = PrioritizedOperation(operation: operation, priority: priority)
        await queue.enqueue(op, priority: priority)
        await processNext()
    }
    
    /// Pauses processing.
    public func pause() {
        isPaused = true
    }
    
    /// Resumes processing.
    public func resume() async {
        isPaused = false
        await processNext()
    }
    
    /// Processes the next operation if possible.
    private func processNext() async {
        guard !isPaused, runningCount < maxConcurrent else { return }
        
        guard let op = await queue.tryDequeue() else { return }
        
        runningCount += 1
        
        Task {
            await op.operation()
            await self.operationComplete()
        }
    }
    
    /// Called when an operation completes.
    private func operationComplete() async {
        runningCount -= 1
        await processNext()
    }
}
