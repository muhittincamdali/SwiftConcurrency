// AsyncZip.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncZipSequence (2 sequences)

/// Zips two async sequences into a sequence of tuples.
///
/// Produces elements by pairing corresponding elements from each sequence.
/// Terminates when either sequence ends.
///
/// ```swift
/// let zipped = AsyncZipSequence(numbersStream, lettersStream)
/// for await (number, letter) in zipped {
///     print("\(number): \(letter)")
/// }
/// ```
public struct AsyncZipSequence<S1: AsyncSequence, S2: AsyncSequence>: AsyncSequence
where S1: Sendable, S2: Sendable, S1.Element: Sendable, S2.Element: Sendable {
    
    public typealias Element = (S1.Element, S2.Element)
    
    private let sequence1: S1
    private let sequence2: S2
    
    /// Creates a zipped sequence from two async sequences.
    public init(_ s1: S1, _ s2: S2) {
        self.sequence1 = s1
        self.sequence2 = s2
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator1: sequence1.makeAsyncIterator(),
            iterator2: sequence2.makeAsyncIterator()
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator1: S1.AsyncIterator
        private var iterator2: S2.AsyncIterator
        
        init(iterator1: S1.AsyncIterator, iterator2: S2.AsyncIterator) {
            self.iterator1 = iterator1
            self.iterator2 = iterator2
        }
        
        public mutating func next() async throws -> Element? {
            async let e1 = iterator1.next()
            async let e2 = iterator2.next()
            
            guard let v1 = try await e1, let v2 = try await e2 else {
                return nil
            }
            
            return (v1, v2)
        }
    }
}

// MARK: - AsyncZip3Sequence (3 sequences)

/// Zips three async sequences into a sequence of tuples.
public struct AsyncZip3Sequence<S1: AsyncSequence, S2: AsyncSequence, S3: AsyncSequence>: AsyncSequence
where S1: Sendable, S2: Sendable, S3: Sendable,
      S1.Element: Sendable, S2.Element: Sendable, S3.Element: Sendable {
    
    public typealias Element = (S1.Element, S2.Element, S3.Element)
    
    private let sequence1: S1
    private let sequence2: S2
    private let sequence3: S3
    
    /// Creates a zipped sequence from three async sequences.
    public init(_ s1: S1, _ s2: S2, _ s3: S3) {
        self.sequence1 = s1
        self.sequence2 = s2
        self.sequence3 = s3
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator1: sequence1.makeAsyncIterator(),
            iterator2: sequence2.makeAsyncIterator(),
            iterator3: sequence3.makeAsyncIterator()
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator1: S1.AsyncIterator
        private var iterator2: S2.AsyncIterator
        private var iterator3: S3.AsyncIterator
        
        init(
            iterator1: S1.AsyncIterator,
            iterator2: S2.AsyncIterator,
            iterator3: S3.AsyncIterator
        ) {
            self.iterator1 = iterator1
            self.iterator2 = iterator2
            self.iterator3 = iterator3
        }
        
        public mutating func next() async throws -> Element? {
            async let e1 = iterator1.next()
            async let e2 = iterator2.next()
            async let e3 = iterator3.next()
            
            guard let v1 = try await e1,
                  let v2 = try await e2,
                  let v3 = try await e3 else {
                return nil
            }
            
            return (v1, v2, v3)
        }
    }
}

// MARK: - AsyncZip4Sequence (4 sequences)

/// Zips four async sequences into a sequence of tuples.
public struct AsyncZip4Sequence<
    S1: AsyncSequence,
    S2: AsyncSequence,
    S3: AsyncSequence,
    S4: AsyncSequence
