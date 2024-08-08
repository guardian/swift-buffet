import Foundation
import ArgumentParser

struct ProtoSwiftTool: ParsableCommand {
    @Argument(help: "The input .proto file")
    var inputProto: String

    @Argument(help: "The output .swift file")
    var outputSwift: String

    @Option(
        name: .customLong("swift-prefix"),
        help: "The prefix to use for Swift objects"
    )
    var swiftPrefix: String = ""

    @Option(
        name: .customLong("include-protobuf"),
        help: "Add initialisers from protobuf objects"
    )
    var includeProtobuf: Bool = false

    @Option(
        name: .customLong("proto-prefix"),
        help: "The prefix to use for protobuf objects"
    )
    var protoPrefix: String = "Proto"

    @Flag(name: .shortAndLong, help: "Show all logging")
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Show no logging")
    var quite: Bool = false

    func run() throws {
        let inputURL = URL(fileURLWithPath: inputProto)
        let outputURL = URL(fileURLWithPath: outputSwift)

        if quite == false {
            print("Processing \(inputURL)")
        }
        
        let (messages, enums) = try parseProtoFile(
            at: inputURL,
            with: swiftPrefix,
            verbose: verbose,
            quite: quite
        )
       
        let swiftCode = generateSwiftCode(
            from: messages,
            enums: enums,
            with: swiftPrefix,
            includeProto: includeProtobuf,
            with: protoPrefix
        )

        try swiftCode.write(
            to: outputURL,
            atomically: true,
            encoding: .utf8
        )
    }
}

ProtoSwiftTool.main()
