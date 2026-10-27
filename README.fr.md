<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="État de la CI"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="Dernière version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="Plateformes prises en charge: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="Version du langage: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="Licence: MIT"></picture></a>
</p>

<p align="center">
<a href="#démarrage-rapide"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-fr-light.svg" alt="Commencer"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-fr-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-fr-light.svg" alt="Exemples"></picture></a>
</p>

> Ceci est une traduction du README anglais. En cas de différence, la version anglaise fait foi.

<!-- brand:end -->

SwiftConcurrency est un petit paquet Swift 6 qui règle les problèmes courants autour de `async`/`await` que la bibliothèque standard laisse à chaque app : ne pas télécharger plus de quatre fichiers à la fois, empêcher deux sauvegardes de se chevaucher, abandonner une requête au bout de dix secondes, réessayer avec un backoff, ne lancer la recherche que lorsque l’utilisateur arrête de saisir, n’envoyer qu’une seule requête quand trois écrans demandent les mêmes données, et cesser d’appeler un serveur en panne. Chaque problème a un type ou une fonction ; tous sont `Sendable`, mettent fin à leurs attentes quand la tâche est annulée et acceptent une `Clock`, de sorte que les tests peuvent avancer le temps au lieu de l’attendre. Il n’a aucune dépendance.

## Points forts

- **Ordre et limites** — `TaskQueue` exécute les opérations asynchrones dans l’ordre où elles ont été ajoutées, une par une ou jusqu’à une limite que vous choisissez ; `AsyncSemaphore` et `concurrentMap(maxConcurrency:)` plafonnent ce qui s’exécute en même temps.
- **Échéances et nouvelles tentatives** — `withTimeout`, `withDeadline` et `retry` avec un `Backoff` constant, linéaire ou exponentiel et du jitter ; les délais sont plafonnés avant de devenir une `Duration`, si bien qu’aucun nombre de tentatives ni aucun multiplicateur ne provoque de dépassement.
- **Contrôle de cadence pour le code d’interface** — `Debouncer` pour les champs de recherche et `Throttler` (exécutions en début et en fin de période) pour les gestionnaires de défilement et de glissement, sous forme d’objets simples que vous appelez depuis un view model.
- **Échouer vite, partager le travail** — `CircuitBreaker` cesse d’appeler un service qui échoue en continu ; `SingleFlight` n’envoie qu’une requête quand de nombreux appelants demandent la même clé en même temps.
- **L’annulation partout** — chaque attente du paquet se termine aussitôt que sa tâche est annulée ; un appelant annulé ne prend aucun permis, n’exécute jamais son opération et ne laisse rien en mémoire.
- **Des tests qui n’attendent pas** — `TestClock` et `waitForSleepers()` permettent à un test de terminer un backoff de 30 secondes à la ligne de son choix, avec le même résultat à chaque exécution.

## Démarrage rapide

**1. Ajouter le paquet**

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. Importer le module**

```swift
import SwiftConcurrency
```

**3. L’utiliser**

Chargez de nombreux profils, quatre requêtes à la fois, chacune avec un délai d’expiration de 10 secondes et jusqu’à trois tentatives avec un backoff exponentiel
([ReadmeSamples.swift](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift)) :

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

`ProfileAPI` représente votre code réseau : n’importe quel type `Sendable` doté d’une méthode asynchrone `profile(id:)`. Les résultats reviennent dans l’ordre de `ids`. Si une requête échoue encore après trois tentatives, son erreur est levée telle quelle et les requêtes encore en cours sont annulées.

## Installation

### Swift Package Manager

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

Ou ajoutez-le aux `dependencies` de votre `Package.swift` :

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

## Utilisation

Les exemples ci-dessous sont copiés depuis
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift), que l’app d’exemple compile et que la suite de tests exécute.

### Rechercher pendant la saisie

`Debouncer` lance la recherche une fois que l’utilisateur a cessé de saisir pendant 300 ms. Chaque nouvelle frappe remplace la recherche en attente.

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

### Empêcher les sauvegardes de se chevaucher

Un actor laisse l’appel suivant démarrer pendant que le précédent attend. `TaskQueue` ne le fait pas : avec la limite par défaut de 1, chaque écriture démarre après la fin de la précédente, dans l’ordre des appels à `save`.

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

`TaskQueue(maxConcurrentOperations: 4)` exécute jusqu’à quatre opérations à la fois tout en les démarrant dans l’ordre.

### Envoyer une seule requête pour de nombreux appelants

`SingleFlight` partage la requête déjà en cours pour un profil, et `CircuitBreaker` refuse les appels pendant 30 secondes après cinq échecs consécutifs.

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

