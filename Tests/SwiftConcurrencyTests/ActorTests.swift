// ActorTests.swift
// SwiftConcurrencyTests
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftConcurrency

final class ActorTests: XCTestCase {
    
    // MARK: - CacheActor Tests
    
    func testCacheActorStoresAndRetrieves() async {
        let cache = CacheActor<String, Int>()
        
        await cache.set("key1", value: 42)
        let value = await cache.get("key1")
        
        XCTAssertEqual(value, 42)
    }
    
    func testCacheActorExpiration() async throws {
        let cache = CacheActor<String, Int>(defaultTTL: .milliseconds(100))
        
        await cache.set("key1", value: 42)
        
        // Value exists initially
        var value = await cache.get("key1")
        XCTAssertEqual(value, 42)
        
        // Wait for expiration
        try await Task.sleep(for: .milliseconds(150))
        
        // Value should be expired
        value = await cache.get("key1")
        XCTAssertNil(value)
    }
    
    func testCacheActorGetOrSet() async {
        let cache = CacheActor<String, Int>()
        var computeCount = 0
        
        let value1 = await cache.getOrSet("key1") {
            computeCount += 1
            return 42
        }
        
        let value2 = await cache.getOrSet("key1") {
            computeCount += 1
            return 100
        }
        
        XCTAssertEqual(value1, 42)
        XCTAssertEqual(value2, 42) // Should return cached value
        XCTAssertEqual(computeCount, 1) // Only computed once
    }
    
    // MARK: - AsyncSemaphore Tests
    
    func testSemaphoreLimitsConcurrency() async {
        let semaphore = AsyncSemaphore(value: 2)
        var concurrent = 0
        var maxConcurrent = 0
        let lock = NSLock()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await semaphore.wait()
                    
                    lock.lock()
                    concurrent += 1
                    maxConcurrent = max(maxConcurrent, concurrent)
                    lock.unlock()
                    
                    try? await Task.sleep(for: .milliseconds(50))
                    
                    lock.lock()
                    concurrent -= 1
                    lock.unlock()
                    
                    await semaphore.signal()
                }
            }
        }
        
        XCTAssertLessThanOrEqual(maxConcurrent, 2)
    }
    
    func testSemaphoreWithSemaphore() async {
        let semaphore = AsyncSemaphore(value: 1)
        var executed = false
        
        await semaphore.withSemaphore {
            executed = true
        }
        
        XCTAssertTrue(executed)
    }
    
    // MARK: - AsyncBarrier Tests
    
    func testBarrierSynchronizesTasks() async {
        let barrier = AsyncBarrier(count: 3)
        var arrivedCount = 0
        let lock = NSLock()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    lock.lock()
                    arrivedCount += 1
                    lock.unlock()
                    
                    await barrier.wait()
                    
                    // After barrier, all tasks should have arrived
                    lock.lock()
                    let count = arrivedCount
                    lock.unlock()
                    XCTAssertEqual(count, 3)
                }
            }
        }
    }
    
    // MARK: - NetworkActor Tests
    
    func testNetworkActorStatistics() async {
        let network = NetworkActor()
        
        let stats = await network.statistics
        XCTAssertEqual(stats.totalRequests, 0)
        XCTAssertEqual(stats.successfulRequests, 0)
        XCTAssertEqual(stats.failedRequests, 0)
    }
    
    // MARK: - BinarySemaphore Tests
    
    func testBinarySemaphoreLocking() async {
        let mutex = BinarySemaphore()
        var value = 0
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    await mutex.lock()
                    value += 1
                    await mutex.unlock()
                }
            }
        }
        
        XCTAssertEqual(value, 100)
    }
}
