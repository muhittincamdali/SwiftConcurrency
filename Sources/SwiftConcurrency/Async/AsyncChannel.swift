// AsyncChannel.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncChannel

/// A typed, bounded async channel for producer-consumer communication.
///
/// Inspired by Go channels, `AsyncChannel` allows one or more producers
/// to send values that are consumed by an async `for-in` loop.
///
/// ## Overview
///
/// Use `AsyncChannel` when you need to pass values between concurrent tasks
/// in a producer-consumer pattern.
///
/// ```swift
/// let channel = AsyncChannel<String>(capacity: 10)
///
/// Task {
///     await channel.send("Hello")
///     await channel.send("World")
///     await channel.finish()
/// }
///
/// for await message in channel {
///     print(message)
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Channels
/// - ``init(capacity:)``
///
/// ### Sending Values
/// - ``send(_:)``
/// - ``finish()``
public final class AsyncChannel<Element: Sendable>: AsyncSequence, @unchecked Sendable {

    public typealias AsyncIterator = Iterator

    /// Internal state actor for thread safety.
    private let state: ChannelState<Element>

    /// Creates a new async channel with the given buffer capacity.
    ///
    /// - Parameter capacity: Maximum number of elements buffered before producers suspend.
    ///   Defaults to 1.
    public init(capacity: Int = 1) {
        precondition(capacity > 0, "Channel capacity must be greater than zero")
        self.state = ChannelState(capacity: capacity)
    }

    /// Sends a value into the channel.
    ///
    /// If the buffer is full, the calling task suspends until space is available.
    ///
    /// - Parameter value: The value to send.
    public func send(_ value: Element) async {
        await state.send(value)
    }

    /// Marks the channel as finished. No more values can be sent.
    public func finish() async {
        await state.finish()
    }

    /// The number of elements currently buffered.
    public var count: Int {
        get async { await state.count }
    }
    
    /// Whether the channel has been finished.
    public var isFinished: Bool {
        get async { await state.isFinished }
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(state: state)
    }

    /// Iterator that yields values from the channel until it is finished and drained.
    public struct Iterator: AsyncIteratorProtocol {
        let state: ChannelState<Element>

        public mutating func next() async -> Element? {
            await state.next()
        }
    }
}

// MARK: - Channel State

/// Actor managing channel state.
actor ChannelState<Element: Sendable> {
    private var buffer: [Element] = []
    private let capacity: Int
    private var finished = false
    private var consumers: [CheckedContinuation<Element?, Never>] = []
    private var producers: [CheckedContinuation<Void, Never>] = []

    init(capacity: Int) {
        self.capacity = capacity
    }

    /// Enqueues a value, suspending the producer if the buffer is full.
    func send(_ value: Element) async {
        if buffer.count >= capacity && !finished {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                producers.append(continuation)
            }
        }

        guard !finished else { return }

        if let consumer = consumers.first {
            consumers.removeFirst()
            consumer.resume(returning: value)
        } else {
            buffer.append(value)
        }
    }

    /// Marks the channel as finished and flushes waiting consumers.
    func finish() {
        finished = true
        for producer in producers {
            producer.resume()
        }
        producers.removeAll()
        for consumer in consumers {
            consumer.resume(returning: nil)
        }
        consumers.removeAll()
    }

    /// Dequeues the next value, suspending if the buffer is empty.
    func next() async -> Element? {
        if !buffer.isEmpty {
            let value = buffer.removeFirst()
            if let producer = producers.first {
                producers.removeFirst()
                producer.resume()
            }
            return value
        }

        if finished {
            return nil
        }

        return await withCheckedContinuation { continuation in
            consumers.append(continuation)
        }
    }

    /// Returns the number of buffered elements.
    var count: Int {
        buffer.count
    }

    /// Whether the channel has been marked as finished.
    var isFinished: Bool {
        finished
    }
}

// MARK: - Unbuffered Channel

