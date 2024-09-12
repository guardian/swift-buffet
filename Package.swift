// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftBuffet",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .plugin(name: "SwiftBuffetPlugin", targets: ["SwiftBuffetPlugin"]),
        .executable(name: "SwiftBuffet", targets: ["SwiftBuffet"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.5.0")
        ),
    ],
    targets: [
        .plugin(
            name: "SwiftBuffetPlugin",
            capability: .buildTool(),
            dependencies: ["SwiftBuffet"]
        ),
        .executableTarget(
            name: "SwiftBuffet",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SwiftBuffetTests",
            dependencies: ["SwiftBuffet"]
        )
    ]
)
