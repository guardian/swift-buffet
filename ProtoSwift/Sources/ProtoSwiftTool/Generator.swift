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

    writeDateFormatter(to: &output)

    return output
}

/// Writes the Swift code for protocol buffer enums.
///
/// - Parameters:
///   - enums: An array of `ProtoEnum` to be written.
///   - output: A mutable string where the generated code will be appended.
internal func write(_ enums: [ProtoEnum], to output: inout String) {
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
        writCodableInit(for: protoEnum, to: &output)

        if protoEnum.parentName != nil {
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
internal func writeEnumProtoInit(for protoEnum: ProtoEnum, to output: inout String) {
    output += "#if USE_PROTO\n"
    output += "    init?(_ proto: Proto\(protoEnum.fullName)) {\n"
    output += "        self.init(rawValue: proto.rawValue)\n"
    output += "    }\n"
    output += "#endif\n"
}

/// Writes the Swift code for protocol buffer messages.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` to be written.
///   - output: A mutable string where the generated code will be appended.
/// - Returns: A boolean indicating whether a TimeInterval helper is needed.
@discardableResult
internal func write(_ messages: [ProtoMessage], to output: inout String) -> Bool {
    if messages.isEmpty == false {
        output += "// MARK: - Structs\n"
    }

    var needsTimeIntervalHelper = false

    for message in messages.sorted(by: { $0.name < $1.name }) {
        output += "public struct Blueprint\(message.name): Codable {\n"

        let hasTimeInterval = writeProperties(for: message, to: &output)

        if hasTimeInterval {
            needsTimeIntervalHelper = true
        }

        writeCodingKeys(for: message, to: &output)

        writeBasicInit(for: message, to: &output)

        writCodableInit(for: message, to: &output)

        writeMessageProtoInit(for: message, to: &output)


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
internal func writeProperties(for message: ProtoMessage, to output: inout String) -> Bool {
    var hasTimeInterval = false

    output += "    public let localID = UUID()\n"

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
internal func writeBasicInit(for message: ProtoMessage, to output: inout String) {

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
internal func writeMessageProtoInit(for message: ProtoMessage, to output: inout String) {
    output += "#if USE_PROTO\n"
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
    output += "#endif\n"
}

internal func writeCodingKeys(for message: ProtoMessage, to output: inout String) {
    output += "\n    enum CodingKeys: String, CodingKey {\n"
    for field in message.fields {
        output += "        case \(field.caseCorrectName) = \"\(snakeToCamelCase(field.name))\"\n"
    }
    output += "    }\n"
}

/// Writes the custom initializer and encoder for messages with TimeInterval fields.
///
/// - Parameters:
///   - message: The `ProtoMessage` to write the custom initializer and encoder for.
///   - output: A mutable string where the generated code will be appended.
internal func writCodableInit(for message: ProtoMessage, to output: inout String) {
    output += "\n"
    output += "    public init(from decoder: Decoder) throws {\n"
    output += "        let container = try decoder.container(keyedBy: CodingKeys.self)\n"

    for field in message.fields {
        if field.isRepeated {
            output += "        self.\(field.caseCorrectName) = try container.decodeIfPresent(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName)) ?? []\n"
        } else if field.isMap {
            output += "        self.\(field.caseCorrectName) = try container.decodeIfPresent(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName)) ?? [:]\n"
        } else if field.caseCorrectedType == "TimeInterval" {
            output += "        let \(field.caseCorrectName)String = try container.decode(String.self, forKey: .\(field.caseCorrectName))\n"
            output += "        self.\(field.caseCorrectName) = TimeInterval(from: \(field.caseCorrectName)String) ?? 0\n"
        } else if field.caseCorrectedType.contains("Date") {
            output += "        let \(field.caseCorrectName)String = try container.decode(String.self, forKey: .\(field.caseCorrectName))\n"
            output += "        self.\(field.caseCorrectName) = dateFormatter.date(from: \(field.caseCorrectName)String)\n"
        } else if field.isOptional {
            output += "        self.\(field.caseCorrectName) = try container.decodeIfPresent(\(field.caseCorrectedType.replacingOccurrences(of: "?", with: "")).self, forKey: .\(field.caseCorrectName))\n"
        } else if field.type == "bool" {
            output += "        self.\(field.caseCorrectName) = try container.decodeIfPresent(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName)) ?? false\n"
        } else {
            output += "        self.\(field.caseCorrectName) = try container.decode(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName))\n"
        }
    }
    output += "    }\n\n"

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

/// Writes the custom initializer and encoder for messages with TimeInterval fields.
///
/// - Parameters:
///   - protoEnum: The `ProtoEnum` to write the custom initializer and encoder for.
///   - output: A mutable string where the generated code will be appended.
internal func writCodableInit(for protoEnum: ProtoEnum, to output: inout String) {
    let strippedCases = stripCommonPrefix(from: protoEnum.cases)
    let pair = zip(
        strippedCases.map(\.name),
        protoEnum.cases.map(\.name)
    )
    output += "\n"
    output += "    public init(from decoder: Decoder) throws {\n"
    output += "        let container = try decoder.singleValueContainer()\n\n"
    output += "        if let stringValue = try? container.decode(String.self) {\n"
    output += "            // Convert string to enum\n"
    output += "            switch stringValue {\n"
    for (caseName, stringName) in pair {
        output += "            case \"\(stringName)\":\n"
        output += "                self = .\(caseName)\n"
    }
    output += "            default:\n"
    output += "                self = .unspecified\n"
    output += "            }\n"
    output += "        } else if let intValue = try? container.decode(Int.self) {\n"
    output += "            // Convert integer to enum\n"
    output += "            self = Blueprint\(protoEnum.name)(rawValue: intValue) ?? .unspecified\n"
    output += "        } else {\n"
    output += "            throw DecodingError.dataCorruptedError(in: container, debugDescription: \"Invalid value for MyEnum\")\n"
    output += "        }\n"
    output += "    }\n\n"

    output += "    public func encode(to encoder: Encoder) throws {\n"
    output += "        var container = encoder.singleValueContainer()\n"
    output += "        switch self {\n"
    for (caseName, stringName) in pair {
        output += "        case .\(caseName):\n"
        output += "            try container.encode(\"\(stringName)\")\n"
    }
    output += "        default:\n"
    output += "            try container.encode(\"UNSPECIFIED\")\n"
    output += "        }\n"
    output += "    }\n"
}

/// Writes the TimeInterval helper extension if needed.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` to check for TimeInterval fields.
///   - output: A mutable string where the generated code will be appended.
internal func writeTimeIntervalHelper(_ messages: [ProtoMessage], to output: inout String) {
    if let fileContents = readFileContents(filename: "TimeInterval+String.swift") {
        output += "// MARK: - TimeInterval Extension\n"
        output += fileContents
            .replacingOccurrences(of: "import Foundation", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        output += "// File not found."
    }
}

internal func writeDateFormatter(to output: inout String) {
    output += "\n\n"
    output += "var dateFormatter: ISO8601DateFormatter {\n"
    output += "    let formatter = ISO8601DateFormatter()\n"
    output += "    formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]\n"
    output += "    return formatter\n"
    output += "}\n"
}
