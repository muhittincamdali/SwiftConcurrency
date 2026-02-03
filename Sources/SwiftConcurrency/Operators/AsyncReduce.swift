// AsyncReduce.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncReduceSequence

/// Reduces an async sequence to a single value with intermediate results.
///
/// Unlike the standard `reduce` which returns only the final result,
/// this produces a sequence of accumulated values.
///
/// ```swift
/// let numbers = AsyncStream { continuation in
///     for i in 1...5 { continuation.yield(i) }
///     continuation.finish()
/// }
///
/// let running = numbers.scan(0, +)
/// for await sum in running {
///     print(sum) // 1, 3, 6, 10, 15
/// }
/// ```
public struct AsyncScanSequence<Base: AsyncSequence, Result: Sendable>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Result
    
    private let base: Base
    private let initialResult: Result
    private let nextPartialResult: @Sendable (Result, Base.Element) async throws -> Result
    
    /// Creates a scan sequence.
    ///
    /// - Parameters:
    ///   - base: The source sequence.
    ///   - initialResult: Initial accumulator value.
    ///   - nextPartialResult: Combining function.
    public init(
        _ base: Base,
        _ initialResult: Result,
        _ nextPartialResult: @escaping @Sendable (Result, Base.Element) async throws -> Result
    ) {
        self.base = base
        self.initialResult = initialResult
        self.nextPartialResult = nextPartialResult
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: base.makeAsyncIterator(),
            accumulator: initialResult,
            nextPartialResult: nextPartialResult
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private var accumulator: Result
        private let nextPartialResult: @Sendable (Result, Base.Element) async throws -> Result
        
        init(
            iterator: Base.AsyncIterator,
            accumulator: Result,
            nextPartialResult: @escaping @Sendable (Result, Base.Element) async throws -> Result
        ) {
            self.iterator = iterator
            self.accumulator = accumulator
            self.nextPartialResult = nextPartialResult
        }
        
        public mutating func next() async throws -> Element? {
            guard let element = try await iterator.next() else {
                return nil
            }
            
            accumulator = try await nextPartialResult(accumulator, element)
            return accumulator
        }
    }
}

// MARK: - AsyncReducingSequence (with emit control)

/// Reduces with control over when to emit accumulated values.
public struct AsyncReducingSequence<Base: AsyncSequence, Result: Sendable>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Result
    
    /// Control for whether to emit the current accumulator.
    public enum EmitControl: Sendable {
        /// Emit the current accumulator value.
        case emit(Result)
        
        /// Skip emission, continue accumulating.
        case skip(Result)
        
        /// Emit and reset to a new value.
        case emitAndReset(emit: Result, reset: Result)
    }
    
    private let base: Base
    private let initialResult: Result
    private let reducer: @Sendable (Result, Base.Element) async throws -> EmitControl
    
    /// Creates a reducing sequence with emit control.
    public init(
        _ base: Base,
        _ initialResult: Result,
        _ reducer: @escaping @Sendable (Result, Base.Element) async throws -> EmitControl
    ) {
        self.base = base
        self.initialResult = initialResult
        self.reducer = reducer
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: base.makeAsyncIterator(),
            accumulator: initialResult,
            reducer: reducer
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private var accumulator: Result
        private let reducer: @Sendable (Result, Base.Element) async throws -> EmitControl
        
        init(
            iterator: Base.AsyncIterator,
            accumulator: Result,
            reducer: @escaping @Sendable (Result, Base.Element) async throws -> EmitControl
        ) {
            self.iterator = iterator
            self.accumulator = accumulator
            self.reducer = reducer
        }
        
        public mutating func next() async throws -> Element? {
            while let element = try await iterator.next() {
                let control = try await reducer(accumulator, element)
                
                switch control {
                case .emit(let result):
                    accumulator = result
                    return result
                    
                case .skip(let result):
                    accumulator = result
                    continue
                    
                case .emitAndReset(let emit, let reset):
                    accumulator = reset
                    return emit
                }
            }
            
            return nil
        }
    }
}

// MARK: - AsyncWindowedReduceSequence

