// AsyncLock.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncLock

/// A simple async mutex for mutual exclusion.
///
/// Provides exclusive access to a resource, suspending callers
/// when the lock is held.
///
/// ```swift
/// let lock = AsyncLock()
///
/// await lock.withLock {
///     // Critical section
///     await modifySharedState()
/// }
/// ```
public actor AsyncLock {
    
    // MARK: - Properties
    
    /// Whether the lock is currently held.
    private var isLocked = false
    
    /// Queue of waiters.
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates an async lock.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Acquires the lock.
    ///
    /// Suspends if the lock is held by another caller.
    public func lock() async {
        if !isLocked {
            isLocked = true
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Releases the lock.
    ///
    /// Wakes the next waiter if any.
    public func unlock() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            isLocked = false
        }
    }
    
    /// Attempts to acquire the lock without waiting.
    ///
    /// - Returns: `true` if acquired, `false` if already held.
    public func tryLock() -> Bool {
        if !isLocked {
            isLocked = true
            return true
        }
        return false
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
    
    /// Whether the lock is currently held.
    public var locked: Bool {
        isLocked
    }
    
    /// Number of waiting acquirers.
    public var waitingCount: Int {
        waiters.count
    }
}

// MARK: - AsyncRecursiveLock

/// A recursive async lock allowing re-entry by the same task.
///
/// Unlike `AsyncLock`, allows the same task to acquire the lock
/// multiple times without deadlocking.
public actor AsyncRecursiveLock {
    
    // MARK: - Properties
    
    /// Current owner task identifier.
    private var owner: ObjectIdentifier?
    
    /// Re-entry count for the owner.
    private var recursionCount = 0
    
    /// Waiting tasks.
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a recursive lock.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Acquires the lock, allowing re-entry.
    public func lock() async {
        let taskId = ObjectIdentifier(Task.current as AnyObject)
        
        if owner == taskId {
            recursionCount += 1
            return
        }
        
        if owner == nil {
            owner = taskId
            recursionCount = 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        
        // When woken, we own the lock
        owner = taskId
        recursionCount = 1
    }
    
    /// Releases the lock.
    public func unlock() {
        recursionCount -= 1
        
        if recursionCount == 0 {
            owner = nil
            
            if let waiter = waiters.first {
                waiters.removeFirst()
                waiter.resume()
            }
        }
    }
    
    /// Executes while holding the lock.
    public func withLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lock()
        defer { unlock() }
        return try await operation()
    }
}

// MARK: - AsyncFairLock

/// A fair lock guaranteeing FIFO ordering.
///
/// Waiters are served in the order they requested the lock.
public actor AsyncFairLock {
    
    // MARK: - Types
    
    private struct Waiter {
        let ticket: UInt64
        let continuation: CheckedContinuation<Void, Never>
    }
    
    // MARK: - Properties
    
    private var isLocked = false
    private var nextTicket: UInt64 = 0
    private var waiters: [Waiter] = []
    
    // MARK: - Initialization
    
    /// Creates a fair lock.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Acquires the lock with FIFO ordering.
    public func lock() async {
        if !isLocked && waiters.isEmpty {
            isLocked = true
            return
        }
        
        let ticket = nextTicket
        nextTicket += 1
        
        await withCheckedContinuation { continuation in
            let waiter = Waiter(ticket: ticket, continuation: continuation)
            waiters.append(waiter)
            waiters.sort { $0.ticket < $1.ticket }
        }
    }
    
    /// Releases the lock.
    public func unlock() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.continuation.resume()
        } else {
            isLocked = false
        }
    }
    
    /// Executes while holding the lock.
    public func withLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lock()
        defer { unlock() }
        return try await operation()
    }
}

// MARK: - AsyncTimedLock

