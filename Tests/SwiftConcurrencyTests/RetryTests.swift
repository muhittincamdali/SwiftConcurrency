import Testing
import SwiftConcurrency

@Suite("retry")
struct RetryTests {
    /// Attempts that fail until `succeedOn`, recording each attempt number.
    actor FlakyService {
        let succeedOn: Int
        private(set) var attempts: [Int] = []

        init(succeedOn: Int) {
            self.succeedOn = succeedOn
        }

        func call(_ attempt: Int) throws -> String {
            attempts.append(attempt)
            guard attempt >= succeedOn else { throw TestFailure(id: attempt) }
            return "ok on \(attempt)"
        }
    }

    @Test("Retries after the backoff delay until the operation succeeds")
    func succeedsAfterRetries() async throws {
        let clock = TestClock()
        let service = FlakyService(succeedOn: 3)
        let backoff = Backoff.exponential(initial: .seconds(1), multiplier: 2)
        let call = Task {
            try await retry(maxAttempts: 5, backoff: backoff, clock: clock) { attempt in
                try await service.call(attempt)
            }
        }

        try await clock.waitForSleepers()
        #expect(await service.attempts == [1])
        clock.advance(by: .milliseconds(999))
        #expect(await service.attempts == [1], "the second attempt waits the full first delay")
        clock.advance(by: .milliseconds(1))

        try await clock.waitForSleepers()
        #expect(await service.attempts == [1, 2])
        clock.advance(by: .seconds(2))

        #expect(try await call.value == "ok on 3")
        #expect(await service.attempts == [1, 2, 3])
        #expect(clock.now == .init(offset: .seconds(3)))
    }

    @Test("Rethrows the last error once the attempts are used up")
    func rethrowsLastError() async {
        let service = FlakyService(succeedOn: .max)
        await #expect(throws: TestFailure(id: 4)) {
            try await retry(maxAttempts: 4, backoff: .immediate) { try await service.call($0) }
        }
        #expect(await service.attempts == [1, 2, 3, 4])
    }

    @Test("maxAttempts of 1 runs the operation once")
    func singleAttempt() async {
        let service = FlakyService(succeedOn: 2)
        await #expect(throws: TestFailure(id: 1)) {
            try await retry(maxAttempts: 1, backoff: .immediate) { try await service.call($0) }
        }
        #expect(await service.attempts == [1])
    }

    @Test("An error that shouldRetry rejects is thrown without another attempt")
    func shouldRetryStops() async {
        let service = FlakyService(succeedOn: 3)
        await #expect(throws: TestFailure(id: 1)) {
            try await retry(maxAttempts: 5, backoff: .immediate, shouldRetry: { _ in false }) {
                try await service.call($0)
            }
        }
        #expect(await service.attempts == [1])
    }

    @Test("CancellationError from the operation is never retried")
    func cancellationIsNotRetried() async {
        let attempts = Recorder<Int>()
        await #expect(throws: CancellationError.self) {
            try await retry(maxAttempts: 5, backoff: .immediate) { attempt in
                await attempts.append(attempt)
                throw CancellationError()
            }
        }
        #expect(await attempts.values == [1])
    }

    @Test("Cancelling during the wait ends it and starts no new attempt")
    func cancelDuringWait() async throws {
        let clock = TestClock()
        let service = FlakyService(succeedOn: 2)
        let call = Task {
            try await retry(maxAttempts: 3, backoff: .constant(.seconds(10)), clock: clock) {
                try await service.call($0)
            }
        }
        try await clock.waitForSleepers()
        call.cancel()
        await #expect(throws: CancellationError.self) { try await call.value }
        #expect(await service.attempts == [1])
        #expect(clock.sleeperCount == 0)
    }

    @MainActor
    @Test("The operation runs on the caller's actor")
    func keepsCallerIsolation() async throws {
        var attempts = 0 // main-actor state, mutated without Sendable
        let result = try await retry(maxAttempts: 3, backoff: .immediate) { attempt in
            MainActor.assertIsolated()
            attempts += 1
            if attempt < 2 { throw TestFailure() }
            return attempt
        }
        #expect(result == 2)
        #expect(attempts == 2)
    }

    #if os(macOS)
    @Test("maxAttempts of 0 stops the process")
    func zeroAttemptsTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = try? await retry(maxAttempts: 0) { _ in 1 }
        }
    }
    #endif
}
