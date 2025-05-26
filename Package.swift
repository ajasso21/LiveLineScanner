// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiveLineScanner",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LiveLineScanner",
            targets: ["LiveLineScanner"]),
    ],
    dependencies: [
        .package(name: "Starscream", url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "4.0.0")),
        .package(name: "SwiftUICharts", url: "https://github.com/willdale/SwiftUICharts.git", .upToNextMajor(from: "1.0.0")),
        .package(name: "Hero", url: "https://github.com/HeroTransitions/Hero.git", .upToNextMajor(from: "1.6.2")),
        .package(name: "OpenAI", url: "https://github.com/MacPaw/OpenAI.git", .upToNextMajor(from: "0.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LiveLineScanner",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "SwiftUICharts", package: "SwiftUICharts"),
                .product(name: "Hero", package: "Hero"),
                .product(name: "OpenAI", package: "OpenAI")
            ]),
        .testTarget(
            name: "LiveLineScannerTests",
            dependencies: ["LiveLineScanner"]
        ),
    ]
)
