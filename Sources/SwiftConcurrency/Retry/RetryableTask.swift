// RetryableTask.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A task that can be retried with configurable policies.
///
/// `RetryableTask` wraps an async operation and automatically retries
/// it according to the configured retry policy.
///
/// ## Overview
///
/// Use `RetryableTask` when you need fine-grained control over retry
/// behavior, including custom error handling and retry conditions.
///
/// ```swift
/// let task = RetryableTask(
///     maxAttempts: 5,
///     backoff: .exponential(initial: .milliseconds(100)),
///     shouldRetry: { error in
///         (error as? NetworkError)?.isRetryable ?? false
///     }
/// ) {
///     try await fetchData()
/// }
///
/// let result = try await task.run()
/// ```
///
/// ## Topics
///
/// ### Creating Retryable Tasks
/// - ``init(maxAttempts:backoff:shouldRetry:onRetry:operation:)``
///
/// ### Running Tasks
/// - ``run()``
public struct RetryableTask<Success: Sendable>: Sendable {
    
    // MARK: - Types
    
    /// A backoff configuration.
    public enum Backoff: Sendable {
        /// Constant delay between retries.
        case constant(Duration)
        /// Linear increasing delay.
        case linear(initial: Duration, increment: Duration, max: Duration)
        /// Exponential increasing delay.
        case exponential(initial: Duration, multiplier: Double, max: Duration)
        /// Custom backoff strategy.
        case custom(@Sendable (Int) -> Duration)
        
        /// Computes the delay for an attempt.
        func delay(forAttempt attempt: Int) -> Duration {
            switch self {
            case .constant(let duration):
                return duration
                
            case .linear(let initial, let increment, let max):
                let delay = initial.nanoseconds + Int64(attempt) * increment.nanoseconds
                return .nanoseconds(min(delay, max.nanoseconds))
                
            case .exponential(let initial, let multiplier, let max):
                let factor = pow(multiplier, Double(attempt))
                let delay = Double(initial.nanoseconds) * factor
                return .nanoseconds(Int64(min(delay, Double(max.nanoseconds))))
                
            case .custom(let strategy):
                return strategy(attempt)
            }
        }
    }
    
    /// Information about a retry attempt.
    public struct RetryInfo: Sendable {
        /// The attempt number (1-based).
        public let attempt: Int
        /// The total number of attempts allowed.
        public let maxAttempts: Int
        /// The error that caused the retry.
        public let error: Error
        /// The delay before the next retry.
        public let delay: Duration
        
        /// Whether this is the last attempt.
        public var isLastAttempt: Bool {
            attempt >= maxAttempts
        }
    }
    
    /// Result of all retry attempts.
    public struct RetryResult: Sendable {
        /// The final result (if successful).
        public let value: Success?
        /// All errors encountered.
        public let errors: [Error]
        /// Total number of attempts made.
        public let totalAttempts: Int
        /// Whether the operation eventually succeeded.
        public var succeeded: Bool { value != nil }
    }
    
    // MARK: - Properties
    
    /// Maximum number of attempts.
    private let maxAttempts: Int
    
    /// The backoff strategy.
    private let backoff: Backoff
    
    /// Predicate to determine if an error should be retried.
    private let shouldRetry: @Sendable (Error) -> Bool
    
    /// Callback invoked before each retry.
    private let onRetry: (@Sendable (RetryInfo) async -> Void)?
    
    /// The operation to retry.
    private let operation: @Sendable () async throws -> Success
    
    // MARK: - Initialization
    
    /// Creates a retryable task.
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts (default 3).
    ///   - backoff: The backoff strategy.
    ///   - shouldRetry: Predicate to check if error should be retried.
    ///   - onRetry: Optional callback before each retry.
    ///   - operation: The operation to perform.
    public init(
        maxAttempts: Int = 3,
        backoff: Backoff = .exponential(initial: .milliseconds(100), multiplier: 2.0, max: .seconds(30)),
        shouldRetry: @escaping @Sendable (Error) -> Bool = { _ in true },
        onRetry: (@Sendable (RetryInfo) async -> Void)? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        precondition(maxAttempts > 0, "Max attempts must be at least 1")
        self.maxAttempts = maxAttempts
        self.backoff = backoff
        self.shouldRetry = shouldRetry
        self.onRetry = onRetry
        self.operation = operation
    }
    
    // MARK: - Public Methods
    
    /// Runs the retryable task.
    ///
    /// - Returns: The result of the operation.
    /// - Throws: The last error if all retries fail.
    public func run() async throws -> Success {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should retry
                if attempt < maxAttempts && shouldRetry(error) {
                    let delay = backoff.delay(forAttempt: attempt - 1)
                    
                    // Notify about retry
                    if let onRetry = onRetry {
                        let info = RetryInfo(
                            attempt: attempt,
                            maxAttempts: maxAttempts,
                            error: error,
                            delay: delay
                        )
                        await onRetry(info)
                    }
                    
                    // Wait before retrying
                    try await Task.sleep(for: delay)
                } else {
                    throw error
                }
            }
        }
        
        // This should never be reached, but just in case
        throw lastError!
    }
    
    /// Runs and returns detailed results.
    ///
    /// - Returns: A result containing the value or all errors.
    public func runWithDetails() async -> RetryResult {
        var errors: [Error] = []
        var totalAttempts = 0
        
        for attempt in 1...maxAttempts {
            totalAttempts = attempt
            
            do {
                let value = try await operation()
                return RetryResult(
                    value: value,
                    errors: errors,
                    totalAttempts: totalAttempts
                )
            } catch {
                errors.append(error)
                
                if attempt < maxAttempts && shouldRetry(error) {
                    let delay = backoff.delay(forAttempt: attempt - 1)
                    try? await Task.sleep(for: delay)
                } else {
                    break
                }
            }
        }
        
        return RetryResult(
            value: nil,
            errors: errors,
            totalAttempts: totalAttempts
        )
    }
}

// MARK: - Convenience Functions

/// Retries an operation with default settings.
///
/// - Parameters:
///   - maxAttempts: Maximum attempts.
///   - backoff: Backoff strategy.
///   - operation: The operation to retry.
/// - Returns: The result.
/// - Throws: The last error if all retries fail.
public func withRetry<T: Sendable>(
    maxAttempts: Int = 3,
    backoff: RetryableTask<T>.Backoff = .exponential(
        initial: .milliseconds(100),
        multiplier: 2.0,
        max: .seconds(30)
    ),
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let task = RetryableTask(
        maxAttempts: maxAttempts,
        backoff: backoff,
        operation: operation
    )
    return try await task.run()
}

/// Retries an operation with custom retry condition.
///
/// - Parameters:
///   - maxAttempts: Maximum attempts.
///   - shouldRetry: Predicate for retry decision.
///   - operation: The operation to retry.
/// - Returns: The result.
/// - Throws: The last error if all retries fail.
public func withRetry<T: Sendable>(
    maxAttempts: Int = 3,
    shouldRetry: @escaping @Sendable (Error) -> Bool,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let task = RetryableTask(
        maxAttempts: maxAttempts,
        shouldRetry: shouldRetry,
        operation: operation
    )
    return try await task.run()
}
