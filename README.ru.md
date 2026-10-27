<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="Статус CI"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="Последняя версия: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="Поддерживаемые платформы: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="Версия языка: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="Лицензия: MIT"></picture></a>
</p>

<p align="center">
<a href="#быстрый-старт"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-ru-light.svg" alt="Начать"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-ru-light.svg" alt="Документация"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-ru-light.svg" alt="Примеры"></picture></a>
</p>

> Это перевод README на английском языке. Если они расходятся, актуальна английская версия.

<!-- brand:end -->

SwiftConcurrency — небольшой пакет на Swift 6 для повседневных задач вокруг `async`/`await`, которые стандартная библиотека оставляет каждому приложению: скачивать не больше четырёх файлов одновременно, не допускать наложения двух сохранений, отказываться от запроса через десять секунд, повторять попытки с backoff, искать только тогда, когда пользователь перестал печатать, отправлять один запрос, когда три экрана просят одни и те же данные, и перестать обращаться к упавшему серверу. Для каждой задачи есть один тип или одна функция; все они `Sendable`, завершают ожидание при отмене задачи и принимают `Clock`, чтобы тесты могли переводить время вперёд, а не ждать его. Зависимостей нет.

## Основные возможности

- **Порядок и лимиты** — `TaskQueue` выполняет асинхронные операции в порядке добавления: по одной или до выбранного вами лимита; `AsyncSemaphore` и `concurrentMap(maxConcurrency:)` ограничивают, сколько выполняется одновременно.
- **Дедлайны и повторные попытки** — `withTimeout`, `withDeadline` и `retry` с постоянным, линейным или экспоненциальным `Backoff` и jitter; задержки ограничиваются до превращения в `Duration`, поэтому ни число попыток, ни множитель не приводят к переполнению.
- **Управление частотой для UI-кода** — `Debouncer` для полей поиска и `Throttler` (с запуском в начале и в конце интервала) для обработчиков прокрутки и перетаскивания; это обычные объекты, которые вы вызываете из view model.
- **Быстрый отказ, общая работа** — `CircuitBreaker` перестаёт обращаться к сервису, который постоянно даёт сбой; `SingleFlight` отправляет один запрос, когда много вызывающих одновременно просят один и тот же ключ.
- **Отмена везде** — любое ожидание в пакете сразу завершается при отмене его задачи; отменённый ожидающий не занимает разрешение, никогда не выполняет свою операцию и ничего не оставляет в памяти.
- **Тесты без ожидания** — `TestClock` и `waitForSleepers()` позволяют тесту завершить 30-секундный backoff на выбранной строке, и при каждом запуске результат один и тот же.

## Быстрый старт

**1. Добавьте пакет**

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. Импортируйте модуль**

```swift
import SwiftConcurrency
```

**3. Используйте**

Загрузите много профилей по четыре запроса одновременно: у каждого запроса тайм-аут 10 секунд и до трёх попыток с экспоненциальным backoff
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

`ProfileAPI` обозначает ваш сетевой код: любой тип `Sendable` с асинхронным методом `profile(id:)`. Результаты возвращаются в порядке `ids`. Если запрос продолжает завершаться ошибкой и после трёх попыток, его ошибка выбрасывается без изменений, а запросы, которые ещё выполняются, отменяются.

## Установка

### Swift Package Manager

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

Или добавьте его в `dependencies` вашего `Package.swift`:

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

## Использование

Примеры ниже скопированы из
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift): пример приложения собирает этот файл, а набор тестов запускает его.

### Поиск во время набора

`Debouncer` запускает поиск, когда пользователь перестал печатать на 300 мс. Каждое новое нажатие клавиши заменяет ожидающий поиск.

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

### Не допускать наложения сохранений

Actor позволяет следующему вызову начаться, пока предыдущий ожидает. `TaskQueue` так не делает: при лимите по умолчанию, равном 1, каждая запись начинается после завершения предыдущей, в порядке вызовов `save`.

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

`TaskQueue(maxConcurrentOperations: 4)` выполняет до четырёх операций одновременно и всё равно запускает их по порядку.

### Один запрос для многих вызывающих

`SingleFlight` делит уже выполняющийся запрос профиля между вызывающими, а `CircuitBreaker` отклоняет вызовы в течение 30 секунд после пяти сбоев подряд.

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

### Тестирование без ожидания

