// BufferedAsyncSequence.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// Buffer overflow policy.
public enum BufferPolicy: Sendable {
    /// Suspend the producer when buffer is full.
    case suspendOnFull
    /// Drop newest elements when buffer is full.
    case dropNewest
    /// Drop oldest elements when buffer is full.
    case dropOldest
    /// Unbounded buffer (use with caution).
    case unbounded
}

/// An async sequence that buffers elements from its base sequence.
///
/// `BufferedAsyncSequence` prefetches elements from the underlying sequence
/// into a buffer, improving throughput for slow consumers and fast producers.
///
/// ## Overview
///
/// Use `BufferedAsyncSequence` when you want to decouple the production
/// and consumption rates of an async sequence.
///
/// ```swift
/// let buffered = someAsyncSequence.buffered(capacity: 10)
/// for await item in buffered {
///     // Elements are prefetched into a buffer
///     process(item)
/// }
/// ```
public struct BufferedAsyncSequence<Base: AsyncSequence & Sendable>: AsyncSequence, Sendable where Base.Element: Sendable {
    
    /// The type of element produced by this sequence.
    public typealias Element = Base.Element
    
    /// The base async sequence.
    private let base: Base
    
    /// The buffer capacity.
    private let capacity: Int
    
    /// The buffer policy.
    private let policy: BufferPolicy
    
    /// Creates a buffered async sequence.
    ///
    /// - Parameters:
    ///   - base: The underlying async sequence.
    ///   - capacity: Maximum number of elements to buffer.
    ///   - policy: How to handle buffer overflow.
    public init(
        base: Base,
        capacity: Int,
        policy: BufferPolicy = .suspendOnFull
    ) {
        precondition(capacity > 0 || policy == .unbounded, "Capacity must be positive")
        self.base = base
        self.capacity = capacity
        self.policy = policy
    }
    
    /// Creates an async iterator for the buffered sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base, capacity: capacity, policy: policy)
    }
    
    /// The async iterator for buffered sequences.
    public final class AsyncIterator: AsyncIteratorProtocol {
        
        /// The buffer storage actor.
        private let buffer: BufferStorageActor<Base.Element>
        
        /// The producer task.
        private var producerTask: Task<Void, Never>?
        
        /// Creates a new iterator.
        init(base: Base, capacity: Int, policy: BufferPolicy) {
            self.buffer = BufferStorageActor(capacity: capacity, policy: policy)
            
            let bufferRef = buffer
            
            // Start producer task
            self.producerTask = Task {
                var iterator = base.makeAsyncIterator()
                while !Task.isCancelled {
                    do {
                        if let element = try await iterator.next() {
                            await bufferRef.append(element)
                        } else {
                            await bufferRef.finish()
                            break
                        }
                    } catch {
                        await bufferRef.fail(with: error)
                        break
                    }
                }
            }
        }
        
        deinit {
            producerTask?.cancel()
        }
        
        /// Returns the next element from the buffer.
        public func next() async throws -> Base.Element? {
            try await buffer.next()
        }
    }
}

