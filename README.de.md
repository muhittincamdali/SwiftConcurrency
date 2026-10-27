<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="CI-Status"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="Aktuelle Version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="Unterstützte Plattformen: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="Sprachversion: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="Lizenz: MIT"></picture></a>
</p>

<p align="center">
<a href="#schnellstart"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-de-light.svg" alt="Loslegen"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-de-light.svg" alt="Dokumentation"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-de-light.svg" alt="Beispiele"></picture></a>
</p>

> Dies ist eine Übersetzung der englischen README. Bei Abweichungen gilt die englische Fassung.

<!-- brand:end -->

SwiftConcurrency ist ein kleines Swift-6-Paket für die alltäglichen Probleme rund um `async`/`await`, die die Standardbibliothek jeder App selbst überlässt: höchstens vier Dateien gleichzeitig herunterladen, verhindern, dass sich zwei Speichervorgänge überschneiden, eine Anfrage nach zehn Sekunden aufgeben, mit Backoff wiederholen, erst suchen, wenn der Nutzer aufhört zu tippen, nur eine Anfrage senden, wenn drei Bildschirme dieselben Daten anfordern, und einen ausgefallenen Server nicht mehr aufrufen. Jedes Problem hat einen Typ oder eine Funktion; alle sind `Sendable`, beenden ihre Wartezeiten, wenn der Task abgebrochen wird, und nehmen eine `Clock` entgegen, damit Tests die Zeit vorstellen können, statt auf sie zu warten. Es hat keine Abhängigkeiten.

## Highlights

- **Reihenfolge und Limits** — `TaskQueue` führt asynchrone Operationen in der Reihenfolge aus, in der sie hinzugefügt wurden, einzeln oder bis zu einem frei gewählten Limit; `AsyncSemaphore` und `concurrentMap(maxConcurrency:)` begrenzen, wie viel gleichzeitig läuft.
- **Fristen und Wiederholungen** — `withTimeout`, `withDeadline` und `retry` mit konstantem, linearem oder exponentiellem `Backoff` und Jitter; Verzögerungen werden begrenzt, bevor sie zu einer `Duration` werden, sodass weder eine Wiederholungszahl noch ein Multiplikator überläuft.
- **Ratensteuerung für UI-Code** — `Debouncer` für Suchfelder und `Throttler` (mit Ausführung am Anfang und am Ende) für Scroll- und Drag-Handler, als einfache Objekte, die du aus einem View Model aufrufst.
- **Schnell scheitern, Arbeit teilen** — `CircuitBreaker` hört auf, einen Dienst aufzurufen, der immer wieder fehlschlägt; `SingleFlight` sendet nur eine Anfrage, wenn viele Aufrufer gleichzeitig denselben Schlüssel anfordern.
- **Abbruch überall** — jedes Warten im Paket endet sofort, wenn sein Task abgebrochen wird; ein abgebrochener Wartender nimmt keine Berechtigung in Anspruch, führt seine Operation nie aus und hinterlässt nichts im Speicher.
- **Tests, die nicht warten** — mit `TestClock` und `waitForSleepers()` beendet ein Test ein 30-Sekunden-Backoff in der Zeile seiner Wahl, bei jedem Lauf mit demselben Ergebnis.

## Schnellstart

**1. Paket hinzufügen**

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. Modul importieren**

```swift
import SwiftConcurrency
```

**3. Verwenden**

Lade viele Profile, vier Anfragen gleichzeitig, jede mit einem Timeout von 10 Sekunden und bis zu drei Versuchen mit exponentiellem Backoff
([ReadmeSamples.swift](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)):

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

`ProfileAPI` steht für deinen Netzwerkcode: jeder `Sendable`-Typ mit einer asynchronen Methode `profile(id:)`. Die Ergebnisse kommen in der Reihenfolge von `ids` zurück. Schlägt eine Anfrage auch nach drei Versuchen fehl, wird ihr Fehler unverändert geworfen und die noch laufenden Anfragen werden abgebrochen.

## Installation

### Swift Package Manager

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

Oder füge es zu den `dependencies` in deiner `Package.swift` hinzu:

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

## Verwendung

Die folgenden Beispiele sind kopiert aus
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift), das die Beispiel-App baut und die Testsuite ausführt.

### Suchen während der Eingabe

`Debouncer` führt die Suche aus, sobald der Nutzer 300 ms lang nicht mehr getippt hat. Jeder neue Tastendruck ersetzt die wartende Suche.

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

### Überschneidende Speichervorgänge verhindern

Ein Actor lässt den nächsten Aufruf starten, während der vorherige wartet. `TaskQueue` tut das nicht: Beim Standardlimit von 1 beginnt jeder Schreibvorgang erst, wenn der vorherige beendet ist, in der Reihenfolge der `save`-Aufrufe.

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

`TaskQueue(maxConcurrentOperations: 4)` führt bis zu vier Operationen gleichzeitig aus und startet sie trotzdem der Reihe nach.

### Eine Anfrage für viele Aufrufer senden

`SingleFlight` teilt die Anfrage, die für ein Profil bereits läuft, und `CircuitBreaker` lehnt Aufrufe 30 Sekunden lang ab, nachdem fünfmal in Folge ein Fehler aufgetreten ist.

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

