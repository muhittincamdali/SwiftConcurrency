<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="CI ステータス"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="最新バージョン: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="対応プラットフォーム: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="言語バージョン: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="ライセンス: MIT"></picture></a>
</p>

<p align="center">
<a href="#クイックスタート"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ja-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ja-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ja-light.svg" alt="はじめる"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ja-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ja-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ja-light.svg" alt="ドキュメント"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ja-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ja-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ja-light.svg" alt="サンプル"></picture></a>
</p>

> このドキュメントは英語版 README の翻訳です。内容が異なる場合は英語版が最新です。

<!-- brand:end -->

SwiftConcurrency は、`async`/`await` まわりの日常的な問題を解決する小さな Swift 6 パッケージです。標準ライブラリはこれらの問題を各アプリに任せています。たとえば、同時にダウンロードするファイルを 4 つまでにする、2 つの保存処理が重ならないようにする、10 秒たったらリクエストをあきらめる、バックオフを付けて再試行する、ユーザーが入力をやめてから検索する、3 つの画面が同じデータを求めても 1 回だけリクエストを送る、停止しているサーバーを呼び出し続けない、といったことです。問題ごとに 1 つの型または関数が用意されています。すべて `Sendable` で、タスクがキャンセルされると待機を終了し、`Clock` を受け取るため、テストでは時間を待たずに進められます。依存関係はありません。

## 主な特長

- **順序と上限** — `TaskQueue` は非同期処理を追加された順に、1 つずつ、または指定した上限まで同時に実行します。`AsyncSemaphore` と `concurrentMap(maxConcurrency:)` は同時に実行する数を制限します。
- **期限と再試行** — `withTimeout`、`withDeadline`、そして固定・線形・指数の `Backoff` とジッターに対応した `retry`。待ち時間は `Duration` になる前に上限が適用されるため、再試行回数や乗数が大きくてもオーバーフローしません。
- **UI コード向けのレート制御** — 検索フィールド向けの `Debouncer` と、スクロールやドラッグの処理向けの `Throttler`（先頭と末尾の実行に対応）。どちらも view model から呼び出せる素朴なオブジェクトです。
- **早く失敗し、処理を共有する** — `CircuitBreaker` は失敗し続けるサービスの呼び出しを止めます。`SingleFlight` は、多数の呼び出し元が同じキーを同時に求めたときに、リクエストを 1 回だけ送ります。
- **あらゆる場所でのキャンセル対応** — パッケージ内のすべての待機は、タスクがキャンセルされると直ちに終了します。キャンセルされた待機側は許可を取得せず、処理を実行せず、メモリにも何も残しません。
- **待たないテスト** — `TestClock` と `waitForSleepers()` により、テストは 30 秒のバックオフを任意の行で終わらせられ、毎回同じ結果になります。

## クイックスタート

**1. パッケージを追加する**

Xcode で **File › Add Package Dependencies…** を選び、リポジトリの URL を入力します。

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. モジュールをインポートする**

```swift
import SwiftConcurrency
```

**3. 使ってみる**

多数のプロフィールを、同時に 4 リクエストずつ読み込みます。各リクエストには 10 秒のタイムアウトがあり、指数バックオフで最大 3 回まで試行します
（[ReadmeSamples.swift](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)）。

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

`ProfileAPI` はネットワーク処理を表します。非同期の `profile(id:)` メソッドを持つ任意の `Sendable` な型です。結果は `ids` の順に返ります。リクエストが 3 回試行しても失敗した場合は、そのエラーがそのままスローされ、実行中のほかのリクエストはキャンセルされます。

## インストール

### Swift Package Manager

Xcode で **File › Add Package Dependencies…** を選び、リポジトリの URL を入力します。

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

または `Package.swift` の `dependencies` に追加します。

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

## 使い方

以下のサンプルは、サンプルアプリがビルドし、テストスイートが実行する
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift) からコピーしたものです。

### 入力しながら検索する

`Debouncer` は、ユーザーが 300 ミリ秒入力をやめたあとに検索を実行します。新しいキー入力があるたびに、待機中の検索は置き換えられます。

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

### 保存処理が重ならないようにする

actor では、前の呼び出しが await で待っている間に次の呼び出しが始まります。`TaskQueue` はそうなりません。既定の上限 1 では、各書き込みは前の書き込みが終わってから、`save` を呼んだ順に始まります。

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

`TaskQueue(maxConcurrentOperations: 4)` は最大 4 つの処理を同時に実行し、それでも順番どおりに開始します。

### 多数の呼び出し元に対してリクエストを 1 回だけ送る

`SingleFlight` は、あるプロフィールに対してすでに実行中のリクエストを共有します。`CircuitBreaker` は、5 回連続で失敗したあと 30 秒間、呼び出しを拒否します。

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

