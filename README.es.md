<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="Estado de CI"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="Última versión: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="Plataformas compatibles: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="Versión del lenguaje: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="Licencia: MIT"></picture></a>
</p>

<p align="center">
<a href="#inicio-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-es-light.svg" alt="Empezar"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-es-light.svg" alt="Documentación"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-es-light.svg" alt="Ejemplos"></picture></a>
</p>

> Esta es una traducción del README en inglés. Si hay diferencias, la versión en inglés es la vigente.

<!-- brand:end -->

SwiftConcurrency es un paquete pequeño de Swift 6 para los problemas cotidianos en torno a `async`/`await` que la biblioteca estándar deja en manos de cada app: descargar como máximo cuatro archivos a la vez, evitar que dos guardados se solapen, abandonar una petición pasados diez segundos, reintentar con backoff, buscar solo cuando el usuario deja de escribir, enviar una única petición cuando tres pantallas piden los mismos datos y dejar de llamar a un servidor que está caído. Cada problema tiene un tipo o una función; todos son `Sendable`, terminan sus esperas cuando se cancela la tarea y reciben un `Clock`, de modo que las pruebas pueden mover el tiempo en lugar de esperarlo. No tiene dependencias.

## Lo más destacado

- **Orden y límites** — `TaskQueue` ejecuta las operaciones asíncronas en el orden en que se añadieron, de una en una o hasta el límite que elijas; `AsyncSemaphore` y `concurrentMap(maxConcurrency:)` acotan cuánto se ejecuta a la vez.
- **Plazos y reintentos** — `withTimeout`, `withDeadline` y `retry` con `Backoff` constante, lineal o exponencial y jitter; los retardos se acotan antes de convertirse en un `Duration`, así que ningún número de reintentos ni multiplicador provoca un desbordamiento.
- **Control de frecuencia para el código de UI** — `Debouncer` para los campos de búsqueda y `Throttler` (con ejecución al inicio y al final) para los manejadores de scroll y arrastre, como objetos sencillos que llamas desde un view model.
- **Fallar rápido, compartir el trabajo** — `CircuitBreaker` deja de llamar a un servicio que no para de fallar; `SingleFlight` envía una sola petición cuando muchos llamadores piden la misma clave a la vez.
- **Cancelación en todas partes** — cada espera del paquete termina de inmediato cuando se cancela su tarea; un llamador cancelado no toma ningún permiso, nunca ejecuta su operación y no deja nada en memoria.
- **Pruebas que no esperan** — `TestClock` y `waitForSleepers()` permiten que una prueba termine un backoff de 30 segundos en la línea que elija, con el mismo resultado en cada ejecución.

## Inicio rápido

**1. Añade el paquete**

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. Importa el módulo**

```swift
import SwiftConcurrency
```

**3. Úsalo**

Carga muchos perfiles, cuatro peticiones a la vez, cada una con un tiempo límite de 10 segundos y hasta tres intentos con backoff exponencial
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

`ProfileAPI` representa tu código de red: cualquier tipo `Sendable` con un método asíncrono `profile(id:)`. Los resultados llegan en el orden de `ids`. Si una petición sigue fallando tras tres intentos, su error se lanza sin modificar y se cancelan las peticiones que aún están en curso.

## Instalación

### Swift Package Manager

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

O añádelo a las `dependencies` de tu `Package.swift`:

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

## Uso

Los ejemplos siguientes están copiados de
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift), que la app de ejemplo compila y la batería de pruebas ejecuta.

### Buscar mientras se escribe

`Debouncer` ejecuta la búsqueda cuando el usuario lleva 300 ms sin escribir. Cada nueva pulsación reemplaza a la búsqueda en espera.

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

### Evitar que los guardados se solapen

Un actor deja que la siguiente llamada empiece mientras la anterior está esperando. `TaskQueue` no: con el límite predeterminado de 1, cada escritura empieza cuando termina la anterior, en el orden de las llamadas a `save`.

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

`TaskQueue(maxConcurrentOperations: 4)` ejecuta hasta cuatro operaciones a la vez y aun así las inicia en orden.

### Enviar una sola petición para muchos llamadores

`SingleFlight` comparte la petición que ya está en curso para un perfil, y `CircuitBreaker` rechaza las llamadas durante 30 segundos tras cinco fallos seguidos.

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

### Probarlo sin esperar

