// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "mysql-nio",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "MySQLNIO", targets: ["MySQLNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.14.0"),
    ],
    targets: [
        .target(name: "MySQLNIO", dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
        ]),
        .testTarget(name: "MySQLNIOTests", dependencies: [
            .target(name: "MySQLNIO"),
        ]),
    ]
)