/// An unbuffered channel that requires a receiver before sending completes.
///
/// Similar to Go's unbuffered channels, sends block until a receiver is ready.
public final class UnbufferedChannel<Element: Sendable>: AsyncSequence, @unchecked Sendable {
    
    public typealias AsyncIterator = Iterator
    
    private let state: UnbufferedChannelState<Element>
    
    /// Creates an unbuffered channel.
    public init() {
        self.state = UnbufferedChannelState()
    }
    
    /// Sends a value, blocking until a receiver is ready.
    ///
    /// - Parameter value: The value to send.
    public func send(_ value: Element) async {
        await state.send(value)
    }
    
    /// Marks the channel as finished.
    public func finish() async {
        await state.finish()
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(state: state)
    }
    
    /// Iterator for unbuffered channel.
    public struct Iterator: AsyncIteratorProtocol {
        let state: UnbufferedChannelState<Element>
        
        public mutating func next() async -> Element? {
            await state.receive()
        }
    }
}

/// Actor managing unbuffered channel state.
actor UnbufferedChannelState<Element: Sendable> {
    
    private var pendingSend: (value: Element, continuation: CheckedContinuation<Void, Never>)?
    private var pendingReceive: CheckedContinuation<Element?, Never>?
    private var finished = false
    
    /// Sends a value, waiting for a receiver.
    func send(_ value: Element) async {
        guard !finished else { return }
        
        if let receiver = pendingReceive {
            pendingReceive = nil
            receiver.resume(returning: value)
            return
        }
        
        await withCheckedContinuation { continuation in
            pendingSend = (value, continuation)
        }
    }
    
    /// Receives a value, waiting for a sender.
    func receive() async -> Element? {
        if finished && pendingSend == nil {
            return nil
        }
        
        if let (value, continuation) = pendingSend {
            pendingSend = nil
            continuation.resume()
            return value
        }
        
        if finished {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            pendingReceive = continuation
        }
    }
    
    /// Marks the channel as finished.
    func finish() {
        finished = true
        if let receiver = pendingReceive {
            pendingReceive = nil
            receiver.resume(returning: nil)
        }
        if let (_, continuation) = pendingSend {
            pendingSend = nil
            continuation.resume()
        }
    }
}

// MARK: - Broadcast Channel

/// A channel that broadcasts values to multiple receivers.
///
/// Each receiver gets a copy of every value sent after they subscribed.
public final class BroadcastChannel<Element: Sendable>: @unchecked Sendable {
    
    private let state: BroadcastChannelState<Element>
    
    /// Creates a broadcast channel.
    public init() {
        self.state = BroadcastChannelState()
    }
    
    /// Sends a value to all current receivers.
    ///
    /// - Parameter value: The value to broadcast.
    public func send(_ value: Element) async {
        await state.send(value)
    }
    
    /// Closes the channel.
    public func close() async {
        await state.close()
    }
    
    /// Subscribes and returns a stream of values.
    ///
    /// - Returns: An async stream of broadcast values.
    public func subscribe() async -> AsyncStream<Element> {
        await state.subscribe()
    }
}

/// Actor managing broadcast channel state.
actor BroadcastChannelState<Element: Sendable> {
    
    private var subscribers: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var isClosed = false
    
    /// Sends a value to all subscribers.
    func send(_ value: Element) {
        guard !isClosed else { return }
        for continuation in subscribers.values {
            continuation.yield(value)
        }
    }
    
    /// Closes the channel.
    func close() {
        isClosed = true
        for continuation in subscribers.values {
            continuation.finish()
        }
        subscribers.removeAll()
    }
    
    /// Subscribes to the channel.
    func subscribe() -> AsyncStream<Element> {
        let id = UUID()
        
        return AsyncStream { continuation in
            if isClosed {
                continuation.finish()
                return
            }
            
            subscribers[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.unsubscribe(id: id)
                }
            }
        }
    }
    
    /// Removes a subscriber.
    private func unsubscribe(id: UUID) {
        subscribers.removeValue(forKey: id)
    }
}