>: AsyncSequence
where S1: Sendable, S2: Sendable, S3: Sendable, S4: Sendable,
      S1.Element: Sendable, S2.Element: Sendable, S3.Element: Sendable, S4.Element: Sendable {
    
    public typealias Element = (S1.Element, S2.Element, S3.Element, S4.Element)
    
    private let sequence1: S1
    private let sequence2: S2
    private let sequence3: S3
    private let sequence4: S4
    
    /// Creates a zipped sequence from four async sequences.
    public init(_ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4) {
        self.sequence1 = s1
        self.sequence2 = s2
        self.sequence3 = s3
        self.sequence4 = s4
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator1: sequence1.makeAsyncIterator(),
            iterator2: sequence2.makeAsyncIterator(),
            iterator3: sequence3.makeAsyncIterator(),
            iterator4: sequence4.makeAsyncIterator()
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator1: S1.AsyncIterator
        private var iterator2: S2.AsyncIterator
        private var iterator3: S3.AsyncIterator
        private var iterator4: S4.AsyncIterator
        
        init(
            iterator1: S1.AsyncIterator,
            iterator2: S2.AsyncIterator,
            iterator3: S3.AsyncIterator,
            iterator4: S4.AsyncIterator
        ) {
            self.iterator1 = iterator1
            self.iterator2 = iterator2
            self.iterator3 = iterator3
            self.iterator4 = iterator4
        }
        
        public mutating func next() async throws -> Element? {
            async let e1 = iterator1.next()
            async let e2 = iterator2.next()
            async let e3 = iterator3.next()
            async let e4 = iterator4.next()
            
            guard let v1 = try await e1,
                  let v2 = try await e2,
                  let v3 = try await e3,
                  let v4 = try await e4 else {
                return nil
            }
            
            return (v1, v2, v3, v4)
        }
    }
}

// MARK: - AsyncZipLongestSequence

/// Zips two async sequences, continuing until both end.
///
/// Uses optional values when one sequence ends before the other.
public struct AsyncZipLongestSequence<S1: AsyncSequence, S2: AsyncSequence>: AsyncSequence
where S1: Sendable, S2: Sendable, S1.Element: Sendable, S2.Element: Sendable {
    
    public typealias Element = (S1.Element?, S2.Element?)
    
    private let sequence1: S1
    private let sequence2: S2
    
    /// Creates a zip-longest sequence.
    public init(_ s1: S1, _ s2: S2) {
        self.sequence1 = s1
        self.sequence2 = s2
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator1: sequence1.makeAsyncIterator(),
            iterator2: sequence2.makeAsyncIterator()
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator1: S1.AsyncIterator
        private var iterator2: S2.AsyncIterator
        private var finished1 = false
        private var finished2 = false
        
        init(iterator1: S1.AsyncIterator, iterator2: S2.AsyncIterator) {
            self.iterator1 = iterator1
            self.iterator2 = iterator2
        }
        
        public mutating func next() async throws -> Element? {
            if finished1 && finished2 {
                return nil
            }
            
            var v1: S1.Element?
            var v2: S2.Element?
            
            if !finished1 {
                v1 = try await iterator1.next()
                if v1 == nil { finished1 = true }
            }
            
            if !finished2 {
                v2 = try await iterator2.next()
                if v2 == nil { finished2 = true }
            }
            
            if v1 == nil && v2 == nil {
                return nil
            }
            
            return (v1, v2)
        }
    }
}

// MARK: - AsyncZipWithIndexSequence

/// Zips an async sequence with its indices.
public struct AsyncZipWithIndexSequence<Base: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = (index: Int, element: Base.Element)
    
    private let base: Base
    private let startIndex: Int
    
    /// Creates an indexed sequence.
    ///
    /// - Parameters:
    ///   - base: The base sequence.
    ///   - startIndex: Starting index. Defaults to 0.
    public init(_ base: Base, startIndex: Int = 0) {
        self.base = base
        self.startIndex = startIndex
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator(), currentIndex: startIndex)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private var currentIndex: Int
        
        init(iterator: Base.AsyncIterator, currentIndex: Int) {
            self.iterator = iterator
            self.currentIndex = currentIndex
        }
        
        public mutating func next() async throws -> Element? {
            guard let element = try await iterator.next() else {
                return nil
            }
            
            let result = (index: currentIndex, element: element)
            currentIndex += 1
            return result
        }
    }
}

// MARK: - AsyncZipWithPreviousSequence

