/// A clock reduced to "time elapsed since creation", so that non-generic types can store any
/// `Clock` whose duration is `Swift.Duration`.
struct ElapsedClock: Sendable {
    /// The time since this value was created.
    let elapsed: @Sendable () -> Duration
    /// Sleeps until `elapsed()` reaches the given value.
    let sleepUntil: @Sendable (Duration) async throws -> Void

    init<C: Clock>(_ clock: C) where C.Duration == Duration {
        let start = clock.now
        elapsed = { start.duration(to: clock.now) }
        sleepUntil = { target in
            try await clock.sleep(until: start.advanced(by: target), tolerance: nil)
        }
    }

    func sleep(for duration: Duration) async throws {
        try await sleepUntil(elapsed() + duration)
    }
}
