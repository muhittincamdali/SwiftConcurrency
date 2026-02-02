import Foundation

// MARK: - AsyncOperation

/// Bridges traditional `Operation`-based work into the async/await world.
///
/// Wraps synchronous or `Operation`-queue-based work so it can be awaited
/// from structured concurrency contexts.
///
/// ```swift
/// let result = try await AsyncOperation.run(on: queue) {
///     processLargeDataset()
/// }
/// ```
public struct AsyncOperation: Sendable {

    /// Runs a synchronous closure on the given `OperationQueue` and returns the result.
    ///
    /// - Parameters:
    ///   - queue: The operation queue to schedule the work on.
    ///   - block: A synchronous closure that produces a result.
    /// - Returns: The value produced by the closure.
    /// - Throws: Rethrows any error thrown by the closure.
    public static func run<T: Sendable>(
        on queue: OperationQueue,
        block: @Sendable @escaping () throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.addOperation {
                do {
                    let result = try block()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Runs a synchronous non-throwing closure on the given `OperationQueue`.
    ///
    /// - Parameters:
    ///   - queue: The operation queue to schedule the work on.
    ///   - block: A synchronous closure that produces a result.
    /// - Returns: The value produced by the closure.
    public static func run<T: Sendable>(
        on queue: OperationQueue,
        block: @Sendable @escaping () -> T
    ) async -> T {
        await withCheckedContinuation { continuation in
            queue.addOperation {
                let result = block()
                continuation.resume(returning: result)
            }
        }
    }

    /// Wraps an existing `Operation` subclass and awaits its completion.
    ///
    /// The operation is added to the provided queue and the calling task
    /// suspends until the operation finishes.
    ///
    /// - Parameters:
    ///   - operation: The operation to execute.
    ///   - queue: The queue to add the operation to.
    public static func await(
        operation: Operation,
        on queue: OperationQueue
    ) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let completionOp = BlockOperation {
                continuation.resume()
            }
            completionOp.addDependency(operation)
            queue.addOperations([operation, completionOp], waitUntilFinished: false)
        }
    }

    /// Creates an `OperationQueue` with the specified concurrency and QoS.
    ///
    /// - Parameters:
    ///   - maxConcurrent: Maximum concurrent operations. Defaults to system decision.
    ///   - qualityOfService: The quality of service level. Defaults to `.default`.
    ///   - name: Optional name for the queue.
    /// - Returns: A configured `OperationQueue`.
    public static func makeQueue(
        maxConcurrent: Int = OperationQueue.defaultMaxConcurrentOperationCount,
        qualityOfService: QualityOfService = .default,
        name: String? = nil
    ) -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = maxConcurrent
        queue.qualityOfService = qualityOfService
        queue.name = name
        return queue
    }
}