Pasa un `TestClock`, espera a que el código se duerma y mueve tú mismo el tiempo. Esta prueba de
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) escribe cuatro letras y comprueba que solo se busca la última consulta:

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

`Recorder` es un pequeño actor del target de pruebas que recoge valores y espera a que lleguen.

## Demo

La app [ConcurrencyDemo](Examples/ConcurrencyDemo) ejecuta cada herramienta con la biblioteca real. Las capturas proceden de la app en un simulador de iOS 27 y se tomaron con
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Búsqueda con debounce | Cola de descargas (límite 2) | Reintento y circuit breaker |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="Pantalla de búsqueda: cuatro pulsaciones, una búsqueda, resultados para “task”"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="Cola de descargas: una línea de tiempo de seis archivos de los que como máximo dos se solapan"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="Registro de reintentos: tres peticiones fallan tras tres intentos y después el circuito abierto rechaza dos"></picture> |

Para ejecutarla, abre `ConcurrencyDemo.xcodeproj` en [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) con Xcode 26 o posterior, elige un simulador de iPhone o **My Mac** y pulsa **Run**.
[Examples/README.md](Examples/README.md) describe cada pantalla.

## Documentación

Referencia de la API y artículos:

- [Referencia de SwiftConcurrency](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [Primeros pasos](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [Pruebas de código dependiente del tiempo](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [Cancelación y límites](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## Guías

- [Primeros pasos](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — qué tipo resuelve qué problema, con un ejemplo para cada uno.
- [Pruebas de código dependiente del tiempo](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — el flujo de trabajo con `TestClock`: crear, esperar a los que duermen, avanzar.
- [Cancelación y límites](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — qué hace cada API cuando se cancela su tarea, qué entradas rechaza y cómo acota la memoria.

## Requisitos

| Plataforma | Versión mínima |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| Herramientas | Swift 6.2 · Xcode 26+ |

## Arquitectura

El paquete es un único módulo, `SwiftConcurrency`, agrupado por problema:

| Carpeta | Tipos |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked` (un unfair lock), `WaiterQueue` (FIFO de llamadores suspendidos), `ElapsedClock` |

Decisiones de diseño:

- **Clases con un lock, no actores.** `signal()`, `cancel()`, `submit(_:)` y `advance(by:)` surten efecto antes de devolver el control, por lo que pueden llamarse desde código síncrono, desde `defer` y desde pruebas sin un `await` que deje que se ejecute otro trabajo entre medias.
- **Los llamadores suspendidos son continuations en una `WaiterQueue`.** Un manejador de cancelación elimina su propia entrada bajo el mismo lock que la registra, de modo que ningún llamador se pierde ni se reanuda dos veces.
- **Las operaciones se ejecutan en el actor del llamador siempre que pueden.** `retry`, `AsyncSemaphore.withPermit` y `CircuitBreaker.run` son `nonisolated(nonsending)`, así que los closures que pasas pueden tocar el estado del main actor y no necesitan capturas `Sendable`. El trabajo que debe ejecutarse en otra tarea (`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`) recibe closures `@Sendable`.
- **Todo tipo con temporización recibe un `Clock`.** El código de producción usa `ContinuousClock`; las pruebas pasan un `TestClock`.

### Dónde encaja

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) cubre operadores sobre `AsyncSequence` (`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`); úsalo cuando tus datos ya lleguen como una secuencia. SwiftConcurrency cubre el trabajo que se inicia mediante llamadas: límites, colas, plazos, reintentos, debounce de una llamada a un método, circuit breaking y peticiones compartidas. Los dos paquetes funcionan juntos.

## Hoja de ruta

- Compatibilidad con Linux: sustituir `OSAllocatedUnfairLock` por el `Mutex` de la biblioteca estándar, lo que exige subir las versiones mínimas de las plataformas de Apple a iOS 18 y macOS 15.
- Un limitador de frecuencia de tipo token bucket para las API que permiten un número de peticiones por segundo.
- Una opción de prioridad para `TaskQueue`, de modo que las operaciones urgentes puedan empezar antes que las más antiguas.

## Contribuir

Las contribuciones son bienvenidas. Lee la [guía de contribución](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md) y el [código de conducta](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md) antes de abrir una pull request. Informa de los problemas de seguridad de forma privada, como se describe en la [política de seguridad](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md).

## Licencia

Publicado bajo la licencia MIT. Consulta [LICENSE](LICENSE).
