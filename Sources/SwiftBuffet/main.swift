import Foundation
import ArgumentParser

struct SwiftBuffet: ParsableCommand {
    @Argument(help: "The input .proto file")
    var inputProto: String

    @Argument(help: "The output .swift file")
    var outputSwift: String

    @Option(
        name: .customLong("swift-prefix"),
        help: "The prefix to use for Swift objects"
    )
    var swiftPrefix: String = ""

    @Flag(
        name: .customLong("include-protobuf"),
        help: "Add initialisers from protobuf objects"
    )
    var includeProtobuf: Bool = false

    @Option(
        name: .customLong("proto-prefix"),
        help: "The prefix to use for protobuf objects"
    )
    var protoPrefix: String = "Proto"

    @Flag(
        name: .customLong("store-backing-data"),
        help: "Keeps the data when initialised from a protobuf object"
    )
    var storeBackingData: Bool = false

    @Option(
        name: .customLong("local-id-messages"),
        help: "Message names that should include a generated local ID property. Useful as a stable identity in SwiftUI"
    )
    var localIDMessages: [String] = []

    @Flag(name: .shortAndLong, help: "Show all logging")
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Show no logging")
    var quiet: Bool = false

    func run() throws {
        let inputURL = URL(fileURLWithPath: inputProto)
        let outputURL = URL(fileURLWithPath: outputSwift)

        if quiet == false {
            print("Processing \(inputURL)")
        }

        let (messages, enums) = try parseProtoFile(
            at: inputURL,
            with: swiftPrefix,
            verbose: verbose
        )
       
        let swiftCode = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: swiftPrefix,
            includeProto: includeProtobuf,
            includeLocalIDFor: localIDMessages,
            includeBackingData: storeBackingData,
            with: protoPrefix
        )

        try swiftCode.write(
            to: outputURL,
            atomically: true,
            encoding: .utf8
        )
    }
}

SwiftBuffet.main()
