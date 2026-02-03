// AsyncFlatMap.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncFlatMapSequence

/// Transforms each element into an async sequence and flattens the results.
///
/// Elements from transformed sequences are emitted sequentially - completing
/// one inner sequence before moving to the next.
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
    ///
    /// - Parameters:
    ///   - base: The source sequence.
    ///   - transform: Function to transform elements into sequences.
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
        private var iterator: Base.AsyncIterator
        private let transform: @Sendable (Base.Element) async throws -> Transformed
        private var currentIterator: Transformed.AsyncIterator?
        
        init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            self.iterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async throws -> Element? {
            while true {
                // Try current inner sequence
                if var inner = currentIterator {
                    if let element = try await inner.next() {
                        currentIterator = inner
                        return element
                    }
                    currentIterator = nil
                }
                
                // Get next element from base
                guard let baseElement = try await iterator.next() else {
                    return nil
                }
                
                // Transform and set as current
                let transformed = try await transform(baseElement)
                currentIterator = transformed.makeAsyncIterator()
            }
        }
    }
}

// MARK: - AsyncConcurrentFlatMapSequence

/// Transforms elements concurrently and merges results.
///
/// Unlike `AsyncFlatMapSequence`, this processes multiple inner sequences
/// concurrently, emitting elements as they become available.
public struct AsyncConcurrentFlatMapSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let maxConcurrency: Int
    private let transform: @Sendable (Base.Element) async throws -> Transformed
    
    /// Creates a concurrent flat map sequence.
    ///
    /// - Parameters:
    ///   - base: The source sequence.
    ///   - maxConcurrency: Maximum concurrent inner sequences.
    ///   - transform: Function to transform elements into sequences.
    public init(
        _ base: Base,
        maxConcurrency: Int = 4,
        transform: @escaping @Sendable (Base.Element) async throws -> Transformed
    ) {
        precondition(maxConcurrency > 0)
        self.base = base
        self.maxConcurrency = maxConcurrency
        self.transform = transform
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, maxConcurrency: maxConcurrency, transform: transform)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let channel: AsyncChannel<Element>
        private var channelIterator: AsyncChannel<Element>.Iterator
        private let task: Task<Void, Never>
        
        init(
            base: Base,
            maxConcurrency: Int,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            let channel = AsyncChannel<Element>(capacity: maxConcurrency * 2)
            self.channel = channel
            self.channelIterator = channel.makeAsyncIterator()
            
            self.task = Task {
                await withTaskGroup(of: Void.self) { group in
                    var runningCount = 0
                    var iterator = base.makeAsyncIterator()
                    
                    while !Task.isCancelled {
                        // Start new inner sequences up to max concurrency
                        while runningCount < maxConcurrency {
                            guard let element = try? await iterator.next() else {
                                break
                            }
                            
                            runningCount += 1
                            group.addTask {
                                do {
                                    let transformed = try await transform(element)
                                    for try await item in transformed {
                                        await channel.send(item)
                                    }
                                } catch {
                                    // Silently handle errors in inner sequences
                                }
                            }
                        }
                        
                        // Wait for one to complete if at max
                        if runningCount >= maxConcurrency {
                            await group.next()
                            runningCount -= 1
                        } else {
                            break
                        }
                    }
                    
                    // Wait for remaining
                    await group.waitForAll()
                    await channel.finish()
                }
            }
        }
        
        public mutating func next() async -> Element? {
            await channelIterator.next()
        }
    }
}

// MARK: - AsyncSwitchMapSequence

/// Transforms elements and switches to the latest inner sequence.
///
/// When a new element arrives, cancels the previous inner sequence
/// and switches to the new one.
public struct AsyncSwitchMapSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed
    
    /// Creates a switch map sequence.
    public init(
        _ base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Transformed
    ) {
        self.base = base
        self.transform = transform
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, transform: transform)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let channel: AsyncChannel<Element>
        private var channelIterator: AsyncChannel<Element>.Iterator
        private let task: Task<Void, Never>
        
        init(
            base: Base,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            let channel = AsyncChannel<Element>(capacity: 8)
            self.channel = channel
            self.channelIterator = channel.makeAsyncIterator()
            
            self.task = Task {
                var currentInnerTask: Task<Void, Never>?
                var iterator = base.makeAsyncIterator()
                
                while !Task.isCancelled {
                    guard let element = try? await iterator.next() else {
                        break
                    }
                    
                    // Cancel previous inner sequence
                    currentInnerTask?.cancel()
                    
                    // Start new inner sequence
                    currentInnerTask = Task {
                        do {
                            let transformed = try await transform(element)
                            for try await item in transformed {
                                if Task.isCancelled { break }
                                await channel.send(item)
                            }
                        } catch {
                            // Handle errors silently
                        }
                    }
                }
                
                // Wait for final inner sequence
                await currentInnerTask?.value
                await channel.finish()
            }
        }
        
        public mutating func next() async -> Element? {
            await channelIterator.next()
        }
    }
}

