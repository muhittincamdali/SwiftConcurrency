# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.2.x   | :white_check_mark: |
| 1.1.x   | :white_check_mark: |
| < 1.1   | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities to: security@muhittincamdali.com

**Do NOT open public issues for security vulnerabilities.**

## Concurrency Security Considerations

SwiftConcurrency handles concurrent operations. Security considerations include:

### Data Races
- All types are designed to be Sendable-compliant
- Actor isolation prevents data races
- Regular testing with Thread Sanitizer

### Deadlocks
- Async/await prevents traditional deadlocks
- Semaphore usage documented for proper handling

### Resource Exhaustion
- Rate limiting utilities prevent DoS
- Configurable limits on concurrent operations

## Best Practices

```swift
// ✅ Safe: Using actor for shared state
actor Counter {
    private var value = 0
    func increment() { value += 1 }
}

// ❌ Unsafe: Shared mutable state
class Counter {
    var value = 0 // Data race!
    func increment() { value += 1 }
}
```

Thank you for helping keep SwiftConcurrency secure! 🛡️
