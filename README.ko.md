<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="CI 상태"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="최신 버전: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="지원 플랫폼: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="언어 버전: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="라이선스: MIT"></picture></a>
</p>

<p align="center">
<a href="#빠른-시작"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ko-light.svg" alt="시작하기"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ko-light.svg" alt="문서"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ko-light.svg" alt="예제"></picture></a>
</p>

> 이 문서는 영어 README의 번역본입니다. 내용이 다를 경우 영어 버전이 최신입니다.

<!-- brand:end -->

SwiftConcurrency는 `async`/`await`를 둘러싼 일상적인 문제를 해결하는 작은 Swift 6 패키지입니다. 표준 라이브러리는 이런 문제를 각 앱에 맡겨 둡니다. 파일을 한 번에 네 개까지만 내려받기, 두 저장 작업이 겹치지 않게 하기, 요청을 열 초 뒤에 포기하기, 백오프를 적용해 재시도하기, 사용자가 입력을 멈춘 뒤에만 검색하기, 세 화면이 같은 데이터를 요청해도 요청을 하나만 보내기, 다운된 서버 호출 중단하기가 그 예입니다. 문제마다 타입 또는 함수가 하나씩 있으며, 모두 `Sendable`이고, 작업이 취소되면 대기를 끝내며, `Clock`을 받기 때문에 테스트에서 시간을 기다리지 않고 직접 움직일 수 있습니다. 의존성은 없습니다.

## 주요 기능

- **순서와 제한** — `TaskQueue`는 비동기 작업을 추가된 순서대로, 한 번에 하나씩 또는 지정한 한도까지 실행합니다. `AsyncSemaphore`와 `concurrentMap(maxConcurrency:)`는 동시에 실행되는 양을 제한합니다.
- **데드라인과 재시도** — `withTimeout`, `withDeadline`, 그리고 고정, 선형, 지수 `Backoff`와 지터를 지원하는 `retry`. 지연 시간은 `Duration`이 되기 전에 상한이 적용되므로 재시도 횟수나 배수가 아무리 커도 오버플로가 일어나지 않습니다.
- **UI 코드를 위한 속도 제어** — 검색 필드를 위한 `Debouncer`와 스크롤·드래그 핸들러를 위한 `Throttler`(처음과 마지막 실행 지원). 둘 다 view model에서 바로 호출하는 단순한 객체입니다.
- **빠른 실패, 작업 공유** — `CircuitBreaker`는 계속 실패하는 서비스의 호출을 멈추고, `SingleFlight`는 여러 호출자가 동시에 같은 키를 요청하면 요청을 하나만 보냅니다.
- **어디서나 취소 지원** — 패키지의 모든 대기는 해당 작업이 취소되면 즉시 끝납니다. 취소된 대기자는 퍼밋을 가져가지 않고, 작업을 실행하지 않으며, 메모리에도 아무것도 남기지 않습니다.
- **기다리지 않는 테스트** — `TestClock`과 `waitForSleepers()`를 사용하면 테스트가 30초짜리 백오프를 원하는 줄에서 끝낼 수 있으며, 매번 같은 결과가 나옵니다.

## 빠른 시작

**1. 패키지 추가**

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. 모듈 가져오기**

```swift
import SwiftConcurrency
```

**3. 사용하기**

많은 프로필을 한 번에 네 개의 요청씩 불러옵니다. 각 요청에는 10초 타임아웃이 있고 지수 백오프로 최대 세 번 시도합니다
([ReadmeSamples.swift](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)).

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

`ProfileAPI`는 여러분의 네트워크 코드를 가리킵니다. 비동기 `profile(id:)` 메서드를 가진 모든 `Sendable` 타입이 해당합니다. 결과는 `ids` 순서대로 돌아옵니다. 요청이 세 번 시도한 뒤에도 실패하면 그 오류가 그대로 던져지고, 아직 실행 중인 요청은 취소됩니다.

## 설치

### Swift Package Manager

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

또는 `Package.swift`의 `dependencies`에 추가하세요.

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

## 사용법

아래 샘플은 예제 앱이 빌드하고 테스트 스위트가 실행하는
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)에서 가져왔습니다.

### 입력하는 대로 검색

`Debouncer`는 사용자가 300ms 동안 입력을 멈추면 검색을 실행합니다. 새로 키를 누를 때마다 대기 중인 검색이 대체됩니다.

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

### 저장 작업이 겹치지 않게 하기

actor는 이전 호출이 대기하는 동안 다음 호출이 시작되도록 허용합니다. `TaskQueue`는 그렇지 않습니다. 기본 한도인 1에서는 각 쓰기가 이전 쓰기가 끝난 뒤에, `save`를 호출한 순서대로 시작됩니다.

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

`TaskQueue(maxConcurrentOperations: 4)`는 최대 네 개의 작업을 동시에 실행하면서도 순서대로 시작합니다.

### 여러 호출자에게 요청 하나만 보내기

`SingleFlight`는 어떤 프로필에 대해 이미 실행 중인 요청을 공유하고, `CircuitBreaker`는 연속 다섯 번 실패한 뒤 30초 동안 호출을 거부합니다.

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