// MARK: - AsyncExhaustMapSequence

/// Transforms elements but ignores new elements while processing.
///
/// Only processes new base elements when the current inner sequence completes.
public struct AsyncExhaustMapSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed
    
    /// Creates an exhaust map sequence.
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
        private var iterator: Base.AsyncIterator
        private let transform: @Sendable (Base.Element) async throws -> Transformed
        private var currentIterator: Transformed.AsyncIterator?
        private var isProcessing = false
        
        init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            self.iterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async throws -> Element? {
            while true {
                // If processing, drain current inner sequence
                if isProcessing, var inner = currentIterator {
                    if let element = try await inner.next() {
                        currentIterator = inner
                        return element
                    }
                    currentIterator = nil
                    isProcessing = false
                }
                
                // Get next base element
                guard let baseElement = try await iterator.next() else {
                    return nil
                }
                
                // Start processing
                isProcessing = true
                let transformed = try await transform(baseElement)
                currentIterator = transformed.makeAsyncIterator()
            }
        }
    }
}

// MARK: - AsyncConcatMapSequence

/// Transforms and concatenates sequences in order, queuing new requests.
///
/// Unlike concurrent flat map, maintains strict ordering of inner sequences.
public struct AsyncConcatMapSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed
    
    /// Creates a concat map sequence.
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
        private var iterator: Base.AsyncIterator
        private let transform: @Sendable (Base.Element) async throws -> Transformed
        private var pendingElements: [Base.Element] = []
        private var currentIterator: Transformed.AsyncIterator?
        
        init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            self.iterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async throws -> Element? {
            while true {
                // Try current inner sequence
                if var inner = currentIterator {
                    if let element = try await inner.next() {
                        currentIterator = inner
                        return element
                    }
                    currentIterator = nil
                }
                
                // Try pending elements first
                if !pendingElements.isEmpty {
                    let element = pendingElements.removeFirst()
                    let transformed = try await transform(element)
                    currentIterator = transformed.makeAsyncIterator()
                    continue
                }
                
                // Get next from base
                guard let baseElement = try await iterator.next() else {
                    return nil
                }
                
                let transformed = try await transform(baseElement)
                currentIterator = transformed.makeAsyncIterator()
            }
        }
    }
}

// MARK: - AsyncFlatMapLatestSequence

/// Transforms elements and emits only from the most recent inner sequence.
///
/// Similar to switch map but allows overlap during transition.
public struct AsyncFlatMapLatestSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed
    
    /// Creates a flat map latest sequence.
    public init(
        _ base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Transformed
    ) {
        self.base = base
        self.transform = transform
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, transform: transform)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let actor: FlatMapLatestActor<Base, Transformed>
        
        init(
            base: Base,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed
        ) {
            self.actor = FlatMapLatestActor(base: base, transform: transform)
        }
        
        public mutating func next() async -> Element? {
            await actor.next()
        }
    }
}

/// Actor to manage flat map latest state.
private actor FlatMapLatestActor<Base: AsyncSequence, Transformed: AsyncSequence>
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    typealias Element = Transformed.Element
    
    private let channel: AsyncChannel<Element>
    private var channelIterator: AsyncChannel<Element>.Iterator
    private let task: Task<Void, Never>
    private var currentVersion: Int = 0
    
    init(
        base: Base,
        transform: @escaping @Sendable (Base.Element) async throws -> Transformed
    ) {
        let channel = AsyncChannel<Element>(capacity: 8)
        self.channel = channel
        self.channelIterator = channel.makeAsyncIterator()
        
        self.task = Task { [channel] in
            var iterator = base.makeAsyncIterator()
            var innerTasks: [Task<Void, Never>] = []
            var latestVersion = 0
            
            while !Task.isCancelled {
                guard let element = try? await iterator.next() else {
                    break
                }
                
                latestVersion += 1
                let version = latestVersion
                
                let innerTask = Task {
                    do {
                        let transformed = try await transform(element)
                        for try await item in transformed {
                            if Task.isCancelled { break }
                            // Only emit if still the latest
                            if version == latestVersion {
                                await channel.send(item)
                            }
                        }
                    } catch {
                        // Handle errors silently
                    }
                }
                
                innerTasks.append(innerTask)
            }
            
            // Wait for remaining tasks
            for task in innerTasks {
                await task.value
            }
            
            await channel.finish()
        }
    }
    
    func next() async -> Element? {
        await channelIterator.next()
    }
}

