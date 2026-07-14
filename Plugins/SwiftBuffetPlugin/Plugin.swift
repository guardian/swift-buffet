import PackagePlugin
import Foundation

/// Optional per-target configuration, read from a `swiftbuffet.json` file in the
/// target's directory. All fields are optional; a missing file means defaults.
struct SwiftBuffetConfig: Decodable {
    var swiftPrefix: String?
    var includeProtobuf: Bool?
    var protoPrefix: String?
    var storeBackingData: Bool?
    var localIDMessages: [String]?
    var quiet: Bool?

    static let fileName = "swiftbuffet.json"

    static func load(in directory: Path) throws -> (config: SwiftBuffetConfig, path: Path)? {
        let path = directory.appending(Self.fileName)
        guard let data = FileManager.default.contents(atPath: path.string) else {
            return nil
        }
        let config = try JSONDecoder().decode(SwiftBuffetConfig.self, from: data)
        return (config, path)
    }

    /// Maps the config onto SwiftBuffet CLI arguments.
    func arguments(input: Path, output: Path) -> [String] {
        var args = [input.string, output.string]
        if let swiftPrefix {
            args += ["--swift-prefix", swiftPrefix]
        }
        if includeProtobuf == true {
            args.append("--include-protobuf")
        }
        if let protoPrefix {
            args += ["--proto-prefix", protoPrefix]
        }
        if storeBackingData == true {
            args.append("--store-backing-data")
        }
        for message in localIDMessages ?? [] {
            args += ["--local-id-messages", message]
        }
        // Stay quiet in build logs unless the config explicitly opts out.
        if quiet != false {
            args.append("--quiet")
        }
        return args
    }
}

@main
struct SwiftBuffet: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // This plugin only runs for package targets that can have source files.
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

        let loaded = try SwiftBuffetConfig.load(in: target.directory)
        var commands: [Command] = []

        for sourceFile in sourceFiles {
            if sourceFile.path.extension == "proto" {
                let outputPath = context.pluginWorkDirectory.appending("\(sourceFile.path.stem).swift")
                var inputFiles = [sourceFile.path]
                if let configPath = loaded?.path {
                    inputFiles.append(configPath)
                }
                commands.append(
                    .buildCommand(
                        displayName: "Generating Swift code for \(sourceFile.path.lastComponent)",
                        executable: try context.tool(named: "SwiftBuffet").path,
                        arguments: (loaded?.config ?? SwiftBuffetConfig()).arguments(
                            input: sourceFile.path,
                            output: outputPath
                        ),
                        inputFiles: inputFiles,
                        outputFiles: [outputPath]
                    )
                )
            }
        }

        return commands
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftBuffet: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let loaded = try SwiftBuffetConfig.load(in: context.xcodeProject.directory)
        var commands: [Command] = []

        for sourceFile in target.inputFiles {
            if sourceFile.path.extension == "proto" {
                let outputPath = context.pluginWorkDirectory.appending("\(sourceFile.path.stem).swift")
                var inputFiles = [sourceFile.path]
                if let configPath = loaded?.path {
                    inputFiles.append(configPath)
                }
                commands.append(.buildCommand(
                    displayName: "Generating Swift code for \(sourceFile.path.lastComponent)",
                    executable: try context.tool(named: "SwiftBuffet").path,
                    arguments: (loaded?.config ?? SwiftBuffetConfig()).arguments(
                        input: sourceFile.path,
                        output: outputPath
                    ),
                    inputFiles: inputFiles,
                    outputFiles: [outputPath]
                ))
            }
        }

        return commands
    }
}
#endif
