import Foundation

// MARK: - DispatchQueueSerialExecutor

/// A custom serial executor backed by a `DispatchQueue`.
///
/// Allows actors to run their isolated code on a specific dispatch queue,
/// which is useful for integrating with legacy code or ensuring execution
/// on a particular queue (e.g., a database queue).
///
/// ```swift
/// actor DatabaseActor {
///     private let executor = DispatchQueueSerialExecutor(
///         queue: DispatchQueue(label: "com.app.database")
///     )
///
///     nonisolated var unownedExecutor: UnownedSerialExecutor {
///         executor.asUnownedSerialExecutor()
///     }
/// }
/// ```
public final class DispatchQueueSerialExecutor: SerialExecutor, @unchecked Sendable {

    /// The underlying dispatch queue.
    private let queue: DispatchQueue

    /// Creates a serial executor backed by the given dispatch queue.
    ///
    /// - Parameter queue: A serial dispatch queue. Using a concurrent queue
    ///   may lead to undefined behavior.
    public init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// Creates a serial executor with a new queue using the given label.
    ///
    /// - Parameter label: The label for the dispatch queue.
    public convenience init(label: String) {
        self.init(queue: DispatchQueue(label: label))
    }

    /// Enqueues a job to be executed on the underlying dispatch queue.
    public func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        queue.async {
            unownedJob.runSynchronously(on: executor)
        }
    }

    /// Returns an unowned reference to this executor.
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    /// The underlying dispatch queue for external use.
    public var underlyingQueue: DispatchQueue {
        queue
    }
}
