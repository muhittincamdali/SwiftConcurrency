<!-- i18n-source: README.md@c10651cbbca1f6397d017fdd2da35aeeac02c073 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/banner-light.svg" alt="SwiftConcurrency: Limit, order, time out, retry and debounce async work in Swift 6, and test it with a clock you control."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftConcurrency/actions/workflows/ci.yml/badge.svg" alt="CI durumu"></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-version-light.svg" alt="Son sürüm: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-platforms-light.svg" alt="Desteklenen platformlar: iOS 16+ · macOS 13+ · tvOS 16+ · watchOS 9+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-language-light.svg" alt="Dil sürümü: Swift 6.2+ · Swift 6 mode"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/badge-license-light.svg" alt="Lisans: MIT"></picture></a>
</p>

<p align="center">
<a href="#hızlı-başlangıç"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-start-tr-light.svg" alt="Başlayın"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-docs-tr-light.svg" alt="Dokümantasyon"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftConcurrency/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftConcurrency/main/.github/brand/button-examples-tr-light.svg" alt="Örnekler"></picture></a>
</p>

> Bu belge İngilizce README'nin çevirisidir. İkisi arasında fark varsa güncel olan İngilizce sürümdür.

<!-- brand:end -->

SwiftConcurrency, `async`/`await` etrafındaki gündelik sorunlar için küçük bir Swift 6 paketidir. Standart kütüphane bu sorunları her uygulamanın kendisine bırakır: aynı anda dörtten fazla dosya indirmemek, iki kaydetme işleminin üst üste binmesini engellemek, on saniye sonra bir istekten vazgeçmek, geri çekilmeyle (backoff) yeniden denemek, yalnızca kullanıcı yazmayı bıraktığında arama yapmak, üç ekran aynı veriyi istediğinde tek bir istek göndermek ve çöken bir sunucuyu aramayı bırakmak. Her sorunun tek bir türü ya da fonksiyonu vardır; hepsi `Sendable`'dır, görev iptal edildiğinde beklemelerini sonlandırır ve bir `Clock` alır; böylece testler zamanı beklemek yerine ilerletebilir. Hiçbir bağımlılığı yoktur.

## Öne çıkanlar

- **Sıra ve sınırlar** — `TaskQueue`, asenkron işlemleri eklendikleri sırayla, tek tek ya da seçtiğiniz bir sınıra kadar eşzamanlı çalıştırır; `AsyncSemaphore` ve `concurrentMap(maxConcurrency:)` aynı anda ne kadar işin çalışacağını sınırlar.
- **Zaman aşımları ve yeniden denemeler** — `withTimeout`, `withDeadline` ve sabit, doğrusal ya da üstel `Backoff` ile jitter destekleyen `retry`; bekleme süreleri `Duration`'a dönüşmeden önce üst sınırla kısıtlanır, bu yüzden hiçbir deneme sayısı ya da çarpan taşmaya yol açmaz.
- **Arayüz kodu için hız denetimi** — arama alanları için `Debouncer`, kaydırma ve sürükleme işleyicileri için `Throttler` (ilk ve son çalıştırma); ikisi de bir view model'den çağırdığınız sade nesnelerdir.
- **Hızlı başarısız olma, işi paylaşma** — `CircuitBreaker`, sürekli hata veren bir servisi aramayı bırakır; `SingleFlight`, birçok çağıran aynı anda aynı anahtarı istediğinde tek bir istek gönderir.
- **Her yerde iptal desteği** — paketteki her bekleme, görevi iptal edildiğinde hemen sona erer; iptal edilen bekleyen izin almaz, işlemini asla çalıştırmaz ve bellekte iz bırakmaz.
- **Beklemeyen testler** — `TestClock` ve `waitForSleepers()`, bir testin 30 saniyelik backoff'u seçtiği satırda bitirmesini sağlar; sonuç her çalıştırmada aynıdır.

## Hızlı başlangıç

**1. Paketi ekleyin**

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

**2. Modülü içe aktarın**

```swift
import SwiftConcurrency
```

**3. Kullanın**

Çok sayıda profili aynı anda dört istekle yükleyin; her istek 10 saniyelik zaman aşımına ve üstel backoff ile en fazla üç denemeye sahiptir
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

