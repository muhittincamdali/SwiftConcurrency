// BatchTaskGroup.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A task group that processes items in configurable batches.
///
/// `BatchTaskGroup` divides work into batches, processing each batch
/// concurrently while controlling memory usage and system load.
///
/// ## Overview
///
/// Use `BatchTaskGroup` when processing large datasets that would
/// overwhelm system resources if processed all at once.
///
/// ```swift
/// let items = Array(1...10000)
/// let results = try await BatchTaskGroup.process(
///     items,
///     batchSize: 100,
///     maxConcurrentBatches: 4
/// ) { batch in
///     // Process each batch
///     return batch.map { $0 * 2 }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Batch Task Groups
/// - ``process(_:batchSize:maxConcurrentBatches:transform:)``
/// - ``processWithProgress(_:batchSize:progress:transform:)``
///
/// ### Configuration
/// - ``BatchConfiguration``
public enum BatchTaskGroup {
    
    // MARK: - Types
    
    /// Configuration for batch processing.
    public struct BatchConfiguration: Sendable {
        /// Number of items per batch.
        public var batchSize: Int
        /// Maximum batches to process concurrently.
        public var maxConcurrentBatches: Int
        /// Whether to cancel remaining batches on failure.
        public var cancelOnFailure: Bool
        /// Delay between starting batches (for rate limiting).
        public var batchDelay: Duration?
        
        /// Default configuration with batch size of 50.
        public static var `default`: BatchConfiguration {
            BatchConfiguration(
                batchSize: 50,
                maxConcurrentBatches: 4,
                cancelOnFailure: true,
                batchDelay: nil
            )
        }
        
        /// Creates a batch configuration.
        /// - Parameters:
        ///   - batchSize: Items per batch.
        ///   - maxConcurrentBatches: Max concurrent batches.
        ///   - cancelOnFailure: Cancel on failure.
        ///   - batchDelay: Delay between batches.
        public init(
            batchSize: Int,
            maxConcurrentBatches: Int = 4,
            cancelOnFailure: Bool = true,
            batchDelay: Duration? = nil
        ) {
            self.batchSize = max(1, batchSize)
            self.maxConcurrentBatches = max(1, maxConcurrentBatches)
            self.cancelOnFailure = cancelOnFailure
            self.batchDelay = batchDelay
        }
    }
    
    /// Progress information for batch processing.
    public struct BatchProgress: Sendable {
        /// The current batch index (0-based).
        public let currentBatch: Int
        /// The total number of batches.
        public let totalBatches: Int
        /// The number of items processed so far.
        public let processedItems: Int
        /// The total number of items.
        public let totalItems: Int
        
        /// Progress as a fraction (0.0 to 1.0).
        public var fractionCompleted: Double {
            guard totalItems > 0 else { return 1.0 }
            return Double(processedItems) / Double(totalItems)
        }
        
        /// Progress as a percentage (0 to 100).
        public var percentComplete: Int {
            Int(fractionCompleted * 100)
        }
    }
    
    /// A batch of items to process.
    public struct Batch<T: Sendable>: Sendable {
        /// The items in this batch.
        public let items: [T]
        /// The batch index (0-based).
        public let index: Int
        /// The total number of batches.
        public let totalBatches: Int
        /// The starting index in the original array.
        public let startIndex: Int
    }
    
    // MARK: - Static Methods
    
    /// Processes items in batches with a transform function.
    ///
    /// - Parameters:
    ///   - items: The items to process.
    ///   - batchSize: Number of items per batch.
    ///   - maxConcurrentBatches: Maximum concurrent batches.
    ///   - transform: Transform function applied to each batch.
    /// - Returns: Flattened array of transformed results.
    public static func process<Element: Sendable, Result: Sendable>(
        _ items: [Element],
        batchSize: Int,
        maxConcurrentBatches: Int = 4,
        transform: @escaping @Sendable ([Element]) async throws -> [Result]
    ) async throws -> [Result] {
        let config = BatchConfiguration(
            batchSize: batchSize,
            maxConcurrentBatches: maxConcurrentBatches
        )
        return try await processWithConfiguration(items, configuration: config, transform: transform)
    }
    
    /// Processes items in batches with configuration.
    ///
    /// - Parameters:
    ///   - items: The items to process.
    ///   - configuration: Batch configuration.
    ///   - transform: Transform function applied to each batch.
    /// - Returns: Flattened array of transformed results.
    public static func processWithConfiguration<Element: Sendable, Result: Sendable>(
        _ items: [Element],
        configuration: BatchConfiguration,
        transform: @escaping @Sendable ([Element]) async throws -> [Result]
    ) async throws -> [Result] {
        let batches = createBatches(from: items, size: configuration.batchSize)
        
        guard !batches.isEmpty else { return [] }
        
        var allResults: [[Result]] = Array(repeating: [], count: batches.count)
        
        try await withThrowingTaskGroup(of: (Int, [Result]).self) { group in
            var runningCount = 0
            var batchIndex = 0
            
            // Start initial batches
            while runningCount < configuration.maxConcurrentBatches && batchIndex < batches.count {
                let batch = batches[batchIndex]
                let index = batchIndex
                group.addTask {
                    let result = try await transform(batch)
                    return (index, result)
                }
                runningCount += 1
                batchIndex += 1
            }
            
            // Process results and start new batches
            for try await (index, result) in group {
                allResults[index] = result
                runningCount -= 1
                
                if batchIndex < batches.count {
                    if let delay = configuration.batchDelay {
                        try await Task.sleep(for: delay)
                    }
                    
                    let batch = batches[batchIndex]
                    let nextIndex = batchIndex
                    group.addTask {
                        let result = try await transform(batch)
                        return (nextIndex, result)
                    }
                    runningCount += 1
                    batchIndex += 1
                }
            }
        }
        
        return allResults.flatMap { $0 }
    }
    
