// FilteredAsyncSequence.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// An async sequence that filters elements from its base sequence.
///
/// `FilteredAsyncSequence` applies a predicate to each element,
/// only yielding elements that satisfy the condition.
///
/// ## Overview
///
/// Use `FilteredAsyncSequence` to remove unwanted elements from an
/// async sequence based on a condition.
///
/// ```swift
/// let numbers = someAsyncSequence.asyncFilter { $0 > 10 }
/// for await number in numbers {
///     // Only numbers greater than 10
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Filtered Sequences
/// - ``init(base:predicate:)``
/// - ``AsyncSequence/asyncFilter(_:)``
public struct FilteredAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base: Sendable, Base.Element: Sendable {
    
    /// The type of element produced by this sequence.
    public typealias Element = Base.Element
    
    // MARK: - Properties
    
    /// The base async sequence.
    private let base: Base
    
    /// The filter predicate.
    private let predicate: @Sendable (Base.Element) async throws -> Bool
    
    // MARK: - Initialization
    
    /// Creates a filtered async sequence.
    ///
    /// - Parameters:
    ///   - base: The underlying async sequence.
    ///   - predicate: A closure that returns `true` for elements to include.
    public init(
        base: Base,
        predicate: @escaping @Sendable (Base.Element) async throws -> Bool
    ) {
        self.base = base
        self.predicate = predicate
    }
    
    // MARK: - AsyncSequence
    
    /// Creates an async iterator for the filtered sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), predicate: predicate)
    }
    
    /// The async iterator for filtered sequences.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The base iterator.
        private var baseIterator: Base.AsyncIterator
        
        /// The filter predicate.
        private let predicate: @Sendable (Base.Element) async throws -> Bool
        
        /// Creates a new iterator.
        init(
            base: Base.AsyncIterator,
            predicate: @escaping @Sendable (Base.Element) async throws -> Bool
        ) {
            self.baseIterator = base
            self.predicate = predicate
        }
        
        /// Returns the next element that satisfies the predicate.
        public mutating func next() async throws -> Base.Element? {
            while let element = try await baseIterator.next() {
                if try await predicate(element) {
                    return element
                }
            }
            return nil
        }
    }
}

// MARK: - Compact Filter

/// An async sequence that filters out nil values and unwraps results.
///
/// `CompactFilteredAsyncSequence` applies a transform that may return nil,
/// filtering out nil results and unwrapping the non-nil values.
public struct CompactFilteredAsyncSequence<Base: AsyncSequence, Output: Sendable>: AsyncSequence where Base: Sendable, Base.Element: Sendable {
    
    /// The type of element produced by this sequence.
    public typealias Element = Output
    
    // MARK: - Properties
    
    /// The base async sequence.
    private let base: Base
    
    /// The transform closure.
    private let transform: @Sendable (Base.Element) async throws -> Output?
    
    // MARK: - Initialization
    
    /// Creates a compact filtered async sequence.
    ///
    /// - Parameters:
    ///   - base: The underlying async sequence.
    ///   - transform: A closure that transforms and optionally filters elements.
    public init(
        base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Output?
    ) {
        self.base = base
        self.transform = transform
    }
    
    // MARK: - AsyncSequence
    
    /// Creates an async iterator for the sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), transform: transform)
    }
    
    /// The async iterator for compact filtered sequences.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The base iterator.
        private var baseIterator: Base.AsyncIterator
        
        /// The transform closure.
        private let transform: @Sendable (Base.Element) async throws -> Output?
        
        /// Creates a new iterator.
        init(
            base: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Output?
        ) {
            self.baseIterator = base
            self.transform = transform
        }
        
        /// Returns the next non-nil transformed element.
        public mutating func next() async throws -> Output? {
            while let element = try await baseIterator.next() {
                if let transformed = try await transform(element) {
                    return transformed
                }
            }
            return nil
        }
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Filters elements based on an async predicate.
    ///
    /// - Parameter predicate: A closure that returns `true` for elements to keep.
    /// - Returns: An async sequence of filtered elements.
    public func asyncFilter(
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) -> FilteredAsyncSequence<Self> {
        FilteredAsyncSequence(base: self, predicate: predicate)
    }
    
    /// Filters elements based on a synchronous predicate.
    ///
    /// - Parameter predicate: A closure that returns `true` for elements to keep.
    /// - Returns: An async sequence of filtered elements.
    public func asyncFilter(
        _ predicate: @escaping @Sendable (Element) -> Bool
    ) -> FilteredAsyncSequence<Self> {
        FilteredAsyncSequence(base: self) { element in
            predicate(element)
        }
    }
    
    /// Compact maps elements, filtering out nil results.
    ///
    /// - Parameter transform: A closure that transforms elements.
    /// - Returns: An async sequence of non-nil transformed elements.
    public func asyncCompactMap<Output: Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> Output?
    ) -> CompactFilteredAsyncSequence<Self, Output> {
        CompactFilteredAsyncSequence(base: self, transform: transform)
    }
}

// MARK: - Unique Filter

/// An async sequence that filters out duplicate elements.
public struct UniqueAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base: Sendable, Base.Element: Sendable & Hashable {
    
    /// The type of element produced by this sequence.
    public typealias Element = Base.Element
    
    /// The base async sequence.
    private let base: Base
    
    /// Creates a unique async sequence.
    ///
    /// - Parameter base: The underlying async sequence.
    public init(base: Base) {
        self.base = base
    }
    
    /// Creates an async iterator for the sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
    
    /// The async iterator for unique sequences.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The base iterator.
        private var baseIterator: Base.AsyncIterator
        
        /// Set of seen elements.
        private var seen: Set<Base.Element> = []
        
        /// Creates a new iterator.
        init(base: Base.AsyncIterator) {
            self.baseIterator = base
        }
        
        /// Returns the next unique element.
        public mutating func next() async throws -> Base.Element? {
            while let element = try await baseIterator.next() {
                if !seen.contains(element) {
                    seen.insert(element)
                    return element
                }
            }
            return nil
        }
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable & Hashable {
    
    /// Filters out duplicate elements.
    ///
    /// - Returns: An async sequence with unique elements.
    public func unique() -> UniqueAsyncSequence<Self> {
        UniqueAsyncSequence(base: self)
    }
}
