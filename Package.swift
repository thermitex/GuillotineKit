// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "GuillotineKit",
    products: [
        .executable(name: "Guillotine", targets: ["GuillotineCLI"]),
        .library(name: "GuillotineKit", targets: ["GuillotineKit"]),
    ],
    dependencies: [
         .package(path: "../BDIndexDB"),
         .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
         .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GuillotineCLI",
            dependencies: [
                "GuillotineKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .target(name: "GuillotineKit",
            dependencies: [
                .product(name: "IndexStoreDB", package: "BDIndexDB"),
                .product(name: "Logging", package: "swift-log")
            ]),
        .testTarget(
            name: "GuillotineTests",
            dependencies: [
                "GuillotineKit"
            ]),
    ]
)