/// Zips each element with its previous element.
public struct AsyncZipWithPreviousSequence<Base: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = (previous: Base.Element?, current: Base.Element)
    
    private let base: Base
    
    /// Creates a sequence that pairs elements with their predecessors.
    public init(_ base: Base) {
        self.base = base
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private var previous: Base.Element?
        
        init(iterator: Base.AsyncIterator) {
            self.iterator = iterator
        }
        
        public mutating func next() async throws -> Element? {
            guard let current = try await iterator.next() else {
                return nil
            }
            
            let result = (previous: previous, current: current)
            previous = current
            return result
        }
    }
}

// MARK: - AsyncZipWithNextSequence

/// Zips each element with its next element.
public struct AsyncZipWithNextSequence<Base: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = (current: Base.Element, next: Base.Element?)
    
    private let base: Base
    
    /// Creates a sequence that pairs elements with their successors.
    public init(_ base: Base) {
        self.base = base
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private var current: Base.Element?
        private var started = false
        
        init(iterator: Base.AsyncIterator) {
            self.iterator = iterator
        }
        
        public mutating func next() async throws -> Element? {
            if !started {
                current = try await iterator.next()
                started = true
            }
            
            guard let curr = current else {
                return nil
            }
            
            let next = try await iterator.next()
            current = next
            
            return (current: curr, next: next)
        }
    }
}

// MARK: - AsyncInterleavedSequence

/// Interleaves elements from two async sequences.
///
/// Alternates between sequences, producing one element from each in turn.
public struct AsyncInterleavedSequence<S1: AsyncSequence, S2: AsyncSequence>: AsyncSequence
where S1: Sendable, S2: Sendable, S1.Element == S2.Element, S1.Element: Sendable {
    
    public typealias Element = S1.Element
    
    private let sequence1: S1
    private let sequence2: S2
    
    /// Creates an interleaved sequence.
    public init(_ s1: S1, _ s2: S2) {
        self.sequence1 = s1
        self.sequence2 = s2
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator1: sequence1.makeAsyncIterator(),
            iterator2: sequence2.makeAsyncIterator()
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator1: S1.AsyncIterator
        private var iterator2: S2.AsyncIterator
        private var useFirst = true
        private var finished1 = false
        private var finished2 = false
        
        init(iterator1: S1.AsyncIterator, iterator2: S2.AsyncIterator) {
            self.iterator1 = iterator1
            self.iterator2 = iterator2
        }
        
        public mutating func next() async throws -> Element? {
            while !finished1 || !finished2 {
                if useFirst && !finished1 {
                    if let element = try await iterator1.next() {
                        useFirst = false
                        return element
                    } else {
                        finished1 = true
                    }
                }
                
                if !useFirst && !finished2 {
                    if let element = try await iterator2.next() {
                        useFirst = true
                        return element
                    } else {
                        finished2 = true
                    }
                }
                
                // If current source finished, try the other
                useFirst = !useFirst
            }
            
            return nil
        }
    }
}

// MARK: - AsyncRoundRobinSequence

/// Round-robin iteration over multiple async sequences.
public struct AsyncRoundRobinSequence<Element: Sendable>: AsyncSequence, Sendable {
    
    private let sources: [AnySendableAsyncSequence<Element>]
    
    /// Creates a round-robin sequence from multiple sources.
    public init<S: AsyncSequence & Sendable>(_ sequences: [S]) where S.Element == Element {
        self.sources = sequences.map { AnySendableAsyncSequence($0) }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterators: sources.map { $0.makeAsyncIterator() })
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterators: [AnySendableAsyncSequence<Element>.AnyAsyncIterator]
        private var currentIndex = 0
        private var exhausted: Set<Int> = []
        
        init(iterators: [AnySendableAsyncSequence<Element>.AnyAsyncIterator]) {
            self.iterators = iterators
        }
        
