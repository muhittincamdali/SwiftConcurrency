import Foundation

// MARK: - RetryPolicy

/// Configurable retry policy with exponential backoff and optional jitter.
///
/// Retries a failing async operation up to a maximum number of attempts,
/// with increasing delays between attempts.
///
/// ```swift
/// let result = try await RetryPolicy(
///     maxAttempts: 3,
///     initialDelay: .seconds(1),
///     backoffMultiplier: 2.0
/// ).execute {
///     try await fetchData()
/// }
/// ```
public struct RetryPolicy: Sendable {

    /// Maximum number of attempts (including the initial one).
    public let maxAttempts: Int

    /// Delay before the first retry.
    public let initialDelay: Duration

    /// Multiplier applied to the delay after each failed attempt.
    public let backoffMultiplier: Double

    /// Maximum delay between retries.
    public let maxDelay: Duration

    /// Whether to add random jitter to delays.
    public let jitter: Bool

    /// Creates a retry policy.
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts. Must be at least 1.
    ///   - initialDelay: Delay before the first retry. Defaults to 1 second.
    ///   - backoffMultiplier: Multiplier for exponential backoff. Defaults to 2.0.
    ///   - maxDelay: Maximum delay cap. Defaults to 60 seconds.
    ///   - jitter: Whether to add random jitter. Defaults to `true`.
    public init(
        maxAttempts: Int = 3,
        initialDelay: Duration = .seconds(1),
        backoffMultiplier: Double = 2.0,
        maxDelay: Duration = .seconds(60),
        jitter: Bool = true
    ) {
        precondition(maxAttempts >= 1, "maxAttempts must be at least 1")
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.backoffMultiplier = backoffMultiplier
        self.maxDelay = maxDelay
        self.jitter = jitter
    }

    /// Executes the operation, retrying on failure according to this policy.
    ///
    /// - Parameter operation: The async throwing closure to attempt.
    /// - Returns: The successful result.
    /// - Throws: The last error if all attempts are exhausted.
    public func execute<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var currentDelay = initialDelay

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                if attempt == maxAttempts {
                    break
                }

                try Task.checkCancellation()

                let delay = computeDelay(currentDelay)
                try await Task.sleep(for: delay)

                currentDelay = cap(currentDelay * backoffMultiplier)
            }
        }

        throw lastError!
    }

    // MARK: - Private

    private func computeDelay(_ base: Duration) -> Duration {
        guard jitter else { return base }
        let factor = Double.random(in: 0.5...1.5)
        return base * factor
    }

    private func cap(_ duration: Duration) -> Duration {
        duration < maxDelay ? duration : maxDelay
    }
}

// MARK: - Duration Multiplication

extension Duration {
    /// Multiplies a duration by a scalar.
    static func * (lhs: Duration, rhs: Double) -> Duration {
        let attoseconds = Double(lhs.components.attoseconds)
        let seconds = Double(lhs.components.seconds)
        let total = (seconds + attoseconds * 1e-18) * rhs
        return .milliseconds(Int(total * 1000))
    }
}
