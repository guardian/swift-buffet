import Foundation

func main() {
    if CommandLine.argc < 3 {
        print("Usage: ProtoSwiftTool <input.proto> <output.swift>")
        exit(1)
    }

    let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

    do {
        print("Processing \(inputURL)")
        let (messages, enums) = try parseProtoFile(at: inputURL)
        let swiftCode = generateSwiftCode(from: messages, enums: enums)
        try swiftCode.write(to: outputURL, atomically: true, encoding: .utf8)
    } catch {
        print("Failed to generate Swift code: \(error)")
        exit(1)
    }
}

main()
