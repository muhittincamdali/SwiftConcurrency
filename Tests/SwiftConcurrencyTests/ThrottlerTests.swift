import Testing
import SwiftConcurrency

@Suite("Throttler")
struct ThrottlerTests {
    @Test("The first submit runs at once; the last one of the interval runs at its end")
    func leadingAndTrailing() async throws {
        let clock = TestClock()
        let throttler = Throttler(interval: .seconds(1), clock: clock)
        let ran = Recorder<Int>()

        #expect(throttler.submit { await ran.append(1) })
        #expect(await ran.wait(forCount: 1) == [1])

        clock.advance(by: .milliseconds(300))
        #expect(!throttler.submit { await ran.append(2) })
        #expect(!throttler.submit { await ran.append(3) })
        #expect(throttler.hasPendingAction)

        try await clock.waitForSleepers()
        clock.advance(by: .milliseconds(700))
        #expect(await ran.wait(forCount: 2) == [1, 3], "2 was replaced by 3")
    }

    @Test("The trailing run starts the next interval")
    func trailingRunStartsInterval() async throws {
        let clock = TestClock()
        let throttler = Throttler(interval: .seconds(1), clock: clock)
        let ran = Recorder<Int>()

        throttler.submit { await ran.append(1) }
        _ = await ran.wait(forCount: 1)
        throttler.submit { await ran.append(2) }
        try await clock.waitForSleepers()
        clock.advance(by: .seconds(1))
        _ = await ran.wait(forCount: 2)

        clock.advance(by: .milliseconds(500))
        #expect(!throttler.submit { await ran.append(3) }, "half a second after the trailing run")
        try await clock.waitForSleepers()
        clock.advance(by: .milliseconds(500))
        #expect(await ran.wait(forCount: 3) == [1, 2, 3])
    }

    @Test("With trailing: false, submits during the interval are dropped")
    func withoutTrailing() async throws {
        let clock = TestClock()
        let throttler = Throttler(interval: .seconds(1), trailing: false, clock: clock)
        let ran = Recorder<Int>()

        #expect(throttler.submit { await ran.append(1) })
        #expect(!throttler.submit { await ran.append(2) })
        #expect(!throttler.hasPendingAction)
        #expect(clock.sleeperCount == 0)

        clock.advance(by: .seconds(1))
        #expect(throttler.submit { await ran.append(3) })
        #expect(await ran.wait(forCount: 2) == [1, 3])
    }

    @Test("cancel drops the trailing action but keeps the interval")
    func cancelDropsTrailing() async throws {
        let clock = TestClock()
        let throttler = Throttler(interval: .seconds(1), clock: clock)
        let ran = Recorder<Int>()

        throttler.submit { await ran.append(1) }
        throttler.submit { await ran.append(2) }
        try await clock.waitForSleepers()
        throttler.cancel()
        #expect(!throttler.hasPendingAction)
        #expect(clock.sleeperCount == 0)

        clock.advance(by: .milliseconds(500))
        #expect(!throttler.submit { await ran.append(3) })
        try await clock.waitForSleepers()
        clock.advance(by: .milliseconds(500))
        #expect(await ran.wait(forCount: 2) == [1, 3])
    }
}
