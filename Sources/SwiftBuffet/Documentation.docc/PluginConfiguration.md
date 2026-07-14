# Plugin Configuration
Configure the build plugin per target with a `swiftbuffet.json` file.

## Overview
The build plugin runs the generator with default options. To customize it, place a `swiftbuffet.json` file in the target's source directory (next to your `.proto` files). All fields are optional and map one-to-one onto the command-line options described in <doc:CommandLineUsage>:
```json
{
    "swiftPrefix": "App",
    "includeProtobuf": true,
    "protoPrefix": "Proto",
    "storeBackingData": false,
    "localIDMessages": ["FingerSandwich"],
    "quiet": true
}
```

| Field | Type | CLI equivalent |
| --- | --- | --- |
| `swiftPrefix` | String | `--swift-prefix` |
| `includeProtobuf` | Bool | `--include-protobuf` |
| `protoPrefix` | String | `--proto-prefix` |
| `storeBackingData` | Bool | `--store-backing-data` |
| `localIDMessages` | [String] | `--local-id-messages` (one per element) |
| `quiet` | Bool | `--quiet` — defaults to `true` in plugin builds to keep build logs clean; set `false` to see progress output |
The config file is registered as a build input, so editing it retriggers generation on the next build.

## Excluding the config file from resources
SwiftPM warns about unhandled files in a target directory. Add the config to the target's `exclude` list:

```swift
.target(
    name: "YourTarget",
    exclude: ["swiftbuffet.json"],
    resources: [
        .process("buffet.proto")
    ],
    plugins: [
        .plugin(name: "SwiftBuffetPlugin", package: "SwiftBuffet")
    ]
)
```

## Xcode app projects
The plugin also works in Xcode projects (not just packages). Add the package to the project, attach **SwiftBuffetPlugin** in the target's *Build Phases → Run Build Tool Plug-ins*, and add your `.proto` files to the target. For Xcode projects, `swiftbuffet.json` is looked up in the **project directory** rather than per target.

## SwiftProtobuf bridging
When `includeProtobuf` is `true`, the generated `init?(proto:)`/`init?(data:)` initializers reference types named `<protoPrefix><MessageName>`. Those types must exist in the consuming target — typically by also running `protoc` with the SwiftProtobuf plugin over the same `.proto` files and depending on `SwiftProtobuf`. Swift Buffet does not generate them.
