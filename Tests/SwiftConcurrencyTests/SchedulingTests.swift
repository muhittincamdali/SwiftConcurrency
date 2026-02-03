// SchedulingTests.swift
// SwiftConcurrencyTests
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftConcurrency

final class SchedulingTests: XCTestCase {
    
    // MARK: - TaskScheduler Tests
    
    func testSchedulerSchedulesAfterDelay() async throws {
        let scheduler = TaskScheduler()
        var executed = false
        
        await scheduler.schedule(after: .milliseconds(50)) {
            executed = true
        }
        
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(executed)
    }
    
    func testSchedulerCancelsTask() async throws {
        let scheduler = TaskScheduler()
        var executed = false
        
        let handle = await scheduler.schedule(after: .seconds(1)) {
            executed = true
        }
        
        await scheduler.cancel(handle)
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertFalse(executed)
    }
    
    func testSchedulerRepeatingTask() async throws {
        let scheduler = TaskScheduler()
        var executionCount = 0
        
        let handle = await scheduler.scheduleRepeating(
            interval: .milliseconds(50),
            startImmediately: true
        ) {
            executionCount += 1
        }
        
        try await Task.sleep(for: .milliseconds(180))
        await scheduler.cancel(handle)
        
        // Should have executed 3-4 times (immediately + ~3 intervals)
        XCTAssertGreaterThanOrEqual(executionCount, 3)
    }
    
    func testSchedulerCancelsAll() async {
        let scheduler = TaskScheduler()
        
        await scheduler.schedule(after: .seconds(1)) {}
        await scheduler.schedule(after: .seconds(2)) {}
        await scheduler.schedule(after: .seconds(3)) {}
        
        let countBefore = await scheduler.activeTaskCount
        XCTAssertEqual(countBefore, 3)
        
        await scheduler.cancelAll()
        
        let countAfter = await scheduler.activeTaskCount
        XCTAssertEqual(countAfter, 0)
    }
    
    // MARK: - PriorityQueue Tests
    
    func testPriorityQueueOrdering() async {
        let queue = AsyncPriorityQueue<String>()
        
        await queue.enqueue("low", priority: 1)
        await queue.enqueue("high", priority: 10)
        await queue.enqueue("medium", priority: 5)
        
        let first = await queue.dequeue()
        let second = await queue.dequeue()
        let third = await queue.dequeue()
        
        XCTAssertEqual(first, "high")
        XCTAssertEqual(second, "medium")
        XCTAssertEqual(third, "low")
    }
    
    func testPriorityQueueFIFOSamePriority() async {
        let queue = AsyncPriorityQueue<String>()
        
        await queue.enqueue("first", priority: 5)
        await queue.enqueue("second", priority: 5)
        await queue.enqueue("third", priority: 5)
        
        let a = await queue.dequeue()
        let b = await queue.dequeue()
        let c = await queue.dequeue()
        
        XCTAssertEqual(a, "first")
        XCTAssertEqual(b, "second")
        XCTAssertEqual(c, "third")
    }
    
    func testPriorityQueueCount() async {
        let queue = AsyncPriorityQueue<Int>()
        
        var count = await queue.count
        XCTAssertEqual(count, 0)
        
        await queue.enqueue(1, priority: 1)
        await queue.enqueue(2, priority: 2)
        
        count = await queue.count
        XCTAssertEqual(count, 2)
        
        _ = await queue.tryDequeue()
        
        count = await queue.count
        XCTAssertEqual(count, 1)
    }
    
    // MARK: - DelayedTask Tests
    
    func testDelayedTaskExecutes() async throws {
        let task = DelayedTask(delay: .milliseconds(50)) {
            return 42
        }
        
        task.start()
        let result = try await task.wait()
        
        XCTAssertEqual(result, 42)
        XCTAssertEqual(task.state, .completed)
    }
    
    func testDelayedTaskCanBeCancelled() async {
        let task = DelayedTask(delay: .seconds(10)) {
            return 42
        }
        
        task.start()
        task.cancel()
        
        XCTAssertEqual(task.state, .cancelled)
    }
    
    func testDelayedTaskReschedule() async throws {
        let task = DelayedTask(delay: .seconds(10)) {
            return 42
        }
        
        task.start()
        task.reschedule(delay: .milliseconds(50))
        
        let result = try await task.wait()
        XCTAssertEqual(result, 42)
    }
    
    // MARK: - DebouncedTask Tests
    
    func testDebouncedTaskDebounces() async throws {
        let debounced = DebouncedTask(delay: .milliseconds(100)) {
            return "executed"
        }
        
        // Trigger multiple times rapidly
        Task { try? await debounced.trigger() }
        Task { try? await debounced.trigger() }
        Task { try? await debounced.trigger() }
        
        // Wait for debounce
        try await Task.sleep(for: .milliseconds(200))
    }
    
    // MARK: - TestScheduler Tests
    
    func testTestSchedulerAdvancesTime() async {
        let scheduler = TestScheduler()
        var executed = false
        
        await scheduler.schedule(after: .seconds(10)) {
            executed = true
        }
        
        XCTAssertFalse(executed)
        
        await scheduler.advance(by: .seconds(10))
        
        XCTAssertTrue(executed)
    }
    
    func testTestSchedulerNow() async {
        let scheduler = TestScheduler()
        
        var now = await scheduler.now
        XCTAssertEqual(now, .zero)
        
        await scheduler.advance(by: .seconds(5))
        
        now = await scheduler.now
        XCTAssertEqual(now, .seconds(5))
    }
    
    func testTestSchedulerRunsMultipleTasks() async {
        let scheduler = TestScheduler()
        var results: [Int] = []
        
        await scheduler.schedule(after: .seconds(1)) { results.append(1) }
        await scheduler.schedule(after: .seconds(3)) { results.append(3) }
        await scheduler.schedule(after: .seconds(2)) { results.append(2) }
        
        await scheduler.runUntilIdle()
        
        XCTAssertEqual(results, [1, 2, 3])
    }
}
