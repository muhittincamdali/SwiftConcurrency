// MappedAsyncSequence.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// An async sequence that transforms elements from its base sequence.
///
/// `MappedAsyncSequence` applies an async transform to each element,
/// producing a new sequence of transformed values.
///
/// ## Overview
///
/// Use `MappedAsyncSequence` when you need to asynchronously transform
/// elements from an async sequence.
///
/// ```swift
/// let userIds = [1, 2, 3].async
/// let users = userIds.asyncMap { id in
///     await fetchUser(id: id)
/// }
/// for await user in users {
///     print(user.name)
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Mapped Sequences
/// - ``init(base:transform:)``
/// - ``AsyncSequence/asyncMap(_:)``
public struct MappedAsyncSequence<Base: AsyncSequence, Output: Sendable>: AsyncSequence where Base: Sendable, Base.Element: Sendable {
    
    /// The type of element produced by this sequence.
    public typealias Element = Output
    
    // MARK: - Properties
    
    /// The base async sequence.
    private let base: Base
    
    /// The transform closure.
    private let transform: @Sendable (Base.Element) async throws -> Output
    
    // MARK: - Initialization
    
    /// Creates a mapped async sequence.
    ///
    /// - Parameters:
    ///   - base: The underlying async sequence.
    ///   - transform: A closure that transforms each element.
    public init(
        base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Output
    ) {
        self.base = base
        self.transform = transform
    }
    
    // MARK: - AsyncSequence
    
    /// Creates an async iterator for the mapped sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), transform: transform)
    }
    
    /// The async iterator for mapped sequences.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The base iterator.
        private var baseIterator: Base.AsyncIterator
        
        /// The transform closure.
        private let transform: @Sendable (Base.Element) async throws -> Output
        
        /// Creates a new iterator.
        init(
            base: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Output
        ) {
            self.baseIterator = base
            self.transform = transform
        }
        
        /// Returns the next transformed element.
        public mutating func next() async throws -> Output? {
            guard let element = try await baseIterator.next() else {
                return nil
            }
            return try await transform(element)
        }
    }
}

// MARK: - FlatMapped Sequence

/// An async sequence that flat maps elements into sequences.
///
/// `FlatMappedAsyncSequence` transforms each element into an async sequence,
/// then flattens all sequences into a single sequence.
public struct FlatMappedAsyncSequence<Base: AsyncSequence, SegmentOfResult: AsyncSequence>: AsyncSequence where Base: Sendable, Base.Element: Sendable, SegmentOfResult: Sendable, SegmentOfResult.Element: Sendable {
    
    /// The type of element produced by this sequence.
    public typealias Element = SegmentOfResult.Element
    
    // MARK: - Properties
    
    /// The base async sequence.
    private let base: Base
    
    /// The transform closure.
    private let transform: @Sendable (Base.Element) async throws -> SegmentOfResult
    
    // MARK: - Initialization
    
    /// Creates a flat mapped async sequence.
    ///
    /// - Parameters:
    ///   - base: The underlying async sequence.
    ///   - transform: A closure that transforms each element into a sequence.
    public init(
        base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> SegmentOfResult
    ) {
        self.base = base
        self.transform = transform
    }
    
    // MARK: - AsyncSequence
    
    /// Creates an async iterator for the sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), transform: transform)
    }
    
    /// The async iterator for flat mapped sequences.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The base iterator.
        private var baseIterator: Base.AsyncIterator
        
        /// The transform closure.
        private let transform: @Sendable (Base.Element) async throws -> SegmentOfResult
        
        /// Current segment iterator.
        private var currentSegmentIterator: SegmentOfResult.AsyncIterator?
        
        /// Creates a new iterator.
        init(
            base: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> SegmentOfResult
        ) {
            self.baseIterator = base
            self.transform = transform
        }
        
        /// Returns the next element from the flattened sequences.
        public mutating func next() async throws -> Element? {
            while true {
                // Try to get next from current segment
                if var segmentIterator = currentSegmentIterator {
                    if let element = try await segmentIterator.next() {
                        currentSegmentIterator = segmentIterator
                        return element
                    }
                    currentSegmentIterator = nil
                }
                
                // Get next segment
                guard let baseElement = try await baseIterator.next() else {
                    return nil
                }
                
                let segment = try await transform(baseElement)
                currentSegmentIterator = segment.makeAsyncIterator()
            }
        }
    }
}

// MARK: - Enumerated Sequence

/// An async sequence that yields elements paired with their indices.
public struct EnumeratedAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base: Sendable, Base.Element: Sendable {
    
    /// The type of element produced by this sequence.
    public typealias Element = (offset: Int, element: Base.Element)
    
    /// The base async sequence.
    private let base: Base
    
    /// Creates an enumerated async sequence.
    ///
    /// - Parameter base: The underlying async sequence.
    public init(base: Base) {
        self.base = base
    }
    
    /// Creates an async iterator for the sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
    
    /// The async iterator for enumerated sequences.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The base iterator.
        private var baseIterator: Base.AsyncIterator
        
        /// Current index.
        private var index: Int = 0
        
        /// Creates a new iterator.
        init(base: Base.AsyncIterator) {
            self.baseIterator = base
        }
        
        /// Returns the next enumerated element.
        public mutating func next() async throws -> (offset: Int, element: Base.Element)? {
            guard let element = try await baseIterator.next() else {
                return nil
            }
            let result = (offset: index, element: element)
            index += 1
            return result
        }
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Maps elements using an async transform.
    ///
    /// - Parameter transform: A closure that transforms each element.
    /// - Returns: An async sequence of transformed elements.
    public func asyncMap<Output: Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> Output
    ) -> MappedAsyncSequence<Self, Output> {
        MappedAsyncSequence(base: self, transform: transform)
    }
    
    /// Flat maps elements into async sequences.
    ///
    /// - Parameter transform: A closure that transforms each element into a sequence.
    /// - Returns: A flattened async sequence.
    public func asyncFlatMap<SegmentOfResult: AsyncSequence>(
        _ transform: @escaping @Sendable (Element) async throws -> SegmentOfResult
    ) -> FlatMappedAsyncSequence<Self, SegmentOfResult> where SegmentOfResult: Sendable, SegmentOfResult.Element: Sendable {
        FlatMappedAsyncSequence(base: self, transform: transform)
    }
    
    /// Enumerates elements with their indices.
    ///
    /// - Returns: An async sequence of enumerated elements.
    public func enumerated() -> EnumeratedAsyncSequence<Self> {
        EnumeratedAsyncSequence(base: self)
    }
}

// MARK: - Array to AsyncSequence

extension Array where Element: Sendable {
    
    /// Converts the array to an async sequence.
    public var async: AsyncArray<Element> {
        AsyncArray(elements: self)
    }
}

/// An async sequence backed by an array.
public struct AsyncArray<Element: Sendable>: AsyncSequence, Sendable {
    
    /// The elements.
    private let elements: [Element]
    
    /// Creates an async array.
    ///
    /// - Parameter elements: The elements to iterate.
    public init(elements: [Element]) {
        self.elements = elements
    }
    
    /// Creates an async iterator.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(elements: elements)
    }
    
    /// The async iterator for arrays.
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        /// The elements.
        private let elements: [Element]
        
        /// Current index.
        private var index: Int = 0
        
        /// Creates a new iterator.
        init(elements: [Element]) {
            self.elements = elements
        }
        
        /// Returns the next element.
        public mutating func next() async -> Element? {
            guard index < elements.count else { return nil }
            let element = elements[index]
            index += 1
            return element
        }
    }
}
