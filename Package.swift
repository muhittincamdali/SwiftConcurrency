// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftConcurrency",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftConcurrency",
            targets: ["SwiftConcurrency"]
        )
    ],
    targets: [
        .target(
            name: "SwiftConcurrency",
            path: "Sources/SwiftConcurrency"
        ),
        .testTarget(
            name: "SwiftConcurrencyTests",
            dependencies: ["SwiftConcurrency"],
            path: "Tests/SwiftConcurrencyTests"
        )
    ]
)