/// Actor managing the buffer storage.
actor BufferStorageActor<Element: Sendable> {
    
    /// The buffer array.
    private var elements: [Element] = []
    
    /// Whether the sequence has finished.
    private var isFinished = false
    
    /// Any error that occurred.
    private var error: Error?
    
    /// The buffer capacity.
    private let capacity: Int
    
    /// The buffer policy.
    private let policy: BufferPolicy
    
    /// Continuations waiting for elements.
    private var consumerContinuations: [CheckedContinuation<Element?, Error>] = []
    
    /// Continuations waiting to add elements.
    private var producerContinuations: [CheckedContinuation<Void, Never>] = []
    
    /// Creates buffer storage.
    init(capacity: Int, policy: BufferPolicy) {
        self.capacity = capacity
        self.policy = policy
        self.elements.reserveCapacity(capacity)
    }
    
    /// Appends an element to the buffer.
    func append(_ element: Element) async {
        switch policy {
        case .suspendOnFull:
            while elements.count >= capacity && !isFinished {
                await withCheckedContinuation { continuation in
                    producerContinuations.append(continuation)
                }
            }
            if !isFinished {
                elements.append(element)
                resumeConsumer(with: nil)
            }
            
        case .dropNewest:
            if elements.count < capacity {
                elements.append(element)
                resumeConsumer(with: nil)
            }
            // Otherwise drop the new element
            
        case .dropOldest:
            if elements.count >= capacity {
                elements.removeFirst()
            }
            elements.append(element)
            resumeConsumer(with: nil)
            
        case .unbounded:
            elements.append(element)
            resumeConsumer(with: nil)
        }
    }
    
    /// Marks the sequence as finished.
    func finish() {
        isFinished = true
        resumeAllConsumers()
        resumeAllProducers()
    }
    
    /// Marks the sequence as failed.
    func fail(with error: Error) {
        self.error = error
        isFinished = true
        resumeAllConsumers()
        resumeAllProducers()
    }
    
    /// Gets the next element from the buffer.
    func next() async throws -> Element? {
        if let error = error {
            throw error
        }
        
        if !elements.isEmpty {
            let element = elements.removeFirst()
            resumeProducer()
            return element
        }
        
        if isFinished {
            return nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            consumerContinuations.append(continuation)
        }
    }
    
    /// Resumes a waiting consumer.
    private func resumeConsumer(with element: Element?) {
        guard let continuation = consumerContinuations.first else { return }
        
        if let element = element {
            consumerContinuations.removeFirst()
            continuation.resume(returning: element)
        } else if !elements.isEmpty {
            consumerContinuations.removeFirst()
            let el = elements.removeFirst()
            resumeProducer()
            continuation.resume(returning: el)
        }
    }
    
    /// Resumes all waiting consumers.
    private func resumeAllConsumers() {
        while !consumerContinuations.isEmpty {
            let continuation = consumerContinuations.removeFirst()
            if let error = error {
                continuation.resume(throwing: error)
            } else if !elements.isEmpty {
                continuation.resume(returning: elements.removeFirst())
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Resumes a waiting producer.
    private func resumeProducer() {
        if let continuation = producerContinuations.first {
            producerContinuations.removeFirst()
            continuation.resume()
        }
    }
    
    /// Resumes all waiting producers.
    private func resumeAllProducers() {
        while !producerContinuations.isEmpty {
            let continuation = producerContinuations.removeFirst()
            continuation.resume()
        }
    }
    
    /// Current number of buffered elements.
    var count: Int {
        elements.count
    }
    
    /// Whether the buffer is empty.
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    /// Whether the buffer is full.
    var isFull: Bool {
        elements.count >= capacity
    }
}

// MARK: - AsyncSequence Extension

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Creates a buffered version of this sequence.
    ///
    /// - Parameters:
    ///   - capacity: Maximum buffer size.
    ///   - policy: Buffer overflow policy.
    /// - Returns: A buffered async sequence.
    public func buffered(
        capacity: Int,
        policy: BufferPolicy = .suspendOnFull
    ) -> BufferedAsyncSequence<Self> {
        BufferedAsyncSequence(
            base: self,
            capacity: capacity,
            policy: policy
        )
    }
}

// MARK: - Chunked Sequence

/// An async sequence that groups elements into chunks.
public struct ChunkedAsyncSequence<Base: AsyncSequence & Sendable>: AsyncSequence, Sendable where Base.Element: Sendable {
    
    public typealias Element = [Base.Element]
    
    private let base: Base
    private let size: Int
    
    /// Creates a chunked sequence.
    public init(base: Base, size: Int) {
        precondition(size > 0, "Chunk size must be positive")
        self.base = base
        self.size = size
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), size: size)
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private let size: Int
        private var finished = false
        
        init(base: Base.AsyncIterator, size: Int) {
            self.baseIterator = base
            self.size = size
        }
        
        public mutating func next() async throws -> [Base.Element]? {
            guard !finished else { return nil }
            
            var chunk: [Base.Element] = []
            chunk.reserveCapacity(size)
            
            while chunk.count < size {
                if let element = try await baseIterator.next() {
                    chunk.append(element)
                } else {
                    finished = true
                    break
                }
            }
            
            return chunk.isEmpty ? nil : chunk
        }
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Groups elements into chunks of the specified size.
    ///
    /// - Parameter size: The chunk size.
    /// - Returns: An async sequence of element arrays.
    public func chunked(size: Int) -> ChunkedAsyncSequence<Self> {
        ChunkedAsyncSequence(base: self, size: size)
    }
}