`ProfileAPI`, ağ kodunuzu temsil eder: asenkron bir `profile(id:)` metoduna sahip herhangi bir `Sendable` tür. Sonuçlar `ids` sırasıyla döner. Bir istek üç denemeden sonra yine başarısız olursa hatası değiştirilmeden fırlatılır ve hâlâ çalışan istekler iptal edilir.

## Kurulum

### Swift Package Manager

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/SwiftConcurrency.git
```

Ya da `Package.swift` dosyanızdaki `dependencies` listesine ekleyin:

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

## Kullanım

Aşağıdaki örnekler, örnek uygulamanın derlediği ve test paketinin çalıştırdığı
[`ReadmeSamples.swift`](Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift) dosyasından alınmıştır.

### Yazdıkça arama

`Debouncer`, kullanıcı 300 ms boyunca yazmayı bıraktığında aramayı çalıştırır. Her yeni tuş vuruşu, bekleyen aramanın yerini alır.

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

### Kaydetme işlemlerinin üst üste binmesini önleme

Bir actor, önceki çağrı beklerken bir sonrakinin başlamasına izin verir. `TaskQueue` buna izin vermez: varsayılan sınır olan 1 ile her yazma, `save` çağrılarının sırasıyla, bir öncekinin bitmesinden sonra başlar.

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

`TaskQueue(maxConcurrentOperations: 4)` aynı anda en fazla dört işlem çalıştırır ve bunları yine de sırayla başlatır.

### Birçok çağıran için tek istek gönderme

`SingleFlight`, bir profil için zaten çalışmakta olan isteği paylaşır; `CircuitBreaker` ise üst üste beş hatadan sonra 30 saniye boyunca çağrıları reddeder.

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

### Beklemeden test etme

Bir `TestClock` verin, kod uykuya geçene kadar bekleyin, ardından zamanı kendiniz ilerletin.
[`ReadmeSamplesTests.swift`](Tests/SwiftConcurrencyTests/ReadmeSamplesTests.swift) dosyasındaki bu test dört harf yazar ve yalnızca son sorgunun arandığını doğrular:

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

`Recorder`, test hedefindeki küçük bir actor'dür; değerleri toplar ve onları bekler.

## Demo

[ConcurrencyDemo](Examples/ConcurrencyDemo) uygulaması her aracı gerçek kütüphaneyle çalıştırır. Ekran görüntüleri, uygulamanın bir iOS 27 simülatöründeki halinden alınmıştır ve
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) ile yakalanmıştır:

| Debounce'lu arama | İndirme kuyruğu (sınır 2) | Yeniden deneme ve circuit breaker |
| --- | --- | --- |
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-search-dark.png"><img src="docs/images/demo-search-light.png" width="260" alt="Arama ekranı: dört tuş vuruşu, tek arama, “task” için sonuçlar"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-downloads-dark.png"><img src="docs/images/demo-downloads-light.png" width="260" alt="İndirme kuyruğu: en fazla ikisinin üst üste bindiği altı dosyanın zaman çizelgesi"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-retry-dark.png"><img src="docs/images/demo-retry-light.png" width="260" alt="Yeniden deneme günlüğü: üç istek üç denemeden sonra başarısız oluyor, ardından açık devre ikisini reddediyor"></picture> |

Çalıştırmak için `ConcurrencyDemo.xcodeproj` dosyasını [Examples/ConcurrencyDemo](Examples/ConcurrencyDemo) içinden Xcode 26 veya üstüyle açın, bir iPhone simülatörü ya da **My Mac** seçin ve **Run**'a basın.
[Examples/README.md](Examples/README.md) her ekranı anlatır.

## Dokümantasyon

API başvuru belgeleri ve makaleler:

- [SwiftConcurrency API başvurusu](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/)
- [Başlarken](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/gettingstarted)
- [Zamana bağlı kodu test etme](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/testingtimebasedcode)
- [İptal ve sınırlar](https://muhittincamdali.github.io/SwiftConcurrency/documentation/swiftconcurrency/cancellationandlimits)

## Rehberler

- [Başlarken](Sources/SwiftConcurrency/SwiftConcurrency.docc/GettingStarted.md) — hangi tür hangi sorunu çözer, her biri için bir örnekle.
- [Zamana bağlı kodu test etme](Sources/SwiftConcurrency/SwiftConcurrency.docc/TestingTimeBasedCode.md)
  — `TestClock` iş akışı: oluşturma, uyuyanları bekleme, ilerletme.
- [İptal ve sınırlar](Sources/SwiftConcurrency/SwiftConcurrency.docc/CancellationAndLimits.md)
  — her API'nin görevi iptal edildiğinde ne yaptığı, reddettiği girdiler ve belleği nasıl sınırladığı.

## Gereksinimler

| Platform | En düşük sürüm |
| --- | --- |
| iOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |
| visionOS | 1 |
| Araç zinciri | Swift 6.2 · Xcode 26+ |

## Mimari

Paket, `SwiftConcurrency` adlı tek bir modüldür ve sorunlara göre gruplanmıştır:

| Klasör | Türler |
| --- | --- |
| `Synchronization/` | `AsyncSemaphore` |
| `Tasks/` | `TaskQueue`, `SingleFlight`, `withTimeout` / `withDeadline`, `concurrentMap` / `concurrentForEach` |
| `Resilience/` | `retry`, `Backoff`, `CircuitBreaker` |
| `Rate/` | `Debouncer`, `Throttler` |
| `Testing/` | `TestClock` |
| `Internal/` | `Locked` (adil olmayan bir kilit), `WaiterQueue` (askıya alınmış çağıranların FIFO kuyruğu), `ElapsedClock` |

Tasarım kararları:

- **Actor değil, kilitli sınıflar.** `signal()`, `cancel()`, `submit(_:)` ve `advance(by:)` geri dönmeden önce etkisini gösterir; bu yüzden araya başka işlerin girmesine izin veren bir `await` olmadan senkron koddan, `defer` içinden ve testlerden çağrılabilirler.
- **Askıdaki çağıranlar, bir `WaiterQueue` içindeki continuation'lardır.** Bir iptal işleyicisi, kendi kaydını o kaydı oluşturan kilidin altında siler; böylece hiçbir bekleyen kaybolmaz ya da iki kez devam ettirilmez.
- **İşlemler, mümkün olduğunda çağıranın actor'ünde çalışır.** `retry`, `AsyncSemaphore.withPermit` ve `CircuitBreaker.run` `nonisolated(nonsending)` olduğundan verdiğiniz closure'lar main actor durumuna dokunabilir ve `Sendable` yakalama gerektirmez. Başka bir görevde çalışması gereken işler (`TaskQueue`, `SingleFlight`, `withTimeout`, `concurrentMap`) `@Sendable` closure alır.
- **Zamanlı her tür bir `Clock` alır.** Üretim kodu `ContinuousClock` kullanır; testler bir `TestClock` verir.

### Nereye oturuyor

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms), `AsyncSequence` üzerindeki operatörleri (`debounce`, `throttle`, `merge`, `zip`, `AsyncChannel`) kapsar; verileriniz zaten bir dizi olarak geliyorsa onu kullanın. SwiftConcurrency ise çağrılarla başlatılan işleri kapsar: sınırlar, kuyruklar, zaman aşımları, yeniden denemeler, bir metot çağrısını debounce etme, circuit breaking ve paylaşılan istekler. İki paket yan yana çalışır.

## Yol haritası

- Linux desteği: `OSAllocatedUnfairLock` yerine standart kütüphanenin `Mutex` türünü kullanmak; bunun için Apple platformlarındaki asgari sürümlerin iOS 18 ve macOS 15'e yükseltilmesi gerekir.
- Saniyede belirli sayıda isteğe izin veren API'ler için bir token-bucket hız sınırlayıcı.
- `TaskQueue` için bir öncelik seçeneği; böylece acil işlemler eski olanlardan önce başlayabilir.

## Katkıda bulunma

Katkılarınızı bekliyoruz. Pull request açmadan önce [katkı rehberini](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CONTRIBUTING.md) ve [davranış kurallarını](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/CODE_OF_CONDUCT.md) okuyun. Güvenlik açıklarını [güvenlik politikasında](https://github.com/muhittincamdali/SwiftConcurrency/blob/main/SECURITY.md) anlatıldığı gibi gizli olarak bildirin.

## Lisans

MIT lisansıyla yayımlanmıştır. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
