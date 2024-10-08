import Foundation

/// Parses a protocol buffer file from the given URL path.
///
/// - Parameter path: The URL of the .proto file to be parsed.
/// - Returns: A tuple containing arrays of `ProtoMessage` and `ProtoEnum`.
/// - Throws: An error if the file cannot be read.
internal func parseProtoFile(
    at path: URL,
    with swiftPrefix: String,
    verbose: Bool,
    quite: Bool
) throws -> ([ProtoMessage], [ProtoEnum]) {
    var content = try String(contentsOf: path)
    return parseContent(
        &content,
        parent: nil,
        with: swiftPrefix,
        verbose: verbose,
        quite: quite
    )
}

/// Recursively parses the content of a protocol buffer file.
///
/// - Parameters:
///   - content: The content of the .proto file.
///   - parent: The name of the parent message or enum, if any.
/// - Returns: A tuple containing arrays of `ProtoMessage` and `ProtoEnum`.
internal func parseContent(
    _ content: inout String,
    parent: String?,
    with swiftPrefix: String,
    verbose: Bool,
    quite: Bool
) -> ([ProtoMessage], [ProtoEnum]) {

    var localMessages: [ProtoMessage] = []
    var localEnums: [ProtoEnum] = []

    // Parsing messages
    let messageMatches = content.matches(of: messagePattern)
    for match in messageMatches {

        let messageName = String(match.1)
        var messageBody = String(match.2)

        // This will recessively call parse content on the
        // body to find nested messages and enums
        processMessage(
            messageName,
            &messageBody,
            &localMessages,
            &localEnums,
            parent,
            swiftPrefix,
            verbose: verbose,
            quite: quite
        )

        // Remove the parsed content to avoid duplication
        content = content.replacingOccurrences(
            of: String(match.0),
            with: ""
        )
    }

    // Parsing enums
    let enumMatches = content.matches(of: enumPattern)
    for match in enumMatches {

        let enumName = String(match.1)
        var enumBody = String(match.2)

        // This will recessively call parse content on the
        // body to find nested messages and enums
        processEnum(
            enumName,
            &enumBody,
            &localMessages,
            &localEnums,
            parent,
            swiftPrefix,
            verbose: verbose,
            quite: quite
        )

        // Remove the parsed content to avoid duplication
        content = content.replacingOccurrences(
            of: String(match.0),
            with: ""
        )
    }

    return (localMessages, localEnums)
}

/// Processes a protocol buffer enum by parsing its content and extracting nested messages and enums.
///
/// - Parameters:
///   - name: The name of the enum.
///   - body: The content of the enum.
///   - localMessages: A mutable array to store parsed `ProtoMessage` objects.
///   - localEnums: A mutable array to store parsed `ProtoEnum` objects.
///   - parent: The name of the parent message or enum, if any.
internal func processEnum(
    _ name: String,
    _ body: inout String,
    _ localMessages: inout [ProtoMessage],
    _ localEnums: inout [ProtoEnum],
    _ parent: String?,
    _ prefix: String,
    verbose: Bool,
    quite: Bool
) {
    if quite == false {
        print("Matched enum: \(name)")
    }
    if verbose == true {
        print("Matched enum body: \(body)")
    }
    let (nestedMessages, nestedEnums) = parseContent(
        &body,
        parent: name,
        with: prefix,
        verbose: verbose,
        quite: quite
    )

    localMessages.append(contentsOf: nestedMessages)
    localEnums.append(contentsOf: nestedEnums)

    let cases = parseEnumCases(
        from: body,
        verbose: verbose,
        quite: quite
    )

    localEnums.append(
        ProtoEnum(
            name: name,
            cases: cases,
            parentName: parent
        )
    )
}

/// Processes a protocol buffer message by parsing its content and extracting nested messages and enums.
///
/// - Parameters:
///   - name: The name of the message.
///   - body: The content of the message.
///   - localMessages: A mutable array to store parsed `ProtoMessage` objects.
///   - localEnums: A mutable array to store parsed `ProtoEnum` objects.
///   - parent: The name of the parent message, if any.
internal func processMessage(
    _ name: String,
    _ body: inout String,
    _ localMessages: inout [ProtoMessage],
    _ localEnums: inout [ProtoEnum],
    _ parent: String?,
    _ prefix: String,
    verbose: Bool,
    quite: Bool
) {
    if quite == false {
        print("Matched message: \(name)")
    }
    if verbose == true {
        print("Message body: \(body)")
    }

    let (nestedMessages, nestedEnums) = parseContent(
        &body,
        parent: name,
        with: prefix,
        verbose: verbose,
        quite: quite
    )

    localMessages.append(contentsOf: nestedMessages)
    localEnums.append(contentsOf: nestedEnums)

    let fields = parseMessageFields(
        from: body,
        with: prefix,
        verbose: verbose,
        quite: quite
    )

    localMessages.append(
        ProtoMessage(
            name: name,
            fields: fields,
            parentName: parent
        )
    )
}


/// Parses the fields of a protocol buffer message.
///
/// - Parameter content: The content of the message.
/// - Returns: An array of `ProtoField` representing the fields of the message.
internal func parseMessageFields(
    from content: String,
    with swiftPrefix: String,
    verbose: Bool,
    quite: Bool
) -> [ProtoField] {
    var fields: [ProtoField] = []

    // Use Swift's Regex for parsing fields
    let fieldMatches = content.matches(of: fieldPattern)
    if quite == false {
        print("Field matches count: \(fieldMatches.count)")
    }

    for match in fieldMatches {
        let comment = match.output.1.map { String($0) }
        let fieldModifier = match.output.3.map { String($0) }
        let fieldType = String(match.output.4)
        let fieldName = String(match.output.5)
        let fieldOptions = match.output.6.map { String($0) }
        let isOptional = fieldModifier?.contains("optional") == true
        let isRepeated = fieldModifier?.contains("repeated") == true
        let isMap = fieldModifier?.starts(with: "map") == true
        let isDeprecated = fieldOptions?.contains("deprecated = true") == true
        if verbose {
            print("Matched field type: \(fieldType), field name: \(fieldName), isOptional: \(isOptional), isRepeated: \(isRepeated), isMap: \(isMap))")
        }
        fields.append(
            ProtoField(
                swiftPrefix: swiftPrefix,
                name: fieldName,
                type: fieldType,
                comment: comment,
                isOptional: isOptional,
                isRepeated: isRepeated,
                isMap: isMap,
                isDeprecated: isDeprecated
            )
        )
    }

    return fields
}

/// Parses the cases of a protocol buffer enum.
///
/// - Parameter content: The content of the enum.
/// - Returns: An array of `ProtoEnumCase` representing the cases of the enum.
internal func parseEnumCases(
    from content: String,
    verbose: Bool,
    quite: Bool
) -> [ProtoEnumCase] {
    var cases: [ProtoEnumCase] = []

    // Use Swift's Regex for parsing enum cases
    let caseMatches = content.matches(of: enumCasePattern)

    if quite == false {
        print("Enum case matches count: \(caseMatches.count)")
    }

    for match in caseMatches {
        let caseName = String(match.1)
        let caseValue = Int(match.2)!
        if verbose {
            print("Matched enum case name: \(caseName), value: \(caseValue)")
        }
        cases.append(
            ProtoEnumCase(
                name: caseName,
                value: caseValue
            )
        )
    }

    return cases
}