    /// Processes items in batches with progress reporting.
    ///
    /// - Parameters:
    ///   - items: The items to process.
    ///   - batchSize: Number of items per batch.
    ///   - progress: Closure called with progress updates.
    ///   - transform: Transform function applied to each batch.
    /// - Returns: Flattened array of transformed results.
    public static func processWithProgress<Element: Sendable, Result: Sendable>(
        _ items: [Element],
        batchSize: Int,
        progress: @escaping @Sendable (BatchProgress) async -> Void,
        transform: @escaping @Sendable ([Element]) async throws -> [Result]
    ) async throws -> [Result] {
        let batches = createBatches(from: items, size: batchSize)
        let totalItems = items.count
        
        guard !batches.isEmpty else { return [] }
        
        var allResults: [[Result]] = Array(repeating: [], count: batches.count)
        var processedCount = 0
        
        for (index, batch) in batches.enumerated() {
            let result = try await transform(batch)
            allResults[index] = result
            processedCount += batch.count
            
            let progressInfo = BatchProgress(
                currentBatch: index,
                totalBatches: batches.count,
                processedItems: processedCount,
                totalItems: totalItems
            )
            await progress(progressInfo)
        }
        
        return allResults.flatMap { $0 }
    }
    
    /// Processes items in batches with detailed batch information.
    ///
    /// - Parameters:
    ///   - items: The items to process.
    ///   - configuration: Batch configuration.
    ///   - transform: Transform function receiving batch with metadata.
    /// - Returns: Flattened array of transformed results.
    public static func processDetailed<Element: Sendable, Result: Sendable>(
        _ items: [Element],
        configuration: BatchConfiguration = .default,
        transform: @escaping @Sendable (Batch<Element>) async throws -> [Result]
    ) async throws -> [Result] {
        let batches = createDetailedBatches(from: items, size: configuration.batchSize)
        
        guard !batches.isEmpty else { return [] }
        
        var allResults: [[Result]] = Array(repeating: [], count: batches.count)
        
        try await withThrowingTaskGroup(of: (Int, [Result]).self) { group in
            var runningCount = 0
            var batchIndex = 0
            
            while runningCount < configuration.maxConcurrentBatches && batchIndex < batches.count {
                let batch = batches[batchIndex]
                let index = batchIndex
                group.addTask {
                    let result = try await transform(batch)
                    return (index, result)
                }
                runningCount += 1
                batchIndex += 1
            }
            
            for try await (index, result) in group {
                allResults[index] = result
                runningCount -= 1
                
                if batchIndex < batches.count {
                    let batch = batches[batchIndex]
                    let nextIndex = batchIndex
                    group.addTask {
                        let result = try await transform(batch)
                        return (nextIndex, result)
                    }
                    runningCount += 1
                    batchIndex += 1
                }
            }
        }
        
        return allResults.flatMap { $0 }
    }
    
    // MARK: - Private Helpers
    
    /// Creates batches from an array.
    private static func createBatches<Element>(from items: [Element], size: Int) -> [[Element]] {
        guard !items.isEmpty else { return [] }
        return stride(from: 0, to: items.count, by: size).map { startIndex in
            let endIndex = Swift.min(startIndex + size, items.count)
            return Array(items[startIndex..<endIndex])
        }
    }
    
    /// Creates detailed batches with metadata.
    private static func createDetailedBatches<Element: Sendable>(from items: [Element], size: Int) -> [Batch<Element>] {
        guard !items.isEmpty else { return [] }
        let totalBatches = (items.count + size - 1) / size
        
        return stride(from: 0, to: items.count, by: size).enumerated().map { index, startIndex in
            let endIndex = Swift.min(startIndex + size, items.count)
            return Batch(
                items: Array(items[startIndex..<endIndex]),
                index: index,
                totalBatches: totalBatches,
                startIndex: startIndex
            )
        }
    }
}

// MARK: - Convenience Extensions

extension Array where Element: Sendable {
    
    /// Processes the array in batches.
    ///
    /// - Parameters:
    ///   - batchSize: Number of items per batch.
    ///   - transform: Transform function applied to each batch.
    /// - Returns: Flattened array of transformed results.
    public func processBatched<Result: Sendable>(
        batchSize: Int,
        transform: @escaping @Sendable ([Element]) async throws -> [Result]
    ) async throws -> [Result] {
        try await BatchTaskGroup.process(
            self,
            batchSize: batchSize,
            transform: transform
        )
    }
    
    /// Maps the array in parallel batches.
    ///
    /// - Parameters:
    ///   - batchSize: Number of items per batch.
    ///   - transform: Transform function applied to each item.
    /// - Returns: Array of transformed results.
    public func batchedMap<Result: Sendable>(
        batchSize: Int,
        transform: @escaping @Sendable (Element) async throws -> Result
    ) async throws -> [Result] {
        try await BatchTaskGroup.process(
            self,
            batchSize: batchSize
        ) { batch in
            var results: [Result] = []
            results.reserveCapacity(batch.count)
            for item in batch {
                let result = try await transform(item)
                results.append(result)
            }
            return results
        }
    }
}
