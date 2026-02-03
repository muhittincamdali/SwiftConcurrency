// RetryTests.swift
// SwiftConcurrencyTests
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftConcurrency

final class RetryTests: XCTestCase {
    
    // MARK: - ExponentialBackoff Tests
    
    func testExponentialBackoffProgression() {
        let backoff = ExponentialBackoff(
            initialDelay: .milliseconds(100),
            multiplier: 2.0,
            maxDelay: .seconds(10)
        )
        
        let delays = (0..<5).map { backoff.delay(forAttempt: $0) }
        
        // Verify exponential progression
        XCTAssertEqual(delays[0].nanoseconds, 100_000_000) // 100ms
        XCTAssertEqual(delays[1].nanoseconds, 200_000_000) // 200ms
        XCTAssertEqual(delays[2].nanoseconds, 400_000_000) // 400ms
        XCTAssertEqual(delays[3].nanoseconds, 800_000_000) // 800ms
        XCTAssertEqual(delays[4].nanoseconds, 1_600_000_000) // 1600ms
    }
    
    func testExponentialBackoffMaxCap() {
        let backoff = ExponentialBackoff(
            initialDelay: .seconds(1),
            multiplier: 10.0,
            maxDelay: .seconds(5)
        )
        
        let delay = backoff.delay(forAttempt: 10)
        XCTAssertEqual(delay.nanoseconds, 5_000_000_000) // Capped at 5s
    }
    
    // MARK: - LinearBackoff Tests
    
    func testLinearBackoffProgression() {
        let backoff = LinearBackoff(
            initialDelay: .milliseconds(100),
            increment: .milliseconds(100),
            maxDelay: .seconds(1)
        )
        
        let delays = (0..<5).map { backoff.delay(forAttempt: $0) }
        
        XCTAssertEqual(delays[0].nanoseconds, 100_000_000) // 100ms
        XCTAssertEqual(delays[1].nanoseconds, 200_000_000) // 200ms
        XCTAssertEqual(delays[2].nanoseconds, 300_000_000) // 300ms
        XCTAssertEqual(delays[3].nanoseconds, 400_000_000) // 400ms
        XCTAssertEqual(delays[4].nanoseconds, 500_000_000) // 500ms
    }
    
    // MARK: - RetryableTask Tests
    
    func testRetryableTaskSucceedsOnFirstAttempt() async throws {
        var attempts = 0
        
        let result = try await withRetry(maxAttempts: 3) {
            attempts += 1
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attempts, 1)
    }
    
    func testRetryableTaskRetriesOnFailure() async throws {
        var attempts = 0
        
        let result = try await withRetry(
            maxAttempts: 5,
            backoff: .constant(.milliseconds(10))
        ) {
            attempts += 1
            if attempts < 3 {
                throw TestError.intentional
            }
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attempts, 3)
    }
    
    func testRetryableTaskExhaustsAttempts() async {
        var attempts = 0
        
        do {
            _ = try await withRetry(
                maxAttempts: 3,
                backoff: .constant(.milliseconds(10))
            ) { () -> String in
                attempts += 1
                throw TestError.intentional
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(attempts, 3)
        }
    }
    
    func testRetryableTaskWithCondition() async throws {
        var attempts = 0
        
        do {
            _ = try await withRetry(
                maxAttempts: 5,
                shouldRetry: { error in
                    // Only retry if it's a retryable error
                    (error as? RetryableError)?.isRetryable ?? false
                }
            ) { () -> String in
                attempts += 1
                if attempts < 3 {
                    throw RetryableError.temporary
                }
                throw RetryableError.permanent
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(attempts, 3) // Stopped at permanent error
        }
    }
    
    // MARK: - RetryPolicy Tests
    
    func testRetryPolicyMaxRetries() async throws {
        let policy = RetryPolicy(maxRetries: 3)
        var attempts = 0
        
        do {
            try await policy.execute {
                attempts += 1
                throw TestError.intentional
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(attempts, 4) // 1 initial + 3 retries
        }
    }
}

// MARK: - Helper Types

enum RetryableError: Error {
    case temporary
    case permanent
    
    var isRetryable: Bool {
        switch self {
        case .temporary: return true
        case .permanent: return false
        }
    }
}
