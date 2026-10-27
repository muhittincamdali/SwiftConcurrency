<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="Latest version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="Supported platforms: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="Language version: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="License: MIT"></picture></a>
</p>

<p align="center">
<a href="#quick-start"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-en-light.svg" alt="Get started"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-en-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-en-light.svg" alt="Examples"></picture></a>
</p>

<!-- brand:end -->

SwiftConcurrency is a small Swift 6 package for the everyday problems around `async`/`await`
that the standard library leaves to each app: download no more than four files at a time, keep
two saves from overlapping, give up on a request after ten seconds, retry with backoff, search
only once the user stops typing, send one request when three screens ask for the same data, and
stop calling a server that is down. Each problem has one type or function; all of them are
`Sendable`, end their waits when the task is cancelled, and take a `Clock`, so that tests can
move time instead of waiting for it. It has no dependencies.

## Highlights

- **Order and limits** — `TaskQueue` runs async operations in the order they were added, one
  at a time or up to a limit you choose; `AsyncSemaphore` and `concurrentMap(maxConcurrency:)`
  cap how much runs at once.
- **Deadlines and retries** — `withTimeout`, `withDeadline` and `retry` with constant, linear
  or exponential `Backoff` and jitter; delays are capped before they become a `Duration`, so no
  retry number or multiplier overflows.
- **Rate control for UI code** — `Debouncer` for search fields and `Throttler` (leading and
  trailing runs) for scroll and drag handlers, as plain objects you call from a view model.
- **Fail fast, share work** — `CircuitBreaker` stops calling a service that keeps failing;
  `SingleFlight` sends one request when many callers ask for the same key at once.
- **Cancellation everywhere** — every wait in the package ends at once when its task is
  cancelled; a cancelled waiter takes no permit, never runs its operation and leaves nothing in
  memory.
- **Tests that do not wait** — `TestClock` and `waitForSleepers()` let a test end a 30-second
  backoff on the line it chooses, with the same result on every run.

## Quick start

**1. Add the package**

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. Import the module**

```swift
import SwiftConcurrency
```

**3. Use it**

Load many profiles, four requests at a time, each with a 10-second timeout and up to three
attempts with exponential backoff
([ReadmeSamples.swift](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)):

```swift
func loadProfiles(ids: [Int], from api: some ProfileAPI) async throws -> [Profile] {
    try await ids.concurrentMap(maxConcurrency: 4) { id in
        try await retry(maxAttempts: 3, backoff: .exponential().jittered(.full)) { _ in
            try await withTimeout(.seconds(10)) {
                try await api.profile(id: id)
            }
        }
    }
}
```

`ProfileAPI` stands for your networking code: any `Sendable` type with an async
`profile(id:)` method. The results come back in the order of `ids`. If a request still fails after three attempts,
its error is thrown unchanged and the requests that are still running are cancelled.

## Installation

### Swift Package Manager

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

Or add it to the `dependencies` in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftConcurrency.git", branch: "main")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "SwiftConcurrency", package: "SwiftConcurrency")
    ])
]
```

## Usage

The samples below are copied from
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift), which the
example app builds and the test suite runs.

### Search as you type

`Debouncer` runs the search once the user has stopped typing for 300 ms. Each new keystroke
replaces the waiting search.

```swift
@MainActor
final class SearchController {
    private(set) var results: [String] = []
    private(set) var searchCount = 0
    private let debouncer: Debouncer
    private let search: @Sendable (String) async -> [String]

    init(
        clock: some Clock<Duration> = ContinuousClock(),
        search: @escaping @Sendable (String) async -> [String]
    ) {
        self.debouncer = Debouncer(for: .milliseconds(300), clock: clock)
        self.search = search
    }

    func queryChanged(_ query: String) {
        debouncer.submit { [search] in
            let results = await search(query)
            await self.show(results)
        }
    }

    private func show(_ results: [String]) {
        self.results = results
        searchCount += 1
    }
}
```

### Keep saves from overlapping

An actor lets the next call start while the previous one awaits. `TaskQueue` does not: with the
default limit of 1 each write starts after the previous one has finished, in the order of the
`save` calls.

```swift
final class Autosaver: Sendable {
    private let queue = TaskQueue()
    private let write: @Sendable (String) async throws -> Void

    init(write: @escaping @Sendable (String) async throws -> Void) {
        self.write = write
    }

    func save(_ text: String) {
        queue.addOperation { [write] in
            try await write(text)
        }
    }

