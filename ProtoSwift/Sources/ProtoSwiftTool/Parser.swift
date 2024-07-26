import Foundation

// Assuming the regex patterns are defined in Regex.swift and imported correctly
func parseProtoFile(at path: URL) throws -> ([ProtoMessage], [ProtoEnum]) {
    let content = try String(contentsOf: path)
    var messages: [ProtoMessage] = []
    var enums: [ProtoEnum] = []

    func parseContent(_ content: String, inMessage: Bool = false) -> ([ProtoMessage], [ProtoEnum]) {
        var localMessages: [ProtoMessage] = []
        var localEnums: [ProtoEnum] = []

        // Use Swift's Regex for parsing
        let messageMatches = content.matches(of: messagePattern)
        print("\(messageMatches.count) messages found")

        for match in messageMatches {
            let messageName = String(match.1)
            var messageBody = String(match.2)

            print("Matched message: \(messageName)")
            print("Message body: \(messageBody)")

            // Parse nested enums within the message body
            let nestedEnumMatches = messageBody.matches(of: enumPattern)
            for nestedEnumMatch in nestedEnumMatches {
                let nestedEnumName = String(nestedEnumMatch.1)
                let nestedEnumBody = String(nestedEnumMatch.2)
                print("Matched nested enum: \(nestedEnumName)")
                print("Nested enum body: \(nestedEnumBody)")
                let nestedEnumCases = parseEnumCases(from: nestedEnumBody)
                localEnums.append(
                    ProtoEnum(
                        name: nestedEnumName,
                        cases: nestedEnumCases
                    )
                )

                // Remove the nested enum from the message body
                let nestedEnumFullMatch = String(nestedEnumMatch.0)
                messageBody = messageBody.replacingOccurrences(of: nestedEnumFullMatch, with: "")
            }

            let fields = parseFields(from: messageBody)

            localMessages.append(
                ProtoMessage(
                    name: messageName,
                    fields: fields
                )
            )
        }

        return (localMessages, localEnums)
    }

    func parseFields(from content: String) -> [ProtoField] {
        var fields: [ProtoField] = []

        // Use Swift's Regex for parsing
        let fieldMatches = content.matches(of: fieldPattern)
        print("Field matches count: \(fieldMatches.count)")

        for match in fieldMatches {
            let fieldModifier = match.1.map { String($0) }
            let fieldType = String(match.2)
            let fieldName = String(match.3)
            let isOptional = fieldModifier?.contains("optional") == true
            let isRepeated = fieldModifier?.contains("repeated") == true
            let isMap = fieldModifier?.starts(with: "map") == true
            print("Matched field type: \(fieldType), field name: \(fieldName), isOptional: \(isOptional), isRepeated: \(isRepeated), isMap: \(isMap))")
            fields.append(
                ProtoField(
                    name: fieldName,
                    type: fieldType,
                    isOptional: isOptional,
                    isRepeated: isRepeated,
                    isMap: isMap
                )
            )
        }

        return fields
    }

    func parseEnumCases(from content: String) -> [ProtoEnumCase] {
        var cases: [ProtoEnumCase] = []

        // Use Swift's Regex for parsing
        let caseMatches = content.matches(of: enumCasePattern)
        print("Enum case matches count: \(caseMatches.count)")

        for match in caseMatches {
            let caseName = String(match.1)
            let caseValue = Int(match.2)!
            print("Matched enum case name: \(caseName), value: \(caseValue)")
            cases.append(
                ProtoEnumCase(
                    name: caseName,
                    value: caseValue
                )
            )
        }

        return cases
    }

    print("Starting parsing of messages")
    let (parsedMessages, parsedEnums) = parseContent(content)
    messages = parsedMessages
    enums = parsedEnums
    print("Finished parsing of messages and enums")

    return (messages, enums)
}