### 待たずにテストする

`TestClock` を渡し、コードがスリープするまで待ってから、自分で時間を進めます。
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) のこのテストは、4 文字を入力し、最後のクエリだけが検索されることを確認します。

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

`Recorder` は、テストターゲット内の小さな actor で、値を収集して待機します。

## デモ

[ConcurrencyDemo](Examples/ConcurrencyDemo) アプリは、実際のライブラリで各ツールを実行します。スクリーンショットは iOS 27 シミュレーター上のアプリから、
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) で取得したものです。

| デバウンス検索 | ダウンロードキュー（上限 2） | 再試行とサーキットブレーカー |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="検索画面：4 回のキー入力、1 回の検索、「task」の結果"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="ダウンロードキュー：6 つのファイルのタイムライン。重なるのは最大 2 つ"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="再試行ログ：3 つのリクエストが 3 回の試行後に失敗し、その後オープン状態の回路が 2 つを拒否"></picture> |

実行するには、[Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) の `ConcurrencyDemo.xcodeproj` を Xcode 26 以降で開き、iPhone シミュレーターまたは **My Mac** を選んで **Run** を押します。
各画面については [Examples/README.md](Examples/README.md) で説明しています。

## ドキュメント

API リファレンスと解説記事：

- [SwiftConcurrency リファレンス](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [はじめに](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [時間に依存するコードのテスト](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [キャンセルと上限](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## ガイド

- [はじめに](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — どの型がどの問題を解決するかを、それぞれのサンプル付きで説明します。
- [時間に依存するコードのテスト](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — `TestClock` のワークフロー：作成、スリープの待機、時間を進める。
- [キャンセルと上限](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — 各 API がタスクのキャンセル時にどう動作するか、拒否する入力、メモリをどのように制限するか。

## 動作要件

| プラットフォーム | 最小バージョン |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| ツールチェーン | Swift 6.2 · Xcode 26+ |

## アーキテクチャ

このパッケージは `SwiftConcurrency` という 1 つのモジュールで、問題ごとにグループ分けされています。

| フォルダー | 型 |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked`（unfair lock）、`WaiterQueue`（中断された呼び出し元の FIFO）、`ElapsedClock` |

設計上の判断：

- **actor ではなく、ロックを使うクラス。** `signal()`、`cancel()`、`submit(_:)`、`advance(by:)` は戻る前に効果が現れます。そのため、間に他の処理が割り込める `await` なしで、同期コード、`defer`、テストから呼び出せます。
- **中断された呼び出し元は `WaiterQueue` 内の continuation です。** キャンセルハンドラーは、登録に使うのと同じロックのもとで自分のエントリを削除するため、待機側が失われたり、2 回再開されたりすることはありません。
- **処理は可能な限り呼び出し元の actor 上で実行されます。** `retry`、`AsyncSemaphore.withPermit`、`CircuitBreaker.run` は `nonisolated(nonsending)` なので、渡すクロージャは main actor の状態に触れられ、`Sendable` なキャプチャも不要です。別のタスクで実行する必要がある処理（`TaskQueue`、`SingleFlight`、`withTimeout`、`concurrentMap`）は `@Sendable` なクロージャを受け取ります。
- **時間を扱う型はすべて `Clock` を受け取ります。** 本番コードは `ContinuousClock` を使い、テストは `TestClock` を渡します。

### 位置づけ

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) は `AsyncSequence` に対するオペレーター（`debounce`、`throttle`、`merge`、`zip`、`AsyncChannel`）を扱います。データがすでにシーケンスとして届く場合に使ってください。SwiftConcurrency は、呼び出しによって開始される処理、つまり上限、キュー、期限、再試行、メソッド呼び出しのデバウンス、サーキットブレーカー、共有リクエストを扱います。2 つのパッケージは併用できます。

## ロードマップ

- Linux 対応：`OSAllocatedUnfairLock` を標準ライブラリの `Mutex` に置き換えます。そのためには、Apple プラットフォームの最低バージョンを iOS 18 と macOS 15 に引き上げる必要があります。
- 1 秒あたりのリクエスト数を制限する API 向けのトークンバケット方式のレートリミッター。
- `TaskQueue` の優先度オプション。緊急の処理を古い処理より先に開始できるようにします。

## コントリビューション

コントリビューションを歓迎します。pull request を作成する前に[コントリビューションガイド](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md)と[行動規範](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md)をお読みください。セキュリティ上の問題は[セキュリティポリシー](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md)に従って非公開で報告してください。

## ライセンス

MIT ライセンスで公開しています。詳細は [LICENSE](LICENSE) を参照してください。
