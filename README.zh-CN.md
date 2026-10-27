<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="CI 状态"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="最新版本: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="支持的平台: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="语言版本: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="许可证: MIT"></picture></a>
</p>

<p align="center">
<a href="#快速开始"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-zh-CN-light.svg" alt="开始使用"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-zh-CN-light.svg" alt="文档"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-zh-CN-light.svg" alt="示例"></picture></a>
</p>

> 本文是英文 README 的译文。如两者内容不一致，以英文版为准。

<!-- brand:end -->

SwiftConcurrency 是一个小巧的 Swift 6 包，用来解决围绕 `async`/`await` 的日常问题，这些问题标准库留给了每个应用自行处理：同时下载的文件不超过四个、避免两次保存互相重叠、请求十秒后放弃、带退避地重试、只在用户停止输入后才搜索、三个页面请求同一份数据时只发送一次请求，以及不再调用已经宕机的服务器。每个问题都有对应的一个类型或函数；它们全部是 `Sendable`，在任务被取消时结束等待，并且接受一个 `Clock`，因此测试可以直接推进时间，而不必真的等待。它没有任何依赖。

## 亮点

- **顺序与限制** — `TaskQueue` 按添加顺序运行异步操作，可以一次一个，也可以最多同时运行你选定的数量；`AsyncSemaphore` 和 `concurrentMap(maxConcurrency:)` 用来限制同时运行的任务数量。
- **截止时间与重试** — `withTimeout`、`withDeadline`，以及支持固定、线性或指数 `Backoff` 和抖动（jitter）的 `retry`；延迟在转换为 `Duration` 之前就已被限制上限，因此任何重试次数或倍数都不会溢出。
- **面向 UI 代码的速率控制** — 用于搜索框的 `Debouncer`，以及用于滚动和拖动处理的 `Throttler`（支持首次和末次执行）；它们都是普通对象，可直接在 view model 中调用。
- **快速失败，共享工作** — `CircuitBreaker` 会停止调用持续失败的服务；当许多调用方同时请求同一个键时，`SingleFlight` 只发送一次请求。
- **处处支持取消** — 包中的每一次等待都会在其任务被取消时立即结束；被取消的等待者不会占用许可，不会运行其操作，也不会在内存中留下任何东西。
- **无需等待的测试** — `TestClock` 和 `waitForSleepers()` 让测试可以在自己选定的那一行结束 30 秒的退避，并且每次运行的结果都相同。

## 快速开始

**1. 添加软件包**

在 Xcode 中选择 **File › Add Package Dependencies…**，然后输入仓库地址：

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. 导入模块**

```swift
import SwiftConcurrency
```

**3. 开始使用**

一次加载大量用户资料，每次并发四个请求，每个请求有 10 秒超时，并使用指数退避最多尝试三次
（[ReadmeSamples.swift](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)）：

```swift
func loadProfiles(ids: [Int], from api: some ProfileAPI) async throws -> [Profile] {
    try await ids.concurrentMap(maxConcurrency: 4) { id in
        try await retry(maxAttempts: 3, backoff: .exponential().jittered(.full)) { _ in
            try await withTimeout(.seconds(10)) {
                try await api.profile(id: id)
            }
        }
    }
}
```

`ProfileAPI` 代表你的网络层代码：任何带有异步 `profile(id:)` 方法的 `Sendable` 类型。结果按 `ids` 的顺序返回。如果某个请求在三次尝试后仍然失败，它的错误会原样抛出，仍在运行的其他请求会被取消。

## 安装

### Swift Package Manager

在 Xcode 中选择 **File › Add Package Dependencies…**，然后输入仓库地址：

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

或者将其添加到 `Package.swift` 的 `dependencies` 中：

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftConcurrency.git", branch: "main")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "SwiftConcurrency", package: "SwiftConcurrency")
    ])
]
```

## 使用方法

下面的示例复制自
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)，示例应用会编译它，测试套件会运行它。

### 边输入边搜索

`Debouncer` 会在用户停止输入 300 毫秒后运行搜索。每一次新的按键都会替换正在等待的搜索。

```swift
@MainActor
final class SearchController {
    private(set) var results: [String] = []
    private(set) var searchCount = 0
    private let debouncer: Debouncer
    private let search: @Sendable (String) async -> [String]

    init(
        clock: some Clock<Duration> = ContinuousClock(),
        search: @escaping @Sendable (String) async -> [String]
    ) {
        self.debouncer = Debouncer(for: .milliseconds(300), clock: clock)
        self.search = search
    }

    func queryChanged(_ query: String) {
        debouncer.submit { [search] in
            let results = await search(query)
            await self.show(results)
        }
    }

    private func show(_ results: [String]) {
        self.results = results
        searchCount += 1
    }
}
```

### 避免保存操作重叠

actor 会在上一次调用还在等待时让下一次调用开始。`TaskQueue` 不会：在默认限制 1 下，每次写入都会在上一次完成之后开始，顺序与 `save` 的调用顺序一致。

```swift
final class Autosaver: Sendable {
    private let queue = TaskQueue()
    private let write: @Sendable (String) async throws -> Void

    init(write: @escaping @Sendable (String) async throws -> Void) {
        self.write = write
    }

    func save(_ text: String) {
        queue.addOperation { [write] in
            try await write(text)
        }
    }

