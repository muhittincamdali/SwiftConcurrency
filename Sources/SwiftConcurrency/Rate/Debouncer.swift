/// Runs an action only after calls have stopped for a given time, such as a search that waits
/// until the user stops typing.
///
/// ```swift
/// @MainActor @Observable
/// final class SearchModel {
///     var results: [Item] = []
///     private let debouncer = Debouncer(for: .milliseconds(300))
///
///     func queryChanged(_ query: String) {
///         debouncer.submit { [weak self] in
///             let items = (try? await api.search(query)) ?? []
///             await MainActor.run { self?.results = items }
///         }
///     }
/// }
/// ```
///
/// Each ``submit(_:)`` replaces the action that is waiting and restarts the wait. The action
/// runs once the wait ends without another `submit`. ``cancel()`` drops the waiting action.
/// An action that has started is not interrupted by a later `submit` or `cancel()`.
public final class Debouncer: Sendable {
    private struct State {
        var generation: UInt64 = 0
        var pending: Task<Void, Never>?
    }

    /// The quiet time that must pass before the action runs.
    public let duration: Duration

    private let clock: ElapsedClock
    private let state = Locked(State())

    /// Creates a debouncer.
    ///
    /// - Parameters:
    ///   - duration: The quiet time that must pass after the last ``submit(_:)``.
    ///   - clock: The clock that measures the time; pass a ``TestClock`` in tests.
    /// - Precondition: `duration` is not negative.
    public init(for duration: Duration, clock: some Clock<Duration> = ContinuousClock()) {
        precondition(duration >= .zero, "Debouncer needs a duration of zero or more, got \(duration)")
        self.duration = duration
        self.clock = ElapsedClock(clock)
    }

    /// Whether an action is waiting to run.
    public var hasPendingAction: Bool {
        state.withLock { $0.pending != nil }
    }

    /// Replaces the waiting action with `action` and restarts the wait.
    public func submit(_ action: @escaping @Sendable () async -> Void) {
        let deadline = clock.elapsed() + duration
        let previous = state.withLock { state -> Task<Void, Never>? in
            state.generation &+= 1
            let generation = state.generation
            let previous = state.pending
            state.pending = Task { [clock] in
                do {
                    try await clock.sleepUntil(deadline)
                } catch {
                    return
                }
                guard self.claim(generation) else { return }
                await action()
            }
            return previous
        }
        previous?.cancel()
    }

    /// Drops the waiting action, if any.
    public func cancel() {
        let previous = state.withLock { state -> Task<Void, Never>? in
            state.generation &+= 1
            defer { state.pending = nil }
            return state.pending
        }
        previous?.cancel()
    }

    /// Marks the action of `generation` as started; false when it was replaced or cancelled.
    private func claim(_ generation: UInt64) -> Bool {
        state.withLock { state in
            guard state.generation == generation else { return false }
            state.pending = nil
            return true
        }
    }
}
