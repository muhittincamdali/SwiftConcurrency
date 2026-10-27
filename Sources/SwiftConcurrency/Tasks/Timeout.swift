/// The error thrown by ``withTimeout(_:tolerance:clock:operation:)`` and
/// ``withDeadline(_:tolerance:clock:operation:)`` when the operation does not finish in time.
public struct TimeoutError: Error, Hashable, Sendable, CustomStringConvertible {
    public init() {}

    public var description: String {
        "The operation did not finish before its deadline."
    }
}

/// Runs `operation` and throws ``TimeoutError`` if it does not finish within `timeout`.
///
/// ```swift
/// let profile = try await withTimeout(.seconds(5)) {
///     try await api.loadProfile()
/// }
/// ```
///
/// When the time is up, the operation's task is cancelled and `withTimeout` throws
/// ``TimeoutError`` as soon as the operation returns. Cancellation in Swift is cooperative, so
/// the operation must stop when it is cancelled (`URLSession`, `Task.sleep` and the types in
/// this package do); an operation that ignores cancellation delays the error until it ends.
///
/// - Parameters:
///   - timeout: The time the operation may take. Zero or a negative value throws
///     ``TimeoutError`` without running the operation.
///   - tolerance: The leeway the clock may take when ending the wait.
///   - clock: The clock that measures the time; pass a ``TestClock`` in tests.
///   - operation: The work to run.
/// - Returns: The operation's result when it finishes in time.
/// - Throws: ``TimeoutError``, the operation's error, or `CancellationError` when the calling
///   task is cancelled.
public func withTimeout<Success: Sendable, C: Clock>(
    _ timeout: C.Instant.Duration,
    tolerance: C.Instant.Duration? = nil,
    clock: C,
    operation: @escaping @Sendable () async throws -> Success
) async throws -> Success {
    let deadline = clock.now.advanced(by: timeout)
    return try await withDeadline(deadline, tolerance: tolerance, clock: clock, operation: operation)
}

/// Runs `operation` and throws ``TimeoutError`` if it does not finish within `timeout`,
/// measured by `ContinuousClock`.
///
/// See ``withTimeout(_:tolerance:clock:operation:)`` for the details.
public func withTimeout<Success: Sendable>(
    _ timeout: Duration,
    tolerance: Duration? = nil,
    operation: @escaping @Sendable () async throws -> Success
) async throws -> Success {
    try await withTimeout(timeout, tolerance: tolerance, clock: ContinuousClock(), operation: operation)
}

/// Runs `operation` and throws ``TimeoutError`` if it has not finished when `clock` reaches
/// `deadline`.
///
/// Use it when several steps share one deadline:
///
/// ```swift
/// let clock = ContinuousClock()
/// let deadline = clock.now + .seconds(10)
/// let token = try await withDeadline(deadline, clock: clock) { try await auth.refresh() }
/// let feed = try await withDeadline(deadline, clock: clock) { try await api.feed(token) }
/// ```
///
/// A deadline that has already passed throws ``TimeoutError`` without running the operation.
public func withDeadline<Success: Sendable, C: Clock>(
    _ deadline: C.Instant,
    tolerance: C.Instant.Duration? = nil,
    clock: C,
    operation: @escaping @Sendable () async throws -> Success
) async throws -> Success {
    try Task.checkCancellation()
    guard clock.now < deadline else { throw TimeoutError() }
    return try await withThrowingTaskGroup(of: Success.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await clock.sleep(until: deadline, tolerance: tolerance)
            throw TimeoutError()
        }
        defer { group.cancelAll() }
        // The group has two children, so `next()` returns a value or throws.
        return try await group.next()!
    }
}