### 기다리지 않고 테스트하기

`TestClock`을 전달하고, 코드가 sleep 상태가 될 때까지 기다린 다음, 직접 시간을 움직입니다.
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift)의 이 테스트는 글자 네 개를 입력하고 마지막 쿼리만 검색되는지 확인합니다.

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

`Recorder`는 테스트 타깃에 있는 작은 actor로, 값을 모으고 그 값을 기다립니다.

## 데모

[ConcurrencyDemo](Examples/ConcurrencyDemo) 앱은 실제 라이브러리로 각 도구를 실행합니다. 스크린샷은 iOS 27 시뮬레이터에서 앱을 실행해
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh)로 캡처한 것입니다.

| 디바운스 검색 | 다운로드 큐(한도 2) | 재시도와 서킷 브레이커 |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="검색 화면: 키 입력 네 번, 검색 한 번, “task” 결과"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="다운로드 큐: 최대 두 개까지만 겹치는 여섯 개 파일의 타임라인"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="재시도 로그: 요청 세 개가 세 번 시도한 뒤 실패하고, 열린 회로가 두 개를 거부함"></picture> |

실행하려면 [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo)의 `ConcurrencyDemo.xcodeproj`를 Xcode 26 이상으로 열고, iPhone 시뮬레이터 또는 **My Mac**을 선택한 뒤 **Run**을 누르세요.
각 화면은 [Examples/README.md](Examples/README.md)에서 설명합니다.

## 문서

API 레퍼런스와 문서:

- [SwiftConcurrency 레퍼런스](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [시작하기](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [시간 기반 코드 테스트하기](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [취소와 제한](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## 가이드

- [시작하기](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — 어떤 타입이 어떤 문제를 해결하는지, 각각의 샘플과 함께 설명합니다.
- [시간 기반 코드 테스트하기](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — `TestClock` 워크플로: 생성, sleep 대기, 시간 진행.
- [취소와 제한](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — 작업이 취소될 때 각 API가 하는 일, 거부하는 입력, 메모리를 제한하는 방법.

## 요구 사항

| 플랫폼 | 최소 버전 |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| 툴체인 | Swift 6.2 · Xcode 26+ |

## 아키텍처

이 패키지는 `SwiftConcurrency`라는 하나의 모듈이며, 문제별로 묶여 있습니다.

| 폴더 | 타입 |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked`(unfair lock), `WaiterQueue`(일시 중단된 호출자의 FIFO), `ElapsedClock` |

설계 결정:

- **actor가 아니라 락을 쓰는 클래스.** `signal()`, `cancel()`, `submit(_:)`, `advance(by:)`는 반환되기 전에 효과가 나타나므로, 그 사이에 다른 작업이 끼어들 수 있는 `await` 없이 동기 코드, `defer`, 테스트에서 호출할 수 있습니다.
- **일시 중단된 호출자는 `WaiterQueue`의 continuation입니다.** 취소 핸들러는 항목을 등록하는 것과 같은 락 아래에서 자기 항목을 제거하므로, 대기자가 사라지거나 두 번 재개되는 일이 없습니다.
- **작업은 가능한 한 호출자의 actor에서 실행됩니다.** `retry`, `AsyncSemaphore.withPermit`, `CircuitBreaker.run`은 `nonisolated(nonsending)`이므로, 전달하는 클로저가 main actor 상태를 건드릴 수 있고 `Sendable` 캡처도 필요하지 않습니다. 다른 작업(task)에서 실행되어야 하는 작업(`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`)은 `@Sendable` 클로저를 받습니다.
- **시간을 다루는 모든 타입은 `Clock`을 받습니다.** 프로덕션 코드는 `ContinuousClock`을 쓰고, 테스트는 `TestClock`을 전달합니다.

### 어디에 맞는가

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms)는 `AsyncSequence`에 대한 연산자(`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`)를 다룹니다. 데이터가 이미 시퀀스로 들어온다면 이것을 사용하세요. SwiftConcurrency는 호출로 시작되는 작업, 즉 제한, 큐, 데드라인, 재시도, 메서드 호출 디바운싱, 서킷 브레이커, 공유 요청을 다룹니다. 두 패키지는 함께 사용할 수 있습니다.

## 로드맵

- Linux 지원: `OSAllocatedUnfairLock`을 표준 라이브러리의 `Mutex`로 교체합니다. 이를 위해 Apple 플랫폼의 최소 버전을 iOS 18과 macOS 15로 올려야 합니다.
- 초당 요청 수를 제한하는 API를 위한 토큰 버킷 속도 제한기.
- `TaskQueue`의 우선순위 옵션. 긴급한 작업이 오래된 작업보다 먼저 시작될 수 있습니다.

## 기여하기

기여를 환영합니다. pull request를 열기 전에 [기여 가이드](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md)와 [행동 강령](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md)을 읽어 주세요. 보안 문제는 [보안 정책](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md)에 따라 비공개로 제보해 주세요.

## 라이선스

MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
