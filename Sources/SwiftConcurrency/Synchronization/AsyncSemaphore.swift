/// A counting semaphore for Swift concurrency: limits how many tasks use a resource at once,
/// without blocking a thread.
///
/// ```swift
/// let downloads = AsyncSemaphore(value: 3)
///
/// func download(_ url: URL) async throws -> Data {
///     try await downloads.withPermit {
///         try await URLSession.shared.data(from: url).0
///     }
/// }
/// ```
///
/// - Waiting tasks are served in the order they called ``wait()``.
/// - ``wait()`` is cancellable: a task cancelled while it waits stops waiting, throws
///   `CancellationError` and never takes a permit.
/// - ``signal()`` is synchronous, so it can be called from a `defer` block or from code that is
///   not async.
///
/// Unlike `DispatchSemaphore`, waiting suspends the task instead of blocking its thread, so a
/// semaphore with value 0 can be used to wait for an event without starving the cooperative
/// thread pool.
public final class AsyncSemaphore: Sendable {
    private struct State {
        var permits: Int
        var waiters = WaiterQueue<CheckedContinuation<Void, any Error>>()
    }

    private let state: Locked<State>

    /// Creates a semaphore with `value` permits.
    ///
    /// - Parameter value: The number of tasks that can hold a permit at the same time. Pass 0 to
    ///   use the semaphore as a signal that tasks wait for.
    /// - Precondition: `value` is not negative.
    public init(value: Int) {
        precondition(value >= 0, "AsyncSemaphore needs a value of 0 or more, got \(value)")
        state = Locked(State(permits: value))
    }

    /// The number of permits that can be taken right now without waiting.
    public var availablePermits: Int {
        state.withLock { $0.permits }
    }

    /// The number of tasks suspended in ``wait()``.
    public var waiterCount: Int {
        state.withLock { $0.waiters.count }
    }

    /// The identifiers the waiter queue keeps, stale ones included (for tests).
    var storedWaiterIdentifierCount: Int {
        state.withLock { $0.waiters.storedIdentifierCount }
    }

    /// Takes a permit, suspending until one is available.
    ///
    /// Every successful call must be balanced by one call to ``signal()``.
    ///
    /// - Throws: `CancellationError` when the task is cancelled before it gets a permit. A task
    ///   that throws holds no permit and must not call ``signal()``.
    public func wait() async throws {
        let id = state.withLock { $0.waiters.makeID() }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                enum Outcome { case cancelled, acquired, suspended }
                let outcome: Outcome = state.withLock { state in
                    if Task.isCancelled { return .cancelled }
                    if state.permits > 0, state.waiters.isEmpty {
                        state.permits -= 1
                        return .acquired
                    }
                    state.waiters.append(continuation, id: id)
                    return .suspended
                }
                switch outcome {
                case .cancelled: continuation.resume(throwing: CancellationError())
                case .acquired: continuation.resume()
                case .suspended: break
                }
            }
        } onCancel: {
            let waiter = state.withLock { $0.waiters.remove(id: id) }
            waiter?.resume(throwing: CancellationError())
        }
    }

    /// Takes a permit if one is available right now.
    ///
    /// - Returns: `true` when a permit was taken; balance it with ``signal()``.
    public func tryWait() -> Bool {
        state.withLock { state in
            guard state.permits > 0, state.waiters.isEmpty else { return false }
            state.permits -= 1
            return true
        }
    }

    /// Returns a permit: resumes the task that has waited longest, or adds the permit to
    /// ``availablePermits`` when nobody waits.
    ///
    /// The permit count saturates at `Int.max`; it does not overflow.
    public func signal() {
        let waiter = state.withLock { state -> CheckedContinuation<Void, any Error>? in
            if let next = state.waiters.popFirst() { return next.value }
            if state.permits < Int.max { state.permits += 1 }
            return nil
        }
        waiter?.resume()
    }

    /// Runs `operation` while holding a permit and returns the permit when `operation` returns
    /// or throws.
    ///
    /// The operation runs on the caller's actor, so it can touch the caller's state.
    ///
    /// - Throws: `CancellationError` when the task is cancelled while waiting for a permit (the
    ///   operation does not run), or whatever `operation` throws.
    nonisolated(nonsending)
    public func withPermit<Result>(
        _ operation: nonisolated(nonsending) () async throws -> Result
    ) async throws -> Result {
        try await wait()
        defer { signal() }
        return try await operation()
    }
}
