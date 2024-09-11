import Foundation

/// Generates Swift code from protocol buffer messages and enums.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` representing protocol buffer messages.
///   - enums: An array of `ProtoEnum` representing protocol buffer enums.
/// - Returns: A string containing the generated Swift code.
func generateSwiftCode(
    from messages: [ProtoMessage],
    enums: [ProtoEnum],
    with swiftPrefix: String,
    includeProto: Bool,
    with protoPrefix: String
) -> String {
    var output = "import Foundation\n\n"

    let needsTimeIntervalHelper = write(
        messages,
        to: &output,
        with: swiftPrefix,
        includeProto: includeProto,
        with: protoPrefix
    )

    write(
        enums,
        to: &output,
        with: swiftPrefix,
        includeProto: includeProto,
        with: protoPrefix
    )

    return output
}

/// Writes the Swift code for protocol buffer enums.
///
/// - Parameters:
///   - enums: An array of `ProtoEnum` to be written.
///   - output: A mutable string where the generated code will be appended.
internal func write(
    _ enums: [ProtoEnum],
    to output: inout String,
    with swiftPrefix: String,
    includeProto: Bool,
    with protoPrefix: String
) {
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
            output += "extension \(swiftPrefix)\(parent) {\n"
            output += "    "
        }

        output += "public enum \(swiftPrefix)\(protoEnum.name): Int, CaseIterable, Hashable, Equatable, Sendable {\n"

        for (caseName, caseValue) in pair {
            if protoEnum.parentName != nil {
                output += "    "
            }
            output += "    case \(caseName) = \(caseValue)\n"
        }
        if includeProto {
            writeEnumProtoInit(
                for: protoEnum,
                to: &output,
                with: protoPrefix
            )
        }

        if protoEnum.parentName != nil {
            output += "    }\n"
        }
        output += "}\n\n"
    }
}

/// Writes the initializer for a protocol buffer enum.
///
/// - Parameters:
///   - protoEnum: The `ProtoEnum` to write the initializer for.
///   - output: A mutable string where the generated code will be appended.
internal func writeEnumProtoInit(for protoEnum: ProtoEnum, to output: inout String, with protoPrefix: String) {
    output += "\n"
    let padding = if protoEnum.parentName != nil {
        "    "
    } else {
        ""
    }
    output += padding + "    internal init?(proto: \(protoPrefix)\(protoEnum.fullName)) {\n"
    output += padding + "        self.init(rawValue: proto.rawValue)\n"
    output += padding + "    }\n"
}

