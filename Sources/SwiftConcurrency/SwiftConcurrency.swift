// SwiftConcurrency.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

/// SwiftConcurrency - Modern Swift concurrency utilities
///
/// A comprehensive library providing:
/// - TaskGroup extensions for batch processing
/// - AsyncSequence operators (debounce, throttle, retry, timeout)
/// - Actor-based state management
/// - Testing utilities for async code
/// - Debug and performance profiling tools
/// - Sendable helpers for thread-safe code
///
/// ## Quick Start
///
/// ```swift
/// import SwiftConcurrency
///
/// // Debounce search queries
/// for await query in searchQueries.debounce(for: .milliseconds(300)) {
///     await performSearch(query)
/// }
///
/// // Retry failed operations
/// let data = try await fetchData().retry(maxAttempts: 3)
///
/// // Concurrent batch processing
/// let results = try await items.concurrentMap(maxConcurrency: 4) { item in
///     await process(item)
/// }
/// ```
public enum SwiftConcurrency {
    /// Library version.
    public static let version = "1.0.0"
}

// Re-export commonly used types for convenience
// These are already public in their respective files
