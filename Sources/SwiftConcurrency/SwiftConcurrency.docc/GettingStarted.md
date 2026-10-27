# Getting started

Add the package, then pick the tool for the problem in front of you.

## Overview

SwiftConcurrency is a Swift package without dependencies. It needs Swift 6.2 (Xcode 26) or
later and runs on iOS 16, macOS 13, tvOS 16, watchOS 9 and visionOS 1 or later.

### Add the package

In Xcode, choose **File › Add Package Dependencies…**, enter
`https://github.com/muhittincamdali/SwiftConcurrency` and add the **SwiftConcurrency** library
to your app target.

In a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftConcurrency", from: "2.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["SwiftConcurrency"]),
]
```

### Choose a tool

| You want to…                                   | Use                                                                        |
| ---------------------------------------------- | -------------------------------------------------------------------------- |
| run at most _n_ things at once                 | ``AsyncSemaphore`` or ``Swift/Sequence/concurrentMap(maxConcurrency:_:)``      |
| run work one after the other, in order         | ``TaskQueue``                                                                |
| give up after a time                           | ``withTimeout(_:tolerance:operation:)``                                      |
| try again after a failure                      | ``retry(maxAttempts:backoff:clock:shouldRetry:operation:)`` with a ``Backoff`` |
| wait until the user stops typing               | ``Debouncer``                                                                |
| do something at most once per second           | ``Throttler``                                                                |
| send one request when many callers ask at once | ``SingleFlight``                                                             |
| stop calling a service that keeps failing      | ``CircuitBreaker``                                                           |
| test any of the above without waiting          | ``TestClock``                                                                |

### Limit how much runs at once

`concurrentMap` keeps the order of the input and never runs more than `maxConcurrency`
transforms:

```swift
let thumbnails = try await photos.concurrentMap(maxConcurrency: 4) { photo in
    try await renderer.thumbnail(for: photo)
}
```

When the work does not come from one sequence, share an ``AsyncSemaphore``:

```swift
let connections = AsyncSemaphore(value: 4)

func fetch(_ request: URLRequest) async throws -> Data {
    try await connections.withPermit {
        try await URLSession.shared.data(for: request).0
    }
}
```

### Keep work from overlapping

An actor does not stop two calls of an async method from interleaving at each `await`. A
``TaskQueue`` with the default limit of 1 does:

```swift
let saves = TaskQueue()

func save(_ document: Document) {
    saves.addOperation { try await storage.write(document) }
}
```

### Time out and retry

```swift
let user = try await retry(maxAttempts: 4, backoff: .exponential().jittered(.full)) { attempt in
    try await withTimeout(.seconds(5)) {
        try await api.user(id: id)
    }
}
```

`retry` rethrows the last error unchanged, never retries cancellation, and runs the operation
on your actor.

### Debounce a search field

```swift
@MainActor @Observable
final class SearchModel {
    var results: [Item] = []
    private let debouncer = Debouncer(for: .milliseconds(300))

    func queryChanged(_ query: String) {
        debouncer.submit {
            let items = await api.search(query)
            await self.show(items)
        }
    }

    private func show(_ items: [Item]) { results = items }
}
```

### Next steps

- <doc:TestingTimeBasedCode> shows how to test these types with ``TestClock``.
- <doc:CancellationAndLimits> lists what each type does when a task is cancelled and which
  inputs it rejects.
- The `Examples/ConcurrencyDemo` app in the repository runs a debounced search, a download
  queue and a retry with a circuit breaker.