/// Writes the Swift code for protocol buffer messages.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` to be written.
///   - output: A mutable string where the generated code will be appended.
/// - Returns: A boolean indicating whether a TimeInterval helper is needed.
@discardableResult
internal func write(
    _ messages: [ProtoMessage],
    to output: inout String,
    with swiftPrefix: String,
    includeProto: Bool,
    with protoPrefix: String
) -> Bool {
    if messages.isEmpty == false {
        output += "// MARK: - Structs\n"
    }

    var needsTimeIntervalHelper = false

    for message in messages.sorted(by: { $0.name < $1.name }) {
        output += "public struct \(swiftPrefix)\(message.name): Hashable, Equatable, Sendable {\n"

        let hasTimeInterval = writeProperties(
            for: message,
            to: &output
        )

        if hasTimeInterval {
            needsTimeIntervalHelper = true
        }

        writeBasicInit(
            for: message,
            to: &output
        )

        if includeProto {
            writeMessageProtoInit(
                for: message,
                to: &output,
                with: protoPrefix
            )
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

    // Maybe add a backingData flag
    output += "    public let _localID = UUID()"
    output += "    public private(set) var _backingData: Data?"

    output += "\n"

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

    let last = fields.popLast()
    
    output += "\n    public init(\n"

    if last == nil {
        output += ") {\n"
    } else {
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
internal func writeMessageProtoInit(for message: ProtoMessage, to output: inout String, with protoPrefix: String) {
    output += "\n    public init?(data: Data) {\n"
    output += "        if let proto = try? \(protoPrefix)\(message.name)(serializedBytes: data) {\n"
    output += "            self.init(proto: proto)\n"
    // Backing data flag
    output += "            self._backingData = data\n"
    output += "        } else {\n"
    output += "            return nil\n"
    output += "        }\n"
    output += "    }\n\n"

    output += "    internal init?(proto: \(protoPrefix)\(message.name)) {\n"
    for field in message.fields {
        if field.isOptional {
            output += "        if proto.has\(field.caseCorrectProtoName.capitalizingFirstLetter()) {\n"
            output += "    " // additional padding
        }

        if field.isRepeated {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectProtoName).compactMap { "
            if field.isPrimitiveType || field.type.contains("int") {
                output += "\(field.caseCorrectedBaseType)($0)"
            } else {
                output += "\(field.caseCorrectedBaseType)(proto: $0)"
            }
            output += " }\n"
        } else if field.isMap {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectProtoName).reduce(into: \(field.caseCorrectedType)()) { $0[$1.key] = $1.value }\n"
        } else if field.caseCorrectedBaseType == "TimeInterval" {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectProtoName).timeInterval\n"
        } else if field.caseCorrectedBaseType == "Date" {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectProtoName).date\n"
        } else if field.isURL {
            if field.isOptional {
                output += "        self.\(field.caseCorrectName) = URL(string: proto.\(field.caseCorrectName))\n"
            } else {
                output += "        if let \(field.caseCorrectName) = URL(string: proto.\(field.caseCorrectName)) {\n"
                output += "            self.\(field.caseCorrectName) = \(field.caseCorrectName)\n"
                output += "        } else {\n"
                output += "            return nil\n"
                output += "        }\n"
            }
        }else if field.type.contains("int") {
            output += "        self.\(field.caseCorrectName) = Int(exactly: proto.\(field.caseCorrectName))!\n"
        } else if field.isPrimitiveType {
            output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectProtoName)\n"
        } else if field.isOptional == false {
            output += "        if let \(field.caseCorrectName) = \(field.caseCorrectedBaseType)(proto: proto.\(field.caseCorrectProtoName)) {\n"
            output += "            self.\(field.caseCorrectName) = \(field.caseCorrectProtoName)\n"
            output += "        } else {\n"
            output += "            return nil\n"
            output += "        }\n"
        } else {
            output += "        self.\(field.caseCorrectName) = \(field.caseCorrectedBaseType)(proto: proto.\(field.caseCorrectProtoName))\n"
        }

        if field.isOptional {
            output += "        } else {\n"
            output += "            self.\(field.caseCorrectName) = nil\n"
            output += "        }\n"
        }

        // backingData flag
        output += "        self._backingData = nil\n"
    }
    output += "    }\n"
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
internal func writeCodableInit(for message: ProtoMessage, to output: inout String) {
    output += "\n"
    output += "    public init(from decoder: Decoder) throws {\n"
    output += "        let container = try decoder.container(keyedBy: CodingKeys.self)\n"

    for field in message.fields {
        if field.isRepeated {
            output += "        self.\(field.caseCorrectName) = try container.decodeIfPresent(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName)) ?? []\n"
        } else if field.isMap {
            output += "        self.\(field.caseCorrectName) = try container.decodeIfPresent(\(field.caseCorrectedType).self, forKey: .\(field.caseCorrectName)) ?? [:]\n"
        } else if field.caseCorrectedType == "TimeInterval" {
            output += "        if let \(field.caseCorrectName)String = try container.decodeIfPresent(String.self, forKey: .\(field.caseCorrectName)) {\n"
            output += "            self.\(field.caseCorrectName) = TimeInterval(from: \(field.caseCorrectName)String) ?? 0\n"
            output += "        } else {\n"
            if field.isOptional {
                output += "            self.\(field.caseCorrectName) = nil\n"
            } else {
                output += "            self.\(field.caseCorrectName) = 0\n"
            }
            output += "        }\n"
        } else if field.caseCorrectedType.contains("Date") {
            output += "        if let \(field.caseCorrectName)String = try container.decodeIfPresent(String.self, forKey: .\(field.caseCorrectName)) {\n"
            output += "            self.\(field.caseCorrectName) = dateFormatter.date(from: \(field.caseCorrectName)String)\n"
            output += "        } else {\n"
            if field.isOptional {
                output += "            self.\(field.caseCorrectName) = nil\n"
            } else {
                output += "            self.\(field.caseCorrectName) = Date()\n"
            }
            output += "        }\n"
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
internal func writeCodableInit(for protoEnum: ProtoEnum, to output: inout String, with swiftPrefix: String) {
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
    output += "            self = \(swiftPrefix)\(protoEnum.name)(rawValue: intValue) ?? .unspecified\n"
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
    output += "        }\n"
    output += "    }\n"
}

/// Writes the TimeInterval helper extension if needed.
///
/// - Parameters:
///   - messages: An array of `ProtoMessage` to check for TimeInterval fields.
///   - output: A mutable string where the generated code will be appended.
internal func writeTimeIntervalHelper(to output: inout String) {
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
