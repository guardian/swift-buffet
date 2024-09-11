// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ExampleApp",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    dependencies: [
        .package(path: "../SwiftBuffet")
    ],
    targets: [
        .executableTarget(
            name: "ExampleApp",
            resources: [
                .process("example.proto")
            ],
            plugins: [
                .plugin(name: "SwiftBuffetPlugin", package: "SwiftBuffet"),
            ]
        )
    ]
)
