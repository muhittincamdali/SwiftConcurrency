// TestScheduler.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A deterministic scheduler for testing async code.
///
/// `TestScheduler` provides a virtual time system that allows
/// testing time-dependent async code without real delays.
///
/// ## Overview
///
/// Use `TestScheduler` in unit tests to control the passage of time,
/// making tests fast and deterministic.
///
/// ```swift
/// let scheduler = TestScheduler()
///
/// var executed = false
/// scheduler.schedule(after: .seconds(10)) {
///     executed = true
/// }
///
/// // Time hasn't passed yet
/// XCTAssertFalse(executed)
///
/// // Advance time
/// await scheduler.advance(by: .seconds(10))
/// XCTAssertTrue(executed)
/// ```
///
/// ## Topics
///
/// ### Creating Test Schedulers
/// - ``init()``
///
/// ### Scheduling
/// - ``schedule(after:operation:)``
/// - ``schedule(at:operation:)``
///
/// ### Time Control
/// - ``advance(by:)``
/// - ``advance(to:)``
/// - ``runUntilIdle()``
public actor TestScheduler {
    
    // MARK: - Types
    
    /// A scheduled work item.
    private struct ScheduledWork: Comparable, Sendable {
        let time: Duration
        let id: UInt64
        let operation: @Sendable () async -> Void
        
        static func < (lhs: ScheduledWork, rhs: ScheduledWork) -> Bool {
            if lhs.time != rhs.time {
                return lhs.time < rhs.time
            }
            return lhs.id < rhs.id
        }
        
        static func == (lhs: ScheduledWork, rhs: ScheduledWork) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// A handle to scheduled work.
    public struct ScheduleHandle: Identifiable, Sendable {
        public let id: UInt64
    }
    
    // MARK: - Properties
    
    /// The current virtual time.
    private var currentTime: Duration = .zero
    
    /// Scheduled work items.
    private var scheduledWork: [ScheduledWork] = []
    
    /// Next work ID.
    private var nextId: UInt64 = 0
    
    /// Whether running work.
    private var isRunning = false
    
    // MARK: - Initialization
    
    /// Creates a test scheduler.
    public init() {}
    
    // MARK: - Public Properties
    
    /// The current virtual time.
    public var now: Duration {
        currentTime
    }
    
    // MARK: - Scheduling
    
    /// Schedules work after a delay.
    ///
    /// - Parameters:
    ///   - delay: Virtual time delay.
    ///   - operation: Work to perform.
    /// - Returns: Handle for cancellation.
    @discardableResult
    public func schedule(
        after delay: Duration,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduleHandle {
        let work = ScheduledWork(
            time: currentTime + delay,
            id: nextId,
            operation: operation
        )
        nextId += 1
        
        scheduledWork.append(work)
        scheduledWork.sort()
        
        return ScheduleHandle(id: work.id)
    }
    
    /// Schedules work at a specific virtual time.
    ///
    /// - Parameters:
    ///   - time: Virtual time to execute.
    ///   - operation: Work to perform.
    /// - Returns: Handle for cancellation.
    @discardableResult
    public func schedule(
        at time: Duration,
        operation: @escaping @Sendable () async -> Void
    ) -> ScheduleHandle {
        let work = ScheduledWork(
            time: time,
            id: nextId,
            operation: operation
        )
        nextId += 1
        
        scheduledWork.append(work)
        scheduledWork.sort()
        
        return ScheduleHandle(id: work.id)
    }
    
    /// Cancels scheduled work.
    ///
    /// - Parameter handle: The handle to cancel.
    public func cancel(_ handle: ScheduleHandle) {
        scheduledWork.removeAll { $0.id == handle.id }
    }
    
    // MARK: - Time Control
    
    /// Advances virtual time by a duration.
    ///
    /// Executes all work scheduled up to the new time.
    ///
    /// - Parameter duration: Amount to advance.
    public func advance(by duration: Duration) async {
        let targetTime = currentTime + duration
        await advance(to: targetTime)
    }
    
    /// Advances virtual time to a specific point.
    ///
    /// - Parameter time: Target virtual time.
    public func advance(to time: Duration) async {
        guard time > currentTime else { return }
        
        isRunning = true
        defer { isRunning = false }
        
        while let nextWork = scheduledWork.first, nextWork.time <= time {
            scheduledWork.removeFirst()
            currentTime = nextWork.time
            await nextWork.operation()
        }
        
        currentTime = time
    }
    
    /// Runs all scheduled work until none remains.
    ///
    /// - Warning: May run forever if work reschedules itself.
    /// - Parameter maxIterations: Maximum iterations (safety limit).
    public func runUntilIdle(maxIterations: Int = 1000) async {
        isRunning = true
        defer { isRunning = false }
        
        var iterations = 0
        while let nextWork = scheduledWork.first, iterations < maxIterations {
            scheduledWork.removeFirst()
            currentTime = nextWork.time
            await nextWork.operation()
            iterations += 1
        }
    }
    
    /// Runs the next scheduled work item.
    ///
    /// - Returns: `true` if work was executed.
    @discardableResult
    public func runNext() async -> Bool {
        guard let nextWork = scheduledWork.first else {
            return false
        }
        
        scheduledWork.removeFirst()
        currentTime = nextWork.time
        await nextWork.operation()
        return true
    }
    
    /// Resets the scheduler to initial state.
    public func reset() {
        currentTime = .zero
        scheduledWork.removeAll()
        nextId = 0
    }
    
    // MARK: - Query
    
    /// Number of pending work items.
    public var pendingCount: Int {
        scheduledWork.count
    }
    
    /// Whether there's pending work.
    public var hasPendingWork: Bool {
        !scheduledWork.isEmpty
    }
    
    /// Time until next scheduled work.
    public var timeToNextWork: Duration? {
        scheduledWork.first.map { $0.time - currentTime }
    }
}

// MARK: - Test Clock

/// A test-friendly clock for controlling time in tests.
public actor TestClock {
    
    /// Current virtual time.
    private var virtualTime: Duration = .zero
    
    /// Continuations waiting for time.
    private var sleepWaiters: [(deadline: Duration, continuation: CheckedContinuation<Void, Error>)] = []
    
    /// Creates a test clock.
    public init() {}
    
    /// The current time.
    public var now: Duration {
        virtualTime
    }
    
    /// Sleeps until the specified deadline.
    ///
    /// In tests, this doesn't actually wait - use `advance` to trigger.
    public func sleep(for duration: Duration) async throws {
        let deadline = virtualTime + duration
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sleepWaiters.append((deadline, continuation))
            sleepWaiters.sort { $0.deadline < $1.deadline }
        }
    }
    
    /// Advances time, waking any sleepers.
    public func advance(by duration: Duration) async {
        virtualTime += duration
        
        while let first = sleepWaiters.first, first.deadline <= virtualTime {
            sleepWaiters.removeFirst()
            first.continuation.resume()
        }
    }
    
    /// Resets the clock.
    public func reset() {
        virtualTime = .zero
        for waiter in sleepWaiters {
            waiter.continuation.resume(throwing: CancellationError())
        }
        sleepWaiters.removeAll()
    }
}

// MARK: - Duration Comparison

extension Duration {
    static func + (lhs: Duration, rhs: Duration) -> Duration {
        let (ls, la) = lhs.components
        let (rs, ra) = rhs.components
        return Duration(secondsComponent: ls + rs, attosecondsComponent: la + ra)
    }
}