/// Reduces elements in sliding windows.
public struct AsyncWindowedReduceSequence<Base: AsyncSequence, Result: Sendable>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Result
    
    private let base: Base
    private let windowSize: Int
    private let step: Int
    private let reducer: @Sendable ([Base.Element]) async throws -> Result
    
    /// Creates a windowed reduce sequence.
    ///
    /// - Parameters:
    ///   - base: Source sequence.
    ///   - windowSize: Size of each window.
    ///   - step: Number of elements to advance between windows.
    ///   - reducer: Function to reduce each window.
    public init(
        _ base: Base,
        windowSize: Int,
        step: Int = 1,
        reducer: @escaping @Sendable ([Base.Element]) async throws -> Result
    ) {
        precondition(windowSize > 0, "Window size must be positive")
        precondition(step > 0, "Step must be positive")
        self.base = base
        self.windowSize = windowSize
        self.step = step
        self.reducer = reducer
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: base.makeAsyncIterator(),
            windowSize: windowSize,
            step: step,
            reducer: reducer
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let windowSize: Int
        private let step: Int
        private let reducer: @Sendable ([Base.Element]) async throws -> Result
        private var buffer: [Base.Element] = []
        private var finished = false
        
        init(
            iterator: Base.AsyncIterator,
            windowSize: Int,
            step: Int,
            reducer: @escaping @Sendable ([Base.Element]) async throws -> Result
        ) {
            self.iterator = iterator
            self.windowSize = windowSize
            self.step = step
            self.reducer = reducer
        }
        
        public mutating func next() async throws -> Element? {
            // Fill buffer to window size
            while buffer.count < windowSize && !finished {
                if let element = try await iterator.next() {
                    buffer.append(element)
                } else {
                    finished = true
                }
            }
            
            // Return nil if we don't have enough for a window
            guard buffer.count >= windowSize else {
                return nil
            }
            
            // Get current window
            let window = Array(buffer.prefix(windowSize))
            let result = try await reducer(window)
            
            // Advance by step
            if step >= buffer.count {
                buffer.removeAll()
            } else {
                buffer.removeFirst(step)
            }
            
            return result
        }
    }
}

// MARK: - AsyncChunkedReduceSequence

/// Groups elements into chunks and reduces each chunk.
public struct AsyncChunkedReduceSequence<Base: AsyncSequence, Result: Sendable>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Result
    
    private let base: Base
    private let chunkSize: Int
    private let reducer: @Sendable ([Base.Element]) async throws -> Result
    
    /// Creates a chunked reduce sequence.
    ///
    /// - Parameters:
    ///   - base: Source sequence.
    ///   - chunkSize: Number of elements per chunk.
    ///   - reducer: Function to reduce each chunk.
    public init(
        _ base: Base,
        chunkSize: Int,
        reducer: @escaping @Sendable ([Base.Element]) async throws -> Result
    ) {
        precondition(chunkSize > 0, "Chunk size must be positive")
        self.base = base
        self.chunkSize = chunkSize
        self.reducer = reducer
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: base.makeAsyncIterator(),
            chunkSize: chunkSize,
            reducer: reducer
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let chunkSize: Int
        private let reducer: @Sendable ([Base.Element]) async throws -> Result
        private var finished = false
        
        init(
            iterator: Base.AsyncIterator,
            chunkSize: Int,
            reducer: @escaping @Sendable ([Base.Element]) async throws -> Result
        ) {
            self.iterator = iterator
            self.chunkSize = chunkSize
            self.reducer = reducer
        }
        
        public mutating func next() async throws -> Element? {
            guard !finished else { return nil }
            
            var chunk: [Base.Element] = []
            
            while chunk.count < chunkSize {
                if let element = try await iterator.next() {
                    chunk.append(element)
                } else {
                    finished = true
                    break
                }
            }
            
            guard !chunk.isEmpty else { return nil }
            
            return try await reducer(chunk)
        }
    }
}

// MARK: - AsyncGroupByReduceSequence

