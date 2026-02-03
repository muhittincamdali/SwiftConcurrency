<div align="center">

# ⚡ SwiftConcurrency

**Swift 6 concurrency utilities - async sequences, task management & more**

[![Swift](https://img.shields.io/badge/Swift-6.0+-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-Compatible-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## ✨ Features

- ⚡ **Swift 6 Ready** — Full strict concurrency mode
- 🔄 **Async Sequences** — Enhanced iteration utilities
- 📊 **Task Groups** — Simplified parallel execution
- 🎯 **Cancellation** — Cooperative cancellation helpers
- 🔒 **Thread Safety** — Actor-based utilities

---

## 🚀 Quick Start

```swift
import SwiftConcurrency

// Parallel execution
let results = await [url1, url2, url3].concurrentMap { url in
    try await fetchData(from: url)
}

// Debounced async
let debounced = search.debounced(for: .milliseconds(300))

// Task with timeout
try await withTimeout(.seconds(5)) {
    await longRunningTask()
}
```

---

## 📄 License

MIT • [@muhittincamdali](https://github.com/muhittincamdali)
