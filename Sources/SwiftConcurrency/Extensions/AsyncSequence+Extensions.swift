// AsyncSequence+Extensions.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - Collection Operations

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Collects all elements into an array.
    ///
    /// ```swift
    /// let items = try await stream.collect()
    /// ```
    ///
    /// - Returns: Array containing all elements.
    /// - Throws: Any error from the sequence.
    public func collect() async throws -> [Element] {
        var elements: [Element] = []
        for try await element in self {
            elements.append(element)
        }
        return elements
    }
    
    /// Collects up to a maximum number of elements.
    ///
    /// - Parameter maxCount: Maximum elements to collect.
    /// - Returns: Array of collected elements.
    /// - Throws: Any error from the sequence.
    public func collect(max maxCount: Int) async throws -> [Element] {
        var elements: [Element] = []
        let capacity = Swift.min(maxCount, 1000)
        elements.reserveCapacity(capacity)
        
        var count = 0
        for try await element in self {
            elements.append(element)
            count += 1
            if count >= maxCount {
                break
            }
        }
        return elements
    }
    
    /// Returns the first element or nil.
    ///
    /// - Returns: The first element, or `nil` if empty.
    /// - Throws: Any error from the sequence.
    public func first() async throws -> Element? {
        var iterator = makeAsyncIterator()
        return try await iterator.next()
    }
    
    /// Returns the last element.
    ///
    /// - Warning: Consumes the entire sequence.
    /// - Returns: The last element, or `nil` if empty.
    /// - Throws: Any error from the sequence.
    public func last() async throws -> Element? {
        var lastElement: Element?
        for try await element in self {
            lastElement = element
        }
        return lastElement
    }
    
    /// Counts the number of elements.
    ///
    /// - Warning: Consumes the entire sequence.
    /// - Returns: The element count.
    /// - Throws: Any error from the sequence.
    public func count() async throws -> Int {
        var count = 0
        for try await _ in self {
            count += 1
        }
        return count
    }
    
    /// Checks if the sequence is empty.
    ///
    /// - Returns: `true` if no elements.
    /// - Throws: Any error from the sequence.
    public func isEmpty() async throws -> Bool {
        var iterator = makeAsyncIterator()
        return try await iterator.next() == nil
    }
}

// MARK: - Reduction Operations

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Reduces elements into a single value.
    ///
    /// ```swift
    /// let sum = try await numbers.asyncReduce(0, +)
    /// ```
    ///
    /// - Parameters:
    ///   - initialResult: The initial accumulator value.
    ///   - nextPartialResult: Combines accumulator with next element.
    /// - Returns: The final accumulated value.
    /// - Throws: Any error from the sequence or closure.
    public func asyncReduce<Result: Sendable>(
        _ initialResult: Result,
        _ nextPartialResult: @Sendable (Result, Element) async throws -> Result
    ) async throws -> Result {
        var result = initialResult
        for try await element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }
}

// MARK: - Predicate Operations

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Checks if all elements satisfy a predicate.
    ///
    /// - Parameter predicate: The condition to check.
    /// - Returns: `true` if all elements satisfy the predicate.
    /// - Throws: Any error from the sequence or predicate.
    public func allSatisfy(
        _ predicate: @Sendable (Element) async throws -> Bool
    ) async throws -> Bool {
        for try await element in self {
            if try await !predicate(element) {
                return false
            }
        }
        return true
    }
    
    /// Checks if any element satisfies a predicate.
    ///
    /// - Parameter predicate: The condition to check.
    /// - Returns: `true` if any element satisfies the predicate.
    /// - Throws: Any error from the sequence or predicate.
    public func anySatisfy(
        _ predicate: @Sendable (Element) async throws -> Bool
    ) async throws -> Bool {
        for try await element in self {
            if try await predicate(element) {
                return true
            }
        }
        return false
    }
    
    /// Checks if no elements satisfy a predicate.
    ///
    /// - Parameter predicate: The condition to check.
    /// - Returns: `true` if no elements satisfy the predicate.
    /// - Throws: Any error from the sequence or predicate.
    public func noneSatisfy(
        _ predicate: @Sendable (Element) async throws -> Bool
    ) async throws -> Bool {
        try await !anySatisfy(predicate)
    }
}

