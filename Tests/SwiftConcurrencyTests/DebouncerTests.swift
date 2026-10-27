import Testing
import SwiftConcurrency

@Suite("Debouncer")
struct DebouncerTests {
    @Test("Only the last of several quick submits runs")
    func lastSubmitWins() async throws {
        let clock = TestClock()
        let debouncer = Debouncer(for: .milliseconds(300), clock: clock)
        let ran = Recorder<String>()

        for query in ["s", "sw", "swi", "swift"] {
            debouncer.submit { await ran.append(query) }
        }
        try await clock.waitForSleepers()
        #expect(clock.sleeperCount == 1, "replaced actions stop waiting")

        clock.advance(by: .milliseconds(300))
        #expect(await ran.wait(forCount: 1) == ["swift"])
        #expect(!debouncer.hasPendingAction)
    }

    @Test("Each submit restarts the wait")
    func submitRestartsWait() async throws {
        let clock = TestClock()
        let debouncer = Debouncer(for: .milliseconds(300), clock: clock)
        let ran = Recorder<String>()

        debouncer.submit { await ran.append("first") }
        try await clock.waitForSleepers()
        clock.advance(by: .milliseconds(200))
        debouncer.submit { await ran.append("second") }
        try await clock.waitForSleepers()

        clock.advance(by: .milliseconds(200))
        #expect(clock.sleeperCount == 1, "500 ms after the second submit is 100 ms short")
        #expect(debouncer.hasPendingAction)

        clock.advance(by: .milliseconds(100))
        #expect(await ran.wait(forCount: 1) == ["second"])
    }

    @Test("cancel drops the waiting action")
    func cancelDropsAction() async throws {
        let clock = TestClock()
        let debouncer = Debouncer(for: .seconds(1), clock: clock)
        let ran = Recorder<String>()

        debouncer.submit { await ran.append("dropped") }
        try await clock.waitForSleepers()
        debouncer.cancel()
        #expect(clock.sleeperCount == 0)
        #expect(!debouncer.hasPendingAction)

        debouncer.submit { await ran.append("kept") }
        try await clock.waitForSleepers()
        clock.advance(by: .seconds(1))
        #expect(await ran.wait(forCount: 1) == ["kept"])
    }

    @Test("Actions submitted after the wait ended run again")
    func runsAgainAfterQuietPeriod() async throws {
        let clock = TestClock()
        let debouncer = Debouncer(for: .seconds(1), clock: clock)
        let ran = Recorder<Int>()
        for round in 1...3 {
            debouncer.submit { await ran.append(round) }
            try await clock.waitForSleepers()
            clock.advance(by: .seconds(1))
            _ = await ran.wait(forCount: round)
        }
        #expect(await ran.values == [1, 2, 3])
    }
}
