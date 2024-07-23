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
        .package(path: "../ProtoSwift")
    ],
    targets: [
        .executableTarget(
            name: "ExampleApp",
            dependencies: [
                .product(name: "ProtoSwift", package: "ProtoSwift")
            ],
            resources: [
                .copy("../proto/example.proto")
            ]
        )
    ]
)