        public mutating func next() async -> Element? {
            guard !iterators.isEmpty else { return nil }
            
            let startIndex = currentIndex
            
            repeat {
                if !exhausted.contains(currentIndex) {
                    if let element = await iterators[currentIndex].next() {
                        let index = currentIndex
                        currentIndex = (currentIndex + 1) % iterators.count
                        return element
                    } else {
                        exhausted.insert(currentIndex)
                    }
                }
                
                currentIndex = (currentIndex + 1) % iterators.count
            } while currentIndex != startIndex
            
            // One more check in case we started on an exhausted index
            for i in 0..<iterators.count where !exhausted.contains(i) {
                if let element = await iterators[i].next() {
                    return element
                }
            }
            
            return nil
        }
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Zips this sequence with another.
    ///
    /// - Parameter other: The other sequence to zip with.
    /// - Returns: A sequence of tuples.
    public func zip<S: AsyncSequence & Sendable>(
        with other: S
    ) -> AsyncZipSequence<Self, S> where S.Element: Sendable {
        AsyncZipSequence(self, other)
    }
    
    /// Zips this sequence with two others.
    public func zip<S2: AsyncSequence & Sendable, S3: AsyncSequence & Sendable>(
        _ s2: S2, _ s3: S3
    ) -> AsyncZip3Sequence<Self, S2, S3>
    where S2.Element: Sendable, S3.Element: Sendable {
        AsyncZip3Sequence(self, s2, s3)
    }
    
    /// Zips this sequence with three others.
    public func zip<
        S2: AsyncSequence & Sendable,
        S3: AsyncSequence & Sendable,
        S4: AsyncSequence & Sendable
    >(
        _ s2: S2, _ s3: S3, _ s4: S4
    ) -> AsyncZip4Sequence<Self, S2, S3, S4>
    where S2.Element: Sendable, S3.Element: Sendable, S4.Element: Sendable {
        AsyncZip4Sequence(self, s2, s3, s4)
    }
    
    /// Zips with another sequence, continuing until both end.
    public func zipLongest<S: AsyncSequence & Sendable>(
        with other: S
    ) -> AsyncZipLongestSequence<Self, S> where S.Element: Sendable {
        AsyncZipLongestSequence(self, other)
    }
    
    /// Zips with indices.
    ///
    /// - Parameter startIndex: Starting index. Defaults to 0.
    /// - Returns: A sequence of (index, element) tuples.
    public func enumerated(from startIndex: Int = 0) -> AsyncZipWithIndexSequence<Self> {
        AsyncZipWithIndexSequence(self, startIndex: startIndex)
    }
    
    /// Pairs each element with its predecessor.
    public func withPrevious() -> AsyncZipWithPreviousSequence<Self> {
        AsyncZipWithPreviousSequence(self)
    }
    
    /// Pairs each element with its successor.
    public func withNext() -> AsyncZipWithNextSequence<Self> {
        AsyncZipWithNextSequence(self)
    }
    
    /// Interleaves with another sequence of the same element type.
    public func interleaved<S: AsyncSequence & Sendable>(
        with other: S
    ) -> AsyncInterleavedSequence<Self, S> where S.Element == Element {
        AsyncInterleavedSequence(self, other)
    }
}

// MARK: - Free Functions

/// Zips two async sequences.
public func zip<S1: AsyncSequence & Sendable, S2: AsyncSequence & Sendable>(
    _ s1: S1, _ s2: S2
) -> AsyncZipSequence<S1, S2>
where S1.Element: Sendable, S2.Element: Sendable {
    AsyncZipSequence(s1, s2)
}

/// Zips three async sequences.
public func zip<
    S1: AsyncSequence & Sendable,
    S2: AsyncSequence & Sendable,
    S3: AsyncSequence & Sendable
>(
    _ s1: S1, _ s2: S2, _ s3: S3
) -> AsyncZip3Sequence<S1, S2, S3>
where S1.Element: Sendable, S2.Element: Sendable, S3.Element: Sendable {
    AsyncZip3Sequence(s1, s2, s3)
}

/// Zips four async sequences.
public func zip<
    S1: AsyncSequence & Sendable,
    S2: AsyncSequence & Sendable,
    S3: AsyncSequence & Sendable,
    S4: AsyncSequence & Sendable
>(
    _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4
) -> AsyncZip4Sequence<S1, S2, S3, S4>
where S1.Element: Sendable, S2.Element: Sendable, S3.Element: Sendable, S4.Element: Sendable {
    AsyncZip4Sequence(s1, s2, s3, s4)
}
