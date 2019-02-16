// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "nio-mysql",
    products: [
        .library(name: "NIOMySQL", targets: ["NIOMySQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .branch("master")),
    ],
    targets: [
        .target(name: "NIOMySQL", dependencies: ["NIO"]),
        .testTarget(name: "NIOMySQLTests", dependencies: ["NIOMySQL"]),
    ]
)
