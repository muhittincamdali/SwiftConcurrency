# Cancellation and limits

What each type does when a task is cancelled, which inputs it rejects, and how it keeps memory
and arithmetic bounded.

## Overview

Cancellation in Swift is cooperative: cancelling a task sets a flag, and the code it runs
decides when to stop. Every suspension point in this package checks that flag, so a cancelled
task never stays stuck in a SwiftConcurrency wait.

### Cancellation

| API                                                       | When the waiting task is cancelled                                                                                                                                                                                            |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ``AsyncSemaphore/wait()``                                   | Leaves the queue and throws `CancellationError`. It took no permit, so it must not call ``AsyncSemaphore/signal()``. A task that is already cancelled does not take a free permit either.                                       |
| ``TaskQueue``                                               | An operation cancelled before its turn never runs; its task throws `CancellationError`. A running operation receives the cancellation. ``TaskQueue/perform(priority:_:)`` passes the caller's cancellation on to its operation. |
| ``withTimeout(_:tolerance:clock:operation:)``               | Throws `CancellationError` (not ``TimeoutError``) and cancels the operation.                                                                                                                                                    |
| ``retry(maxAttempts:backoff:clock:shouldRetry:operation:)`` | Ends the wait between attempts and throws `CancellationError`. An operation that throws `CancellationError` is never retried.                                                                                                 |
| ``Swift/Sequence/concurrentMap(maxConcurrency:_:)``         | Cancels the running transforms and starts no new ones.                                                                                                                                                                        |
| ``SingleFlight/value(for:operation:)``                      | This caller stops waiting; the shared operation keeps running for the others and is cancelled only when every caller has gone.                                                                                                |
| ``Debouncer``, ``Throttler``                                  | ``Debouncer/cancel()`` and ``Throttler/cancel()`` drop the waiting action. An action that has started runs to the end.                                                                                                            |
| ``TestClock/sleep(until:tolerance:)``                       | Throws `CancellationError` and unregisters the sleeper.                                                                                                                                                                       |

A timeout ends only as fast as the operation reacts to cancellation. `URLSession`,
`Task.sleep` and this package react at once; a loop that never checks
`Task.isCancelled` delays ``TimeoutError`` until it returns.

### Inputs that are rejected

Values that cannot describe a valid configuration stop the program with a message that names
the value, the way Swift's standard library treats an out-of-range index:

- a negative ``AsyncSemaphore`` value;
- a ``TaskQueue`` limit, `concurrentMap` limit, `retry` attempt count or ``CircuitBreaker``
  failure threshold below 1;
- a negative duration for ``Backoff``, ``Debouncer``, ``Throttler``, ``CircuitBreaker`` or
  ``TestClock/advance(by:)``;
- a ``Backoff/exponential(initial:multiplier:maxDelay:)`` multiplier that is NaN, infinite or
  below 1.

A zero or negative ``withTimeout(_:tolerance:clock:operation:)`` timeout is not an error: it
means the time is already up, so ``TimeoutError`` is thrown without running the operation.

### Arithmetic

- ``Backoff`` computes delays in floating point and caps them at `maxDelay` before they become
  a `Duration`. An exponent that overflows becomes infinity, not NaN, and gives `maxDelay`;
  jitter never exceeds the base delay. No retry number, up to `Int.max`, traps.
- ``AsyncSemaphore/signal()`` saturates the permit count at `Int.max`.

### Memory

- Waiters that are cancelled are removed at once. The queues of ``AsyncSemaphore`` and
  ``TestClock`` compact the identifiers of removed waiters once they outnumber the live ones,
  so thousands of cancellations leave nothing behind.
- ``SingleFlight`` forgets an operation as soon as it finishes; it holds nothing for keys that
  are not in flight.
- `concurrentMap` keeps at most `maxConcurrency` child tasks alive.
- ``TaskQueue`` keeps every operation that was added and has not finished, like
  `OperationQueue`. If producers can outpace the queue, bound them yourself, for example with an
  ``AsyncSemaphore`` around ``TaskQueue/perform(priority:_:)``.

### Nothing is logged

The package does not log, print, collect metrics or store the values that pass through it, so
errors and results reach only your code.
