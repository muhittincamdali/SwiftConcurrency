# SwiftConcurrency API Documentation

## Task Management

### RetryTask

Executes a task with automatic retry on failure.

```swift
let result = try await RetryTask(
    maxAttempts: 3,
    delay: .seconds(1),
    backoff: .exponential(multiplier: 2)
) {
    try await fetchData()
}.execute()
```

### ThrottledTask

Limits execution rate.

```swift
let throttled = ThrottledTask(interval: .seconds(1))
for item in items {
    await throttled.execute {
        try await process(item)
    }
}
```

### DebouncedTask

Debounces rapid executions.

```swift
let debounced = DebouncedTask(delay: .milliseconds(300))
for keystroke in keystrokes {
    await debounced.execute {
        await search(query)
    }
}
// Only the last execution runs
```

### TimeoutTask

Adds timeout to any async operation.

```swift
let result = try await TimeoutTask(
    timeout: .seconds(10)
) {
    try await longRunningOperation()
}.execute()
```

## Async Sequences

### AsyncThrottleSequence

```swift
let throttled = numbers.throttle(for: .seconds(1))
for await number in throttled {
    print(number) // At most once per second
}
```

### AsyncDebounceSequence

```swift
let debounced = searchQueries.debounce(for: .milliseconds(300))
for await query in debounced {
    await performSearch(query)
}
```

### AsyncMergeSequence

```swift
let merged = merge(stream1, stream2, stream3)
for await value in merged {
    process(value) // From any stream
}
```

### AsyncBufferSequence

```swift
let buffered = fastProducer.buffer(
    policy: .bounded(10),
    overflow: .dropOldest
)
for await batch in buffered.chunks(of: 5) {
    process(batch)
}
```

## Actors

### AsyncCache

Thread-safe cache with TTL.

```swift
let cache = AsyncCache<String, Data>(ttl: .minutes(5))

// Get or fetch
let data = await cache.get("key") {
    try await fetchFromNetwork()
}
```

### AsyncQueue

FIFO task execution.

```swift
let queue = AsyncQueue(maxConcurrent: 3)

for task in tasks {
    await queue.enqueue {
        try await execute(task)
    }
}
```

### AsyncSemaphore

Limits concurrent access.

```swift
let semaphore = AsyncSemaphore(limit: 5)

await semaphore.wait()
defer { semaphore.signal() }
try await useResource()
```

### AsyncBarrier

Synchronization barrier.

```swift
let barrier = AsyncBarrier(count: 5)

// In each of 5 tasks:
await barrier.wait() // Blocks until all 5 reach here
// All proceed together
```

## Utilities

### MainActor Helpers

```swift
// Run on main actor
await MainActor.run {
    updateUI()
}

// Assert main actor
MainActor.assertIsolated()
```

### Task Extensions

```swift
// Sleep with Duration
try await Task.sleep(for: .seconds(1))

// Check cancellation
try Task.checkCancellation()

// With cancellation handler
try await withTaskCancellationHandler {
    try await longOperation()
} onCancel: {
    cleanup()
}
```

### Async Property Wrapper

```swift
@AsyncProperty var user: User?

// Automatically published on main actor
await $user.assign(fetchedUser)
```

## Full API Reference

| Type | Category | Description |
|------|----------|-------------|
| RetryTask | Task | Retry with backoff |
| ThrottledTask | Task | Rate limiting |
| DebouncedTask | Task | Debouncing |
| TimeoutTask | Task | Timeout handling |
| AsyncThrottleSequence | Sequence | Throttle elements |
| AsyncDebounceSequence | Sequence | Debounce elements |
| AsyncMergeSequence | Sequence | Merge streams |
| AsyncZipSequence | Sequence | Pair elements |
| AsyncBufferSequence | Sequence | Buffer with overflow |
| AsyncCache | Actor | Thread-safe cache |
| AsyncQueue | Actor | Task queue |
| AsyncSemaphore | Actor | Resource limiting |
| AsyncBarrier | Actor | Synchronization |
