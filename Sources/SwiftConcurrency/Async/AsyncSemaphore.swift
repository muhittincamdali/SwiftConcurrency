// AsyncSemaphore.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A counting semaphore for limiting concurrent access to resources.
///
/// `AsyncSemaphore` provides a modern Swift concurrency-based implementation
/// of counting semaphores, allowing you to limit the number of concurrent
/// operations accessing a shared resource.
///
/// ## Overview
///
/// Use `AsyncSemaphore` when you need to limit concurrent access to a resource,
/// such as limiting concurrent network requests or database connections.
///
/// ```swift
/// let semaphore = AsyncSemaphore(value: 3) // Allow 3 concurrent operations
///
/// await withTaskGroup(of: Void.self) { group in
///     for url in urls {
///         group.addTask {
///             await semaphore.wait()
///             defer { semaphore.signal() }
///             await fetchData(from: url)
///         }
///     }
/// }
/// ```
public actor AsyncSemaphore {
    
    // MARK: - Properties
    
    /// The current value of the semaphore.
    private var value: Int
    
    /// The initial value of the semaphore.
    private let initialValue: Int
    
    /// Queue of waiters.
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a semaphore with the specified initial value.
    ///
    /// - Parameter value: The initial semaphore value. Must be non-negative.
    ///   This represents the maximum number of concurrent accesses allowed.
    public init(value: Int) {
        precondition(value >= 0, "Semaphore value must be non-negative")
        self.value = value
        self.initialValue = value
    }
    
    // MARK: - Public Methods
    
    /// Waits for the semaphore to become available.
    ///
    /// If the semaphore value is greater than zero, it decrements the value
    /// and returns immediately. Otherwise, it suspends until the semaphore
    /// becomes available.
    public func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Attempts to acquire the semaphore without waiting.
    ///
    /// - Returns: `true` if the semaphore was acquired, `false` otherwise.
    public func tryWait() -> Bool {
        if value > 0 {
            value -= 1
            return true
        }
        return false
    }
    
    /// Signals the semaphore, potentially waking a waiter.
    ///
    /// Increments the semaphore value. If there are waiters, wakes the
    /// first one in the queue.
    public func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            value += 1
        }
    }
    
    /// Executes a closure while holding the semaphore.
    ///
    /// Automatically acquires the semaphore before executing the closure
    /// and releases it afterward.
    ///
    /// - Parameter operation: The closure to execute.
    /// - Returns: The result of the closure.
    public func withSemaphore<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await wait()
        defer { signal() }
        return try await operation()
    }
    
    /// The current available permits.
    public var availablePermits: Int {
        value
    }
    
    /// The number of tasks waiting for the semaphore.
    public var waitingCount: Int {
        waiters.count
    }
    
    /// Resets the semaphore to its initial value.
    ///
    /// - Warning: Any waiting tasks will remain suspended.
    public func reset() {
        value = initialValue
    }
}

// MARK: - Binary Semaphore

/// A binary semaphore (mutex) for mutual exclusion.
///
/// `BinarySemaphore` is a specialized semaphore with only two states:
/// locked and unlocked.
public actor BinarySemaphore {
    
    /// The current lock state.
    private var isLocked: Bool
    
    /// Waiters for the lock.
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    /// Creates a binary semaphore.
    ///
    /// - Parameter locked: Initial state. Defaults to unlocked.
    public init(locked: Bool = false) {
        self.isLocked = locked
    }
    
    /// Locks the semaphore.
    public func lock() async {
        if !isLocked {
            isLocked = true
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Attempts to lock without waiting.
    ///
    /// - Returns: `true` if locked successfully.
    public func tryLock() -> Bool {
        if !isLocked {
            isLocked = true
            return true
        }
        return false
    }
    
    /// Unlocks the semaphore.
    public func unlock() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            isLocked = false
        }
    }
    
    /// Executes a closure while holding the lock.
    ///
    /// - Parameter operation: The closure to execute.
    /// - Returns: The result of the closure.
    public func withLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lock()
        defer { unlock() }
        return try await operation()
    }
}

// MARK: - Fair Semaphore

/// A fair semaphore that guarantees FIFO ordering of waiters.
///
/// Unlike the regular `AsyncSemaphore`, `FairSemaphore` guarantees
/// that waiters are served in the order they arrived.
public actor FairSemaphore {
    
    /// A ticket for tracking waiter order.
    private struct Ticket {
        let number: UInt64
        let continuation: CheckedContinuation<Void, Never>
    }
    
    /// Current semaphore value.
    private var value: Int
    
    /// Next ticket number to assign.
    private var nextTicket: UInt64 = 0
    
    /// Waiting tickets in order.
    private var waitingTickets: [Ticket] = []
    
    /// Creates a fair semaphore.
    ///
    /// - Parameter value: Initial value.
    public init(value: Int) {
        precondition(value >= 0, "Semaphore value must be non-negative")
        self.value = value
    }
    
    /// Waits for the semaphore (FIFO ordered).
    public func wait() async {
        if value > 0 && waitingTickets.isEmpty {
            value -= 1
            return
        }
        
        let ticketNumber = nextTicket
        nextTicket += 1
        
        await withCheckedContinuation { continuation in
            let ticket = Ticket(number: ticketNumber, continuation: continuation)
            waitingTickets.append(ticket)
            waitingTickets.sort { $0.number < $1.number }
        }
    }
    
    /// Signals the semaphore, waking the longest-waiting task.
    public func signal() {
        if let ticket = waitingTickets.first {
            waitingTickets.removeFirst()
            ticket.continuation.resume()
        } else {
            value += 1
        }
    }
    
    /// Executes a closure while holding the semaphore.
    public func withSemaphore<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await wait()
        defer { signal() }
        return try await operation()
    }
}

// MARK: - Read-Write Lock

/// A read-write lock allowing multiple readers or one writer.
public actor ReadWriteLock {
    
    /// Number of active readers.
    private var readers: Int = 0
    
    /// Whether a writer is active.
    private var isWriting = false
    
    /// Waiters for read access.
    private var readWaiters: [CheckedContinuation<Void, Never>] = []
    
    /// Waiters for write access.
    private var writeWaiters: [CheckedContinuation<Void, Never>] = []
    
    /// Creates a read-write lock.
    public init() {}
    
    /// Acquires read access.
    public func lockRead() async {
        while isWriting {
            await withCheckedContinuation { continuation in
                readWaiters.append(continuation)
            }
        }
        readers += 1
    }
    
    /// Releases read access.
    public func unlockRead() {
        readers -= 1
        if readers == 0, let writer = writeWaiters.first {
            writeWaiters.removeFirst()
            writer.resume()
        }
    }
    
    /// Acquires write access.
    public func lockWrite() async {
        while readers > 0 || isWriting {
            await withCheckedContinuation { continuation in
                writeWaiters.append(continuation)
            }
        }
        isWriting = true
    }
    
    /// Releases write access.
    public func unlockWrite() {
        isWriting = false
        
        // Prefer waiting readers
        while !readWaiters.isEmpty {
            let reader = readWaiters.removeFirst()
            reader.resume()
        }
        
        // Or wake a writer
        if let writer = writeWaiters.first {
            writeWaiters.removeFirst()
            writer.resume()
        }
    }
    
    /// Executes a read operation.
    public func withReadLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lockRead()
        defer { unlockRead() }
        return try await operation()
    }
    
    /// Executes a write operation.
    public func withWriteLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lockWrite()
        defer { unlockWrite() }
        return try await operation()
    }
}
