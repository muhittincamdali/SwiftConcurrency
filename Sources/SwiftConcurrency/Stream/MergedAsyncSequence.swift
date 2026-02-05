import Foundation

// MARK: - MergedAsyncSequence

/// Merges multiple async sequences of the same element type into a single stream.
///
/// Elements are emitted in the order they become available across all sources.
/// The merged sequence completes when all source sequences have finished.
///
/// ```swift
/// let merged = MergedAsyncSequence(streamA, streamB)
/// for await value in merged {
///     print(value)
/// }
/// ```
public struct MergedAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {

    public typealias AsyncIterator = Iterator

    /// Type-erased async sequence producer.
    private let sources: [AnySendableAsyncSequence<Element>]

    /// Creates a merged sequence from two async sequences.
    public init<S1: AsyncSequence & Sendable, S2: AsyncSequence & Sendable>(
        _ s1: S1,
        _ s2: S2
    ) where S1.Element == Element, S2.Element == Element {
        self.sources = [
            AnySendableAsyncSequence(s1),
            AnySendableAsyncSequence(s2)
        ]
    }

    /// Creates a merged sequence from three async sequences.
    public init<S1: AsyncSequence & Sendable, S2: AsyncSequence & Sendable, S3: AsyncSequence & Sendable>(
        _ s1: S1,
        _ s2: S2,
        _ s3: S3
    ) where S1.Element == Element, S2.Element == Element, S3.Element == Element {
        self.sources = [
            AnySendableAsyncSequence(s1),
            AnySendableAsyncSequence(s2),
            AnySendableAsyncSequence(s3)
        ]
    }

    /// Creates a merged sequence from an array of async streams.
    public init(streams: [AsyncStream<Element>]) {
        self.sources = streams.map { AnySendableAsyncSequence($0) }
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(sources: sources)
    }

    /// Iterator that concurrently pulls from all sources.
    public struct Iterator: AsyncIteratorProtocol {
        private let channel: AsyncChannel<Element>
        private var channelIterator: AsyncChannel<Element>.Iterator
        private let task: Task<Void, Never>

        init(sources: [AnySendableAsyncSequence<Element>]) {
            let channel = AsyncChannel<Element>(capacity: 16)
            self.channel = channel
            self.channelIterator = channel.makeAsyncIterator()

            self.task = Task {
                await withTaskGroup(of: Void.self) { group in
                    for source in sources {
                        group.addTask {
                            var iterator = source.makeAsyncIterator()
                            while let element = try? await iterator.next() {
                                await channel.send(element)
                            }
                        }
                    }
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

// MARK: - AnySendableAsyncSequence

/// Type-erased async sequence wrapper that is `Sendable`.
internal struct AnySendableAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
    typealias AsyncIterator = AnyAsyncIterator

    private let makeIteratorClosure: @Sendable () -> AnyAsyncIterator

    init<S: AsyncSequence & Sendable>(_ sequence: S) where S.Element == Element {
        let box = MergeUncheckedBox(sequence)
        self.makeIteratorClosure = {
            var iterator = box.value.makeAsyncIterator()
            return AnyAsyncIterator {
                try? await iterator.next()
            }
        }
    }

    func makeAsyncIterator() -> AnyAsyncIterator {
        makeIteratorClosure()
    }

    struct AnyAsyncIterator: AsyncIteratorProtocol {
        let nextClosure: () async -> Element?
        mutating func next() async -> Element? {
            await nextClosure()
        }
    }
}

/// Internal wrapper for merge operations.
@usableFromInline
struct MergeUncheckedBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
