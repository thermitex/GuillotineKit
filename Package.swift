// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "GuillotineKit",
    products: [
        .executable(name: "Guillotine", targets: ["GuillotineCLI"]),
        .executable(name: "GuillotineService", targets: ["GuillotineService"]),
        .executable(name: "gltc", targets: ["GuillotineClient"]),
        .library(name: "GuillotineKit", targets: ["GuillotineKit"]),
    ],
    dependencies: [
        .package(url: "https://code.byted.org/liruijie.x/BDIndexDB", .branch("main")),
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
        .target(
            name: "GuillotineService",
            dependencies: [
                "GuillotineKit",
            ],
            exclude: ["com.bytedance.GuillotineService.plist"]),
        .target(
            name: "GuillotineClient",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [.copy("diff.py")]),
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
