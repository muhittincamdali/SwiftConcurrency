# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

SwiftConcurrency 2 is a rewrite for Swift 6. The 1.x sources were removed in June 2026 and
the package did not build; 2.0 replaces them with a smaller set of types, each tested and
documented. Nothing from the 1.x API is kept.

### Added

- `AsyncSemaphore`: a counting semaphore with FIFO waiters and a cancellable `wait()` (a
  cancelled waiter throws `CancellationError` and takes no permit), synchronous `signal()` and
  `tryWait()`, and `withPermit(_:)`, which runs the operation on the caller's actor.
- `TaskQueue`: runs async operations in the order they were added with
  `maxConcurrentOperations` (default 1). `addOperation(priority:_:)` returns the operation's
  task, `perform(priority:_:)` waits for the result and passes cancellation on,
  `cancelAll()` and `waitUntilIdle()`. An operation cancelled before its turn never runs.
- `withTimeout(_:tolerance:clock:operation:)`, `withTimeout(_:tolerance:operation:)` and
  `withDeadline(_:tolerance:clock:operation:)`, throwing `TimeoutError`. A deadline that has
  already passed throws without running the operation.
- `retry(maxAttempts:backoff:clock:shouldRetry:operation:)` and `Backoff` (`.immediate`,
  `.constant`, `.linear`, `.exponential`, `jittered(.full)` / `jittered(.equal)`). Delays are
  capped before they become a `Duration`; cancellation is never retried.
- `Sequence.concurrentMap(maxConcurrency:_:)` and `concurrentForEach(maxConcurrency:_:)`,
  which keep the order of the elements and never run more than the limit.
- `Debouncer` and `Throttler` (leading run, optional trailing run), both with `cancel()`.
- `CircuitBreaker` (closed, open, half-open with a single trial call) and `CircuitOpenError`.
- `SingleFlight`: overlapping calls for the same key share one operation; it is cancelled when
  every caller has been cancelled.
- `TestClock`: a `Clock` that moves only on `advance(by:)` / `advance(to:)`, with
  `waitForSleepers(count:)` and `sleeperCount` for deterministic tests. Every time-based API
  takes a clock.
- A DocC catalog with the articles "Getting started", "Testing time-based code" and
  "Cancellation and limits", published to GitHub Pages.
- `Examples/ConcurrencyDemo`, an iOS and macOS app with a debounced search, a download queue
  drawn as a timeline and a retry log with a circuit breaker. The README samples live in its
  `ReadmeSamples.swift`, which the test suite compiles and runs.
- CI through the shared workflows of `muhittincamdali/.github`: `swift test` on macOS, builds
  for iOS, macOS, tvOS, watchOS and visionOS, tests on an iOS simulator, the example app,
  DocC, link, hygiene and translation checks.

### Changed

- Requires Swift 6.2 (Xcode 26) and the Swift 6 language mode; minimum platforms are iOS 16,
  macOS 13, tvOS 16, watchOS 9 and visionOS 1 (the first releases with `Clock`).

### Removed

- The 1.x types (`TaskPool`, actors such as `StateActor` and `NetworkActor`, `AsyncSequence`
  operators, debugging and profiling helpers, `EventBus`, `MetricsCollector`,
  `TimeTravelScheduler`). For `AsyncSequence` operators use
  [swift-async-algorithms](https://github.com/apple/swift-async-algorithms).
- CocoaPods support (`SwiftConcurrency.podspec`) and the release workflow that published a
  GitHub release for every tag on its own.

## [1.0.0] - 2026-02-03

First tagged version: Swift 5.9 utilities for actors, async sequences, retries, timeouts and
task groups. It is superseded by 2.0.

[Unreleased]: https://github.com/muhittincamdali/SwiftConcurrency/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/muhittincamdali/SwiftConcurrency/releases/tag/v1.0.0
