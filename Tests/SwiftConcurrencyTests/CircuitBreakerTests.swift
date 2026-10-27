import Testing
import SwiftConcurrency

@Suite("CircuitBreaker")
struct CircuitBreakerTests {
    private func fail(_ breaker: CircuitBreaker, times: Int) async {
        for _ in 0..<times {
            _ = try? await breaker.run { () -> Int in throw TestFailure() }
        }
    }

    @Test("Opens after the threshold of failures in a row and refuses calls")
    func opensAfterThreshold() async {
        let clock = TestClock()
        let breaker = CircuitBreaker(failureThreshold: 3, resetTimeout: .seconds(30), clock: clock)

        await fail(breaker, times: 2)
        #expect(breaker.state == .closed)
        await fail(breaker, times: 1)
        #expect(breaker.state == .open)

        clock.advance(by: .seconds(10))
        let ran = Recorder<Bool>()
        await #expect(throws: CircuitOpenError(retryAfter: .seconds(20))) {
            try await breaker.run { await ran.append(true) }
        }
        #expect(await ran.values.isEmpty, "a refused call does not run")
    }

    @Test("A success resets the count of failures")
    func successResetsCount() async throws {
        let breaker = CircuitBreaker(failureThreshold: 3, clock: TestClock())
        await fail(breaker, times: 2)
        _ = try await breaker.run { 1 }
        await fail(breaker, times: 2)
        #expect(breaker.state == .closed)
    }

    @Test("After the reset timeout a successful trial call closes the breaker")
    func halfOpenTrialSucceeds() async throws {
        let clock = TestClock()
        let breaker = CircuitBreaker(failureThreshold: 1, resetTimeout: .seconds(5), clock: clock)
        await fail(breaker, times: 1)

        clock.advance(by: .seconds(5))
        #expect(breaker.state == .halfOpen)
        #expect(try await breaker.run { "trial" } == "trial")
        #expect(breaker.state == .closed)
    }

    @Test("A failed trial call opens the breaker for another reset timeout")
    func halfOpenTrialFails() async {
        let clock = TestClock()
        let breaker = CircuitBreaker(failureThreshold: 1, resetTimeout: .seconds(5), clock: clock)
        await fail(breaker, times: 1)
        clock.advance(by: .seconds(5))

        await fail(breaker, times: 1)
        #expect(breaker.state == .open)
        clock.advance(by: .seconds(4))
        #expect(breaker.state == .open)
        clock.advance(by: .seconds(1))
        #expect(breaker.state == .halfOpen)
    }

    @Test("Only one trial call runs while the breaker is half-open")
    func singleTrialCall() async throws {
        let clock = TestClock()
        let breaker = CircuitBreaker(failureThreshold: 1, resetTimeout: .seconds(1), clock: clock)
        await fail(breaker, times: 1)
        clock.advance(by: .seconds(1))

        let gate = AsyncSemaphore(value: 0)
        let trial = Task { try await breaker.run { try await gate.wait() } }
        await waitUntil("the trial call runs") { gate.waiterCount == 1 }

        await #expect(throws: CircuitOpenError(retryAfter: .zero)) {
            try await breaker.run { 2 }
        }
        gate.signal()
        try await trial.value
        #expect(breaker.state == .closed)
    }

    @Test("Errors that are not failures do not count")
    func nonFailureErrors() async {
        let breaker = CircuitBreaker(failureThreshold: 1, clock: TestClock()) { error in
            (error as? TestFailure)?.id != 404
        }
        for _ in 0..<5 {
            await #expect(throws: TestFailure(id: 404)) {
                try await breaker.run { () -> Int in throw TestFailure(id: 404) }
            }
        }
        #expect(breaker.state == .closed)

        await #expect(throws: CancellationError.self) {
            try await CircuitBreaker(failureThreshold: 1, clock: TestClock()).run { () -> Int in
                throw CancellationError()
            }
        }
    }

    @Test("A call that started before the breaker opened does not change the new state")
    func staleOutcomeIsIgnored() async throws {
        let clock = TestClock()
        let breaker = CircuitBreaker(failureThreshold: 1, resetTimeout: .seconds(10), clock: clock)
        let gate = AsyncSemaphore(value: 0)
        let slow = Task { try await breaker.run { try await gate.wait() } }
        await waitUntil("the slow call runs") { gate.waiterCount == 1 }

        await fail(breaker, times: 1)
        #expect(breaker.state == .open)
        gate.signal()
        try await slow.value
        #expect(breaker.state == .open, "the slow call's success does not close the breaker")
    }

    @Test("reset closes the breaker")
    func reset() async {
        let breaker = CircuitBreaker(failureThreshold: 1, clock: TestClock())
        await fail(breaker, times: 1)
        breaker.reset()
        #expect(breaker.state == .closed)
    }

    #if os(macOS)
    @Test("A threshold of zero stops the process")
    func zeroThresholdTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = CircuitBreaker(failureThreshold: 0)
        }
    }
    #endif
}