    func waitForPendingSaves() async throws {
        try await queue.waitUntilIdle()
    }
}
```

`TaskQueue(maxConcurrentOperations: 4)` runs up to four operations at once and still starts
them in order.

### Send one request for many callers

`SingleFlight` shares the request that is already running for a profile, and `CircuitBreaker`
refuses calls for 30 seconds after five failures in a row.

```swift
final class ProfileLoader: Sendable {
    private let api: any ProfileAPI
    let inFlight = SingleFlight<Int, Profile>()
    private let breaker: CircuitBreaker

    init(api: any ProfileAPI, clock: some Clock<Duration> = ContinuousClock()) {
        self.api = api
        self.breaker = CircuitBreaker(failureThreshold: 5, resetTimeout: .seconds(30), clock: clock)
    }

    func profile(id: Int) async throws -> Profile {
        try await inFlight.value(for: id) { [api, breaker] in
            try await breaker.run {
                try await api.profile(id: id)
            }
        }
    }
}
```

### Test it without waiting

Pass a `TestClock`, wait until the code sleeps, then move time yourself. This test from
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) types four
letters and checks that only the last query is searched:

```swift
let clock = TestClock()
let searched = Recorder<String>()
let controller = SearchController(clock: clock) { query in
    await searched.append(query)
    return ["\(query) result"]
}
for query in ["t", "ta", "tas", "task"] {
    controller.queryChanged(query)
}
try await clock.waitForSleepers()
clock.advance(by: .milliseconds(300))
#expect(await searched.wait(forCount: 1) == ["task"])
```

`Recorder` is a small actor in the test target that collects values and waits for them.

## Demo

The [ConcurrencyDemo](Examples/ConcurrencyDemo) app runs each tool with the real library. The
screenshots come from the app on an iOS 27 simulator, captured by
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Debounced search | Download queue (limit 2) | Retry and circuit breaker |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="Search screen: four keystrokes, one search, results for “task”"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="Download queue: a timeline of six files where at most two overlap"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="Retry log: three requests fail after three attempts, then the open circuit refuses two"></picture> |

To run it, open `ConcurrencyDemo.xcodeproj` in [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo)
with Xcode 26 or later, choose an iPhone simulator or **My Mac**, and press **Run**.
[Examples/README.md](Examples/README.md) describes each screen.

## Documentation

Reference documentation and articles:

- [SwiftConcurrency reference](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [Getting started](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [Testing time-based code](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [Cancellation and limits](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## Guides

- [Getting started](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — which
  type solves which problem, with a sample for each.
- [Testing time-based code](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — the `TestClock` workflow: create, wait for sleepers, advance.
- [Cancellation and limits](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — what each API does when its task is cancelled, the inputs it rejects and how it bounds
  memory.

## Requirements

| Platform | Minimum version |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| Toolchain | Swift 6.2 · Xcode 26+ |

## Architecture

The package is one module, `SwiftConcurrency`, grouped by problem:

| Folder | Types |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked` (an unfair lock), `WaiterQueue` (FIFO of suspended callers), `ElapsedClock` |

Design decisions:

- **Classes with a lock, not actors.** `signal()`, `cancel()`, `submit(_:)` and
  `advance(by:)` take effect before they return, so they can be called from synchronous code,
  from `defer` and from tests without an `await` that lets other work run in between.
- **Suspended callers are continuations in a `WaiterQueue`.** A cancellation handler removes
  its own entry under the same lock that registers it, so no waiter is lost or resumed twice.
- **Operations run on the caller's actor where they can.** `retry`, `AsyncSemaphore.withPermit`
  and `CircuitBreaker.run` are `nonisolated(nonsending)`, so the closures you pass may touch
  main-actor state and need no `Sendable` captures. Work that must run in another task
  (`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`) takes `@Sendable` closures.
- **Every timed type takes a `Clock`.** Production code gets `ContinuousClock`; tests pass a
  `TestClock`.

### Where it fits

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) covers operators on
`AsyncSequence` (`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`); use it when your
data already arrives as a sequence. SwiftConcurrency covers work that is started by calls:
limits, queues, deadlines, retries, debouncing a method call, circuit breaking and shared
requests. The two packages work side by side.

## Roadmap

- Linux support: replace `OSAllocatedUnfairLock` with the standard library's `Mutex`, which
  needs raising the minimum Apple platforms to iOS 18 and macOS 15.
- A token-bucket rate limiter for APIs that allow a number of requests per second.
- A priority option for `TaskQueue`, so urgent operations can start before older ones.

## Contributing

Contributions are welcome. Read the [contributing guide](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md) and the [code of conduct](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md) before opening a pull request. Report security issues privately as described in the [security policy](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md).

## License

Released under the MIT license. See [LICENSE](LICENSE).