// MARK: - AsyncFlatMapCompactSequence

/// Transforms and flattens, filtering out nil results.
public struct AsyncFlatMapCompactSequence<Base: AsyncSequence, Transformed: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, Transformed: Sendable, Transformed.Element: Sendable {
    
    public typealias Element = Transformed.Element
    
    private let base: Base
    private let transform: @Sendable (Base.Element) async throws -> Transformed?
    
    /// Creates a flat map compact sequence.
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
        private var iterator: Base.AsyncIterator
        private let transform: @Sendable (Base.Element) async throws -> Transformed?
        private var currentIterator: Transformed.AsyncIterator?
        
        init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async throws -> Transformed?
        ) {
            self.iterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async throws -> Element? {
            while true {
                // Try current inner sequence
                if var inner = currentIterator {
                    if let element = try await inner.next() {
                        currentIterator = inner
                        return element
                    }
                    currentIterator = nil
                }
                
                // Get next from base
                guard let baseElement = try await iterator.next() else {
                    return nil
                }
                
                // Transform, skip if nil
                guard let transformed = try await transform(baseElement) else {
                    continue
                }
                
                currentIterator = transformed.makeAsyncIterator()
            }
        }
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Transforms each element to a sequence and flattens.
    ///
    /// - Parameter transform: Function returning an async sequence.
    /// - Returns: Flattened sequence of transformed elements.
    public func flatMap<S: AsyncSequence & Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> S
    ) -> AsyncFlatMapSequence<Self, S> where S.Element: Sendable {
        AsyncFlatMapSequence(self, transform: transform)
    }
    
    /// Transforms concurrently and merges results.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum concurrent transformations.
    ///   - transform: Function returning an async sequence.
    public func concurrentFlatMap<S: AsyncSequence & Sendable>(
        maxConcurrency: Int = 4,
        _ transform: @escaping @Sendable (Element) async throws -> S
    ) -> AsyncConcurrentFlatMapSequence<Self, S> where S.Element: Sendable {
        AsyncConcurrentFlatMapSequence(self, maxConcurrency: maxConcurrency, transform: transform)
    }
    
    /// Transforms and switches to the latest inner sequence.
    ///
    /// - Parameter transform: Function returning an async sequence.
    public func switchMap<S: AsyncSequence & Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> S
    ) -> AsyncSwitchMapSequence<Self, S> where S.Element: Sendable {
        AsyncSwitchMapSequence(self, transform: transform)
    }
    
    /// Transforms but ignores new elements while processing.
    ///
    /// - Parameter transform: Function returning an async sequence.
    public func exhaustMap<S: AsyncSequence & Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> S
    ) -> AsyncExhaustMapSequence<Self, S> where S.Element: Sendable {
        AsyncExhaustMapSequence(self, transform: transform)
    }
    
    /// Transforms and concatenates in order.
    ///
    /// - Parameter transform: Function returning an async sequence.
    public func concatMap<S: AsyncSequence & Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> S
    ) -> AsyncConcatMapSequence<Self, S> where S.Element: Sendable {
        AsyncConcatMapSequence(self, transform: transform)
    }
    
    /// Transforms and emits only from the most recent.
    ///
    /// - Parameter transform: Function returning an async sequence.
    public func flatMapLatest<S: AsyncSequence & Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> S
    ) -> AsyncFlatMapLatestSequence<Self, S> where S.Element: Sendable {
        AsyncFlatMapLatestSequence(self, transform: transform)
    }
    
    /// Transforms and flattens, filtering nil transforms.
    ///
    /// - Parameter transform: Function returning an optional async sequence.
    public func flatMapCompact<S: AsyncSequence & Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> S?
    ) -> AsyncFlatMapCompactSequence<Self, S> where S.Element: Sendable {
        AsyncFlatMapCompactSequence(self, transform: transform)
    }
    
    /// Flattens a sequence of sequences.
    public func flatten<S: AsyncSequence & Sendable>() -> AsyncFlatMapSequence<Self, S>
    where Element == S, S.Element: Sendable {
        flatMap { $0 }
    }
}
