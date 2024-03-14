// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "mysql-nio",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "MySQLNIO", targets: ["MySQLNIO"]),
        .library(name: "MySQLNIOCore", targets: ["MySQLNIOCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.4.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "2.6.0" ..< "4.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.53.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.24.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "MySQLNIOCore",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MySQLNIO",
            dependencies: [
                .target(name: "MySQLNIOCore"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MySQLNIOCoreTests",
            dependencies: [.target(name: "MySQLNIOCore")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MySQLNIOTests",
            dependencies: [.target(name: "MySQLNIO")],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
] }
