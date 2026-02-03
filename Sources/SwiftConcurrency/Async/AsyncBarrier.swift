// AsyncBarrier.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A synchronization barrier that blocks tasks until all reach the barrier.
///
/// `AsyncBarrier` allows multiple tasks to synchronize at a common point,
/// ensuring all tasks have reached the barrier before any can proceed.
///
/// ## Overview
///
/// Use `AsyncBarrier` when you need multiple concurrent tasks to wait
/// for each other before proceeding to the next phase of computation.
///
/// ```swift
/// let barrier = AsyncBarrier(count: 3)
///
/// await withTaskGroup(of: Void.self) { group in
///     for i in 0..<3 {
///         group.addTask {
///             print("Task \(i) doing work...")
///             await barrier.wait()
///             print("Task \(i) continuing after barrier")
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Barriers
/// - ``init(count:)``
///
/// ### Synchronization
/// - ``wait()``
/// - ``reset()``
public actor AsyncBarrier {
    
    // MARK: - Properties
    
    /// The number of tasks that must reach the barrier.
    private let count: Int
    
    /// Current number of waiting tasks.
    private var waitingCount: Int = 0
    
    /// The generation number (incremented each time barrier is passed).
    private var generation: UInt64 = 0
    
    /// Continuations of waiting tasks.
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a barrier for the specified number of tasks.
    ///
    /// - Parameter count: The number of tasks that must reach the barrier
    ///   before any can proceed. Must be greater than zero.
    public init(count: Int) {
        precondition(count > 0, "Barrier count must be greater than zero")
        self.count = count
    }
    
    // MARK: - Public Methods
    
    /// Waits at the barrier until all tasks have arrived.
    ///
    /// The last task to arrive at the barrier releases all waiting tasks.
    ///
    /// ```swift
    /// await barrier.wait()
    /// // All tasks have reached this point
    /// ```
    public func wait() async {
        let currentGeneration = generation
        waitingCount += 1
        
        if waitingCount == count {
            // Last task to arrive - release everyone
            let currentWaiters = waiters
            waiters = []
            waitingCount = 0
            generation += 1
            
            for waiter in currentWaiters {
                waiter.resume()
            }
        } else {
            // Wait for other tasks
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    /// Waits at the barrier with a timeout.
    ///
    /// - Parameter timeout: Maximum time to wait.
    /// - Returns: `true` if all tasks arrived, `false` if timed out.
    public func wait(timeout: Duration) async -> Bool {
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let currentGeneration = generation
            waitingCount += 1
            
            if waitingCount == count {
                let currentWaiters = waiters
                waiters = []
                waitingCount = 0
                generation += 1
                
                for waiter in currentWaiters {
                    waiter.resume()
                }
                continuation.resume(returning: true)
            } else {
                Task {
                    try? await Task.sleep(for: timeout)
                    await self.handleTimeout(
                        generation: currentGeneration,
                        continuation: continuation
                    )
                }
            }
        }
        return result
    }
    
    /// Handles timeout for a waiting task.
    private func handleTimeout(
        generation expectedGeneration: UInt64,
        continuation: CheckedContinuation<Bool, Never>
    ) {
        if generation == expectedGeneration {
            // Still waiting, remove ourselves
            waitingCount -= 1
            continuation.resume(returning: false)
        }
        // If generation changed, we already passed the barrier
    }
    
    /// Resets the barrier to its initial state.
    ///
    /// - Warning: This will leave any waiting tasks suspended indefinitely.
    public func reset() {
        waitingCount = 0
        generation += 1
        waiters = []
    }
    
    /// The number of tasks currently waiting at the barrier.
    public var waiting: Int {
        waitingCount
    }
    
    /// The number of tasks still needed to release the barrier.
    public var remaining: Int {
        count - waitingCount
    }
}

// MARK: - Cyclic Barrier

/// A reusable barrier that can be used multiple times.
///
/// `CyclicBarrier` automatically resets after all tasks pass through,
/// allowing it to be reused for multiple synchronization points.
///
/// ```swift
/// let barrier = CyclicBarrier(parties: 3)
///
/// for phase in 0..<5 {
///     await withTaskGroup(of: Void.self) { group in
///         for i in 0..<3 {
///             group.addTask {
///                 // Do phase work
///                 await barrier.await()
///             }
///         }
///     }
/// }
/// ```
public actor CyclicBarrier {
    
    // MARK: - Properties
    
    /// Number of parties required.
    private let parties: Int
    
    /// Current count of waiting parties.
    private var count: Int
    
    /// Generation number.
    private var generation: UInt64 = 0
    
    /// Waiting continuations.
    private var waiters: [CheckedContinuation<Int, Never>] = []
    
    /// Optional action to run when barrier trips.
    private let barrierAction: (@Sendable () async -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a cyclic barrier for the specified number of parties.
    ///
    /// - Parameters:
    ///   - parties: The number of parties that must await.
    ///   - action: Optional action to execute when barrier trips.
    public init(
        parties: Int,
        action: (@Sendable () async -> Void)? = nil
    ) {
        precondition(parties > 0, "Parties must be greater than zero")
        self.parties = parties
        self.count = parties
        self.barrierAction = action
    }
    
    // MARK: - Public Methods
    
    /// Awaits at the barrier until all parties arrive.
    ///
    /// - Returns: The arrival index (0 is the last to arrive).
    @discardableResult
    public func await() async -> Int {
        count -= 1
        let index = count
        
        if count == 0 {
            // Last party - trip the barrier
            let currentWaiters = waiters
            waiters = []
            count = parties
            generation += 1
            
            if let action = barrierAction {
                await action()
            }
            
            for waiter in currentWaiters {
                waiter.resume(returning: index)
            }
            
            return index
        } else {
            // Wait for other parties
            return await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    /// The number of parties required to trip the barrier.
    public var numberOfParties: Int {
        parties
    }
    
    /// The number of parties currently waiting.
    public var numberWaiting: Int {
        parties - count
    }
    
    /// Resets the barrier to its initial state.
    public func reset() {
        count = parties
        generation += 1
        waiters = []
    }
}

// MARK: - Phaser

/// A flexible barrier supporting dynamic task registration.
///
/// `Phaser` allows tasks to dynamically register and deregister,
/// making it suitable for scenarios where the number of participating
/// tasks may change over time.
public actor Phaser {
    
    // MARK: - Properties
    
    /// Number of registered parties.
    private var registeredParties: Int = 0
    
    /// Number of arrived parties.
    private var arrivedParties: Int = 0
    
    /// Current phase number.
    private var phase: Int = 0
    
    /// Waiting continuations.
    private var waiters: [CheckedContinuation<Int, Never>] = []
    
    // MARK: - Initialization
    
    /// Creates a phaser with initial parties.
    ///
    /// - Parameter parties: Initial number of registered parties.
    public init(parties: Int = 0) {
        self.registeredParties = parties
    }
    
    // MARK: - Registration
    
    /// Registers a new party.
    ///
    /// - Returns: The current phase number.
    @discardableResult
    public func register() -> Int {
        registeredParties += 1
        return phase
    }
    
    /// Registers multiple new parties.
    ///
    /// - Parameter parties: Number of parties to register.
    /// - Returns: The current phase number.
    @discardableResult
    public func bulkRegister(_ parties: Int) -> Int {
        registeredParties += parties
        return phase
    }
    
    // MARK: - Arrival
    
    /// Arrives at the barrier without waiting.
    ///
    /// - Returns: The arrival phase number.
    @discardableResult
    public func arrive() -> Int {
        arrivedParties += 1
        return checkAdvance()
    }
    
    /// Arrives and deregisters from the phaser.
    ///
    /// - Returns: The arrival phase number.
    @discardableResult
    public func arriveAndDeregister() -> Int {
        arrivedParties += 1
        registeredParties -= 1
        return checkAdvance()
    }
    
    /// Arrives and waits for others to arrive.
    ///
    /// - Returns: The phase number after advancing.
    public func arriveAndAwaitAdvance() async -> Int {
        arrivedParties += 1
        
        if arrivedParties >= registeredParties {
            return advancePhase()
        }
        
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks if phase should advance.
    private func checkAdvance() -> Int {
        if arrivedParties >= registeredParties {
            return advancePhase()
        }
        return phase
    }
    
    /// Advances to the next phase.
    private func advancePhase() -> Int {
        let oldPhase = phase
        phase += 1
        arrivedParties = 0
        
        let currentWaiters = waiters
        waiters = []
        
        for waiter in currentWaiters {
            waiter.resume(returning: phase)
        }
        
        return oldPhase
    }
    
    // MARK: - Properties
    
    /// The current phase number.
    public var currentPhase: Int {
        phase
    }
    
    /// The number of registered parties.
    public var registeredCount: Int {
        registeredParties
    }
    
    /// The number of arrived parties.
    public var arrivedCount: Int {
        arrivedParties
    }
    
    /// The number of unarrived parties.
    public var unarrivedCount: Int {
        registeredParties - arrivedParties
    }
}
