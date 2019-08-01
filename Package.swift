// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "mysql-nio",
    products: [
        .library(name: "MySQLNIO", targets: ["MySQLNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0"),
    ],
    targets: [
        .systemLibrary(
            name: "CMySQLOpenSSL",
            pkgConfig: "openssl",
            providers: [
                .apt(["openssl libssl-dev"]),
                .brew(["openssl"])
            ]
        ),
        .target(name: "MySQLNIO", dependencies: ["CMySQLOpenSSL", "NIO", "NIOSSL"]),
        .testTarget(name: "MySQLNIOTests", dependencies: ["MySQLNIO"]),
    ]
)