### Tester sans attendre

Passez une `TestClock`, attendez que le code se mette en veille, puis faites avancer le temps vous-même. Ce test tiré de
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) saisit quatre lettres et vérifie que seule la dernière requête est recherchée :

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

`Recorder` est un petit actor de la cible de test qui collecte des valeurs et les attend.

## Démo

L’app [ConcurrencyDemo](Examples/ConcurrencyDemo) exécute chaque outil avec la vraie bibliothèque. Les captures d’écran proviennent de l’app dans un simulateur iOS 27 et ont été réalisées par
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) :

| Recherche avec debounce | File de téléchargement (limite 2) | Nouvelle tentative et circuit breaker |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="Écran de recherche : quatre frappes, une recherche, résultats pour « task »"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="File de téléchargement : une chronologie de six fichiers dont deux au plus se chevauchent"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="Journal des tentatives : trois requêtes échouent après trois tentatives, puis le circuit ouvert en refuse deux"></picture> |

Pour l’exécuter, ouvrez `ConcurrencyDemo.xcodeproj` dans [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) avec Xcode 26 ou version ultérieure, choisissez un simulateur d’iPhone ou **My Mac**, puis appuyez sur **Run**.
[Examples/README.md](Examples/README.md) décrit chaque écran.

## Documentation

Référence de l’API et articles :

- [Référence de SwiftConcurrency](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [Premiers pas](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [Tester du code dépendant du temps](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [Annulation et limites](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## Guides

- [Premiers pas](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — quel type résout quel problème, avec un exemple pour chacun.
- [Tester du code dépendant du temps](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — le workflow `TestClock` : créer, attendre les dormeurs, avancer.
- [Annulation et limites](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — ce que fait chaque API quand sa tâche est annulée, les entrées qu’elle rejette et la façon dont elle borne la mémoire.

## Prérequis

| Plateforme | Version minimale |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| Chaîne d’outils | Swift 6.2 · Xcode 26+ |

## Architecture

Le paquet est un seul module, `SwiftConcurrency`, regroupé par problème :

| Dossier | Types |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked` (un unfair lock), `WaiterQueue` (FIFO des appelants suspendus), `ElapsedClock` |

Choix de conception :

- **Des classes avec un verrou, pas des actors.** `signal()`, `cancel()`, `submit(_:)` et `advance(by:)` prennent effet avant de rendre la main ; on peut donc les appeler depuis du code synchrone, depuis `defer` et depuis des tests, sans `await` qui laisserait d’autres tâches s’exécuter entre-temps.
- **Les appelants suspendus sont des continuations dans une `WaiterQueue`.** Un gestionnaire d’annulation retire sa propre entrée sous le même verrou que celui qui l’enregistre, si bien qu’aucun appelant n’est perdu ni repris deux fois.
- **Les opérations s’exécutent sur l’actor de l’appelant lorsque c’est possible.** `retry`, `AsyncSemaphore.withPermit` et `CircuitBreaker.run` sont `nonisolated(nonsending)` ; les closures que vous passez peuvent donc toucher à l’état du main actor et n’ont pas besoin de captures `Sendable`. Le travail qui doit s’exécuter dans une autre tâche (`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`) prend des closures `@Sendable`.
- **Tout type lié au temps accepte une `Clock`.** Le code de production reçoit `ContinuousClock` ; les tests passent une `TestClock`.

### Sa place par rapport à d’autres outils

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) couvre les opérateurs sur `AsyncSequence` (`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`) ; utilisez-le quand vos données arrivent déjà sous forme de séquence. SwiftConcurrency couvre le travail lancé par des appels : limites, files, échéances, nouvelles tentatives, debounce d’un appel de méthode, circuit breaking et requêtes partagées. Les deux paquets fonctionnent côte à côte.

## Feuille de route

- Prise en charge de Linux : remplacer `OSAllocatedUnfairLock` par le `Mutex` de la bibliothèque standard, ce qui suppose de relever les versions minimales des plateformes Apple à iOS 18 et macOS 15.
- Un limiteur de débit à seau de jetons (token bucket) pour les API qui autorisent un certain nombre de requêtes par seconde.
- Une option de priorité pour `TaskQueue`, afin que les opérations urgentes puissent démarrer avant les plus anciennes.

## Contribuer

Les contributions sont les bienvenues. Lisez le [guide de contribution](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md) et le [code de conduite](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md) avant d’ouvrir une pull request. Signalez les problèmes de sécurité en privé, comme indiqué dans la [politique de sécurité](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md).

## Licence

Publié sous licence MIT. Voir [LICENSE](LICENSE).
