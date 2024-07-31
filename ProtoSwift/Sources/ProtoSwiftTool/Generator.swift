import Foundation

/// Generates Swift code from protocol buffer messages and enums.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` representing protocol buffer messages.
///   - enums: An array of `ProtoEnum` representing protocol buffer enums.
/// - Returns: A string containing the generated Swift code.
func generateSwiftCode(from messages: [ProtoMessage], enums: [ProtoEnum]) -> String {
    var output = "import Foundation\n\n"

    let needsTimeIntervalHelper = write(messages, to: &output)
    write(enums, to: &output)

    if needsTimeIntervalHelper {
        writeTimeIntervalHelper(messages, to: &output)
    }

    return output
}

/// Writes the Swift code for protocol buffer enums.
///
/// - Parameters:
///   - enums: An array of `ProtoEnum` to be written.
///   - output: A mutable string where the generated code will be appended.
fileprivate func write(_ enums: [ProtoEnum], to output: inout String) {
    if enums.isEmpty == false {
        output += "// MARK: - Enums\n"
    }
    for protoEnum in enums.sorted(by: { $0.name < $1.name }) {
        let strippedCases = stripCommonPrefix(from: protoEnum.cases)
        let pair = zip(
            strippedCases.map(\.name),
            protoEnum.cases.map(\.value)
        )
        if let parent = protoEnum.parentName {
            output += "extension Blueprint\(parent) {\n"
        }
        output += "public enum Blueprint\(protoEnum.name): Int, Codable {\n"
        for (caseName, caseValue) in pair {
            output += "    case \(caseName) = \(caseValue)\n"
        }
        writeEnumProtoInit(for: protoEnum, to: &output)
        if let parent = protoEnum.parentName {
            output += "}\n"
        }
        output += "}\n\n"
    }
}

/// Writes the initializer for a protocol buffer enum.
///
/// - Parameters:
///   - protoEnum: The `ProtoEnum` to write the initializer for.
///   - output: A mutable string where the generated code will be appended.
fileprivate func writeEnumProtoInit(for protoEnum: ProtoEnum, to output: inout String) {
    output += "    init?(_ proto: Proto\(protoEnum.fullName)) {\n"
    output += "        self.init(rawValue: proto.rawValue)\n"
    output += "    }\n"
}

/// Writes the Swift code for protocol buffer messages.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` to be written.
///   - output: A mutable string where the generated code will be appended.
/// - Returns: A boolean indicating whether a TimeInterval helper is needed.
@discardableResult
fileprivate func write(_ messages: [ProtoMessage], to output: inout String) -> Bool {
    if messages.isEmpty == false {
        output += "// MARK: - Structs\n"
    }

    var needsTimeIntervalHelper = false

    for message in messages.sorted(by: { $0.name < $1.name }) {
        output += "public struct Blueprint\(message.name): Codable {\n"

        let hasTimeInterval = addProperties(for: message, to: &output)

        addBasicInit(for: message, to: &output)
        writeMessageProtoInit(for: message, to: &output)

        if hasTimeInterval {
            writeDurationInit(for: message, to: &output)
            needsTimeIntervalHelper = true
        }

        output += "}\n\n"
    }

    return needsTimeIntervalHelper
}

/// Adds properties to a message struct.
///
/// - Parameters:
///   - message: The `ProtoMessage` to add properties for.
///   - output: A mutable string where the generated code will be appended.
/// - Returns: A boolean indicating whether the message has a TimeInterval property.
@discardableResult
fileprivate func addProperties(for message: ProtoMessage, to output: inout String) -> Bool {
    var hasTimeInterval = false
    for field in message.fields {
        if let comment = field.comment {
            output += "\n"
            output += comment
                .replacingOccurrences(of: "/**", with: "")
                .replacingOccurrences(of: "*/", with: "")
                .replacingOccurrences(of: "*", with: "")
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { String("    // \($0)") }
                .joined(separator: "\n")
            output += "\n"
        }
        output += "    public let \(field.caseCorrectName): \(field.caseCorrectedType)\n"
        if field.caseCorrectedType.contains("TimeInterval") {
            hasTimeInterval = true
        }
    }
    return hasTimeInterval
}

