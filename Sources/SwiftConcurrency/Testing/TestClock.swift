/// A clock whose time only moves when you call ``advance(by:)``, for testing code that sleeps.
///
/// Every type in this package that waits for time to pass (``Debouncer``, ``Throttler``,
/// ``retry(maxAttempts:backoff:clock:shouldRetry:operation:)``, ``withTimeout(_:tolerance:clock:operation:)``,
/// ``CircuitBreaker``) takes a `Clock`. Give it a `TestClock` in tests and the test decides when
/// each sleep ends, so the test runs in microseconds and gives the same result on every run.
///
/// ```swift
/// let clock = TestClock()
/// let debouncer = Debouncer(for: .milliseconds(300), clock: clock)
///
/// debouncer.submit { await search("swift") }
/// await clock.waitForSleepers()          // the debouncer is now sleeping
/// clock.advance(by: .milliseconds(300))  // its sleep ends; the search runs
/// ```
///
/// A task that calls `sleep(until:)` with a deadline at or before ``now`` returns at once.
/// Otherwise it stays suspended until ``advance(by:)`` or ``advance(to:)`` moves ``now`` to or
/// past its deadline, or until the task is cancelled, in which case `sleep` throws
/// `CancellationError`.
///
/// Because a sleeping task registers itself asynchronously, call ``waitForSleepers(count:)``
/// before advancing when the code under test was started from another task; advancing before
/// the sleep is registered would move time past a deadline that does not exist yet.
public final class TestClock: Clock, Sendable {
    /// A point in the time of a ``TestClock``: the duration since the clock was created.
    public struct Instant: InstantProtocol, Hashable, Sendable {
        /// The time since the start of the clock.
        public var offset: Swift.Duration

        public init(offset: Swift.Duration = .zero) {
            self.offset = offset
        }

        public func advanced(by duration: Swift.Duration) -> Instant {
            Instant(offset: offset + duration)
        }

        public func duration(to other: Instant) -> Swift.Duration {
            other.offset - offset
        }

        public static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    private struct Sleeper {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct SleeperWatch {
        let count: Int
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct State {
        var now: Instant
        var sleepers = WaiterQueue<Sleeper>()
        var watches = WaiterQueue<SleeperWatch>()
    }

    private let state: Locked<State>

    /// Creates a clock that starts at `now`.
    public init(now: Instant = Instant()) {
        state = Locked(State(now: now))
    }

    public var now: Instant {
        state.withLock { $0.now }
    }

    /// Zero: a test clock can represent any duration exactly.
    public var minimumResolution: Swift.Duration { .zero }

    /// The number of tasks currently suspended in `sleep(until:tolerance:)`.
    public var sleeperCount: Int {
        state.withLock { $0.sleepers.count }
    }

    /// Suspends until ``advance(by:)`` or ``advance(to:)`` reaches `deadline`.
    ///
    /// - Throws: `CancellationError` when the task is cancelled before or during the sleep.
    public func sleep(until deadline: Instant, tolerance: Swift.Duration? = nil) async throws {
        try Task.checkCancellation()
        let id = state.withLock { $0.sleepers.makeID() }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                enum Outcome { case wait([CheckedContinuation<Void, any Error>]), resume, cancel }
                let outcome: Outcome = state.withLock { state in
                    if Task.isCancelled { return .cancel }
                    if deadline <= state.now { return .resume }
                    state.sleepers.append(Sleeper(deadline: deadline, continuation: continuation), id: id)
                    return .wait(Self.takeSatisfiedWatches(&state))
                }
                switch outcome {
                case .cancel:
                    continuation.resume(throwing: CancellationError())
                case .resume:
                    continuation.resume()
                case .wait(let watches):
                    for watch in watches { watch.resume() }
                }
            }
        } onCancel: {
            let sleeper = state.withLock { $0.sleepers.remove(id: id) }
            sleeper?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Moves the clock forward by `duration` and wakes every sleeper whose deadline is reached,
    /// earliest deadline first.
    ///
    /// The woken tasks resume on their own executors after this method returns; it does not wait
    /// for them to run.
    ///
    /// - Precondition: `duration` is not negative.
    public func advance(by duration: Swift.Duration) {
        precondition(duration >= .zero, "TestClock cannot move backwards (advance(by: \(duration)))")
        let target = now.advanced(by: duration)
        advance(to: target)
    }

    /// Moves the clock to `instant` and wakes every sleeper whose deadline is reached, earliest
    /// deadline first. Does nothing when `instant` is not after ``now``.
    public func advance(to instant: Instant) {
        let due: [Sleeper] = state.withLock { state in
            guard instant > state.now else { return [] }
            state.now = instant
            return state.sleepers.removeAll { $0.deadline <= instant }
        }
        for sleeper in due.sorted(by: { $0.deadline < $1.deadline }) {
            sleeper.continuation.resume()
        }
    }

    /// Suspends until at least `count` tasks are sleeping on this clock.
    ///
    /// Use it to make sure that the code under test has started its sleep before you call
    /// ``advance(by:)``.
    ///
    /// - Throws: `CancellationError` when the waiting task is cancelled.
    public func waitForSleepers(count: Int = 1) async throws {
        precondition(count >= 0, "waitForSleepers(count:) needs a count of 0 or more")
        try Task.checkCancellation()
        let id = state.withLock { $0.watches.makeID() }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let ready: Bool? = state.withLock { state in
                    if Task.isCancelled { return nil }
                    if state.sleepers.count >= count { return true }
                    state.watches.append(SleeperWatch(count: count, continuation: continuation), id: id)
                    return false
                }
                switch ready {
                case nil: continuation.resume(throwing: CancellationError())
                case true?: continuation.resume()
                case false?: break
                }
            }
        } onCancel: {
            let watch = state.withLock { $0.watches.remove(id: id) }
            watch?.continuation.resume(throwing: CancellationError())
        }
    }

    private static func takeSatisfiedWatches(_ state: inout State) -> [CheckedContinuation<Void, any Error>] {
        guard !state.watches.isEmpty else { return [] }
        let sleeperCount = state.sleepers.count
        return state.watches.removeAll { sleeperCount >= $0.count }.map(\.continuation)
    }
}
