// swift-tools-version:5.7
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
        .package(url: "https://github.com/apple/swift-crypto.git", "2.0.0" ..< "4.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.53.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.24.0"),
    ],
    targets: [
        .target(
            name: "MySQLNIOCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]
        ),
        .target(
            name: "MySQLNIO",
            dependencies: [
                .target(name: "MySQLNIOCore"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]
        ),
        .testTarget(name: "MySQLNIOCoreTests", dependencies: [
            .target(name: "MySQLNIOCore"),
        ]),
        .testTarget(name: "MySQLNIOTests", dependencies: [
            .target(name: "MySQLNIO"),
        ]),
    ]
)
