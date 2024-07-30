import Foundation

// Assuming the regex patterns are defined in Regex.swift and imported correctly
func parseProtoFile(at path: URL) throws -> ([ProtoMessage], [ProtoEnum]) {
    var content = try String(contentsOf: path)
    print("Starting parsing of messages")
    return parseContent(&content, parent: nil)
}

fileprivate func parseContent(_ content: inout String, parent: String?) -> ([ProtoMessage], [ProtoEnum]) {

    var localMessages: [ProtoMessage] = []
    var localEnums: [ProtoEnum] = []

    // Use Swift's Regex for parsing
    let messageMatches = content.matches(of: messagePattern)
    for match in messageMatches {
        let messageName = String(match.1)
        var messageBody = String(match.2)

        print("Matched message: \(messageName)")
        print("Message body: \(messageBody)")

        let (nestedMessages, nestedEnums) = parseContent(
            &messageBody,
            parent: messageName
        )

        localMessages.append(contentsOf: nestedMessages)
        localEnums.append(contentsOf: nestedEnums)

        let fields = parseMessageFields(from: messageBody)

        localMessages.append(
            ProtoMessage(
                name: messageName,
                fields: fields,
                parentName: parent
            )
        )

        // remove the parsed content
        content = content.replacingOccurrences(
            of: String(match.0),
            with: ""
        )
    }

    let enumMatches = content.matches(of: enumPattern)
    for match in enumMatches {
        let enumName = String(match.1)
        var enumBody = String(match.2)
        print("Matched nested enum: \(enumName)")
        print("Nested enum body: \(enumBody)")

        let (nestedMessages, nestedEnums) = parseContent(
            &enumBody,
            parent: enumName
        )

        localMessages.append(contentsOf: nestedMessages)
        localEnums.append(contentsOf: nestedEnums)

        let enumCases = parseEnumCases(from: enumBody)
        localEnums.append(
            ProtoEnum(
                name: enumName,
                cases: enumCases,
                parentName: parent
            )
        )

        // remove the parsed content
        content = content.replacingOccurrences(
            of: String(match.0),
            with: ""
        )
    }

    return (localMessages, localEnums)
}

fileprivate func parseMessageFields(from content: String) -> [ProtoField] {
    var fields: [ProtoField] = []

    // Use Swift's Regex for parsing
    let fieldMatches = content.matches(of: fieldPattern)
    print("Field matches count: \(fieldMatches.count)")

    for match in fieldMatches {
        let comment = match.output.1.map { String($0) }
        let fieldModifier = match.output.3.map { String($0) }
        let fieldType = String(match.output.4)
        let fieldName = String(match.output.5)
        let isOptional = fieldModifier?.contains("optional") == true
        let isRepeated = fieldModifier?.contains("repeated") == true
        let isMap = fieldModifier?.starts(with: "map") == true
        print("Matched field type: \(fieldType), field name: \(fieldName), isOptional: \(isOptional), isRepeated: \(isRepeated), isMap: \(isMap))")
        fields.append(
            ProtoField(
                name: fieldName,
                type: fieldType,
                coment: comment,
                isOptional: isOptional,
                isRepeated: isRepeated,
                isMap: isMap
            )
        )
    }

    return fields
}

fileprivate func parseEnumCases(from content: String) -> [ProtoEnumCase] {
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
