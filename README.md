<p align="center">
  <img src="logo.png" alt="Swift Buffet Logo" />
</p>

Swift Buffet is a Swift package that generates Swift files from Protocol Buffer (`.proto`) files. This tool can be used both as a command-line tool and as a Swift Package Manager plugin.

## Installation

### Swift Package Manager

To integrate Swift Buffet into your project, add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/guardian/swift-buffet.git", from: "1.0.0")
]
```

### As a Plugin

To use Swift Buffet as a plugin, include it in your target's `plugins` array in `Package.swift`:

```swift
targets: [
    .target(
        name: "YourTarget",
        resources: [
            .process("yourFile.proto")
        ],
        plugins: [
            .plugin(name: "SwiftBuffetPlugin", package: "SwiftBuffet"))
        ]
    )
]
```

## Usage

### Command-line Tool

To generate Swift files from a `.proto` file, run the following command:

```bash
swift run swift-buffet path/to/your/file.proto
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Acknowledgements

- [Protocol Buffers](https://developers.google.com/protocol-buffers)
- [Swift Package Manager](https://swift.org/package-manager/)

---
