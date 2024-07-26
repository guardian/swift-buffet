import Foundation

func mapProtoTypeToSwift(_ type: String, isMap: Bool = false) -> String {
    if isMap {
        // Skip map types since they are handled separately
        return type
    }
    switch type {
    case "double": return "Double"
    case "float": return "Float"
    case "int32", "sint32", "sfixed32": return "Int"
    case "int64", "sint64", "sfixed64": return "Int"
    case "uint32", "fixed32": return "UInt"
    case "uint64", "fixed64": return "UInt"
    case "bool": return "Bool"
    case "string": return "String"
    case "bytes": return "Data"
    case "google.protobuf.Timestamp": return "Date"
    case "google.protobuf.Duration": return "TimeInterval"
    default: return type // Handle nested messages and enums if needed
    }
}

func snakeToCamelCase(_ string: String) -> String {
    let components = string.split(separator: "_")
    guard let first = components.first else {
        return string.lowercased()
    }
    return components
        .dropFirst()
        .reduce(String(first).lowercased()) {
            $0 + $1.capitalized
        }
}

func stripCommonPrefix(from cases: [ProtoEnumCase]) -> [ProtoEnumCase] {
    guard let prefix = findCommonPrefix(in: cases.map { $0.name }) else {
        return cases
    }

    return cases.map { enumCase in
        let removePrefix = enumCase.name.replacingOccurrences(of: prefix, with: "")
        let newName = snakeToCamelCase(removePrefix)
        return ProtoEnumCase(
            name: newName,
            value: enumCase.value
        )
    }
}

func findCommonPrefix(in strings: [String]) -> String? {
    guard var prefix = strings.first else {
        return nil
    }
    for string in strings {
        while !string.hasPrefix(prefix) {
            prefix = String(prefix.dropLast())
            if prefix.isEmpty {
                return nil
            }
        }
    }
    return prefix
}

func readFileContents(filename: String, file: StaticString = #file) -> String? {
    let fileURL = URL(fileURLWithPath: "\(file)", isDirectory: false)
    let directoryURL = fileURL.deletingLastPathComponent()
    let targetFileURL = directoryURL.appendingPathComponent(filename)

    do {
        let fileContents = try String(contentsOf: targetFileURL)
        return fileContents
    } catch {
        print("Error reading file: \(error)")
        return nil
    }
}
