import Testing
@testable import SwiftConcurrency

@Suite("TestClock")
struct TestClockTests {
    @Test("A deadline that has passed returns at once")
    func pastDeadlineReturns() async throws {
        let clock = TestClock()
        clock.advance(by: .seconds(5))
        try await clock.sleep(until: .init(offset: .seconds(5)))
        try await clock.sleep(for: .zero)
        #expect(clock.sleeperCount == 0)
    }

    @Test("A sleeper wakes when time reaches its deadline, not before")
    func wakesAtDeadline() async throws {
        let clock = TestClock()
        let sleeper = Task { try await clock.sleep(for: .seconds(10)) }
        try await clock.waitForSleepers()

        clock.advance(by: .seconds(9))
        #expect(clock.sleeperCount == 1)

        clock.advance(by: .seconds(1))
        try await sleeper.value
        #expect(clock.sleeperCount == 0)
        #expect(clock.now == .init(offset: .seconds(10)))
    }

    @Test("advance(to:) wakes every due sleeper and keeps later ones")
    func advanceToWakesDueSleepers() async throws {
        let clock = TestClock()
        let first = Task { try await clock.sleep(for: .seconds(1)) }
        let second = Task { try await clock.sleep(for: .seconds(2)) }
        let third = Task { try await clock.sleep(for: .seconds(3)) }
        try await clock.waitForSleepers(count: 3)

        clock.advance(to: .init(offset: .seconds(2)))
        try await first.value
        try await second.value
        #expect(clock.sleeperCount == 1)

        clock.advance(to: .init(offset: .seconds(1)))
        #expect(clock.now == .init(offset: .seconds(2)), "advancing to an earlier instant does nothing")

        clock.advance(by: .seconds(1))
        try await third.value
    }

    @Test("Cancelling a sleeper throws CancellationError and unregisters it")
    func cancelSleeper() async throws {
        let clock = TestClock()
        let sleeper = Task { try await clock.sleep(for: .seconds(1)) }
        try await clock.waitForSleepers()

        sleeper.cancel()
        await #expect(throws: CancellationError.self) { try await sleeper.value }
        #expect(clock.sleeperCount == 0)
    }

    @Test("A task cancelled before it sleeps does not sleep")
    func cancelledBeforeSleep() async {
        let clock = TestClock()
        let sleeper = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await clock.sleep(for: .seconds(1))
        }
        await #expect(throws: CancellationError.self) { try await sleeper.value }
        #expect(clock.sleeperCount == 0)
    }

    @Test("waitForSleepers can be cancelled")
    func cancelWaitForSleepers() async {
        let clock = TestClock()
        let waiter = Task { try await clock.waitForSleepers(count: 1) }
        waiter.cancel()
        await #expect(throws: CancellationError.self) { try await waiter.value }
    }

    @Test("Instants measure the duration between them")
    func instantArithmetic() {
        let start = TestClock.Instant()
        let later = start.advanced(by: .milliseconds(1500))
        #expect(start.duration(to: later) == .milliseconds(1500))
        #expect(later.duration(to: start) == .milliseconds(-1500))
        #expect(start < later)
    }

    #if os(macOS)
    @Test("Moving the clock backwards stops the process")
    func advanceBackwardsTraps() async {
        await #expect(processExitsWith: .failure) {
            TestClock().advance(by: .seconds(-1))
        }
    }
    #endif
}
