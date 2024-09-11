import PackagePlugin
import Foundation

@main
struct SwiftBuffet: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // This plugin only runs for package targets that can have source files.
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

        var commands: [Command] = []

        for sourceFile in sourceFiles {
            if sourceFile.path.extension == "proto" {
                let outputPath = context.pluginWorkDirectory.appending("\(sourceFile.path.stem).swift")
                commands.append(
                    .buildCommand(
                        displayName: "Generating Swift code for \(sourceFile.path.lastComponent)",
                        executable: try context.tool(named: "SwiftBuffetTool").path,
                        arguments: [sourceFile.path.string, outputPath.string],
                        inputFiles: [sourceFile.path],
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
        var commands: [Command] = []

        for sourceFile in target.inputFiles {
            if sourceFile.path.extension == "proto" {
                let outputPath = context.pluginWorkDirectory.appending("\(sourceFile.path.stem).swift")
                commands.append(.buildCommand(
                    displayName: "Generating Swift code for \(sourceFile.path.lastComponent)",
                    executable: try context.tool(named: "SwiftBuffetTool").path,
                    arguments: [sourceFile.path.string, outputPath.string],
                    inputFiles: [sourceFile.path],
                    outputFiles: [outputPath]
                ))
            }
        }

        return commands
    }
}
#endif
