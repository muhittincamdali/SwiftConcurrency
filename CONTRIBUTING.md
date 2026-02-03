# Contributing to SwiftConcurrency

Thank you for your interest in contributing! 🚀

## Prerequisites

- Swift 5.9+
- Understanding of Swift Concurrency (async/await, actors, structured concurrency)

## Development Setup

```bash
git clone https://github.com/muhittincamdali/SwiftConcurrency.git
cd SwiftConcurrency
open Package.swift
```

## Adding New Utilities

### 1. Choose the Right Module

- `Tasks/` - Task management utilities
- `Sequences/` - Async sequence operators
- `Actors/` - Actor-based utilities
- `Utilities/` - General helpers

### 2. Follow Concurrency Best Practices

```swift
// ✅ Good: Sendable conformance
public struct ThrottledTask<T: Sendable>: Sendable {
    // ...
}

// ✅ Good: Actor isolation
public actor AsyncCache<Key: Hashable & Sendable, Value: Sendable> {
    // ...
}

// ✅ Good: Proper cancellation handling
public func execute() async throws -> T {
    try Task.checkCancellation()
    // ...
}
```

### 3. Add Documentation

```swift
/// Executes a task with automatic retry on failure.
///
/// ## Example
///
/// ```swift
/// let result = try await RetryTask(maxAttempts: 3) {
///     try await fetchData()
/// }.execute()
/// ```
///
/// - Parameter maxAttempts: Maximum retry attempts.
/// - Returns: The task result.
/// - Throws: The last error if all retries fail.
```

### 4. Add Tests

```swift
final class RetryTaskTests: XCTestCase {
    func testSucceedsOnFirstAttempt() async throws {
        let task = RetryTask(maxAttempts: 3) {
            return "success"
        }
        
        let result = try await task.execute()
        XCTAssertEqual(result, "success")
    }
    
    func testRetriesOnFailure() async throws {
        var attempts = 0
        let task = RetryTask(maxAttempts: 3) {
            attempts += 1
            if attempts < 3 {
                throw TestError()
            }
            return "success"
        }
        
        let result = try await task.execute()
        XCTAssertEqual(attempts, 3)
    }
}
```

## Pull Request Checklist

- [ ] Code is Sendable-compliant
- [ ] Cancellation is handled properly
- [ ] No data races (verified with Thread Sanitizer)
- [ ] Documentation includes examples
- [ ] Tests cover success, failure, and cancellation cases
- [ ] CHANGELOG updated

## Testing for Data Races

```bash
swift test --sanitize=thread
```

Thank you for contributing! 🙏
