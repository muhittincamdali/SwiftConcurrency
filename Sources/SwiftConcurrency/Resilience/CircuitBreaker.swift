/// The error thrown by ``CircuitBreaker/run(_:)`` while the circuit is open.
public struct CircuitOpenError: Error, Hashable, Sendable, CustomStringConvertible {
    /// The time until the breaker lets a trial call through.
    public let retryAfter: Duration

    public init(retryAfter: Duration) {
        self.retryAfter = retryAfter
    }

    public var description: String {
        "The circuit is open after repeated failures; calls are refused for another \(retryAfter)."
    }
}

/// Stops calling a failing dependency for a while, so that a server that is down is not flooded
/// with requests and callers fail fast instead of waiting for timeouts.
///
/// ```swift
/// let breaker = CircuitBreaker(failureThreshold: 5, resetTimeout: .seconds(30))
///
/// let quote = try await breaker.run {
///     try await pricingService.quote(for: cart)
/// }
/// ```
///
/// The breaker has three states:
///
/// - ``State/closed``: calls run. After `failureThreshold` failures in a row the breaker opens.
/// - ``State/open``: calls throw ``CircuitOpenError`` without running. After `resetTimeout` the
///   breaker becomes half-open.
/// - ``State/halfOpen``: one trial call runs while other calls are refused. If it succeeds the
///   breaker closes; if it fails the breaker opens again for another `resetTimeout`.
///
/// Which errors count as failures is up to `isFailure`; by default every error except
/// cancellation does. An error that is not a failure is rethrown without changing the state.
public final class CircuitBreaker: Sendable {
    /// The state of a ``CircuitBreaker``.
    public enum State: Sendable, Hashable {
        case closed
        case open
        case halfOpen
    }

    private enum Phase {
        case closed(consecutiveFailures: Int)
        case open(until: Duration)
        case halfOpen(trialRunning: Bool)
    }

    private struct Storage {
        var phase: Phase = .closed(consecutiveFailures: 0)
        /// Changes on every state change, so a call that started under an earlier state cannot
        /// change the current one when it ends.
        var epoch: UInt64 = 0
    }

    /// The number of failures in a row that opens the breaker.
    public let failureThreshold: Int

    /// How long the breaker stays open before it lets a trial call through.
    public let resetTimeout: Duration

    private let isFailure: @Sendable (any Error) -> Bool
    private let clock: ElapsedClock
    private let storage = Locked(Storage())

    /// Creates a closed breaker.
    ///
    /// - Parameters:
    ///   - failureThreshold: The number of failures in a row that opens the breaker.
    ///   - resetTimeout: How long the breaker stays open.
    ///   - clock: The clock that measures `resetTimeout`; pass a ``TestClock`` in tests.
    ///   - isFailure: Whether an error counts as a failure. By default every error except
    ///     `CancellationError` does.
    /// - Precondition: `failureThreshold` is 1 or more and `resetTimeout` is not negative.
    public init(
        failureThreshold: Int = 5,
        resetTimeout: Duration = .seconds(30),
        clock: some Clock<Duration> = ContinuousClock(),
        isFailure: @escaping @Sendable (any Error) -> Bool = { !($0 is CancellationError) }
    ) {
        precondition(failureThreshold >= 1, "CircuitBreaker needs a failureThreshold of 1 or more, got \(failureThreshold)")
        precondition(resetTimeout >= .zero, "CircuitBreaker needs a resetTimeout of zero or more, got \(resetTimeout)")
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
        self.isFailure = isFailure
        self.clock = ElapsedClock(clock)
    }

    /// The current state. An open breaker whose `resetTimeout` has passed reports
    /// ``State/halfOpen``.
    public var state: State {
        let now = clock.elapsed()
        return storage.withLock { storage in
            switch storage.phase {
            case .closed: return .closed
            case .open(let until): return now >= until ? .halfOpen : .open
            case .halfOpen: return .halfOpen
            }
        }
    }

    /// Runs `operation` if the breaker allows it and records whether it failed.
    ///
    /// The operation runs on the caller's actor.
    ///
    /// - Throws: ``CircuitOpenError`` when the breaker refuses the call, otherwise whatever
    ///   `operation` throws.
    nonisolated(nonsending)
    public func run<Success>(
        _ operation: nonisolated(nonsending) () async throws -> Success
    ) async throws -> Success {
        let epoch = try admit()
        do {
            let result = try await operation()
            record(succeeded: true, epoch: epoch)
            return result
        } catch {
            if isFailure(error) {
                record(succeeded: false, epoch: epoch)
            } else {
                record(succeeded: nil, epoch: epoch)
            }
            throw error
        }
    }

    /// Closes the breaker and forgets the failures counted so far.
    public func reset() {
        storage.withLock { storage in
            storage.phase = .closed(consecutiveFailures: 0)
            storage.epoch &+= 1
        }
    }

    /// Lets a call through or throws ``CircuitOpenError``; returns the epoch the call runs in.
    private func admit() throws -> UInt64 {
        let now = clock.elapsed()
        return try storage.withLock { storage in
            switch storage.phase {
            case .closed:
                return storage.epoch
            case .open(let until) where now < until:
                throw CircuitOpenError(retryAfter: until - now)
            case .open:
                storage.phase = .halfOpen(trialRunning: true)
                storage.epoch &+= 1
                return storage.epoch
            case .halfOpen(trialRunning: true):
                throw CircuitOpenError(retryAfter: .zero)
            case .halfOpen(trialRunning: false):
                storage.phase = .halfOpen(trialRunning: true)
                return storage.epoch
            }
        }
    }

    /// Records the outcome of a call: `true` success, `false` failure, `nil` an error that does
    /// not count.
    private func record(succeeded: Bool?, epoch: UInt64) {
        let now = clock.elapsed()
        storage.withLock { storage in
            guard storage.epoch == epoch else { return }
            switch (storage.phase, succeeded) {
            case (.closed, true?):
                storage.phase = .closed(consecutiveFailures: 0)
            case (.closed(let failures), false?):
                if failures + 1 >= failureThreshold {
                    storage.phase = .open(until: now + resetTimeout)
                    storage.epoch &+= 1
                } else {
                    storage.phase = .closed(consecutiveFailures: failures + 1)
                }
            case (.halfOpen, true?):
                storage.phase = .closed(consecutiveFailures: 0)
                storage.epoch &+= 1
            case (.halfOpen, false?):
                storage.phase = .open(until: now + resetTimeout)
                storage.epoch &+= 1
            case (.halfOpen, nil):
                storage.phase = .halfOpen(trialRunning: false)
            case (.closed, nil), (.open, _):
                break
            }
        }
    }
}
