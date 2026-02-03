// ExponentialBackoff.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// An exponential backoff strategy for retry delays.
///
/// `ExponentialBackoff` increases the delay exponentially with each retry,
/// optionally adding jitter to prevent thundering herd problems.
///
/// ## Overview
///
/// Exponential backoff is the recommended strategy for most retry scenarios,
/// as it reduces load on failing systems while still allowing recovery.
///
/// ```swift
/// let backoff = ExponentialBackoff(
///     initialDelay: .milliseconds(100),
///     multiplier: 2.0,
///     maxDelay: .seconds(30)
/// )
///
/// for attempt in 0..<5 {
///     let delay = backoff.delay(forAttempt: attempt)
///     print("Attempt \(attempt): delay \(delay)")
/// }
/// // Attempt 0: 100ms
/// // Attempt 1: 200ms
/// // Attempt 2: 400ms
/// // Attempt 3: 800ms
/// // Attempt 4: 1600ms
/// ```
///
/// ## Topics
///
/// ### Creating Backoff Strategies
/// - ``init(initialDelay:multiplier:maxDelay:jitter:)``
///
/// ### Computing Delays
/// - ``delay(forAttempt:)``
public struct ExponentialBackoff: BackoffStrategy, Sendable {
    
    // MARK: - Types
    
    /// Jitter configuration for randomizing delays.
    public enum Jitter: Sendable {
        /// No jitter.
        case none
        /// Full jitter: random between 0 and computed delay.
        case full
        /// Equal jitter: half fixed, half random.
        case equal
        /// Decorrelated jitter: random between base and previous * 3.
        case decorrelated
        /// Custom jitter factor (0.0 to 1.0).
        case custom(Double)
    }
    
    // MARK: - Properties
    
    /// The initial delay before the first retry.
    public let initialDelay: Duration
    
    /// The multiplier applied to each subsequent delay.
    public let multiplier: Double
    
    /// The maximum delay cap.
    public let maxDelay: Duration
    
    /// The jitter strategy.
    public let jitter: Jitter
    
    // MARK: - Initialization
    
    /// Creates an exponential backoff strategy.
    ///
    /// - Parameters:
    ///   - initialDelay: Initial delay before first retry.
    ///   - multiplier: Multiplier for each retry (default 2.0).
    ///   - maxDelay: Maximum delay cap.
    ///   - jitter: Jitter strategy for randomization.
    public init(
        initialDelay: Duration,
        multiplier: Double = 2.0,
        maxDelay: Duration,
        jitter: Jitter = .none
    ) {
        precondition(multiplier > 1.0, "Multiplier must be greater than 1.0")
        self.initialDelay = initialDelay
        self.multiplier = multiplier
        self.maxDelay = maxDelay
        self.jitter = jitter
    }
    
    // MARK: - BackoffStrategy
    
    /// Computes the delay for a given retry attempt.
    ///
    /// - Parameter attempt: The retry attempt number (0-based).
    /// - Returns: The delay duration before this retry.
    public func delay(forAttempt attempt: Int) -> Duration {
        guard attempt >= 0 else { return .zero }
        
        // Compute base delay
        let baseNanoseconds = initialDelay.nanoseconds
        let exponentialFactor = pow(multiplier, Double(attempt))
        var delayNanoseconds = Double(baseNanoseconds) * exponentialFactor
        
        // Apply max cap
        let maxNanoseconds = Double(maxDelay.nanoseconds)
        delayNanoseconds = min(delayNanoseconds, maxNanoseconds)
        
        // Apply jitter
        delayNanoseconds = applyJitter(delayNanoseconds, attempt: attempt)
        
        return .nanoseconds(Int64(delayNanoseconds))
    }
    
    // MARK: - Private Methods
    
    /// Applies jitter to a delay value.
    private func applyJitter(_ delay: Double, attempt: Int) -> Double {
        switch jitter {
        case .none:
            return delay
            
        case .full:
            return Double.random(in: 0...delay)
            
        case .equal:
            let half = delay / 2
            return half + Double.random(in: 0...half)
            
        case .decorrelated:
            let baseNanoseconds = Double(initialDelay.nanoseconds)
            let previous = attempt > 0 ? delay / multiplier : baseNanoseconds
            let upperBound = min(previous * 3, Double(maxDelay.nanoseconds))
            return Double.random(in: baseNanoseconds...upperBound)
            
        case .custom(let factor):
            let jitterRange = delay * factor
            return delay - jitterRange / 2 + Double.random(in: 0...jitterRange)
        }
    }
}

// MARK: - Duration Extension

extension Duration {
    /// The duration in nanoseconds.
    var nanoseconds: Int64 {
        let (seconds, attoseconds) = components
        return seconds * 1_000_000_000 + attoseconds / 1_000_000_000
    }
}

// MARK: - Convenience Initializers

extension ExponentialBackoff {
    
    /// Creates a standard exponential backoff.
    ///
    /// Uses 100ms initial delay, 2x multiplier, 30s max.
    public static var standard: ExponentialBackoff {
        ExponentialBackoff(
            initialDelay: .milliseconds(100),
            multiplier: 2.0,
            maxDelay: .seconds(30),
            jitter: .equal
        )
    }
    
    /// Creates an aggressive backoff with shorter delays.
    ///
    /// Uses 10ms initial delay, 1.5x multiplier, 5s max.
    public static var aggressive: ExponentialBackoff {
        ExponentialBackoff(
            initialDelay: .milliseconds(10),
            multiplier: 1.5,
            maxDelay: .seconds(5),
            jitter: .full
        )
    }
    
    /// Creates a gentle backoff with longer delays.
    ///
    /// Uses 500ms initial delay, 2x multiplier, 60s max.
    public static var gentle: ExponentialBackoff {
        ExponentialBackoff(
            initialDelay: .milliseconds(500),
            multiplier: 2.0,
            maxDelay: .seconds(60),
            jitter: .decorrelated
        )
    }
}

// MARK: - Backoff Strategy Protocol

/// Protocol for backoff strategies.
public protocol BackoffStrategy: Sendable {
    /// Computes the delay for a retry attempt.
    ///
    /// - Parameter attempt: The attempt number (0-based).
    /// - Returns: The delay duration.
    func delay(forAttempt attempt: Int) -> Duration
}

// MARK: - Fibonacci Backoff

/// A Fibonacci-based backoff strategy.
///
/// Uses Fibonacci sequence for delay progression: 1, 1, 2, 3, 5, 8, 13...
public struct FibonacciBackoff: BackoffStrategy, Sendable {
    
    /// The base delay unit.
    public let baseDelay: Duration
    
    /// The maximum delay cap.
    public let maxDelay: Duration
    
    /// Creates a Fibonacci backoff.
    ///
    /// - Parameters:
    ///   - baseDelay: The base unit for delays.
    ///   - maxDelay: Maximum delay cap.
    public init(baseDelay: Duration, maxDelay: Duration) {
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
    
    /// Computes the delay for a retry attempt.
    public func delay(forAttempt attempt: Int) -> Duration {
        let fib = fibonacci(attempt + 1)
        let delayNanoseconds = Int64(fib) * baseDelay.nanoseconds
        let maxNanoseconds = maxDelay.nanoseconds
        return .nanoseconds(min(delayNanoseconds, maxNanoseconds))
    }
    
    /// Computes the nth Fibonacci number.
    private func fibonacci(_ n: Int) -> Int {
        guard n > 0 else { return 0 }
        guard n > 2 else { return 1 }
        
        var a = 1
        var b = 1
        for _ in 3...n {
            let next = a + b
            a = b
            b = next
        }
        return b
    }
}
