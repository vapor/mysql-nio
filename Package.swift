// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "mysql-nio",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "MySQLNIO", targets: ["MySQLNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0"),
    ],
    targets: [
        .systemLibrary(
            name: "CMySQLOpenSSL",
            pkgConfig: "openssl",
            providers: [
                .apt(["openssl libssl-dev"]),
                .brew(["openssl@1.1"])
            ]
        ),
        .target(name: "MySQLNIO", dependencies: ["CMySQLOpenSSL", "Logging", "NIO", "NIOSSL"]),
        .testTarget(name: "MySQLNIOTests", dependencies: ["MySQLNIO"]),
    ]
)