/// Groups consecutive elements by a key and reduces each group.
public struct AsyncGroupByReduceSequence<Base: AsyncSequence, Key: Equatable & Sendable, Result: Sendable>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = (key: Key, result: Result)
    
    private let base: Base
    private let keySelector: @Sendable (Base.Element) -> Key
    private let reducer: @Sendable ([Base.Element]) async throws -> Result
    
    /// Creates a group-by reduce sequence.
    ///
    /// - Parameters:
    ///   - base: Source sequence.
    ///   - keySelector: Function to extract group key.
    ///   - reducer: Function to reduce each group.
    public init(
        _ base: Base,
        keySelector: @escaping @Sendable (Base.Element) -> Key,
        reducer: @escaping @Sendable ([Base.Element]) async throws -> Result
    ) {
        self.base = base
        self.keySelector = keySelector
        self.reducer = reducer
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: base.makeAsyncIterator(),
            keySelector: keySelector,
            reducer: reducer
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let keySelector: @Sendable (Base.Element) -> Key
        private let reducer: @Sendable ([Base.Element]) async throws -> Result
        private var currentGroup: [Base.Element] = []
        private var currentKey: Key?
        private var pendingElement: Base.Element?
        private var finished = false
        
        init(
            iterator: Base.AsyncIterator,
            keySelector: @escaping @Sendable (Base.Element) -> Key,
            reducer: @escaping @Sendable ([Base.Element]) async throws -> Result
        ) {
            self.iterator = iterator
            self.keySelector = keySelector
            self.reducer = reducer
        }
        
        public mutating func next() async throws -> Element? {
            // Handle pending element from previous iteration
            if let pending = pendingElement {
                pendingElement = nil
                currentKey = keySelector(pending)
                currentGroup = [pending]
            }
            
            guard !finished else {
                // Emit final group
                if !currentGroup.isEmpty, let key = currentKey {
                    let group = currentGroup
                    currentGroup = []
                    currentKey = nil
                    return (key: key, result: try await reducer(group))
                }
                return nil
            }
            
            while let element = try await iterator.next() {
                let key = keySelector(element)
                
                if currentKey == nil {
                    currentKey = key
                    currentGroup = [element]
                } else if key == currentKey {
                    currentGroup.append(element)
                } else {
                    // Key changed, emit current group
                    let resultKey = currentKey!
                    let group = currentGroup
                    
                    pendingElement = element
                    currentGroup = []
                    currentKey = nil
                    
                    return (key: resultKey, result: try await reducer(group))
                }
            }
            
            finished = true
            
            // Emit final group
            if !currentGroup.isEmpty, let key = currentKey {
                let group = currentGroup
                currentGroup = []
                currentKey = nil
                return (key: key, result: try await reducer(group))
            }
            
            return nil
        }
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Produces running accumulations.
    ///
    /// - Parameters:
    ///   - initialResult: Initial accumulator value.
    ///   - nextPartialResult: Combining function.
    /// - Returns: Sequence of accumulated values.
    public func scan<Result: Sendable>(
        _ initialResult: Result,
        _ nextPartialResult: @escaping @Sendable (Result, Element) async throws -> Result
    ) -> AsyncScanSequence<Self, Result> {
        AsyncScanSequence(self, initialResult, nextPartialResult)
    }
    
    /// Produces running sums for numeric elements.
    public func runningSum() -> AsyncScanSequence<Self, Element>
    where Element: Numeric {
        scan(.zero) { $0 + $1 }
    }
    
    /// Produces running products for numeric elements.
    public func runningProduct() -> AsyncScanSequence<Self, Element>
    where Element: Numeric {
        scan(1 as Element) { $0 * $1 }
    }
    
    /// Reduces with emit control.
    public func reducing<Result: Sendable>(
        _ initialResult: Result,
        _ reducer: @escaping @Sendable (Result, Element) async throws -> AsyncReducingSequence<Self, Result>.EmitControl
    ) -> AsyncReducingSequence<Self, Result> {
        AsyncReducingSequence(self, initialResult, reducer)
    }
    
    /// Reduces elements in sliding windows.
    ///
    /// - Parameters:
    ///   - windowSize: Size of each window.
    ///   - step: Elements to advance between windows.
    ///   - reducer: Function to reduce each window.
    public func windowedReduce<Result: Sendable>(
        windowSize: Int,
        step: Int = 1,
        _ reducer: @escaping @Sendable ([Element]) async throws -> Result
    ) -> AsyncWindowedReduceSequence<Self, Result> {
        AsyncWindowedReduceSequence(self, windowSize: windowSize, step: step, reducer: reducer)
    }
    
    /// Computes moving average.
    public func movingAverage(windowSize: Int) -> AsyncWindowedReduceSequence<Self, Double>
    where Element: BinaryInteger {
        windowedReduce(windowSize: windowSize) { window in
            Double(window.reduce(0, +)) / Double(window.count)
        }
    }
    
    /// Computes moving average for floating-point elements.
    public func movingAverage(windowSize: Int) -> AsyncWindowedReduceSequence<Self, Element>
    where Element: FloatingPoint {
        windowedReduce(windowSize: windowSize) { window in
            window.reduce(.zero, +) / Element(window.count)
        }
    }
    
    /// Groups into chunks and reduces.
    ///
    /// - Parameters:
    ///   - chunkSize: Elements per chunk.
    ///   - reducer: Function to reduce each chunk.
    public func chunkedReduce<Result: Sendable>(
        chunkSize: Int,
        _ reducer: @escaping @Sendable ([Element]) async throws -> Result
    ) -> AsyncChunkedReduceSequence<Self, Result> {
        AsyncChunkedReduceSequence(self, chunkSize: chunkSize, reducer: reducer)
    }
    
    /// Groups consecutive elements by key and reduces.
    ///
    /// - Parameters:
    ///   - keySelector: Function to extract group key.
    ///   - reducer: Function to reduce each group.
    public func groupByReduce<Key: Equatable & Sendable, Result: Sendable>(
        by keySelector: @escaping @Sendable (Element) -> Key,
        reducer: @escaping @Sendable ([Element]) async throws -> Result
    ) -> AsyncGroupByReduceSequence<Self, Key, Result> {
        AsyncGroupByReduceSequence(self, keySelector: keySelector, reducer: reducer)
    }
    
    /// Collects elements into chunks.
    public func chunked(size: Int) -> AsyncChunkedReduceSequence<Self, [Element]> {
        chunkedReduce(chunkSize: size) { $0 }
    }
    
    /// Collects all elements into an array.
    public func collect() async throws -> [Element] {
        var result: [Element] = []
        for try await element in self {
            result.append(element)
        }
        return result
    }
    
    /// Reduces to a final value.
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (Result, Element) async throws -> Result
    ) async rethrows -> Result {
        var result = initialResult
        for try await element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }
    
    /// Reduces using a combining closure.
    public func reduce(
        _ nextPartialResult: (Element, Element) async throws -> Element
    ) async rethrows -> Element? {
        var result: Element?
        for try await element in self {
            if let current = result {
                result = try await nextPartialResult(current, element)
            } else {
                result = element
            }
        }
        return result
    }
    
    /// Sum of all elements.
    public func sum() async throws -> Element where Element: Numeric {
        try await reduce(.zero, +)
    }
    
    /// Product of all elements.
    public func product() async throws -> Element where Element: Numeric {
        try await reduce(1 as Element, *)
    }
    
    /// Minimum element.
    public func min() async throws -> Element? where Element: Comparable {
        try await reduce { Swift.min($0, $1) }
    }
    
    /// Maximum element.
    public func max() async throws -> Element? where Element: Comparable {
        try await reduce { Swift.max($0, $1) }
    }
    
    /// Count of elements.
    public func count() async throws -> Int {
        var count = 0
        for try await _ in self {
            count += 1
        }
        return count
    }
    
    /// Average of numeric elements.
    public func average() async throws -> Double where Element: BinaryInteger {
        var sum: Element = 0
        var count = 0
        for try await element in self {
            sum += element
            count += 1
        }
        return count > 0 ? Double(sum) / Double(count) : 0
    }
    
    /// Average of floating-point elements.
    public func average() async throws -> Element where Element: FloatingPoint {
        var sum: Element = 0
        var count = 0
        for try await element in self {
            sum += element
            count += 1
        }
        return count > 0 ? sum / Element(count) : 0
    }
}
