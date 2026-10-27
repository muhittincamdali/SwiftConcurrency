import Testing
import SwiftConcurrency

@Suite("Backoff")
struct BackoffTests {
    @Test("Constant backoff waits the same time before every retry")
    func constant() {
        let backoff = Backoff.constant(.milliseconds(250))
        #expect((1...5).map(backoff.baseDelay(forRetry:)) == Array(repeating: .milliseconds(250), count: 5))
        #expect(Backoff.immediate.baseDelay(forRetry: 3) == .zero)
    }

    @Test("Linear backoff adds the increment and stops at maxDelay")
    func linear() {
        let backoff = Backoff.linear(initial: .seconds(1), increment: .seconds(2), maxDelay: .seconds(6))
        #expect((1...5).map(backoff.baseDelay(forRetry:)) == [.seconds(1), .seconds(3), .seconds(5), .seconds(6), .seconds(6)])
    }

    @Test("Exponential backoff multiplies and stops at maxDelay")
    func exponential() {
        let backoff = Backoff.exponential(initial: .milliseconds(200), multiplier: 2, maxDelay: .seconds(1))
        let delays = (1...5).map(backoff.baseDelay(forRetry:))
        #expect(delays == [.milliseconds(200), .milliseconds(400), .milliseconds(800), .seconds(1), .seconds(1)])
    }

    @Test("A multiplier of 1 keeps the initial delay")
    func multiplierOne() {
        let backoff = Backoff.exponential(initial: .seconds(2), multiplier: 1)
        #expect(backoff.baseDelay(forRetry: 1_000) == .seconds(2))
    }

    @Test("Huge retry numbers give maxDelay instead of overflowing", arguments: [64, 1_100, 10_000, Int.max])
    func hugeRetryNumbers(retry: Int) {
        let exponential = Backoff.exponential(initial: .seconds(1), multiplier: 10, maxDelay: .seconds(30))
        #expect(exponential.baseDelay(forRetry: retry) == .seconds(30))
        let linear = Backoff.linear(initial: .seconds(1), increment: .seconds(Int64.max / 2), maxDelay: .seconds(60))
        #expect(linear.baseDelay(forRetry: retry) == .seconds(60))
    }

    @Test("A maxDelay longer than Int64.max seconds does not trap")
    func maxDelayBeyondInt64Seconds() {
        let maxDelay = Duration.seconds(Int64.max) * 4
        let exponential = Backoff.exponential(maxDelay: maxDelay)
        #expect(exponential.baseDelay(forRetry: 3) == .milliseconds(800))
        #expect(exponential.baseDelay(forRetry: 100) == maxDelay)
        let linear = Backoff.linear(initial: .seconds(1), increment: .seconds(Int64.max), maxDelay: maxDelay)
        #expect(linear.baseDelay(forRetry: 10) == maxDelay)
        var generator = SeededGenerator(seed: 3)
        for retry in [1, 100, Int.max] {
            #expect(exponential.jittered(.full).delay(forRetry: retry, using: &generator) <= maxDelay)
            #expect(exponential.jittered(.equal).delay(forRetry: retry, using: &generator) <= maxDelay)
        }
    }

    @Test("Retry numbers below 1 are treated as the first retry", arguments: [0, -1, Int.min])
    func lowRetryNumbers(retry: Int) {
        let backoff = Backoff.exponential(initial: .milliseconds(100))
        #expect(backoff.baseDelay(forRetry: retry) == .milliseconds(100))
    }

    @Test("Full jitter stays between zero and the base delay")
    func fullJitter() {
        let backoff = Backoff.exponential(initial: .seconds(1), maxDelay: .seconds(8)).jittered(.full)
        var generator = SeededGenerator(seed: 42)
        for retry in 1...200 {
            let base = backoff.baseDelay(forRetry: retry)
            let delay = backoff.delay(forRetry: retry, using: &generator)
            #expect(delay >= .zero && delay <= base)
        }
    }

    @Test("Equal jitter stays between half and all of the base delay")
    func equalJitter() {
        let backoff = Backoff.constant(.seconds(4)).jittered(.equal)
        var generator = SeededGenerator(seed: 7)
        for _ in 0..<200 {
            let delay = backoff.delay(forRetry: 1, using: &generator)
            #expect(delay >= .seconds(2) && delay <= .seconds(4))
        }
    }

    @Test("Jitter on the largest durations does not trap")
    func jitterOnHugeDelays() {
        let backoff = Backoff.constant(.seconds(Int64.max)).jittered(.full)
        var generator = SeededGenerator(seed: 1)
        for _ in 0..<100 {
            #expect(backoff.delay(forRetry: 1, using: &generator) <= .seconds(Int64.max))
        }
    }

    @Test("Jitter of a zero delay is zero")
    func jitterOfZero() {
        #expect(Backoff.immediate.jittered(.full).delay(forRetry: 1) == .zero)
    }

    #if os(macOS)
    // Exit tests cannot capture values on Swift 6.2, so each invalid value has its own body.
    @Test("A multiplier that is not a finite number of 1 or more stops the process")
    func invalidMultiplierTraps() async {
        await #expect(processExitsWith: .failure) { _ = Backoff.exponential(multiplier: .nan) }
        await #expect(processExitsWith: .failure) { _ = Backoff.exponential(multiplier: .infinity) }
        await #expect(processExitsWith: .failure) { _ = Backoff.exponential(multiplier: 0.5) }
        await #expect(processExitsWith: .failure) { _ = Backoff.exponential(multiplier: -2) }
    }

    @Test("A negative delay stops the process")
    func negativeDelayTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Backoff.constant(.seconds(-1))
        }
    }
    #endif
}
