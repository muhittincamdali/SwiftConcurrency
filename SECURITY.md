# Security policy

## Supported versions

Security fixes go into the latest release and the `main` branch.

## Reporting a vulnerability

Report it privately, not in a public issue: open the repository's
[Security tab](https://github.com/muhittincamdali/SwiftConcurrency/security) and choose **Report
a vulnerability**, or follow the other channels in the
[security policy of the muhittincamdali repositories](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).
Include a small program or test that shows the problem and the Swift and OS versions you ran
it on.

## What SwiftConcurrency promises

SwiftConcurrency runs inside your app and handles only the closures and values you give it.
These are the properties a report can hold it to:

- It does not log, print, store or send anything: errors and results reach only your code.
- A cancelled task never stays suspended in one of its waits, and a waiter is resumed exactly
  once.
- Waiters that are cancelled do not accumulate: the semaphore and test clock queues compact
  removed entries, `SingleFlight` forgets finished operations, and `concurrentMap` keeps at most
  `maxConcurrency` child tasks.
- Arithmetic on caller input does not trap: backoff delays are computed in floating point and
  capped before they become a `Duration`, and the semaphore's permit count saturates. Waiting is
  left to the clock you pass: `ContinuousClock`, like `Task.sleep(for:)`, stops the program for
  a deadline more than `Int64.max` seconds (about 292 billion years) away, so a timeout, debounce,
  throttle or retry delay that long is outside what the package promises.
- Invalid configuration (negative durations, limits below 1, a NaN multiplier) stops the
  program at the call that passed it, with a message naming the value.

The [Cancellation and limits](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)
article lists each of these per API.
