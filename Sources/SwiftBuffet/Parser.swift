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

    let oneofs = parseOneofs(
        &body,
        with: prefix,
        verbose: verbose,
        quite: quite
    )

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
            parentName: parent,
            oneofs: oneofs
        )
    )
}


/// Parses and removes `oneof` blocks from a message body, returning the extracted
/// oneofs. This runs before `parseMessageFields` so a oneof's member fields are
/// represented once, as part of its `ProtoOneof`, rather than also being matched as
/// independent top-level fields by the field-matching regex.
///
/// Blocks are extracted by scanning for a balanced closing brace rather than with a
/// single regex, so braces appearing inside comments, string literals, or aggregate
/// options (e.g. `option (metadata) = { enabled: true };`) don't truncate the block
/// and leak its members back out as ordinary fields.
///
/// - Parameters:
///   - body: The message body to parse; matched oneof blocks are removed from it.
/// - Returns: An array of `ProtoOneof` representing the oneof blocks found.
internal func parseOneofs(
    _ body: inout String,
    with swiftPrefix: String,
    verbose: Bool,
    quite: Bool
) -> [ProtoOneof] {
    var oneofs: [ProtoOneof] = []
    var remaining = Substring(body)
    var retained = ""

    while let header = findOneofHeader(in: remaining) {
        let oneofName = header.name

        // Anything before the `oneof` keyword is an ordinary part of the message.
        retained += remaining[remaining.startIndex..<header.start]

        guard let closeBraceIndex = findMatchingClosingBrace(
            in: remaining,
            startingAtOpenBrace: header.openBrace
        ) else {
            // Unbalanced braces: leave the remainder untouched rather than silently
            // dropping it, so a malformed block can't swallow the rest of the message.
            retained += remaining[header.start...]
            remaining = ""
            break
        }

        let bodyStart = remaining.index(after: header.openBrace)
        let oneofBody = String(remaining[bodyStart..<closeBraceIndex])

        if quite == false {
            print("Matched oneof: \(oneofName)")
        }
        if verbose == true {
            print("Matched oneof body: \(oneofBody)")
        }

        let fields = parseMessageFields(
            from: oneofBody,
            with: swiftPrefix,
            verbose: verbose,
            quite: quite
        )

        oneofs.append(
            ProtoOneof(
                name: oneofName,
                fields: fields
            )
        )

        // Drop the whole block so its members aren't also matched as regular fields.
        remaining = remaining[remaining.index(after: closeBraceIndex)...]
    }

    retained += remaining
    body = retained

    return oneofs
}

/// Locates the next `oneof` header that appears in actual code, skipping any that
/// occur inside comments or string literals — a commented-out
/// `// Example: oneof ignored {}` must not produce a phantom oneof.
///
/// - Parameter text: The text to search.
/// - Returns: The index the header starts at, the index of its opening brace, and
///   the oneof's name; or `nil` if no header is found.
internal func findOneofHeader(
    in text: Substring
) -> (start: Substring.Index, openBrace: Substring.Index, name: String)? {
    var index = text.startIndex
    var inLineComment = false
    var inBlockComment = false
    var stringDelimiter: Character?

    while index < text.endIndex {
        let character = text[index]
        let nextIndex = text.index(after: index)
        let nextCharacter = nextIndex < text.endIndex ? text[nextIndex] : nil

        if inLineComment {
            // `\r\n` is a single Swift `Character`, so compare with `isNewline`
            // rather than `== "\n"`, which never matches on CRLF input.
            if character.isNewline {
                inLineComment = false
            }
        } else if inBlockComment {
            if character == "*", nextCharacter == "/" {
                inBlockComment = false
                index = nextIndex
            }
        } else if let delimiter = stringDelimiter {
            if character == "\\", nextCharacter != nil {
                index = nextIndex // Skip the escaped character.
            } else if character == delimiter {
                stringDelimiter = nil
            }
        } else if character == "/", nextCharacter == "/" {
            inLineComment = true
            index = nextIndex
        } else if character == "/", nextCharacter == "*" {
            inBlockComment = true
            index = nextIndex
        } else if character == "\"" || character == "'" {
            stringDelimiter = character
        } else if character == "o", isWordStart(at: index, in: text) {
            if let match = text[index...].prefixMatch(of: oneofHeaderPattern) {
                // The header match ends immediately after the opening brace.
                let openBrace = text.index(before: match.range.upperBound)
                return (index, openBrace, String(match.1))
            }
        }

        index = text.index(after: index)
    }

    return nil
}

/// Indicates whether the given index begins a new word, so that an identifier such
/// as `my_oneof` isn't mistaken for the `oneof` keyword.
private func isWordStart(at index: Substring.Index, in text: Substring) -> Bool {
    guard index > text.startIndex else {
        return true
    }
    let previous = text[text.index(before: index)]
    return !(previous.isLetter || previous.isNumber || previous == "_")
}

/// Scans forward from an opening brace to find its matching closing brace, ignoring
/// braces that appear inside line comments, block comments, or string literals.
///
/// - Parameters:
///   - text: The text to scan.
///   - openBrace: The index of the opening `{` to match.
/// - Returns: The index of the matching `}`, or `nil` if the braces are unbalanced.
internal func findMatchingClosingBrace(
    in text: Substring,
    startingAtOpenBrace openBrace: Substring.Index
) -> Substring.Index? {
    var depth = 0
    var index = openBrace
    var inLineComment = false
    var inBlockComment = false
    var stringDelimiter: Character?

    while index < text.endIndex {
        let character = text[index]
        let nextIndex = text.index(after: index)
        let nextCharacter = nextIndex < text.endIndex ? text[nextIndex] : nil

        if inLineComment {
            // `\r\n` is a single Swift `Character`, so compare with `isNewline`
            // rather than `== "\n"`, which never matches on CRLF input and would
            // leave the scanner stuck inside the comment.
            if character.isNewline {
                inLineComment = false
            }
        } else if inBlockComment {
            if character == "*", nextCharacter == "/" {
                inBlockComment = false
                index = nextIndex
            }
        } else if let delimiter = stringDelimiter {
            if character == "\\", nextCharacter != nil {
                index = nextIndex // Skip the escaped character.
            } else if character == delimiter {
                stringDelimiter = nil
            }
        } else if character == "/", nextCharacter == "/" {
            inLineComment = true
            index = nextIndex
        } else if character == "/", nextCharacter == "*" {
            inBlockComment = true
            index = nextIndex
        } else if character == "\"" || character == "'" {
            stringDelimiter = character
        } else if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                return index
            }
        }

        index = text.index(after: index)
    }

    return nil
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
