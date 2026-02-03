// LinearBackoff.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A linear backoff strategy for retry delays.
///
/// `LinearBackoff` increases the delay linearly with each retry,
/// adding a fixed increment each time.
///
/// ## Overview
///
/// Linear backoff is useful when you want predictable, gradual
/// increase in delay times.
///
/// ```swift
/// let backoff = LinearBackoff(
///     initialDelay: .milliseconds(100),
///     increment: .milliseconds(100),
///     maxDelay: .seconds(5)
/// )
///
/// for attempt in 0..<5 {
///     let delay = backoff.delay(forAttempt: attempt)
///     print("Attempt \(attempt): delay \(delay)")
/// }
/// // Attempt 0: 100ms
/// // Attempt 1: 200ms
/// // Attempt 2: 300ms
/// // Attempt 3: 400ms
/// // Attempt 4: 500ms
/// ```
///
/// ## Topics
///
/// ### Creating Linear Backoff
/// - ``init(initialDelay:increment:maxDelay:)``
public struct LinearBackoff: BackoffStrategy, Sendable {
    
    // MARK: - Properties
    
    /// The initial delay before the first retry.
    public let initialDelay: Duration
    
    /// The increment added to each subsequent delay.
    public let increment: Duration
    
    /// The maximum delay cap.
    public let maxDelay: Duration
    
    // MARK: - Initialization
    
    /// Creates a linear backoff strategy.
    ///
    /// - Parameters:
    ///   - initialDelay: Initial delay before first retry.
    ///   - increment: Fixed increment for each retry.
    ///   - maxDelay: Maximum delay cap.
    public init(
        initialDelay: Duration,
        increment: Duration,
        maxDelay: Duration
    ) {
        self.initialDelay = initialDelay
        self.increment = increment
        self.maxDelay = maxDelay
    }
    
    // MARK: - BackoffStrategy
    
    /// Computes the delay for a given retry attempt.
    ///
    /// - Parameter attempt: The retry attempt number (0-based).
    /// - Returns: The delay duration before this retry.
    public func delay(forAttempt attempt: Int) -> Duration {
        guard attempt >= 0 else { return .zero }
        
        let baseNanoseconds = initialDelay.nanoseconds
        let incrementNanoseconds = increment.nanoseconds
        let delayNanoseconds = baseNanoseconds + Int64(attempt) * incrementNanoseconds
        let maxNanoseconds = maxDelay.nanoseconds
        
        return .nanoseconds(min(delayNanoseconds, maxNanoseconds))
    }
}

// MARK: - Convenience Initializers

extension LinearBackoff {
    
    /// Creates a standard linear backoff.
    ///
    /// Uses 100ms initial, 100ms increment, 5s max.
    public static var standard: LinearBackoff {
        LinearBackoff(
            initialDelay: .milliseconds(100),
            increment: .milliseconds(100),
            maxDelay: .seconds(5)
        )
    }
    
    /// Creates an aggressive linear backoff.
    ///
    /// Uses 50ms initial, 50ms increment, 2s max.
    public static var aggressive: LinearBackoff {
        LinearBackoff(
            initialDelay: .milliseconds(50),
            increment: .milliseconds(50),
            maxDelay: .seconds(2)
        )
    }
}

// MARK: - Constant Backoff

/// A constant backoff strategy with fixed delays.
///
/// `ConstantBackoff` uses the same delay for every retry attempt.
public struct ConstantBackoff: BackoffStrategy, Sendable {
    
    /// The fixed delay.
    public let delay: Duration
    
    /// Creates a constant backoff strategy.
    ///
    /// - Parameter delay: The fixed delay between retries.
    public init(delay: Duration) {
        self.delay = delay
    }
    
    /// Returns the constant delay for any attempt.
    public func delay(forAttempt attempt: Int) -> Duration {
        delay
    }
}

// MARK: - Polynomial Backoff

/// A polynomial backoff strategy.
///
/// `PolynomialBackoff` increases delay based on attempt^exponent.
public struct PolynomialBackoff: BackoffStrategy, Sendable {
    
    /// The base delay unit.
    public let baseDelay: Duration
    
    /// The polynomial exponent.
    public let exponent: Double
    
    /// The maximum delay cap.
    public let maxDelay: Duration
    
    /// Creates a polynomial backoff.
    ///
    /// - Parameters:
    ///   - baseDelay: The base delay unit.
    ///   - exponent: The polynomial exponent (e.g., 2 for quadratic).
    ///   - maxDelay: Maximum delay cap.
    public init(
        baseDelay: Duration,
        exponent: Double = 2.0,
        maxDelay: Duration
    ) {
        self.baseDelay = baseDelay
        self.exponent = exponent
        self.maxDelay = maxDelay
    }
    
    /// Computes the delay for a retry attempt.
    public func delay(forAttempt attempt: Int) -> Duration {
        guard attempt >= 0 else { return .zero }
        
        let factor = pow(Double(attempt + 1), exponent)
        let delayNanoseconds = Double(baseDelay.nanoseconds) * factor
        let maxNanoseconds = Double(maxDelay.nanoseconds)
        
        return .nanoseconds(Int64(min(delayNanoseconds, maxNanoseconds)))
    }
    
    /// Creates a quadratic backoff (exponent = 2).
    public static func quadratic(baseDelay: Duration, maxDelay: Duration) -> PolynomialBackoff {
        PolynomialBackoff(baseDelay: baseDelay, exponent: 2.0, maxDelay: maxDelay)
    }
    
    /// Creates a cubic backoff (exponent = 3).
    public static func cubic(baseDelay: Duration, maxDelay: Duration) -> PolynomialBackoff {
        PolynomialBackoff(baseDelay: baseDelay, exponent: 3.0, maxDelay: maxDelay)
    }
}

// MARK: - Slot Backoff

/// A slot-based backoff for collision avoidance.
///
/// Similar to Ethernet's binary exponential backoff, picks
/// a random slot from an expanding range.
public struct SlotBackoff: BackoffStrategy, Sendable {
    
    /// The slot duration.
    public let slotDuration: Duration
    
    /// Maximum number of slots.
    public let maxSlots: Int
    
    /// Creates a slot-based backoff.
    ///
    /// - Parameters:
    ///   - slotDuration: Duration of each slot.
    ///   - maxSlots: Maximum number of slots.
    public init(slotDuration: Duration, maxSlots: Int = 1024) {
        self.slotDuration = slotDuration
        self.maxSlots = maxSlots
    }
    
    /// Computes a random delay within the slot range.
    public func delay(forAttempt attempt: Int) -> Duration {
        let slotCount = min(1 << (attempt + 1), maxSlots)
        let selectedSlot = Int.random(in: 0..<slotCount)
        return .nanoseconds(Int64(selectedSlot) * slotDuration.nanoseconds)
    }
}
