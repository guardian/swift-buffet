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
        .executable(name: "SwiftBuffetTool", targets: ["SwiftBuffetTool"])
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
            dependencies: ["SwiftBuffetTool"]
        ),
        .executableTarget(
            name: "SwiftBuffetTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SwiftBuffetToolTests",
            dependencies: ["SwiftBuffetTool"]
        )
    ]
)
