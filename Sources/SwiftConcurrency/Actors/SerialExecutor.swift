// SerialExecutor.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A simple serial execution queue using actors.
///
/// `SerialExecutionQueue` ensures operations execute one at a time in order.
///
/// ## Overview
///
/// Use `SerialExecutionQueue` when you need to serialize operations
/// without using a full actor.
///
/// ```swift
/// let queue = SerialExecutionQueue()
/// 
/// // These execute one at a time, in order
/// await queue.run { await operationA() }
/// await queue.run { await operationB() }
/// ```
public actor SerialExecutionQueue {
    
    /// Creates a serial execution queue.
    public init() {}
    
    /// Runs an operation on this queue.
    ///
    /// Operations are guaranteed to execute one at a time.
    ///
    /// - Parameter operation: The operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    public func run<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await operation()
    }
    
    /// Runs an operation on this queue without throwing.
    ///
    /// - Parameter operation: The operation to perform.
    /// - Returns: The result of the operation.
    public func run<T: Sendable>(
        _ operation: @Sendable () async -> T
    ) async -> T {
        await operation()
    }
}

/// An executor that runs jobs on the main thread.
///
/// Use for UI-related operations that must run on main.
@MainActor
public final class MainThreadExecutor: Sendable {
    
    /// Shared instance.
    public static let shared = MainThreadExecutor()
    
    private init() {}
    
    /// Runs an operation on the main thread.
    ///
    /// - Parameter operation: The operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    public func run<T: Sendable>(
        _ operation: @MainActor @Sendable () async throws -> T
    ) async rethrows -> T {
        try await operation()
    }
}

/// A queue that limits concurrent executions.
///
/// Similar to `OperationQueue` with `maxConcurrentOperationCount`.
public actor LimitedConcurrencyQueue {
    
    /// Maximum concurrent operations.
    private let maxConcurrency: Int
    
    /// Current running count.
    private var runningCount: Int = 0
    
    /// Waiting continuations.
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    /// Creates a limited concurrency queue.
    ///
    /// - Parameter maxConcurrency: Maximum concurrent operations.
    public init(maxConcurrency: Int) {
        precondition(maxConcurrency > 0, "Max concurrency must be positive")
        self.maxConcurrency = maxConcurrency
    }
    
    /// Runs an operation when a slot is available.
    ///
    /// - Parameter operation: The operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    public func run<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await acquireSlot()
        defer { releaseSlot() }
        return try await operation()
    }
    
    /// Acquires a slot for execution.
    private func acquireSlot() async {
        if runningCount < maxConcurrency {
            runningCount += 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        runningCount += 1
    }
    
    /// Releases a slot after execution.
    private func releaseSlot() {
        runningCount -= 1
        
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        }
    }
    
    /// The current number of running operations.
    public var currentConcurrency: Int {
        runningCount
    }
    
    /// The number of operations waiting for a slot.
    public var waitingCount: Int {
        waiters.count
    }
}

/// A fair queue that processes operations in FIFO order.
public actor FairQueue {
    
    /// Ticket counter for FIFO ordering.
    private var ticketCounter: UInt64 = 0
    
    /// Currently served ticket.
    private var servingTicket: UInt64 = 0
    
    /// Waiting operations by ticket.
    private var waiters: [UInt64: CheckedContinuation<Void, Never>] = [:]
    
    /// Creates a fair queue.
    public init() {}
    
    /// Runs an operation in FIFO order.
    ///
    /// Operations are guaranteed to start in the order they were submitted.
    ///
    /// - Parameter operation: The operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: Any error thrown by the operation.
    public func run<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        let myTicket = ticketCounter
        ticketCounter += 1
        
        // Wait for our turn
        if myTicket != servingTicket {
            await withCheckedContinuation { continuation in
                waiters[myTicket] = continuation
            }
        }
        
        defer {
            // Advance to next ticket and wake them
            servingTicket += 1
            if let next = waiters.removeValue(forKey: servingTicket) {
                next.resume()
            }
        }
        
        return try await operation()
    }
}