/// A lock with timeout support.
public actor AsyncTimedLock {
    
    // MARK: - Properties
    
    private var isLocked = false
    private var waiters: [(id: UUID, continuation: CheckedContinuation<Bool, Never>)] = []
    
    // MARK: - Initialization
    
    /// Creates a timed lock.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Attempts to acquire the lock with a timeout.
    ///
    /// - Parameter timeout: Maximum time to wait.
    /// - Returns: `true` if acquired, `false` if timed out.
    public func lock(timeout: Duration) async -> Bool {
        if !isLocked {
            isLocked = true
            return true
        }
        
        let id = UUID()
        
        return await withCheckedContinuation { continuation in
            waiters.append((id: id, continuation: continuation))
            
            Task {
                try? await Task.sleep(for: timeout)
                await self.handleTimeout(id: id)
            }
        }
    }
    
    /// Acquires the lock without timeout.
    public func lock() async {
        if !isLocked {
            isLocked = true
            return
        }
        
        let id = UUID()
        
        _ = await withCheckedContinuation { continuation in
            waiters.append((id: id, continuation: continuation))
        }
    }
    
    /// Releases the lock.
    public func unlock() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.continuation.resume(returning: true)
        } else {
            isLocked = false
        }
    }
    
    /// Executes with lock and timeout.
    ///
    /// - Parameters:
    ///   - timeout: Maximum wait time.
    ///   - operation: Closure to execute.
    /// - Returns: The result, or nil if timed out.
    public func withLock<T: Sendable>(
        timeout: Duration,
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T? {
        guard await lock(timeout: timeout) else {
            return nil
        }
        defer { unlock() }
        return try await operation()
    }
    
    // MARK: - Private Methods
    
    private func handleTimeout(id: UUID) {
        if let index = waiters.firstIndex(where: { $0.id == id }) {
            let waiter = waiters.remove(at: index)
            waiter.continuation.resume(returning: false)
        }
    }
}

// MARK: - AsyncSpinLock

/// A spinlock-style lock for very short critical sections.
///
/// Uses cooperative yielding instead of suspending.
public actor AsyncSpinLock {
    
    // MARK: - Properties
    
    private var isLocked = false
    private let maxSpins: Int
    
    // MARK: - Initialization
    
    /// Creates a spin lock.
    ///
    /// - Parameter maxSpins: Maximum spin iterations before yielding.
    public init(maxSpins: Int = 100) {
        self.maxSpins = maxSpins
    }
    
    // MARK: - Public Methods
    
    /// Acquires the lock with spinning.
    public func lock() async {
        var spins = 0
        
        while isLocked {
            spins += 1
            if spins >= maxSpins {
                spins = 0
                await Task.yield()
            }
        }
        
        isLocked = true
    }
    
    /// Attempts to acquire without spinning.
    public func tryLock() -> Bool {
        if !isLocked {
            isLocked = true
            return true
        }
        return false
    }
    
    /// Releases the lock.
    public func unlock() {
        isLocked = false
    }
    
    /// Executes while holding the lock.
    public func withLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lock()
        defer { unlock() }
        return try await operation()
    }
}

// MARK: - AsyncCondition

/// A condition variable for coordinating between tasks.
public actor AsyncCondition {
    
    // MARK: - Properties
    
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a condition variable.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Waits for the condition to be signaled.
    public func wait() async {
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Waits with a timeout.
    ///
    /// - Parameter timeout: Maximum wait time.
    /// - Returns: `true` if signaled, `false` if timed out.
    public func wait(timeout: Duration) async -> Bool {
        let id = UUID()
        var timedOut = false
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            waiters.append(CheckedContinuation<Void, Never> { _ in
                if !timedOut {
                    continuation.resume(returning: true)
                }
            } as! CheckedContinuation<Void, Never>)
            
            Task {
                try? await Task.sleep(for: timeout)
                timedOut = true
                continuation.resume(returning: false)
            }
        }
    }
    
    /// Signals one waiting task.
    public func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        }
    }
    
    /// Signals all waiting tasks.
    public func broadcast() {
        let allWaiters = waiters
        waiters.removeAll()
        
        for waiter in allWaiters {
            waiter.resume()
        }
    }
    
    /// Number of waiting tasks.
    public var waitingCount: Int {
        waiters.count
    }
}

// MARK: - AsyncOnce