/// Adds a basic initializer to a message struct.
///
/// - Parameters:
///   - message: The `ProtoMessage` to add the initializer for.
///   - output: A mutable string where the generated code will be appended.
fileprivate func addBasicInit(for message: ProtoMessage, to output: inout String) {

    func addDefaultValue(for field: ProtoField, to output: inout String) {
        if field.isOptional {
            output += " = nil"
        } else if field.isRepeated {
            output += " = []"
        } else if field.type == "bool" {
            output += " = false"
        }
    }

    var fields = message.fields

    let first = fields.first
    fields.removeFirst()

    let last = fields.popLast()

    if let field = first {
        output += "\n    init(\(field.caseCorrectName): \(field.caseCorrectedType)"
        addDefaultValue(for: field, to: &output)
    }

    if last == nil {
        output += ") {\n"
    } else {
        output += ",\n"

        for field in fields {
            output += "         \(field.caseCorrectName): \(field.caseCorrectedType)"
            addDefaultValue(for: field, to: &output)
            output += ",\n"
        }

        if let field = last {
            output += "         \(field.caseCorrectName): \(field.caseCorrectedType)"
            addDefaultValue(for: field, to: &output)
            output += "\n"
        }

        output += "    ) {\n"
    }

    for field in message.fields {
        output += "        self.\(field.caseCorrectName) = \(field.caseCorrectName)\n"
    }

    output += "    }\n"
}

/// Writes the initializer for a protocol buffer message.
///
/// - Parameters:
///   - message: The `ProtoMessage` to write the initializer for.
///   - output: A mutable string where the generated code will be appended.
fileprivate func writeMessageProtoInit(for message: ProtoMessage, to output: inout String) {
    output += "    init?(_ proto: Proto\(message.name)) {\n"
    for field in message.fields {
        if field.isPrimitiveType {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectName)\n"
        } else if field.isRepeated {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectName).compactMap { \(field.caseCorrectedBaseType)($0) }\n"
        } else if field.isMap {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectName).reduce(into: \(field.caseCorrectedType.replacingOccurrences(of: "?", with: ""))()) { $0[$1.key] = $1.value }\n"
        } else if field.isOptional == false {
            output += "        self.\(field.caseCorrectName) = \(field.caseCorrectedBaseType)(proto.\(field.caseCorrectName))!\n"
        } else if field.caseCorrectedBaseType == "TimeInterval" {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectName).timeInterval\n"
        } else if field.caseCorrectedBaseType == "Date" {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectName).date\n"
        } else {
            output += "        self.\(field.caseCorrectName) = \(field.caseCorrectedBaseType)(proto.\(field.caseCorrectName))\n"
        }
    }
    output += "    }\n"
}

/// Writes the custom initializer and encoder for messages with TimeInterval fields.
///
/// - Parameters:
///   - message: The `ProtoMessage` to write the custom initializer and encoder for.
///   - output: A mutable string where the generated code will be appended.
fileprivate func writeDurationInit(for message: ProtoMessage, to output: inout String) {
    output += "\n    enum CodingKeys: String, CodingKey {\n"
    for field in message.fields {
        output += "        case \(field.caseCorrectName) = \"\(field.caseCorrectName)\"\n"
    }
    output += "    }\n"

    output += "\n"
    output += "    public init(from decoder: Decoder) throws {\n"
    output += "        let container = try decoder.container(keyedBy: CodingKeys.self)\n"

    for field in message.fields {
        switch field.caseCorrectedType {
        case "TimeInterval":
            output += "        let \(field.caseCorrectName)String = try container.decode(String.self, forKey: .\(field.caseCorrectName))\n"
            output += "        self.\(field.caseCorrectName) = TimeInterval(from: \(field.caseCorrectName)String) ?? 0\n"
        default:
            output += "        self.\(field.caseCorrectName) = try container.decode(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName))\n"
        }
    }

    output += "    }\n"

    output += "\n"
    output += "    public func encode(to encoder: Encoder) throws {\n"
    output += "        var container = encoder.container(keyedBy: CodingKeys.self)\n"

    for field in message.fields {
        switch field.caseCorrectedType {
        case "TimeInterval":
            output += "        let \(field.caseCorrectName)String = String(self.\(field.caseCorrectName)) + \"s\"\n"
            output += "        try container.encode(\(field.caseCorrectName)String, forKey: .\(field.caseCorrectName))\n"
        default:
            output += "        try container.encode(self.\(field.caseCorrectName), forKey: .\(field.caseCorrectName))\n"
        }
    }

    output += "    }\n"
}

/// Writes the TimeInterval helper extension if needed.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` to check for TimeInterval fields.
///   - output: A mutable string where the generated code will be appended.
fileprivate func writeTimeIntervalHelper(_ messages: [ProtoMessage], to output: inout String) {
    if let fileContents = readFileContents(filename: "TimeInterval+String.swift") {
        output += "// MARK: - TimeInterval Extension\n"
        output += fileContents
            .replacingOccurrences(of: "import Foundation", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        output += "// File not found."
    }
}
