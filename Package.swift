// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "nio-mysql",
    products: [
        .library(name: "NIOMySQL", targets: ["NIOMySQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .branch("master")),
        .package(url: "https://github.com/tanner0101/swift-nio-ssl.git", .branch("master")),
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
        .target(name: "NIOMySQL", dependencies: ["CMySQLOpenSSL", "NIO", "NIOOpenSSL"]),
        .testTarget(name: "NIOMySQLTests", dependencies: ["NIOMySQL"]),
    ]
)
