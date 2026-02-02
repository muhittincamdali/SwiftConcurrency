import Foundation

// MARK: - AsyncChannel

/// A typed, bounded async channel for producer-consumer communication.
///
/// Inspired by Go channels, `AsyncChannel` allows one or more producers
/// to send values that are consumed by an async `for-in` loop.
///
/// ```swift
/// let channel = AsyncChannel<String>(capacity: 10)
///
/// Task {
///     await channel.send("Hello")
///     await channel.finish()
/// }
///
/// for await message in channel {
///     print(message)
/// }
/// ```
public final class AsyncChannel<Element: Sendable>: AsyncSequence, @unchecked Sendable {

    public typealias AsyncIterator = Iterator

    /// Internal state managed by an actor for thread safety.
    private actor State {
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

    private let state: State

    /// Creates a new async channel with the given buffer capacity.
    ///
    /// - Parameter capacity: Maximum number of elements buffered before producers suspend.
    ///   Defaults to 1.
    public init(capacity: Int = 1) {
        precondition(capacity > 0, "Channel capacity must be greater than zero")
        self.state = State(capacity: capacity)
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

    public func makeAsyncIterator() -> Iterator {
        Iterator(state: state)
    }

    /// Iterator that yields values from the channel until it is finished and drained.
    public struct Iterator: AsyncIteratorProtocol {
        fileprivate let state: State

        public mutating func next() async -> Element? {
            await state.next()
        }
    }
}
