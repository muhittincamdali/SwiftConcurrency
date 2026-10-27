/// Runs `operation` until it succeeds, waiting between attempts as `backoff` says, up to
/// `maxAttempts` attempts in total.
///
/// ```swift
/// let user = try await retry(maxAttempts: 4, backoff: .exponential().jittered(.full)) { attempt in
///     try await api.user(id: id)
/// }
/// ```
///
/// - The operation receives the attempt number, starting at 1.
/// - When the last attempt fails, its error is rethrown unchanged, so callers handle the same
///   errors they would without `retry`.
/// - `CancellationError`, and any error thrown once the task is cancelled, is rethrown at once
///   and never retried. Cancelling the task during a wait ends the wait.
/// - The operation runs on the caller's actor; it does not need to be `Sendable`.
///
/// - Parameters:
///   - maxAttempts: The number of attempts, the first one included. 1 runs the operation once.
///   - backoff: The wait before each retry.
///   - clock: The clock that measures the waits; pass a ``TestClock`` in tests.
///   - shouldRetry: Decides whether an error is worth another attempt. By default every error
///     is, except cancellation.
///   - operation: The work to run.
/// - Precondition: `maxAttempts` is 1 or more.
nonisolated(nonsending)
public func retry<Success>(
    maxAttempts: Int = 3,
    backoff: Backoff = .exponential(),
    clock: some Clock<Duration> = ContinuousClock(),
    shouldRetry: (any Error) -> Bool = { _ in true },
    operation: nonisolated(nonsending) (_ attempt: Int) async throws -> Success
) async throws -> Success {
    precondition(maxAttempts >= 1, "retry needs maxAttempts of 1 or more, got \(maxAttempts)")
    var attempt = 1
    while true {
        try Task.checkCancellation()
        do {
            return try await operation(attempt)
        } catch {
            if error is CancellationError || Task.isCancelled { throw error }
            guard attempt < maxAttempts, shouldRetry(error) else { throw error }
        }
        try await clock.sleep(for: backoff.delay(forRetry: attempt))
        attempt += 1
    }
}
