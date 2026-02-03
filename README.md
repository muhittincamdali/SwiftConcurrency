# SwiftConcurrency

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](Package.swift)

A comprehensive Swift concurrency utilities library providing powerful abstractions for async/await, task groups, actors, and structured concurrency patterns.

## Features

- 🚀 **Task Groups** - Concurrent mapping, throttled execution, ordered results, batch processing
- ⏱️ **Timeouts** - Task timeouts, deadlines, cancellation handling
- 🔄 **Retry Logic** - Exponential backoff, linear backoff, custom strategies
- 📡 **Async Channels** - Go-style channels for inter-task communication
- 🎭 **Actors** - Thread-safe caching, database operations, network isolation
- 🌊 **Async Sequences** - Buffered, filtered, mapped, merged sequences
- ⏰ **Scheduling** - Task scheduler, priority queues, delayed execution
- 🔒 **Synchronization** - Semaphores, barriers, phasers
- 🧪 **Testing** - Test scheduler, mock actors for deterministic tests

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittinc/SwiftConcurrency.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter repository URL.

## Quick Start

### Concurrent Map

Transform collections in parallel with automatic ordering:

```swift
import SwiftConcurrency

let urls = [url1, url2, url3, url4, url5]

// Basic concurrent map
let data = try await urls.concurrentMap { url in
    try await URLSession.shared.data(from: url).0
}

// With concurrency limit (max 3 at a time)
let throttledData = try await urls.concurrentMap(maxConcurrency: 3) { url in
    try await URLSession.shared.data(from: url).0
}
```

### Retry with Backoff

Automatically retry failing operations:

```swift
let result = try await withRetry(maxAttempts: 5) {
    try await fetchDataFromServer()
}

// With custom backoff
let task = RetryableTask(
    maxAttempts: 3,
    backoff: .exponential(initial: .milliseconds(100), multiplier: 2.0, max: .seconds(30)),
    shouldRetry: { error in
        (error as? NetworkError)?.isRetryable ?? false
    }
) {
    try await api.request()
}
let data = try await task.run()
```

### Timeouts

Add timeouts to any async operation:

```swift
// With duration
let result = try await withTimeout(.seconds(30)) {
    try await longRunningOperation()
}

// With absolute deadline
let deadline = Date().addingTimeInterval(60)
let result = try await DeadlineTask.run(deadline: deadline) {
    try await fetchData()
}
```

### Async Channel

Go-style channels for producer-consumer patterns:

```swift
let channel = AsyncChannel<Int>(capacity: 10)

// Producer
Task {
    for i in 1...100 {
        await channel.send(i)
    }
    await channel.close()
}

// Consumer
for await value in channel {
    print("Received: \(value)")
}
```

### Thread-Safe Caching

```swift
let cache = CacheActor<String, User>(defaultTTL: .minutes(5))

// Get or compute
let user = await cache.getOrSet("user-123") {
    await fetchUserFromServer(id: "123")
}
```

### Semaphores

Limit concurrent access to resources:

```swift
let semaphore = AsyncSemaphore(value: 3)

await withTaskGroup(of: Void.self) { group in
    for url in urls {
        group.addTask {
            await semaphore.wait()
            defer { semaphore.signal() }
            await download(url)
        }
    }
}
```

### Batch Processing

Process large datasets in manageable batches:

```swift
let items = Array(1...10000)

let results = try await BatchTaskGroup.process(
    items,
    batchSize: 100,
    maxConcurrentBatches: 4
) { batch in
    await processBatch(batch)
}
```

### Task Scheduling

Schedule tasks for future execution:

```swift
let scheduler = TaskScheduler()

// One-time delayed task
await scheduler.schedule(after: .seconds(30)) {
    print("Hello after 30 seconds!")
}

// Recurring task
await scheduler.scheduleRepeating(interval: .minutes(5)) {
    await refreshData()
}
```

### Priority Queue

Process items by priority:

```swift
let queue = AsyncPriorityQueue<Task>()

await queue.enqueue(lowPriorityTask, priority: 1)
await queue.enqueue(highPriorityTask, priority: 10)
await queue.enqueue(mediumTask, priority: 5)

// Dequeues in priority order: high, medium, low
while let task = await queue.tryDequeue() {
    await task.execute()
}
```

### Async Sequence Extensions

```swift
// Collect all elements
let items = try await stream.collect()

// Filter async
let filtered = someSequence.asyncFilter { await isValid($0) }

// Map async
let mapped = items.asyncMap { await transform($0) }

// Buffer for performance
let buffered = sequence.buffered(capacity: 100)
```

