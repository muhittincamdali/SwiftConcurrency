import os

/// A value guarded by an unfair lock.
///
/// The types of this package keep their state in a `Locked` instead of an actor so that their
/// non-async methods (`signal()`, `cancel()`, `advance(by:)`) take effect before they return,
/// which is what makes them usable from synchronous code and deterministic in tests.
final class Locked<State>: @unchecked Sendable {
    private let lock: OSAllocatedUnfairLock<State>

    init(_ initialState: State) {
        lock = OSAllocatedUnfairLock(uncheckedState: initialState)
    }

    /// Runs `body` with exclusive access to the state. `body` must not suspend or call back into
    /// code that takes the same lock.
    func withLock<Result>(_ body: (inout State) throws -> Result) rethrows -> Result {
        try lock.withLockUnchecked(body)
    }
}
