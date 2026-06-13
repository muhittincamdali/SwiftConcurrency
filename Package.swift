// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftConcurrency",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SwiftConcurrency", targets: ["SwiftConcurrency"]),
    ],
    targets: [
        .target(
            name: "SwiftConcurrency",
            path: "Sources/SwiftConcurrency",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftConcurrencyTests",
            dependencies: ["SwiftConcurrency"]
        )
    ]
)
