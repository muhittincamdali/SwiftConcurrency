# Testing time-based code

Test debounces, backoffs, timeouts and circuit breakers in microseconds, with the same result
on every run.

## Overview

Code that sleeps is slow and flaky to test against the real clock: a test of a 300 ms debounce
either waits 300 ms and more, or races the debounce. ``Debouncer``, ``Throttler``,
``CircuitBreaker``, ``retry(maxAttempts:backoff:clock:shouldRetry:operation:)`` and
``withTimeout(_:tolerance:clock:operation:)`` all take a `Clock` for that reason. Production code
passes nothing and gets `ContinuousClock`; a test passes a ``TestClock`` and moves time itself.

### The three steps

1. Create a ``TestClock`` and give it to the code under test.
2. Start the code, then call ``TestClock/waitForSleepers(count:)``: it returns once the code has
   started its sleep, so the next step cannot happen too early.
3. Call ``TestClock/advance(by:)`` to end the sleep, then check the result.

```swift
import SwiftConcurrency
import Testing

@Test func searchesOnlyTheLastQuery() async throws {
    let clock = TestClock()
    let debouncer = Debouncer(for: .milliseconds(300), clock: clock)
    let searched = SearchLog()   // an actor that records queries

    for query in ["s", "sw", "swi", "swift"] {
        debouncer.submit { await searched.record(query) }
    }
    try await clock.waitForSleepers()
    clock.advance(by: .milliseconds(300))

    #expect(await searched.next() == "swift")
}
```

### Check that nothing happens too early

Because time only moves when you say so, "not yet" is a precise statement. This test checks
that the second attempt waits the whole first backoff, to the millisecond:

```swift
let call = Task {
    try await retry(maxAttempts: 3, backoff: .constant(.seconds(1)), clock: clock) { attempt in
        try await service.call(attempt)
    }
}
try await clock.waitForSleepers()
clock.advance(by: .milliseconds(999))
#expect(await service.attempts == [1])   // still waiting
clock.advance(by: .milliseconds(1))
```

``TestClock/sleeperCount`` tells you whether something is still waiting, which is how the
package's own tests check that a cancelled debounce or retry stopped its sleep.

### Things to know

- A sleep that is cancelled throws `CancellationError` and leaves the clock at once.
- ``TestClock/advance(by:)`` wakes the sleepers and returns; the woken tasks run afterwards.
  Await their results (a task's `value`, an actor that records events) instead of checking
  state on the next line.
- ``TestClock/advance(to:)`` with an instant before ``TestClock/now`` does nothing, and a
  negative ``TestClock/advance(by:)`` stops the program: time never runs backwards.
- ``CircuitBreaker`` only reads the clock and never sleeps, so its tests call `advance` without
  `waitForSleepers`.
