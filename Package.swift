// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "nio-mysql",
    products: [
        .library(name: "NIOMySQL", targets: ["NIOMySQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0-convergence"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0-convergence"),
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
        .target(name: "NIOMySQL", dependencies: ["CMySQLOpenSSL", "NIO", "NIOSSL"]),
        .testTarget(name: "NIOMySQLTests", dependencies: ["NIOMySQL"]),
    ]
)
