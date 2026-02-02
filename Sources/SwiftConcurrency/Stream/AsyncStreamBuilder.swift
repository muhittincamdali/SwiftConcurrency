import Foundation

// MARK: - AsyncStreamBuilder

/// Provides an ergonomic way to construct `AsyncStream` instances.
///
/// Simplifies the creation of async streams by providing a cleaner API
/// with support for yielding, finishing, and error handling.
///
/// ```swift
/// let stream = AsyncStreamBuilder<Int>.build { yield in
///     for i in 0..<10 {
///         yield(i)
///         try await Task.sleep(for: .milliseconds(50))
///     }
/// }
/// ```
public enum AsyncStreamBuilder<Element: Sendable> {

    /// Builds an `AsyncStream` using the provided closure.
    ///
    /// The closure receives a `yield` function to emit elements. The stream
    /// automatically finishes when the closure returns or is cancelled.
    ///
    /// - Parameters:
    ///   - bufferingPolicy: The buffering policy for the stream. Defaults to `.unbounded`.
    ///   - build: A closure that produces elements via the `yield` callback.
    /// - Returns: A configured `AsyncStream`.
    public static func build(
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
        _ build: @Sendable @escaping (_ yield: @Sendable (Element) -> Void) async throws -> Void
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let task = Task {
                do {
                    try await build { element in
                        continuation.yield(element)
                    }
                } catch {
                    // Stream ends on error or cancellation
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Builds an `AsyncStream` from an array of elements with an optional delay.
    ///
    /// - Parameters:
    ///   - elements: The elements to emit.
    ///   - delay: Optional delay between each emission.
    /// - Returns: An `AsyncStream` emitting the given elements.
    public static func from(
        _ elements: [Element],
        delay: Duration? = nil
    ) -> AsyncStream<Element> {
        build { yield in
            for element in elements {
                yield(element)
                if let delay {
                    try await Task.sleep(for: delay)
                }
            }
        }
    }

    /// Creates an empty `AsyncStream` that finishes immediately.
    public static var empty: AsyncStream<Element> {
        AsyncStream { $0.finish() }
    }

    /// Creates an `AsyncStream` that emits a single element.
    ///
    /// - Parameter element: The element to emit.
    /// - Returns: An `AsyncStream` containing one element.
    public static func just(_ element: Element) -> AsyncStream<Element> {
        build { yield in
            yield(element)
        }
    }
}
