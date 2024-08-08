// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ProtoSwift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .plugin(name: "ProtoSwiftPlugin", targets: ["ProtoSwiftPlugin"]),
        .executable(name: "ProtoSwiftTool", targets: ["ProtoSwiftTool"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.5.0")
        ),
    ],
    targets: [
        .plugin(
            name: "ProtoSwiftPlugin",
            capability: .buildTool(),
            dependencies: ["ProtoSwiftTool"]
        ),
        .executableTarget(
            name: "ProtoSwiftTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ProtoSwiftToolTests",
            dependencies: ["ProtoSwiftTool"]
        )
    ]
)