    func waitForPendingSaves() async throws {
        try await queue.waitUntilIdle()
    }
}
```

`TaskQueue(maxConcurrentOperations: 4)` 最多同时运行四个操作，并且仍然按顺序启动它们。

### 为多个调用方只发送一次请求

`SingleFlight` 会共享某个用户资料上已在运行的请求，而 `CircuitBreaker` 会在连续五次失败后的 30 秒内拒绝调用。

```swift
final class ProfileLoader: Sendable {
    private let api: any ProfileAPI
    let inFlight = SingleFlight<Int, Profile>()
    private let breaker: CircuitBreaker

    init(api: any ProfileAPI, clock: some Clock<Duration> = ContinuousClock()) {
        self.api = api
        self.breaker = CircuitBreaker(failureThreshold: 5, resetTimeout: .seconds(30), clock: clock)
    }

    func profile(id: Int) async throws -> Profile {
        try await inFlight.value(for: id) { [api, breaker] in
            try await breaker.run {
                try await api.profile(id: id)
            }
        }
    }
}
```

### 无需等待即可测试

传入一个 `TestClock`，等到代码进入休眠，然后自己推进时间。下面这个来自
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) 的测试输入四个字母，并检查只搜索了最后一次查询：

```swift
let clock = TestClock()
let searched = Recorder<String>()
let controller = SearchController(clock: clock) { query in
    await searched.append(query)
    return ["\(query) result"]
}
for query in ["t", "ta", "tas", "task"] {
    controller.queryChanged(query)
}
try await clock.waitForSleepers()
clock.advance(by: .milliseconds(300))
#expect(await searched.wait(forCount: 1) == ["task"])
```

`Recorder` 是测试 target 中的一个小型 actor，用来收集值并等待它们。

## 演示

[ConcurrencyDemo](Examples/ConcurrencyDemo) 应用使用真实的库运行每一个工具。截图来自 iOS 27 模拟器上的该应用，由
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) 捕获：

| 防抖搜索 | 下载队列（限制 2） | 重试与熔断器 |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="搜索界面：四次按键，一次搜索，显示“task”的结果"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="下载队列：六个文件的时间线，最多同时有两个重叠"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="重试日志：三个请求在三次尝试后失败，随后熔断器打开并拒绝了两个请求"></picture> |

要运行它，请使用 Xcode 26 或更高版本打开 [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) 中的 `ConcurrencyDemo.xcodeproj`，选择一个 iPhone 模拟器或 **My Mac**，然后点击 **Run**。
[Examples/README.md](Examples/README.md) 介绍了每个界面。

## 文档

API 参考文档与文章：

- [SwiftConcurrency 参考文档](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [入门指南](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [测试与时间相关的代码](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [取消与限制](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## 指南

- [入门指南](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — 哪种类型解决哪个问题，每种都附有示例。
- [测试与时间相关的代码](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — `TestClock` 的工作流程：创建、等待休眠者、推进时间。
- [取消与限制](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — 每个 API 在任务被取消时的行为、它拒绝的输入，以及它如何限制内存占用。

## 系统要求

| 平台 | 最低版本 |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| 工具链 | Swift 6.2 · Xcode 26+ |

## 架构

该包是一个模块 `SwiftConcurrency`，按问题分组：

| 文件夹 | 类型 |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked`（一种 unfair lock）、`WaiterQueue`（挂起调用方的 FIFO 队列）、`ElapsedClock` |

设计决策：

- **使用带锁的类，而不是 actor。** `signal()`、`cancel()`、`submit(_:)` 和 `advance(by:)` 在返回之前就已生效，因此可以在同步代码、`defer` 以及测试中调用，而不需要会让其他任务在中间插入执行的 `await`。
- **挂起的调用方是 `WaiterQueue` 中的 continuation。** 取消处理程序在登记该条目的同一把锁下移除自己的条目，因此不会有等待者丢失或被恢复两次。
- **操作尽可能在调用方的 actor 上运行。** `retry`、`AsyncSemaphore.withPermit` 和 `CircuitBreaker.run` 是 `nonisolated(nonsending)`，因此你传入的闭包可以访问 main actor 状态，也不需要 `Sendable` 捕获。必须在另一个任务中运行的工作（`TaskQueue`、`SingleFlight`、`withTimeout`、`concurrentMap`）接受 `@Sendable` 闭包。
- **每个与时间相关的类型都接受一个 `Clock`。** 生产代码使用 `ContinuousClock`；测试传入 `TestClock`。

### 它的定位

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) 涵盖 `AsyncSequence` 上的操作符（`debounce`、`throttle`、`merge`、`zip`、`AsyncChannel`）；如果你的数据本来就以序列的形式到达，请使用它。SwiftConcurrency 涵盖由调用启动的工作：限制、队列、截止时间、重试、对方法调用做防抖、熔断以及共享请求。这两个包可以并行使用。

## 路线图

- Linux 支持：用标准库的 `Mutex` 替换 `OSAllocatedUnfairLock`，这需要把 Apple 平台的最低版本提高到 iOS 18 和 macOS 15。
- 为允许每秒一定数量请求的 API 提供令牌桶（token-bucket）限流器。
- 为 `TaskQueue` 增加优先级选项，使紧急操作可以先于较早的操作开始。

## 参与贡献

欢迎参与贡献。提交 pull request 之前，请先阅读[贡献指南](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md)和[行为准则](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md)。如发现安全问题，请按照[安全策略](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md)私下报告。

## 许可证

基于 MIT 许可证发布。详见 [LICENSE](LICENSE)。
