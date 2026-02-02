import Foundation

// MARK: - TaskTimeout

/// Errors thrown by timeout operations.
public enum TimeoutError: Error, Sendable, CustomStringConvertible {
    /// The operation exceeded the allowed duration.
    case timedOut(duration: Duration)

    public var description: String {
        switch self {
        case .timedOut(let duration):
            return "Operation timed out after \(duration)"
        }
    }
}

/// Runs an async operation with a timeout.
///
/// If the operation does not complete within the specified duration,
/// the task is cancelled and a ``TimeoutError/timedOut(duration:)`` is thrown.
///
/// ```swift
/// let result = try await withTimeout(.seconds(5)) {
///     try await fetchRemoteConfig()
/// }
/// ```
///
/// - Parameters:
///   - duration: Maximum allowed duration for the operation.
///   - operation: The async throwing closure to execute.
/// - Returns: The result of the operation if it completes in time.
/// - Throws: ``TimeoutError/timedOut(duration:)`` if the deadline is exceeded,
///   or rethrows errors from the operation.
public func withTimeout<T: Sendable>(
    _ duration: Duration,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError.timedOut(duration: duration)
        }

        guard let result = try await group.next() else {
            throw TimeoutError.timedOut(duration: duration)
        }

        group.cancelAll()
        return result
    }
}

/// Runs an async operation with a timeout, returning `nil` instead of throwing.
///
/// - Parameters:
///   - duration: Maximum allowed duration for the operation.
///   - operation: The async closure to execute.
/// - Returns: The result if completed in time, or `nil` on timeout.
public func withOptionalTimeout<T: Sendable>(
    _ duration: Duration,
    operation: @Sendable @escaping () async throws -> T
) async -> T? {
    try? await withTimeout(duration, operation: operation)
}