/// Ensures a block executes exactly once.
public actor AsyncOnce<T: Sendable> {
    
    // MARK: - Types
    
    private enum State {
        case notStarted
        case inProgress([CheckedContinuation<T, Error>])
        case completed(Result<T, Error>)
    }
    
    // MARK: - Properties
    
    private var state: State = .notStarted
    
    // MARK: - Initialization
    
    /// Creates an AsyncOnce.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Executes the block exactly once.
    ///
    /// Multiple callers will all receive the same result.
    ///
    /// - Parameter block: The block to execute once.
    /// - Returns: The result of the block.
    public func run(_ block: @Sendable () async throws -> T) async throws -> T {
        switch state {
        case .notStarted:
            state = .inProgress([])
            
            do {
                let result = try await block()
                let continuations: [CheckedContinuation<T, Error>]
                
                if case .inProgress(let waiting) = state {
                    continuations = waiting
                } else {
                    continuations = []
                }
                
                state = .completed(.success(result))
                
                for continuation in continuations {
                    continuation.resume(returning: result)
                }
                
                return result
            } catch {
                let continuations: [CheckedContinuation<T, Error>]
                
                if case .inProgress(let waiting) = state {
                    continuations = waiting
                } else {
                    continuations = []
                }
                
                state = .completed(.failure(error))
                
                for continuation in continuations {
                    continuation.resume(throwing: error)
                }
                
                throw error
            }
            
        case .inProgress(var waiting):
            return try await withCheckedThrowingContinuation { continuation in
                waiting.append(continuation)
                state = .inProgress(waiting)
            }
            
        case .completed(let result):
            return try result.get()
        }
    }
    
    /// Whether the block has completed.
    public var isCompleted: Bool {
        if case .completed = state {
            return true
        }
        return false
    }
    
    /// Resets to allow re-execution.
    public func reset() {
        if case .completed = state {
            state = .notStarted
        }
    }
}

// MARK: - AsyncCountdownLatch

/// A countdown latch that releases when count reaches zero.
public actor AsyncCountdownLatch {
    
    // MARK: - Properties
    
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a countdown latch.
    ///
    /// - Parameter count: Initial count.
    public init(count: Int) {
        precondition(count >= 0)
        self.count = count
    }
    
    // MARK: - Public Methods
    
    /// Decrements the count.
    public func countDown() {
        guard count > 0 else { return }
        
        count -= 1
        
        if count == 0 {
            let allWaiters = waiters
            waiters.removeAll()
            
            for waiter in allWaiters {
                waiter.resume()
            }
        }
    }
    
    /// Waits for count to reach zero.
    public func wait() async {
        if count == 0 { return }
        
        await withCheckedContinuation { continuation in
            if count == 0 {
                continuation.resume()
            } else {
                waiters.append(continuation)
            }
        }
    }
    
    /// Current count.
    public var currentCount: Int {
        count
    }
}

// MARK: - AsyncCyclicBarrier

/// A cyclic barrier that releases when all parties arrive.
public actor AsyncCyclicBarrier {
    
    // MARK: - Properties
    
    private let parties: Int
    private var waiting: Int = 0
    private var generation: Int = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a cyclic barrier.
    ///
    /// - Parameter parties: Number of parties required.
    public init(parties: Int) {
        precondition(parties > 0)
        self.parties = parties
    }
    
    // MARK: - Public Methods
    
    /// Waits at the barrier.
    ///
    /// Returns when all parties have arrived.
    public func await() async {
        let myGeneration = generation
        waiting += 1
        
        if waiting == parties {
            // All parties arrived
            let allWaiters = waiters
            waiters.removeAll()
            waiting = 0
            generation += 1
            
            for waiter in allWaiters {
                waiter.resume()
            }
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    /// Number of parties currently waiting.
    public var numberWaiting: Int {
        waiting
    }
    
    /// Total parties required.
    public var requiredParties: Int {
        parties
    }
    
    /// Resets the barrier.
    public func reset() {
        let allWaiters = waiters
        waiters.removeAll()
        waiting = 0
        generation += 1
        
        for waiter in allWaiters {
            waiter.resume()
        }
    }
}
