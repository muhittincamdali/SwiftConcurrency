# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- TaskPriority utilities
- Async sequence operators

## [1.2.0] - 2026-02-06

### Added
- **Task Management**
  - `TaskGroup` utilities with automatic cancellation
  - `ThrottledTask` for rate limiting
  - `DebouncedTask` for debouncing
  - `RetryTask` with exponential backoff
  - `TimeoutTask` with configurable timeout

- **Async Sequences**
  - `AsyncThrottleSequence` for throttling
  - `AsyncDebounceSequence` for debouncing
  - `AsyncMergeSequence` for combining sequences
  - `AsyncZipSequence` for pairing elements
  - `AsyncBufferSequence` with overflow handling

- **Actors**
  - `AsyncCache` actor with TTL support
  - `AsyncQueue` FIFO task queue
  - `AsyncSemaphore` for resource limiting
  - `AsyncBarrier` for synchronization

- **Utilities**
  - `MainActor.run` helpers
  - `Task.sleep(for:)` with Duration
  - `withTaskCancellationHandler` utilities
  - `CheckedContinuation` helpers

### Changed
- Improved Swift 6 Sendable compliance
- Enhanced error propagation in task groups

### Fixed
- Memory leak in async stream
- Race condition in semaphore

## [1.1.0] - 2026-01-15

### Added
- `AsyncProperty` wrapper
- `@MainActor` utilities
- Structured concurrency helpers

## [1.0.0] - 2026-01-01

### Added
- Initial release with Swift 5.9+ concurrency utilities
- Full documentation and examples

[Unreleased]: https://github.com/muhittincamdali/SwiftConcurrency/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/muhittincamdali/SwiftConcurrency/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/muhittincamdali/SwiftConcurrency/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/muhittincamdali/SwiftConcurrency/releases/tag/v1.0.0
