# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Debug logging system for async operations
- Performance profiling utilities
- Deadlock detection helpers
- MainActor convenience utilities

## [1.0.0] - 2024-01-15

### Added

#### Core
- `TaskPool` - Reusable pool of workers with backpressure
- `DynamicTaskPool` - Auto-scaling worker pool
- `WorkStealingPool` - Load-balanced work stealing implementation
- `TaskQueue` - Priority-based task queue

#### AsyncSequence Operators
- `debounce` - Trailing edge debounce
- `debounceLeading` - Leading edge debounce
- `debounceLeadingTrailing` - Both edges
- `debounceGrouped` - Batch elements during debounce window
- `throttle` - Rate limiting for sequences
- `timeout` - Add timeouts to sequences
- `retry` - Automatic retry with backoff
- `zip` - Combine multiple sequences
- `merge` - Merge sequences into one
- `flatMap` - Async flat mapping
- `buffer` - Buffered sequences
- `filter` - Async filtering

#### Retry Mechanisms
- `RetryPolicy` - Configurable retry strategies
- `ExponentialBackoff` - Exponential delay increase
- `LinearBackoff` - Linear delay increase
- `RetryableTask` - Tasks with built-in retry

#### Actor Utilities
- `StateActor` - Thread-safe state with subscriptions
- `CacheActor` - Actor-based caching
- `DatabaseActor` - Database access serialization
- `NetworkActor` - Network request management
- `SerialExecutor` - Custom serial execution

#### Concurrency Primitives
- `AsyncSemaphore` - Counting semaphore for async
- `AsyncBarrier` - Synchronization barrier
- `AsyncLock` - Async-aware locking
- `AsyncChannel` - Multi-producer multi-consumer channel
- `AsyncThrottler` - Request throttling

#### TaskGroup Extensions
- `BatchTaskGroup` - Process items in batches
- `OrderedTaskGroup` - Maintain result ordering
- `ThrottledTaskGroup` - Limit concurrent tasks
- `ConcurrentMap` - Parallel map operations

#### Timeout & Cancellation
- `TaskTimeout` - Timeout wrapper for tasks
- `DeadlineTask` - Tasks with deadlines
- `CancellationHandler` - Graceful cancellation

#### Scheduling
- `TaskScheduler` - Flexible task scheduling
- `PriorityQueue` - Priority-based execution
- `DelayedTask` - Delayed task execution

#### Testing
- `TestScheduler` - Deterministic time control
- `TestClock` - Virtual clock for tests
- `MockActor` - Actor mocking utilities

#### Stream Utilities
- `AsyncStreamBuilder` - Fluent stream construction
- `BufferedAsyncSequence` - Buffered sequences
- `MergedAsyncSequence` - Stream merging
- `MappedAsyncSequence` - Transformed sequences
- `FilteredAsyncSequence` - Filtered sequences

### Features
- Zero external dependencies
- Swift 6 strict concurrency compliance
- Full Sendable conformance
- Comprehensive DocC documentation
- 100% async/await based

[Unreleased]: https://github.com/muhittincamdali/SwiftConcurrency/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/muhittincamdali/SwiftConcurrency/releases/tag/v1.0.0
