// AsyncFlatMap.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncFlatMapSequence

/// Transforms each element into an async sequence and flattens the results.
///
/// Elements from transformed sequences are emitted sequentially.
///
/// ```swift
/// let users = AsyncStream { ... }
/// let allPosts = users.flatMap { user in
///     fetchPosts(for: user.id)
/// }
/// for await post in allPosts {
///     print(post)
/// }
/// ```
public struct AsyncFlatMapSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed
    
    /// Creates a flat map sequence.
    public init(
        _ base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Transformed
    ) {
        self.base = base
        self.transform = transform
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator(), transform: transform)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private var currentIterator: Transformed.AsyncIterator?
        private let transform: @Sendable (Base.Element) async throws -> Transformed
        
        init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            self.baseIterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async throws -> Element? {
            while true {
                // Try current inner sequence
                if var current = currentIterator {
                    if let element = try await current.next() {
                        currentIterator = current
                        return element
                    }
                    currentIterator = nil
                }
                
                // Get next base element and transform
                guard let baseElement = try await baseIterator.next() else {
                    return nil
                }
                
                let transformed = try await transform(baseElement)
                currentIterator = transformed.makeAsyncIterator()
            }
        }
    }
}

// MARK: - AsyncCompactMapSequence

/// Transforms and filters out nil results.
public struct AsyncCompactMapSequence<Base: AsyncSequence, Transformed: Sendable>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Transformed
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed?
    
    /// Creates a compact map sequence.
    public init(
        _ base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Transformed?
    ) {
        self.base = base
        self.transform = transform
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator(), transform: transform)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private let transform: @Sendable (Base.Element) async throws -> Transformed?
        
        init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed?
        ) {
            self.baseIterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async throws -> Element? {
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
    
    /// Transforms each element into a sequence and flattens.
    ///
    /// - Parameter transform: Transform function.
    /// - Returns: Flattened sequence.
    public func flatMap<T: AsyncSequence>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) -> AsyncFlatMapSequence<Self, T> where T: Sendable, T.Element: Sendable {
        AsyncFlatMapSequence(self, transform: transform)
    }
    
    /// Transforms and filters out nil results.
    ///
    /// - Parameter transform: Transform function.
    /// - Returns: Compact mapped sequence.
    public func compactMap<T: Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> T?
    ) -> AsyncCompactMapSequence<Self, T> {
        AsyncCompactMapSequence(self, transform: transform)
    }
}
