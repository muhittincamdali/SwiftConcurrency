/// Runs an action at most once per interval, such as saving a scroll position or sending a
/// typing indicator.
///
/// ```swift
/// let throttler = Throttler(interval: .seconds(1))
///
/// func scrolled(to offset: Double) {
///     throttler.submit { await store.saveScrollOffset(offset) }
/// }
/// ```
///
/// The first ``submit(_:)`` runs its action at once and starts the interval. Actions submitted
/// during the interval are not run then; with `trailing: true` (the default) the last of them
/// runs when the interval ends and starts the next interval, so the final value is never lost.
/// With `trailing: false` they are dropped.
///
/// Each action runs in its own task. An action that takes longer than the interval can overlap
/// the next one; use a ``TaskQueue`` inside the action when that must not happen.
public final class Throttler: Sendable {
    private struct State {
        var lastRun: Duration?
        var trailingAction: (@Sendable () async -> Void)?
        var timer: Task<Void, Never>?
        /// Identifies `timer`, so that a timer that was cancelled cannot clear its successor.
        var timerGeneration: UInt64 = 0
    }

    /// The shortest time between two runs.
    public let interval: Duration

    /// Whether the last action submitted during an interval runs when the interval ends.
    public let trailing: Bool

    private let clock: ElapsedClock
    private let state = Locked(State())

    /// Creates a throttler.
    ///
    /// - Parameters:
    ///   - interval: The shortest time between two runs.
    ///   - trailing: Whether the last action submitted during an interval runs when it ends.
    ///   - clock: The clock that measures the time; pass a ``TestClock`` in tests.
    /// - Precondition: `interval` is not negative.
    public init(
        interval: Duration,
        trailing: Bool = true,
        clock: some Clock<Duration> = ContinuousClock()
    ) {
        precondition(interval >= .zero, "Throttler needs an interval of zero or more, got \(interval)")
        self.interval = interval
        self.trailing = trailing
        self.clock = ElapsedClock(clock)
    }

    /// Whether an action is waiting for the end of the interval.
    public var hasPendingAction: Bool {
        state.withLock { $0.trailingAction != nil }
    }

    /// Runs `action` now if the interval since the last run has passed; otherwise keeps it for
    /// the end of the interval (`trailing: true`) or drops it.
    ///
    /// - Returns: `true` when the action was started now.
    @discardableResult
    public func submit(_ action: @escaping @Sendable () async -> Void) -> Bool {
        let now = clock.elapsed()
        let runNow: Bool = state.withLock { state in
            if state.timer == nil, Self.intervalHasPassed(since: state.lastRun, now: now, interval: interval) {
                state.lastRun = now
                return true
            }
            guard trailing else { return false }
            state.trailingAction = action
            if state.timer == nil, let lastRun = state.lastRun {
                state.timerGeneration &+= 1
                state.timer = makeTimer(firingAt: lastRun + interval, generation: state.timerGeneration)
            }
            return false
        }
        if runNow {
            Task { await action() }
        }
        return runNow
    }

    /// Drops the action that waits for the end of the interval. The interval itself keeps
    /// running, so the next ``submit(_:)`` is still throttled.
    public func cancel() {
        let timer = state.withLock { state -> Task<Void, Never>? in
            state.trailingAction = nil
            state.timerGeneration &+= 1
            defer { state.timer = nil }
            return state.timer
        }
        timer?.cancel()
    }

    private func makeTimer(firingAt deadline: Duration, generation: UInt64) -> Task<Void, Never> {
        Task { [clock] in
            do {
                try await clock.sleepUntil(deadline)
            } catch {
                return
            }
            self.fireTrailingAction(at: deadline, generation: generation)
        }
    }

    private func fireTrailingAction(at deadline: Duration, generation: UInt64) {
        let action = state.withLock { state -> (@Sendable () async -> Void)? in
            guard state.timerGeneration == generation else { return nil }
            state.timer = nil
            guard let action = state.trailingAction else { return nil }
            state.trailingAction = nil
            state.lastRun = deadline
            return action
        }
        if let action {
            Task { await action() }
        }
    }

    private static func intervalHasPassed(since lastRun: Duration?, now: Duration, interval: Duration) -> Bool {
        guard let lastRun else { return true }
        return now - lastRun >= interval
    }
}
