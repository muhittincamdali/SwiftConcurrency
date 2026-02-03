// TimeoutTests.swift
// SwiftConcurrencyTests
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftConcurrency

final class TimeoutTests: XCTestCase {
    
    // MARK: - TaskTimeout Tests
    
    func testTimeoutSucceedsWithinLimit() async throws {
        let result = try await withTimeout(.milliseconds(500)) {
            try await Task.sleep(for: .milliseconds(50))
            return "success"
        }
        
        XCTAssertEqual(result, "success")
    }
    
    func testTimeoutThrowsWhenExceeded() async {
        do {
            _ = try await withTimeout(.milliseconds(50)) {
                try await Task.sleep(for: .milliseconds(500))
                return "should not reach"
            }
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertTrue(error is TimeoutError)
        }
    }
    
    // MARK: - DeadlineTask Tests
    
    func testDeadlineTaskSucceeds() async throws {
        let deadline = Date().addingTimeInterval(1.0)
        
        let result = try await DeadlineTask.run(deadline: deadline) {
            try await Task.sleep(for: .milliseconds(50))
            return "success"
        }
        
        XCTAssertEqual(result, "success")
    }
    
    func testDeadlineTaskFailsWhenDeadlinePassed() async {
        let deadline = Date().addingTimeInterval(-1.0) // Past deadline
        
        do {
            _ = try await DeadlineTask.run(deadline: deadline) {
                return "should not execute"
            }
            XCTFail("Expected deadline passed error")
        } catch {
            XCTAssertTrue(error is DeadlineTask<String>.DeadlineError)
        }
    }
    
    func testDeadlineTaskWithDuration() async throws {
        let result = try await DeadlineTask.run(after: .seconds(1)) {
            return "success"
        }
        
        XCTAssertEqual(result, "success")
    }
    
    // MARK: - ScheduledTask Tests
    
    func testScheduledTaskExecutes() async throws {
        let task = ScheduledTask(after: .milliseconds(50)) {
            return "executed"
        }
        
        await task.start()
        let result = try await task.wait()
        
        XCTAssertEqual(result, "executed")
    }
    
    func testScheduledTaskCanBeCancelled() async {
        let task = ScheduledTask(after: .seconds(10)) {
            return "should not execute"
        }
        
        await task.start()
        await task.cancel()
        
        let state = await task.currentState
        XCTAssertEqual(state, .cancelled)
    }
    
    // MARK: - CancellationScope Tests
    
    func testCancellationScopeRunsOperation() async throws {
        let scope = CancellationScope()
        
        let result = try await scope.run {
            return "success"
        }
        
        XCTAssertEqual(result, "success")
    }
    
    func testCancellationScopeThrowsWhenCancelled() async {
        let scope = CancellationScope()
        await scope.cancel()
        
        do {
            _ = try await scope.run {
                return "should not execute"
            }
            XCTFail("Expected cancellation error")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
    
    func testCancellationTokenWorks() throws {
        let token = CancellationToken()
        
        XCTAssertFalse(token.isCancelled)
        XCTAssertNoThrow(try token.throwIfCancelled())
        
        token.cancel()
        
        XCTAssertTrue(token.isCancelled)
        XCTAssertThrowsError(try token.throwIfCancelled())
    }
}
