import Testing
@testable import SwiftConcurrency

/// Collects values from concurrent tasks and lets a test wait until a number of them arrived.
actor Recorder<Value: Sendable> {
    private(set) var values: [Value] = []
    private var watchers: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func append(_ value: Value) {
        values.append(value)
        let ready = watchers.filter { values.count >= $0.count }
        watchers.removeAll { values.count >= $0.count }
        for watcher in ready { watcher.continuation.resume() }
    }

    /// Suspends until at least `count` values were recorded and returns them.
    func wait(forCount count: Int) async -> [Value] {
        if values.count < count {
            await withCheckedContinuation { watchers.append((count, $0)) }
        }
        return values
    }
}

/// Tracks how many tasks are inside a section at once.
actor ConcurrencyGauge {
    private(set) var current = 0
    private(set) var maximum = 0

    func enter() {
        current += 1
        maximum = max(maximum, current)
    }

    func leave() {
        current -= 1
    }
}

/// An error used by the tests.
struct TestFailure: Error, Equatable {
    var id = 0
}

/// Polls `condition` until it is true, yielding in between. Used only to wait for a task to
/// reach a suspension point that has no hook of its own; fails the test after `limit` polls.
func waitUntil(
    _ comment: Comment,
    limit: Int = 100_000,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: () -> Bool
) async {
    for _ in 0..<limit {
        if condition() { return }
        await Task.yield()
    }
    Issue.record("Timed out waiting: \(comment)", sourceLocation: sourceLocation)
}

/// A random number generator with a fixed sequence (SplitMix64), for tests of jitter.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