// MARK: - Find Operations

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Finds the first element satisfying a predicate.
    ///
    /// - Parameter predicate: The condition to match.
    /// - Returns: The first matching element, or `nil`.
    /// - Throws: Any error from the sequence or predicate.
    public func first(
        where predicate: @Sendable (Element) async throws -> Bool
    ) async throws -> Element? {
        for try await element in self {
            if try await predicate(element) {
                return element
            }
        }
        return nil
    }
    
    /// Finds the last element satisfying a predicate.
    ///
    /// - Warning: Consumes the entire sequence.
    /// - Parameter predicate: The condition to match.
    /// - Returns: The last matching element, or `nil`.
    /// - Throws: Any error from the sequence or predicate.
    public func last(
        where predicate: @Sendable (Element) async throws -> Bool
    ) async throws -> Element? {
        var lastMatch: Element?
        for try await element in self {
            if try await predicate(element) {
                lastMatch = element
            }
        }
        return lastMatch
    }
}

// MARK: - Grouping Operations

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Groups elements by a key.
    ///
    /// ```swift
    /// let grouped = try await users.grouped(by: \.department)
    /// ```
    ///
    /// - Parameter keyPath: Key path to group by.
    /// - Returns: Dictionary mapping keys to element arrays.
    /// - Throws: Any error from the sequence.
    public func grouped<Key: Hashable & Sendable>(
        by keyPath: KeyPath<Element, Key>
    ) async throws -> [Key: [Element]] {
        var groups: [Key: [Element]] = [:]
        for try await element in self {
            let key = element[keyPath: keyPath]
            groups[key, default: []].append(element)
        }
        return groups
    }
    
    /// Groups elements by a key function.
    ///
    /// - Parameter keySelector: Function returning the key for each element.
    /// - Returns: Dictionary mapping keys to element arrays.
    /// - Throws: Any error from the sequence or key selector.
    public func grouped<Key: Hashable & Sendable>(
        by keySelector: @Sendable (Element) async throws -> Key
    ) async throws -> [Key: [Element]] {
        var groups: [Key: [Element]] = [:]
        for try await element in self {
            let key = try await keySelector(element)
            groups[key, default: []].append(element)
        }
        return groups
    }
}

// MARK: - Skip and Take

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Skips the first n elements.
    ///
    /// - Parameter count: Number of elements to skip.
    /// - Returns: Sequence without the first n elements.
    public func skip(_ count: Int) -> SkipAsyncSequence<Self> {
        SkipAsyncSequence(base: self, count: count)
    }
    
    /// Takes only the first n elements.
    ///
    /// - Parameter count: Maximum elements to take.
    /// - Returns: Sequence with at most n elements.
    public func take(_ count: Int) -> TakeAsyncSequence<Self> {
        TakeAsyncSequence(base: self, count: count)
    }
}

/// An async sequence that skips elements.
public struct SkipAsyncSequence<Base: AsyncSequence & Sendable>: AsyncSequence, Sendable where Base.Element: Sendable {
    public typealias Element = Base.Element
    
    private let base: Base
    private let count: Int
    
    init(base: Base, count: Int) {
        self.base = base
        self.count = count
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), count: count)
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private var remainingToSkip: Int
        
        init(base: Base.AsyncIterator, count: Int) {
            self.baseIterator = base
            self.remainingToSkip = count
        }
        
        public mutating func next() async throws -> Element? {
            while remainingToSkip > 0 {
                guard try await baseIterator.next() != nil else { return nil }
                remainingToSkip -= 1
            }
            return try await baseIterator.next()
        }
    }
}

/// An async sequence that takes a limited number of elements.
public struct TakeAsyncSequence<Base: AsyncSequence & Sendable>: AsyncSequence, Sendable where Base.Element: Sendable {
    public typealias Element = Base.Element
    
    private let base: Base
    private let count: Int
    
    init(base: Base, count: Int) {
        self.base = base
        self.count = count
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), count: count)
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private var remainingToTake: Int
        
        init(base: Base.AsyncIterator, count: Int) {
            self.baseIterator = base
            self.remainingToTake = count
        }
        
        public mutating func next() async throws -> Element? {
            guard remainingToTake > 0 else { return nil }
            remainingToTake -= 1
            return try await baseIterator.next()
        }
    }
}

// MARK: - ForEach

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Performs an action for each element.
    ///
    /// - Parameter body: The action to perform.
    /// - Throws: Any error from the sequence or body.
    public func asyncForEach(
        _ body: @Sendable (Element) async throws -> Void
    ) async throws {
        for try await element in self {
            try await body(element)
        }
    }
}
