# Getting Started
Add Swift Buffet to a package, point it at a proto file, and use the generated types.

## Add the package
Add the dependency to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/guardian/swift-buffet.git", from: "1.0.0")
]
```

## Use the build plugin
Add your `.proto` file to a target as a processed resource and attach the plugin:
```swift
targets: [
    .target(
        name: "YourTarget",
        resources: [
            .process("buffet.proto")
        ],
        plugins: [
            .plugin(name: "SwiftBuffetPlugin", package: "SwiftBuffet")
        ]
    )
]
```
That's it. On every build, the plugin finds each `.proto` file in the target, runs the generator, and compiles the resulting `.swift` file into the target. There is nothing to check in: generated sources live in the build directory.

## Write a proto file
```proto
syntax = "proto3";

message FingerSandwich {
    string filling = 1;
    string bread = 2;
    optional int32 quarters = 3;
}

message Buffet {
    repeated FingerSandwich sandwiches = 1;
    optional bool crusts_removed = 2;
}
```

## Use the generated types
The example above generates two plain structs you can use anywhere in your target:
```swift
let cucumber = FingerSandwich(filling: "cucumber", bread: "white", quarters: 4)
let buffet = Buffet(sandwiches: [cucumber], crustsRemoved: true) // naturally
```
Field names are converted from `snake_case` to `camelCase`, `repeated` fields become arrays, and proto3 `optional` fields become Swift optionals with sensible decoding defaults. See <doc:GeneratedCode> for the full mapping.

## Next steps
- Configure prefixes, protobuf bridging, and more with a `swiftbuffet.json` file — see <doc:PluginConfiguration>.
- Run the generator by hand or in scripts — see <doc:CommandLineUsage>.
- Check which proto constructs are supported — see <doc:SupportedProtoFeatures>.
