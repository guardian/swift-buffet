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

    @Option(
        name: .customLong("store-backing-data"),
        help: "Keeps the data when initialised from a protobuf object"
    )
    var storeBackingData: Bool = false

    @Option(
        name: .customLong("use-local-ids"),
        help: "Add a local ID to protobuf objects, can be useful in SwiftUI"
    )
    var useLocalIDS: Bool = true

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
            includeLocalID: useLocalIDS,
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
