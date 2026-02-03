// ConcurrentMap.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - ConcurrentMap

/// Errors that can occur during concurrent mapping operations.
public enum ConcurrentMapError: Error, Sendable {
    /// The operation was cancelled.
    case cancelled
    /// An element transformation failed.
    case transformationFailed(Error)
    /// Maximum concurrency must be positive.
    case invalidConcurrency
}

/// Configuration for concurrent mapping operations.
public struct ConcurrentMapConfiguration: Sendable {
    /// Maximum number of concurrent operations.
    public var maxConcurrency: Int
    /// Whether to cancel all operations on first failure.
    public var cancelOnFailure: Bool
    /// Priority for spawned tasks.
    public var priority: TaskPriority?
    
    /// Default configuration with unlimited concurrency.
    public static let `default` = ConcurrentMapConfiguration(
        maxConcurrency: .max,
        cancelOnFailure: true,
        priority: nil
    )
    
    /// Creates a concurrent map configuration.
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent operations.
    ///   - cancelOnFailure: Cancel remaining on failure.
    ///   - priority: Task priority.
    public init(
        maxConcurrency: Int = .max,
        cancelOnFailure: Bool = true,
        priority: TaskPriority? = nil
    ) {
        self.maxConcurrency = maxConcurrency
        self.cancelOnFailure = cancelOnFailure
        self.priority = priority
    }
}

/// Provides concurrent mapping capabilities on sequences using Swift task groups.
///
/// Transforms each element of the sequence concurrently while preserving
/// the original order of elements in the output array.
///
/// ## Overview
///
/// Use concurrent mapping when you need to transform collections in parallel,
/// significantly reducing total execution time for I/O-bound operations.
///
/// ```swift
/// let urls = [url1, url2, url3]
/// let data = try await urls.concurrentMap { url in
///     try await URLSession.shared.data(from: url).0
/// }
/// ```
///
/// ## Topics
///
/// ### Concurrent Transformations
/// - ``Sequence/concurrentMap(_:)-8xm4c``
/// - ``Sequence/concurrentMap(maxConcurrency:_:)-5d7rk``
/// - ``Sequence/concurrentCompactMap(_:)``
///
/// ### Configuration
/// - ``ConcurrentMapConfiguration``
extension Sequence where Element: Sendable {

