// TaskGroupTests.swift
// SwiftConcurrencyTests
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftConcurrency

final class TaskGroupTests: XCTestCase {
    
    // MARK: - ThrottledTaskGroup Tests
    
    func testThrottledTaskGroupLimitsConcurrency() async throws {
        let maxConcurrent = 3
        var concurrent = 0
        var maxObserved = 0
        let lock = NSLock()
        
        let items = Array(1...10)
        
        _ = try await items.concurrentMap(maxConcurrency: maxConcurrent) { item in
            lock.lock()
            concurrent += 1
            maxObserved = max(maxObserved, concurrent)
            lock.unlock()
            
            try await Task.sleep(for: .milliseconds(50))
            
            lock.lock()
            concurrent -= 1
            lock.unlock()
            
            return item * 2
        }
        
        XCTAssertLessThanOrEqual(maxObserved, maxConcurrent)
    }
    
    func testThrottledTaskGroupProcessesAllItems() async throws {
        let items = Array(1...20)
        let results = try await items.concurrentMap(maxConcurrency: 5) { $0 * 2 }
        
        XCTAssertEqual(results.count, items.count)
        XCTAssertEqual(results, items.map { $0 * 2 })
    }
    
    // MARK: - BatchTaskGroup Tests
    
    func testBatchTaskGroupProcessesBatches() async throws {
        let items = Array(1...100)
        let batchSize = 10
        var batchCount = 0
        
        let results = try await BatchTaskGroup.process(
            items,
            batchSize: batchSize,
            maxConcurrentBatches: 2
        ) { batch -> [Int] in
            batchCount += 1
            return batch.map { $0 * 2 }
        }
        
        XCTAssertEqual(results.count, items.count)
        XCTAssertEqual(Set(results), Set(items.map { $0 * 2 }))
    }
    
    func testBatchTaskGroupWithProgress() async throws {
        let items = Array(1...50)
        var progressUpdates: [BatchTaskGroup<Int>.BatchProgress] = []
        
        let results = try await BatchTaskGroup.processWithProgress(
            items,
            batchSize: 10,
            progress: { progress in
                progressUpdates.append(progress)
            }
        ) { batch in
            batch.map { $0 * 2 }
        }
        
        XCTAssertEqual(results.count, items.count)
        XCTAssertEqual(progressUpdates.count, 5) // 50 items / 10 per batch
        XCTAssertEqual(progressUpdates.last?.percentComplete, 100)
    }
    
    // MARK: - OrderedTaskGroup Tests
    
    func testOrderedTaskGroupPreservesOrder() async throws {
        let items = Array(1...10)
        
        let results = await withOrderedTaskGroup(of: Int.self) { group in
            for (index, item) in items.enumerated() {
                group.addTask(index: index) {
                    // Add random delay to potentially complete out of order
                    try? await Task.sleep(for: .milliseconds(Int.random(in: 10...50)))
                    return item * 2
                }
            }
            return await group.collectOrdered()
        }
        
        // Results should be in original order despite random delays
        XCTAssertEqual(results, items.map { $0 * 2 })
    }
    
    // MARK: - ConcurrentMap Tests
    
    func testConcurrentMapBasic() async throws {
        let items = [1, 2, 3, 4, 5]
        let results = try await items.concurrentMap { $0 * 2 }
        
        XCTAssertEqual(Set(results), Set([2, 4, 6, 8, 10]))
    }
    
    func testConcurrentMapWithError() async throws {
        let items = [1, 2, 3, 4, 5]
        
        do {
            _ = try await items.concurrentMap { item -> Int in
                if item == 3 {
                    throw TestError.intentional
                }
                return item * 2
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
    
    func testConcurrentCompactMap() async throws {
        let items = [1, 2, 3, 4, 5]
        let results = try await items.concurrentCompactMap { item -> Int? in
            item % 2 == 0 ? item * 2 : nil
        }
        
        XCTAssertEqual(Set(results), Set([4, 8]))
    }
}

// MARK: - Helper Types

enum TestError: Error {
    case intentional
}
