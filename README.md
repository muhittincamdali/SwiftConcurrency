# SwiftConcurrency

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20|%20macOS%2013-blue.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-Compatible-green.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

A comprehensive toolkit for Swift structured concurrency. Provides production-ready utilities for task groups, async channels, retry policies, timeouts, throttling, and more.

---

## Features

| Feature | Description |
|---------|-------------|
| **ConcurrentMap** | Transform sequences concurrently with task groups |
| **ThrottledTaskGroup** | Limit max concurrent tasks to avoid resource exhaustion |
| **AsyncChannel** | Go-style typed channels for async communication |
| **AsyncThrottler** | Debounce and throttle async operations |
| **AsyncOperation** | Bridge `Operation` subclasses to async/await |
| **CacheActor** | Thread-safe in-memory cache powered by actors |
| **SerialExecutor** | Custom serial executor for actor isolation |
| **AsyncStreamBuilder** | Ergonomic async stream construction |
| **MergedAsyncSequence** | Merge multiple async sequences into one |
| **TaskTimeout** | Run async work with a deadline |
| **RetryPolicy** | Retry failed operations with exponential backoff |
| **Task+Extensions** | Handy extensions on `Task` |

---

## Requirements

- Swift 5.9+
- iOS 15+ / macOS 13+

---

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftConcurrency.git", from: "1.0.0")
]
```

Then add `"SwiftConcurrency"` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["SwiftConcurrency"]
)
```

### Xcode

1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL
3. Select version rules and add to your project

---

## Usage

### Concurrent Map

Transform a collection concurrently, preserving order:

```swift
import SwiftConcurrency

let urls: [URL] = [/* ... */]
let responses = try await urls.concurrentMap { url in
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

### Throttled Task Group

Run tasks with a concurrency limit:

```swift
let results = try await ThrottledTaskGroup.run(
    maxConcurrency: 4,
    tasks: urls
) { url in
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

### Async Channel

Communicate between tasks using typed channels:

```swift
let channel = AsyncChannel<String>(capacity: 5)

// Producer
Task {
    await channel.send("Hello")
    await channel.send("World")
    await channel.finish()
}

// Consumer
for await message in channel {
    print(message)
}
```

### Async Throttler

Debounce rapid calls:

```swift
let throttler = AsyncThrottler(interval: .milliseconds(300))

for query in searchQueries {
    await throttler.submit {
        await performSearch(query)
    }
}
```

### Cache Actor

Thread-safe caching:

```swift
let cache = CacheActor<String, Data>(maxCount: 100)

await cache.set("avatar", value: imageData)

if let cached = await cache.get("avatar") {
    displayImage(cached)
}
```

### Task Timeout

Run work with a deadline:

```swift
let result = try await withTimeout(.seconds(5)) {
    try await fetchRemoteConfig()
}
```

### Retry Policy

Retry with exponential backoff:

```swift
let data = try await RetryPolicy(
    maxAttempts: 3,
    initialDelay: .seconds(1),
    backoffMultiplier: 2.0
).execute {
    try await fetchData()
}
```

### Merged Async Sequence

Merge multiple streams:

```swift
let merged = MergedAsyncSequence(
    notifications.map { .notification($0) },
    messages.map { .message($0) }
)

for await event in merged {
    handle(event)
}
```

### Async Stream Builder

Build streams ergonomically:

```swift
let stream = AsyncStreamBuilder<Int>.build { yield in
    for i in 0..<10 {
        yield(i)
        try await Task.sleep(for: .milliseconds(100))
    }
}

for await value in stream {
    print(value)
}
```

### Bridge Operations to Async

```swift
let result = try await AsyncOperation.run(on: operationQueue) {
    // Heavy synchronous work
    processLargeDataset()
}
```

### Task Extensions

```swift
// Sleep with cancellation check
try await Task.sleepChecked(for: .seconds(2))

// Detached with priority
let handle = Task.detachedWithPriority(.high) {
    await heavyComputation()
}
```

---

## Architecture

```
SwiftConcurrency/
├── TaskGroup/
│   ├── ConcurrentMap         # Ordered concurrent transformations
│   └── ThrottledTaskGroup    # Bounded concurrency execution
├── Async/
│   ├── AsyncOperation        # Operation ↔ async bridge
│   ├── AsyncChannel          # Typed producer-consumer channel
│   └── AsyncThrottler        # Rate limiting for async work
├── Actors/
│   ├── SerialExecutor        # Custom serial executor
│   └── CacheActor            # Thread-safe cache
├── Stream/
│   ├── AsyncStreamBuilder    # Ergonomic stream creation
│   └── MergedAsyncSequence   # Multi-stream merging
├── Timeout/
│   └── TaskTimeout           # Deadline-based execution
├── Retry/
│   └── RetryPolicy           # Backoff retry strategy
└── Extensions/
    └── Task+Extensions       # Convenience helpers
```

---

## Thread Safety

All public types are `Sendable`. The library leverages Swift's structured concurrency model:

- **Actors** for mutable shared state (`CacheActor`)
- **Task groups** for parallel work (`ConcurrentMap`, `ThrottledTaskGroup`)
- **AsyncSequence** for streaming data (`AsyncChannel`, `MergedAsyncSequence`)
- **Cooperative cancellation** throughout

---

## Performance Notes

- `ThrottledTaskGroup` uses a semaphore-like pattern via actors to limit concurrency without blocking threads
- `CacheActor` evicts entries when exceeding `maxCount` using LRU ordering
- `MergedAsyncSequence` processes sources concurrently without buffering overhead
- All utilities respect task cancellation for prompt cleanup

---

## Contributing

1. Fork the repository
2. Create a feature branch (`feature/amazing-feature`)
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
