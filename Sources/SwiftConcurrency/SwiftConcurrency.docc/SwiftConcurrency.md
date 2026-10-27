# ``SwiftConcurrency``

Limit, order, time out, retry and rate-limit async work in Swift 6, and test it without waiting.

## Overview

Swift's `async`/`await`, actors and task groups cover structured work. The everyday problems
around them are left to each app: download no more than four files at a time, keep two saves
from overlapping, give up on a request after ten seconds, retry with backoff, search only once
the user stops typing, send one request when three screens ask for the same data, and stop
calling a server that is down. SwiftConcurrency solves each of these with one small type or
function that follows Swift 6's rules: everything is `Sendable`, cancellation is honoured
everywhere, and the operations you pass run on your actor where that is possible.

```swift
import SwiftConcurrency

let profiles = try await ids.concurrentMap(maxConcurrency: 4) { id in
    try await retry(maxAttempts: 3, backoff: .exponential().jittered(.full)) { _ in
        try await withTimeout(.seconds(10)) {
            try await api.profile(id: id)
        }
    }
}
```

Every type that waits for time to pass takes a `Clock`. In tests, pass a ``TestClock`` and move
time yourself: a test of a 30-second backoff runs in microseconds and gives the same result on
every run.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:TestingTimeBasedCode>
- <doc:CancellationAndLimits>

### Limiting concurrency

- ``AsyncSemaphore``
- ``Swift/Sequence/concurrentMap(maxConcurrency:_:)``
- ``Swift/Sequence/concurrentForEach(maxConcurrency:_:)``

### Ordering work

- ``TaskQueue``
- ``SingleFlight``

### Deadlines

- ``withTimeout(_:tolerance:clock:operation:)``
- ``withTimeout(_:tolerance:operation:)``
- ``withDeadline(_:tolerance:clock:operation:)``
- ``TimeoutError``

### Retrying and failing fast

- ``retry(maxAttempts:backoff:clock:shouldRetry:operation:)``
- ``Backoff``
- ``CircuitBreaker``
- ``CircuitOpenError``

### Rate control

- ``Debouncer``
- ``Throttler``

### Testing

- ``TestClock``
