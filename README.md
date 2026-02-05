<h1 align="center">SwiftConcurrency</h1>

<p align="center">
  <strong>⚡ Comprehensive Swift concurrency utilities - async sequences, task management, debugging & more</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift"/>
  <img src="https://img.shields.io/badge/iOS-15.0+-blue.svg" alt="iOS"/>
  <img src="https://img.shields.io/badge/macOS-13.0+-purple.svg" alt="macOS"/>
  <img src="https://img.shields.io/badge/SPM-compatible-green.svg" alt="SPM"/>
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License"/>
</p>

---

## 🚀 Features

| Category | Features |
|----------|----------|
| 📊 **AsyncSequence+** | debounce, throttle, flatMap, compactMap, merge, zip, buffer |
| ⏱️ **Rate Limiting** | Debouncer, Throttler, Semaphore |
| 🔄 **Retry Logic** | Exponential backoff, linear backoff, custom policies |
| 🏊 **Task Pools** | TaskPool, DynamicTaskPool, WorkStealingPool |
| 🎭 **Actors** | StateActor, CacheActor, DatabaseActor, NetworkActor |
| 🔐 **Synchronization** | AsyncLock, AsyncBarrier, AsyncCondition, AsyncLatch |
| 🧪 **Testing** | TestScheduler, TestClock, AsyncExpectation, AsyncMock |
| 🐛 **Debugging** | AsyncDebugger, PerformanceProfiler, DeadlockDetector |
| 📦 **Sendable Helpers** | SendableValue, SendableArray, SendableDictionary, AtomicCounter |

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftConcurrency.git", from: "1.0.0")
]
```

## 🎯 Quick Start

### Debounce Search Queries

```swift
import SwiftConcurrency

// Debounce user input
for await query in searchInput.debounce(for: .milliseconds(300)) {
    await performSearch(query)
}

// Throttle location updates
for await location in locationStream.throttle(for: .seconds(1)) {
    updateMap(location)
}
```

### Retry with Backoff

```swift
// Retry API calls with exponential backoff
let data = try await withRetry(
    maxAttempts: 3,
    backoff: .exponential(initial: .seconds(1), multiplier: 2)
) {
    try await api.fetchData()
}
```

### Task Pool

```swift
// Process items with a pool of workers
let pool = TaskPool<URL, Data>(workers: 4) { url in
    try await URLSession.shared.data(from: url).0
}

await pool.start()
let results = try await pool.submitBatch(urls)
await pool.shutdown()
```

### Actor-Based State

```swift
// Thread-safe state management
let store = StateActor(initialState: AppState())

// Subscribe to changes
for await state in await store.subscribe() {
    updateUI(state)
}

// Update state
await store.update { state in
    state.count += 1
}
```

### Concurrent Map

```swift
// Process items concurrently with limit
let results = try await items.concurrentMap(maxConcurrency: 4) { item in
    await process(item)
}
```

## 🔧 Advanced Usage

### Synchronization Primitives

```swift
// Semaphore - limit concurrent operations
let semaphore = AsyncSemaphore(value: 3)

await withTaskGroup(of: Void.self) { group in
    for url in urls {
        group.addTask {
            await semaphore.wait()
            defer { await semaphore.signal() }
            await download(url)
        }
    }
}

// Barrier - synchronization point
let barrier = AsyncBarrier(count: 4)

await withTaskGroup(of: Void.self) { group in
    for worker in 0..<4 {
        group.addTask {
            await doWork(worker)
            await barrier.arrive()  // Wait for all workers
            await doMoreWork(worker)
        }
    }
}
```

### Debugging & Profiling

```swift
// Debug async operations
let debugger = AsyncDebugger(subsystem: "com.app", category: "network")

let result = try await debugger.trace("API call") {
    try await api.fetchData()
}

// Profile performance
let profiler = PerformanceProfiler()

let data = try await profiler.measure("Database query") {
    try await db.query()
}

print(await profiler.report())

// Detect deadlocks
let detector = DeadlockDetector(threshold: .seconds(30))
detector.start()

try await detector.monitor("Critical operation") {
    try await criticalWork()
}
```

### Testing Utilities

```swift
// Test async code with controlled time
let scheduler = TestScheduler()

var executed = false
scheduler.schedule(after: .seconds(10)) {
    executed = true
}

await scheduler.advance(by: .seconds(10))
XCTAssertTrue(executed)

// Async expectations
let expectation = AsyncExpectation(description: "Data loaded")

Task {
    await loadData()
    await expectation.fulfill()
}

try await expectation.wait(timeout: .seconds(5))

// Mock async functions
let mock = AsyncMock<Int, String> { input in
    "\(input * 2)"
}

let result = try await mock(5)  // "10"
let calls = await mock.calls    // [5]
```

### Sendable Helpers

```swift
// Thread-safe value
let counter = SendableValue(0)
await counter.update { $0 += 1 }
let count = await counter.get()

// Thread-safe dictionary
let cache = SendableDictionary<String, Data>()
await cache.set("key", to: data)
let cached = await cache.get("key")

// Atomic counter
let atomic = AtomicCounter()
await atomic.increment()
await atomic.add(10)
```

## 📚 Full API Documentation

### AsyncSequence Operators

| Operator | Description |
|----------|-------------|
| `debounce(for:)` | Emit only after quiet period |
| `throttle(for:)` | Limit emission rate |
| `flatMap(_:)` | Transform and flatten sequences |
| `compactMap(_:)` | Transform and filter nil |
| `collect()` | Collect all elements into array |
| `count()` | Count elements |

### Task Management

| Type | Description |
|------|-------------|
| `TaskPool` | Reusable pool of workers |
| `DynamicTaskPool` | Auto-scaling worker pool |
| `WorkStealingPool` | Load-balanced work distribution |
| `TaskQueue` | Priority-based task queue |

### Actors

| Actor | Description |
|-------|-------------|
| `StateActor` | State with subscriptions & history |
| `CacheActor` | Thread-safe caching |
| `DatabaseActor` | Serialized database access |
| `NetworkActor` | Network request management |

## 🧪 Requirements

- Swift 5.9+
- iOS 15.0+ / macOS 13.0+
- Xcode 15.0+

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

<p align="center">
  Made with ❤️ for the Swift community
</p>

<a href="https://star-history.com/#muhittincamdali/SwiftConcurrency&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/SwiftConcurrency&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/SwiftConcurrency&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muhittincamdali/SwiftConcurrency&type=Date" />
 </picture>
</a>