### Testen, ohne zu warten

Übergib eine `TestClock`, warte, bis der Code schläft, und stelle die Zeit dann selbst vor. Dieser Test aus
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) tippt vier Buchstaben und prüft, dass nur die letzte Suchanfrage ausgeführt wird:

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

`Recorder` ist ein kleiner Actor im Test-Target, der Werte sammelt und auf sie wartet.

## Demo

Die App [ConcurrencyDemo](Examples/ConcurrencyDemo) führt jedes Werkzeug mit der echten Bibliothek aus. Die Screenshots stammen aus der App in einem iOS-27-Simulator und wurden mit
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) aufgenommen:

| Suche mit Debounce | Download-Warteschlange (Limit 2) | Wiederholung und Circuit Breaker |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="Suchbildschirm: vier Tastendrücke, eine Suche, Ergebnisse für „task“"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="Download-Warteschlange: eine Zeitleiste mit sechs Dateien, von denen sich höchstens zwei überschneiden"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="Wiederholungsprotokoll: drei Anfragen scheitern nach drei Versuchen, dann lehnt der offene Schaltkreis zwei ab"></picture> |

Öffne zum Ausführen `ConcurrencyDemo.xcodeproj` in [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) mit Xcode 26 oder neuer, wähle einen iPhone-Simulator oder **My Mac** und drücke **Run**.
[Examples/README.md](Examples/README.md) beschreibt jeden Bildschirm.

## Dokumentation

API-Referenz und Artikel:

- [SwiftConcurrency-Referenz](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [Erste Schritte](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [Zeitabhängigen Code testen](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [Abbruch und Limits](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## Anleitungen

- [Erste Schritte](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — welcher Typ welches Problem löst, jeweils mit einem Beispiel.
- [Zeitabhängigen Code testen](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — der `TestClock`-Ablauf: erstellen, auf Schlafende warten, vorstellen.
- [Abbruch und Limits](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — was jede API tut, wenn ihr Task abgebrochen wird, welche Eingaben sie ablehnt und wie sie den Speicher begrenzt.

## Voraussetzungen

| Plattform | Mindestversion |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| Toolchain | Swift 6.2 · Xcode 26+ |

## Architektur

Das Paket besteht aus einem einzigen Modul, `SwiftConcurrency`, gegliedert nach Problemen:

| Ordner | Typen |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked` (ein Unfair Lock), `WaiterQueue` (FIFO der suspendierten Aufrufer), `ElapsedClock` |

Designentscheidungen:

- **Klassen mit Lock statt Actors.** `signal()`, `cancel()`, `submit(_:)` und `advance(by:)` wirken, bevor sie zurückkehren. Deshalb lassen sie sich aus synchronem Code, aus `defer` und aus Tests aufrufen, ohne ein `await`, das dazwischen anderer Arbeit Raum gibt.
- **Suspendierte Aufrufer sind Continuations in einer `WaiterQueue`.** Ein Abbruch-Handler entfernt seinen eigenen Eintrag unter demselben Lock, der ihn registriert, sodass kein Wartender verloren geht oder zweimal fortgesetzt wird.
- **Operationen laufen, wo möglich, auf dem Actor des Aufrufers.** `retry`, `AsyncSemaphore.withPermit` und `CircuitBreaker.run` sind `nonisolated(nonsending)`, sodass die übergebenen Closures auf den Zustand des Main Actors zugreifen dürfen und keine `Sendable`-Captures brauchen. Arbeit, die in einem anderen Task laufen muss (`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`), nimmt `@Sendable`-Closures entgegen.
- **Jeder zeitabhängige Typ nimmt eine `Clock` entgegen.** Produktionscode erhält `ContinuousClock`; Tests übergeben eine `TestClock`.

### Wo es hineinpasst

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) deckt Operatoren auf `AsyncSequence` ab (`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`); nutze es, wenn deine Daten bereits als Sequenz eintreffen. SwiftConcurrency deckt Arbeit ab, die durch Aufrufe gestartet wird: Limits, Warteschlangen, Fristen, Wiederholungen, Debouncing eines Methodenaufrufs, Circuit Breaking und geteilte Anfragen. Beide Pakete arbeiten nebeneinander.

## Roadmap

- Linux-Unterstützung: `OSAllocatedUnfairLock` durch das `Mutex` der Standardbibliothek ersetzen; dafür müssen die Mindestversionen der Apple-Plattformen auf iOS 18 und macOS 15 angehoben werden.
- Ein Token-Bucket-Ratenbegrenzer für APIs, die eine bestimmte Anzahl von Anfragen pro Sekunde erlauben.
- Eine Prioritätsoption für `TaskQueue`, damit dringende Operationen vor älteren starten können.

## Mitwirken

Beiträge sind willkommen. Lies vor einem Pull Request den [Leitfaden für Beiträge](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md) und den [Verhaltenskodex](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md). Sicherheitsprobleme meldest du vertraulich, wie in der [Sicherheitsrichtlinie](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md) beschrieben.

## Lizenz

Veröffentlicht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE).