Передайте `TestClock`, дождитесь, пока код уснёт, а затем сами переведите время вперёд. Этот тест из
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) вводит четыре буквы и проверяет, что искали только последний запрос:

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

`Recorder` — небольшой actor в тестовом таргете, который собирает значения и ждёт их.

## Демо

Приложение [ConcurrencyDemo](Examples/ConcurrencyDemo) запускает каждый инструмент на настоящей библиотеке. Скриншоты сделаны в приложении на симуляторе iOS 27 с помощью
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Поиск с debounce | Очередь загрузок (лимит 2) | Повтор и circuit breaker |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="Экран поиска: четыре нажатия клавиш, один поиск, результаты для «task»"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="Очередь загрузок: временная шкала из шести файлов, из которых одновременно перекрываются не больше двух"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="Журнал повторов: три запроса завершаются ошибкой после трёх попыток, затем разомкнутая цепь отклоняет ещё два"></picture> |

Чтобы запустить его, откройте `ConcurrencyDemo.xcodeproj` из [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) в Xcode 26 или новее, выберите симулятор iPhone или **My Mac** и нажмите **Run**.
Каждый экран описан в [Examples/README.md](Examples/README.md).

## Документация

Справочник API и статьи:

- [Справочник SwiftConcurrency](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [Быстрое знакомство](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [Тестирование кода, зависящего от времени](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [Отмена и лимиты](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## Руководства

- [Быстрое знакомство](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — какой тип решает какую задачу, с примером для каждого.
- [Тестирование кода, зависящего от времени](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — рабочий процесс с `TestClock`: создать, дождаться спящих, перевести время вперёд.
- [Отмена и лимиты](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — что делает каждый API при отмене своей задачи, какие входные данные он отклоняет и как ограничивает память.

## Требования

| Платформа | Минимальная версия |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| Инструменты | Swift 6.2 · Xcode 26+ |

## Архитектура

Пакет состоит из одного модуля, `SwiftConcurrency`, сгруппированного по задачам:

| Папка | Типы |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked` (unfair lock), `WaiterQueue` (FIFO приостановленных вызывающих), `ElapsedClock` |

Проектные решения:

- **Классы с блокировкой, а не actors.** `signal()`, `cancel()`, `submit(_:)` и `advance(by:)` вступают в силу до возврата, поэтому их можно вызывать из синхронного кода, из `defer` и из тестов без `await`, который позволил бы другой работе выполниться посередине.
- **Приостановленные вызывающие — это continuations в `WaiterQueue`.** Обработчик отмены удаляет свою запись под той же блокировкой, что и регистрирует её, поэтому ни один ожидающий не теряется и не возобновляется дважды.
- **Операции выполняются на actor вызывающего, когда это возможно.** `retry`, `AsyncSemaphore.withPermit` и `CircuitBreaker.run` объявлены как `nonisolated(nonsending)`, поэтому передаваемые вами замыкания могут обращаться к состоянию main actor и не требуют захвата `Sendable`. Работа, которая должна выполняться в другой задаче (`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`), принимает замыкания `@Sendable`.
- **Каждый тип, работающий со временем, принимает `Clock`.** В продакшн-коде используется `ContinuousClock`; тесты передают `TestClock`.

### Где он уместен

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) охватывает операторы над `AsyncSequence` (`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`); используйте его, когда ваши данные уже поступают как последовательность. SwiftConcurrency охватывает работу, запускаемую вызовами: лимиты, очереди, дедлайны, повторные попытки, debounce вызова метода, circuit breaking и общие запросы. Два пакета работают бок о бок.

## План развития

- Поддержка Linux: заменить `OSAllocatedUnfairLock` на `Mutex` из стандартной библиотеки, для чего потребуется поднять минимальные версии платформ Apple до iOS 18 и macOS 15.
- Ограничитель частоты на основе token bucket для API, допускающих определённое число запросов в секунду.
- Параметр приоритета для `TaskQueue`, чтобы срочные операции могли начинаться раньше более старых.

## Участие в разработке

Мы рады вашему участию. Перед открытием pull request прочитайте [руководство для участников](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md) и [кодекс поведения](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md). О проблемах безопасности сообщайте конфиденциально, как описано в [политике безопасности](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md).

## Лицензия

Распространяется по лицензии MIT. Подробнее — в файле [LICENSE](LICENSE).