    /// Concurrently maps each element of the sequence using the provided transform closure.
    ///
    /// Elements are processed in parallel using a `TaskGroup`, and results are
    /// collected in the original sequence order.
    ///
    /// - Parameter transform: An async throwing closure that transforms each element.
    /// - Returns: An array of transformed elements in their original order.
    /// - Throws: Rethrows any error from the transform closure.
    ///
    /// ```swift
    /// let urls: [URL] = [/* ... */]
    /// let data = try await urls.concurrentMap { url in
    ///     let (data, _) = try await URLSession.shared.data(from: url)
    ///     return data
    /// }
    /// ```
    public func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let indexedElements = Array(self).enumerated().map { ($0.offset, $0.element) }

        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, element) in indexedElements {
                group.addTask {
                    let result = try await transform(element)
                    return (index, result)
                }
            }

            var results = [(Int, T)]()
            results.reserveCapacity(indexedElements.count)

            for try await indexedResult in group {
                results.append(indexedResult)
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }
    
    /// Concurrently maps with a maximum concurrency limit.
    ///
    /// Limits the number of concurrent operations to prevent resource exhaustion.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum number of concurrent transformations.
    ///   - transform: An async throwing closure that transforms each element.
    /// - Returns: An array of transformed elements in their original order.
    /// - Throws: Rethrows any error from the transform closure.
    ///
    /// ```swift
    /// // Process at most 5 URLs at a time
    /// let data = try await urls.concurrentMap(maxConcurrency: 5) { url in
    ///     try await URLSession.shared.data(from: url).0
    /// }
    /// ```
    public func concurrentMap<T: Sendable>(
        maxConcurrency: Int,
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            var results = [(Int, T)]()
            var index = 0
            var iterator = makeIterator()
            var activeCount = 0
            
            // Start initial batch up to maxConcurrency
            while activeCount < maxConcurrency, let element = iterator.next() {
                let currentIndex = index
                group.addTask {
                    let result = try await transform(element)
                    return (currentIndex, result)
                }
                index += 1
                activeCount += 1
            }
            
            // Process results and start new tasks as slots become available
            while let result = try await group.next() {
                results.append(result)
                activeCount -= 1
                
                if let element = iterator.next() {
                    let currentIndex = index
                    group.addTask {
                        let transformResult = try await transform(element)
                        return (currentIndex, transformResult)
                    }
                    index += 1
                    activeCount += 1
                }
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    /// Concurrently maps with configuration.
    ///
    /// - Parameters:
    ///   - configuration: The concurrent map configuration.
    ///   - transform: An async throwing closure that transforms each element.
    /// - Returns: An array of transformed elements.
    /// - Throws: Rethrows any error from the transform closure.
    public func concurrentMap<T: Sendable>(
        configuration: ConcurrentMapConfiguration,
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async throws -> [T] {
        try await concurrentMap(
            maxConcurrency: configuration.maxConcurrency,
            transform
        )
    }

    /// Concurrently maps each element using a non-throwing transform.
    ///
    /// - Parameter transform: An async closure that transforms each element.
    /// - Returns: An array of transformed elements in their original order.
    public func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async -> T
    ) async -> [T] {
        let indexedElements = Array(self).enumerated().map { ($0.offset, $0.element) }

        return await withTaskGroup(of: (Int, T).self) { group in
            for (index, element) in indexedElements {
                group.addTask {
                    let result = await transform(element)
                    return (index, result)
                }
            }

            var results = [(Int, T)]()
            results.reserveCapacity(indexedElements.count)

            for await indexedResult in group {
                results.append(indexedResult)
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }
    
    /// Concurrently maps with a maximum concurrency limit (non-throwing).
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent operations.
    ///   - transform: An async closure that transforms each element.
    /// - Returns: An array of transformed elements.
    public func concurrentMap<T: Sendable>(
        maxConcurrency: Int,
        _ transform: @Sendable @escaping (Element) async -> T
    ) async -> [T] {
        await withTaskGroup(of: (Int, T).self) { group in
            var results = [(Int, T)]()
            var index = 0
            var iterator = makeIterator()
            var activeCount = 0
            
            while activeCount < maxConcurrency, let element = iterator.next() {
                let currentIndex = index
                group.addTask {
                    let result = await transform(element)
                    return (currentIndex, result)
                }
                index += 1
                activeCount += 1
            }
            
            while let result = await group.next() {
                results.append(result)
                activeCount -= 1
                
                if let element = iterator.next() {
                    let currentIndex = index
                    group.addTask {
                        let transformResult = await transform(element)
                        return (currentIndex, transformResult)
                    }
                    index += 1
                    activeCount += 1
                }
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    /// Concurrently performs a `compactMap` over the sequence.
    ///
    /// - Parameter transform: An async throwing closure returning an optional value.
    /// - Returns: An array of non-nil results in their original order.
    public func concurrentCompactMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        let mapped = try await concurrentMap(transform)
        return mapped.compactMap { $0 }
    }
    
    /// Concurrently performs a `compactMap` with concurrency limit.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent operations.
    ///   - transform: An async throwing closure returning an optional value.
    /// - Returns: An array of non-nil results.
    public func concurrentCompactMap<T: Sendable>(
        maxConcurrency: Int,
        _ transform: @Sendable @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        let mapped = try await concurrentMap(maxConcurrency: maxConcurrency, transform)
        return mapped.compactMap { $0 }
    }
    
    /// Concurrently performs forEach on each element.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent operations.
    ///   - body: The closure to execute for each element.
    /// - Throws: Any error from the body closure.
    public func concurrentForEach(
        maxConcurrency: Int = .max,
        _ body: @Sendable @escaping (Element) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            var iterator = makeIterator()
            var activeCount = 0
            
            while activeCount < maxConcurrency, let element = iterator.next() {
                group.addTask {
                    try await body(element)
                }
                activeCount += 1
            }
            
            while try await group.next() != nil {
                activeCount -= 1
                
                if let element = iterator.next() {
                    group.addTask {
                        try await body(element)
                    }
                    activeCount += 1
                }
            }
        }
    }
    
    /// Concurrently filters elements based on an async predicate.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent operations.
    ///   - predicate: An async predicate to test each element.
    /// - Returns: Elements that satisfy the predicate.
    /// - Throws: Any error from the predicate.
    public func concurrentFilter(
        maxConcurrency: Int = .max,
        _ predicate: @Sendable @escaping (Element) async throws -> Bool
    ) async throws -> [Element] {
        try await withThrowingTaskGroup(of: (Int, Element, Bool).self) { group in
            var results = [(Int, Element, Bool)]()
            var index = 0
            var iterator = makeIterator()
            var activeCount = 0
            
            while activeCount < maxConcurrency, let element = iterator.next() {
                let currentIndex = index
                group.addTask {
                    let include = try await predicate(element)
                    return (currentIndex, element, include)
                }
                index += 1
                activeCount += 1
            }
            
            while let result = try await group.next() {
                results.append(result)
                activeCount -= 1
                
                if let element = iterator.next() {
                    let currentIndex = index
                    group.addTask {
                        let include = try await predicate(element)
                        return (currentIndex, element, include)
                    }
                    index += 1
                    activeCount += 1
                }
            }
            
            return results
                .sorted { $0.0 < $1.0 }
                .filter { $0.2 }
                .map { $0.1 }
        }
    }
    
    /// Concurrently reduces elements into a single value.
    ///
    /// Note: Due to the concurrent nature, the reduce operation must be
    /// associative and commutative for correct results.
    ///
    /// - Parameters:
    ///   - initialResult: The initial accumulator value.
    ///   - combineResults: Closure to combine two intermediate results.
    ///   - transform: Transform applied to each element.
    /// - Returns: The final combined result.
    /// - Throws: Any error from the closures.
    public func concurrentReduce<Result: Sendable>(
        _ initialResult: Result,
        combineResults: @Sendable @escaping (Result, Result) -> Result,
        transform: @Sendable @escaping (Element) async throws -> Result
    ) async throws -> Result {
        let partialResults = try await concurrentMap(transform)
        return partialResults.reduce(initialResult, combineResults)
    }
}
