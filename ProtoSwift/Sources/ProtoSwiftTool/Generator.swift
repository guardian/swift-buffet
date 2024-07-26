import Foundation

func generateSwiftCode(from messages: [ProtoMessage], enums: [ProtoEnum]) -> String {
    var output = "import Foundation\n\n"

    let needsTimeIntervalHelper = write(messages, to: &output)
    write(enums, to: &output)

    if needsTimeIntervalHelper {
        writeTimeIntervalHelper(messages, to: &output)
    }

    return output
}

fileprivate func write(_ enums: [ProtoEnum], to output: inout String) {
    // Generate output for enums first to ensure they are available for use in messages
    if enums.isEmpty == false {
        output += "// MARK: - Enums\n"
    }
    for protoEnum in enums.sorted(by: {$0.name < $1.name}) {
        let strippedCases = stripCommonPrefix(from: protoEnum.cases)
        let pair = zip(strippedCases.map({$0.name}), protoEnum.cases.map({$0.name}))
        output += "public enum \(protoEnum.name): String, Codable {\n"
        for (caseName, caseValue) in pair {
            output += "    case \(caseName) = \"\(caseValue)\"\n"
        }
        output += "}\n\n"
    }
}

@discardableResult
fileprivate func write(_ messages: [ProtoMessage], to output: inout String) -> Bool {
    // Generate output for messages
    if messages.isEmpty == false {
        output += "// MARK: - Structs\n"
    }
    
    var needsTimeIntervalHelper = false

    for message in messages.sorted(by: {$0.name < $1.name}) {
        output += "public struct \(message.name): Codable {\n"
        
        let hasTimeInterval = addProperties(for: message, to: &output)

        addBasicInit(for: message, to: &output)
        addProtoInit(for: message, to: &output)

        if hasTimeInterval {
            writeDurationInit(for: message, to: &output)
            needsTimeIntervalHelper = true
        }

        output += "}\n\n"
    }

    return needsTimeIntervalHelper
}

@discardableResult
fileprivate func addProperties(for message: ProtoMessage, to output: inout String) -> Bool {
    var hasTimeInterval = false
    for field in message.fields {
        output += "    let \(field.caseCorrectName): \(field.caseCorrectedType)\n"
        if field.caseCorrectedType.contains("TimeInterval") {
            hasTimeInterval = true
        }
    }
    return hasTimeInterval
}

fileprivate func addBasicInit(for message: ProtoMessage, to output: inout String) {
    var fields = message.fields

    let first = fields.first
    fields.removeFirst()

    let last = fields.popLast()

    if let field = first {
        output += "\n    init(\(field.caseCorrectName): \(field.caseCorrectedType)"
    }

    if last == nil {
        output += ") {\n"
    } else {
        output += ",\n"

        for field in fields {
            output += "         \(field.caseCorrectName): \(field.caseCorrectedType),\n"
        }

        if let field = last {
            output += "         \(field.caseCorrectName): \(field.caseCorrectedType)\n"
        }

        output += "    ) {\n"
    }

    for field in message.fields {
        output += "        self.\(field.caseCorrectName) = \(field.caseCorrectName)\n"
    }

    output += "    }\n"
}

fileprivate func addProtoInit(for message: ProtoMessage, to output: inout String) {
    output += "\n#if USE_PROTO\n"
    output += "    init?(_ proto: Proto\(message.name)) {\n"
    for field in message.fields {
        // if types match
        output += "        self.\(field.caseCorrectName) = proto.\(field.caseCorrectName)\n"
        // TODO: handle cases that
    }
    output += "    }\n"
    output += "#endif\n"
}

fileprivate func writeDurationInit(for message: ProtoMessage, to output: inout String) {
    // Add custom initializer if the struct has a duration field
    output += "\n"
    output += "    init(from decoder: Decoder) throws {\n"
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
    output += "    func encode(to encoder: Encoder) throws {\n"
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
