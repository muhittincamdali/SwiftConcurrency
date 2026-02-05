// AsyncLock.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncLock

/// A simple async-aware mutex lock.
///
/// Provides exclusive access to a critical section using Swift concurrency.
///
/// ```swift
/// let lock = AsyncLock()
///
/// await lock.withLock {
///     // Critical section
///     modifySharedResource()
/// }
/// ```
public actor AsyncLock {
    
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    /// Creates an async lock.
    public init() {}
    
    /// Acquires the lock.
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
    public func unlock() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            isLocked = false
        }
    }
    
    /// Executes a closure with the lock held.
    ///
    /// - Parameter operation: The operation to execute.
    /// - Returns: The operation result.
    public func withLock<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await lock()
        defer { unlock() }
        return try await operation()
    }
}

// AsyncSemaphore and AsyncBarrier are defined in their own files

// MARK: - AsyncCondition

/// A condition variable for async contexts.
public actor AsyncCondition {
    
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    /// Creates a condition.
    public init() {}
    
    /// Waits for the condition.
    public func wait() async {
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Signals one waiter.
    public func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        }
    }
    
    /// Signals all waiters.
    public func broadcast() {
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }
    
    /// Number of waiters.
    public var waiterCount: Int { waiters.count }
}

// MARK: - AsyncOnce

/// Ensures an operation runs exactly once.
///
/// ```swift
/// let once = AsyncOnce<Config>()
/// let config = try await once.run {
///     await loadConfiguration()
/// }
/// ```
public actor AsyncOnce<T: Sendable> {
    
    private enum State {
        case notStarted
        case running([CheckedContinuation<T, Error>])
        case completed(T)
        case failed(Error)
    }
    
    private var state: State = .notStarted
    
    /// Creates an async once.
    public init() {}
    
    /// Runs the operation, returning cached result on subsequent calls.
    public func run(_ operation: @Sendable () async throws -> T) async throws -> T {
        switch state {
        case .completed(let value):
            return value
        case .failed(let error):
            throw error
        case .running:
            return try await withCheckedThrowingContinuation { continuation in
                if case .running(var waiters) = state {
                    waiters.append(continuation)
                    state = .running(waiters)
                }
            }
        case .notStarted:
            state = .running([])
            
            do {
                let value = try await operation()
                
                if case .running(let waiters) = state {
                    for waiter in waiters {
                        waiter.resume(returning: value)
                    }
                }
                
                state = .completed(value)
                return value
            } catch {
                if case .running(let waiters) = state {
                    for waiter in waiters {
                        waiter.resume(throwing: error)
                    }
                }
                
                state = .failed(error)
                throw error
            }
        }
    }
    
    /// Whether the operation has completed.
    public var isCompleted: Bool {
        if case .completed = state { return true }
        return false
    }
    
    /// Resets to allow re-running.
    public func reset() {
        state = .notStarted
    }
}

// MARK: - AsyncLatch

/// A latch that can be decremented and waited on.
public actor AsyncLatch {
    
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    /// Creates a latch.
    public init(count: Int) {
        precondition(count >= 0)
        self.count = count
    }
    
    /// Decrements the count.
    public func countDown() {
        guard count > 0 else { return }
        count -= 1
        
        if count == 0 {
            for waiter in waiters {
                waiter.resume()
            }
            waiters.removeAll()
        }
    }
    
    /// Waits until count reaches zero.
    public func wait() async {
        if count == 0 { return }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Current count.
    public var currentCount: Int { count }
}
