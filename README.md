<p align="center">
  <img src="Assets/logo.png" alt="SwiftConcurrency" width="200"/>
</p>

<h1 align="center">SwiftConcurrency</h1>

<p align="center">
  <strong>⚡ Swift 6 concurrency utilities - async sequences, task management & more</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift"/>
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS"/>
</p>

---

## Features

| Feature | Description |
|---------|-------------|
| 📊 **AsyncSequence+** | Additional operators |
| ⏱️ **Debounce/Throttle** | Rate limiting |
| 🔄 **Retry** | Automatic retry logic |
| 🚦 **Semaphore** | Concurrency limiting |
| ⏰ **Timeout** | Task timeouts |
| 🔗 **TaskGroup+** | Enhanced task groups |

## Async Sequences

```swift
import SwiftConcurrency

// Debounce
searchQuery.debounce(for: .milliseconds(300))

// Throttle
locationUpdates.throttle(for: .seconds(1))

// Retry
try await api.fetch().retry(maxAttempts: 3, delay: .seconds(1))

// Timeout
try await api.fetch().timeout(after: .seconds(10))
```

## Task Management

```swift
// Cancellable task
let task = CancellableTask {
    await longRunningWork()
}
task.cancel()

// Task with progress
let task = ProgressTask { progress in
    for i in 0..<100 {
        progress.update(Double(i) / 100)
        await doWork()
    }
}

// Concurrent limit
let semaphore = AsyncSemaphore(limit: 3)
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

## Operators

```swift
// Merge streams
merge(stream1, stream2, stream3)

// Combine latest
combineLatest(users, settings) { users, settings in
    // Both available
}

// Zip
zip(stream1, stream2)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License

---

## 📈 Star History

<a href="https://star-history.com/#muhittincamdali/SwiftConcurrency&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/SwiftConcurrency&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/SwiftConcurrency&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muhittincamdali/SwiftConcurrency&type=Date" />
 </picture>
</a>