## API Reference

### Task Groups

| Type | Description |
|------|-------------|
| `concurrentMap` | Parallel map preserving order |
| `concurrentCompactMap` | Parallel compact map |
| `concurrentFilter` | Parallel filtering |
| `concurrentForEach` | Parallel iteration |
| `BatchTaskGroup` | Process items in batches |
| `ThrottledTaskGroup` | Limit concurrent operations |
| `OrderedTaskGroup` | Preserve result order |

### Retry Strategies

| Type | Description |
|------|-------------|
| `ExponentialBackoff` | Exponentially increasing delays |
| `LinearBackoff` | Linearly increasing delays |
| `ConstantBackoff` | Fixed delay between retries |
| `FibonacciBackoff` | Fibonacci sequence delays |
| `RetryPolicy` | Configurable retry policy |
| `RetryableTask` | Self-retrying task wrapper |

### Synchronization

| Type | Description |
|------|-------------|
| `AsyncSemaphore` | Counting semaphore |
| `BinarySemaphore` | Mutex (binary semaphore) |
| `AsyncBarrier` | Wait for all tasks |
| `CyclicBarrier` | Reusable barrier |
| `Phaser` | Dynamic party registration |

### Actors

| Type | Description |
|------|-------------|
| `CacheActor` | Thread-safe caching with TTL |
| `DatabaseActor` | Serialized DB operations |
| `NetworkActor` | Network request management |

### Scheduling

| Type | Description |
|------|-------------|
| `TaskScheduler` | Schedule delayed/recurring tasks |
| `AsyncPriorityQueue` | Priority-based task queue |
| `DelayedTask` | Cancellable delayed execution |
| `DebouncedTask` | Debounce rapid calls |
| `ThrottledTask` | Rate-limit execution |

### Testing

| Type | Description |
|------|-------------|
| `TestScheduler` | Deterministic virtual time |
| `TestClock` | Controllable clock for tests |
| `MockActor` | Mock actor for verifications |

## Architecture

```
SwiftConcurrency/
├── TaskGroup/
│   ├── ConcurrentMap.swift
│   ├── ThrottledTaskGroup.swift
│   ├── OrderedTaskGroup.swift
│   └── BatchTaskGroup.swift
├── Async/
│   ├── AsyncChannel.swift
│   ├── AsyncOperation.swift
│   ├── AsyncThrottler.swift
│   ├── AsyncSemaphore.swift
│   └── AsyncBarrier.swift
├── Actors/
│   ├── CacheActor.swift
│   ├── DatabaseActor.swift
│   ├── NetworkActor.swift
│   └── SerialExecutor.swift
├── Stream/
│   ├── BufferedAsyncSequence.swift
│   ├── MergedAsyncSequence.swift
│   ├── FilteredAsyncSequence.swift
│   └── MappedAsyncSequence.swift
├── Timeout/
│   ├── TaskTimeout.swift
│   ├── DeadlineTask.swift
│   └── CancellationHandler.swift
├── Retry/
│   ├── RetryPolicy.swift
│   ├── ExponentialBackoff.swift
│   ├── LinearBackoff.swift
│   └── RetryableTask.swift
├── Scheduling/
│   ├── TaskScheduler.swift
│   ├── PriorityQueue.swift
│   └── DelayedTask.swift
├── Extensions/
│   ├── Task+Extensions.swift
│   ├── AsyncSequence+Extensions.swift
│   └── Result+Async.swift
└── Testing/
    ├── TestScheduler.swift
    └── MockActor.swift
```

## Requirements

- Swift 6.0+
- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 9.0+
- Xcode 16.0+

## Thread Safety

All types in this library are designed to be `Sendable` and safe for use in
concurrent contexts. Actor-based types provide isolated state, while value
types ensure safe passing across concurrency boundaries.

## Best Practices

### Do

- Use `maxConcurrency` to prevent resource exhaustion
- Handle cancellation cooperatively with `Task.checkCancellation()`
- Use appropriate backoff strategies for retries
- Prefer `TaskGroup` over manual task management
- Use actors for shared mutable state

### Don't

- Create unbounded concurrent operations
- Ignore cancellation in long-running tasks
- Use tight retry loops without backoff
- Mix async/await with completion handlers unnecessarily

## Performance

- Zero-overhead abstractions where possible
- Efficient heap-based priority queue implementation
- Lock-free implementations using Swift concurrency primitives
- Memory-efficient buffered sequences

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Muhittin Camdali

---

Made with ❤️ for the Swift community
