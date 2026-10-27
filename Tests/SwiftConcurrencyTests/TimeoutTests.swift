import Testing
import SwiftConcurrency

@Suite("withTimeout and withDeadline")
struct TimeoutTests {
    @Test("An operation that finishes in time returns its value")
    func finishesInTime() async throws {
        let clock = TestClock()
        let value = try await withTimeout(.seconds(1), clock: clock) { 7 }
        #expect(value == 7)
    }

    @Test("An operation still running at the deadline is cancelled and TimeoutError is thrown")
    func timesOut() async throws {
        let clock = TestClock()
        let gate = AsyncSemaphore(value: 0)
        let call = Task {
            try await withTimeout(.seconds(5), clock: clock) {
                try await gate.wait()
            }
        }
        try await clock.waitForSleepers()
        await waitUntil("the operation is waiting") { gate.waiterCount == 1 }

        clock.advance(by: .seconds(4))
        #expect(gate.waiterCount == 1, "one second before the deadline the operation still runs")

        clock.advance(by: .seconds(1))
        await #expect(throws: TimeoutError.self) { try await call.value }
        #expect(gate.waiterCount == 0, "the operation was cancelled")
    }

    @Test("A timeout of zero or less throws without running the operation", arguments: [Duration.zero, .seconds(-1)])
    func nonPositiveTimeout(timeout: Duration) async {
        let clock = TestClock()
        let ran = Recorder<Bool>()
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(timeout, clock: clock) { await ran.append(true) }
        }
        #expect(await ran.values.isEmpty)
    }

    @Test("The operation's own error is rethrown")
    func operationError() async {
        let clock = TestClock()
        await #expect(throws: TestFailure(id: 3)) {
            try await withTimeout(.seconds(1), clock: clock) { throw TestFailure(id: 3) }
        }
    }

    @Test("Cancelling the caller throws CancellationError, not TimeoutError")
    func callerCancelled() async throws {
        let clock = TestClock()
        let gate = AsyncSemaphore(value: 0)
        let call = Task {
            try await withTimeout(.seconds(5), clock: clock) { try await gate.wait() }
        }
        try await clock.waitForSleepers()
        call.cancel()
        await #expect(throws: CancellationError.self) { try await call.value }
    }

    @Test("Steps that share a deadline share its time")
    func sharedDeadline() async throws {
        let clock = TestClock()
        let deadline = clock.now.advanced(by: .seconds(10))
        let first = try await withDeadline(deadline, clock: clock) { 1 }
        #expect(first == 1)

        clock.advance(by: .seconds(10))
        await #expect(throws: TimeoutError.self) {
            try await withDeadline(deadline, clock: clock) { 2 }
        }
    }

    @Test("The ContinuousClock overload times out a real sleep")
    func continuousClock() async {
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(.milliseconds(20)) {
                try await Task.sleep(for: .seconds(30))
            }
        }
    }
}
