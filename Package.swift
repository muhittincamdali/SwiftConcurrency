// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftConcurrency",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "SwiftConcurrency", targets: ["SwiftConcurrency"]),
    ],
    targets: [
        .target(name: "SwiftConcurrency"),
        .testTarget(
            name: "SwiftConcurrencyTests",
            dependencies: ["SwiftConcurrency"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
