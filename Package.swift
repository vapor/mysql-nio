// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "mysql-nio",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "MySQLNIO", targets: ["MySQLNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.14.0"),
        .package(url: "https://github.com/gwynne/swift-mini-rsa-crypt.git", from: "0.0.1"),
    ],
    targets: [
        .target(name: "MySQLNIO", dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Algorithms", package: "swift-algorithms"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
            .product(name: "MiniRSACrypt", package: "swift-mini-rsa-crypt"),
        ]),
        .testTarget(name: "MySQLNIOTests", dependencies: [
            .target(name: "MySQLNIO"),
        ]),
    ]
)
