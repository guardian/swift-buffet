import Foundation

/// A recursive-descent parser for the subset of the proto language that
/// SwiftBuffet generates code for.
///
/// Header statements (`syntax`, `package`, `import`, `option`) are consumed
/// and ignored. `oneof` members become ordinary fields of the enclosing
/// message. Constructs the generator has no representation for (`service`,
/// `extend`) are skipped with a warning; `reserved` statements and option
/// lists are skipped silently. Anything else malformed throws `ParseError`.
struct ProtoParser {

    static func parse(_ source: String, verbose: Bool) throws -> ProtoFileNode {
        var parser = ProtoParser(
            tokens: try Lexer.tokenize(source),
            verbose: verbose
        )
        return try parser.parseFile()
    }

    private let tokens: [Token]
    private let verbose: Bool
    private var index = 0

    private init(tokens: [Token], verbose: Bool) {
        self.tokens = tokens
        self.verbose = verbose
    }

    // MARK: - Grammar

    private mutating func parseFile() throws -> ProtoFileNode {
        var file = ProtoFileNode()
        loop: while true {
            switch peek().kind {
            case .docComment, .semicolon: // empty statements are legal
                advance()
            case .identifier(let keyword):
                switch keyword {
                case "message":
                    file.messages.append(try parseMessage())
                case "enum":
                    file.enums.append(try parseEnum())
                case "syntax", "package", "import", "option":
                    try skipToSemicolon()
                case "service", "extend":
                    try skipUnsupportedBlock(named: keyword)
                default:
                    throw unexpected(expected: "'message', 'enum', or a header statement")
                }
            default:
                break loop
            }
        }
        try expect(.eof, description: "'message', 'enum', or a header statement")
        return file
    }

    private mutating func parseMessage() throws -> MessageNode {
        advance() // "message"
        let name = try expectIdentifier(description: "a message name")
        try expect(.openBrace)
        var node = MessageNode(name: name)

        while peek().kind != .closeBrace {
            let comment = takeDocComments()
            if peek().kind == .closeBrace {
                break // dangling comment before the closing brace
            }
            if peek().kind == .semicolon { // empty statements are legal
                advance()
                continue
            }
            if peek().kind == .dot { // leading-dot absolute type reference
                node.fields.append(try parseField(comment: comment))
                continue
            }

            guard case .identifier(let word) = peek().kind else {
                throw unexpected(expected: "a field, 'message', 'enum', or '}'")
            }

            switch word {
            case "message" where isDeclarationLookahead():
                node.messages.append(try parseMessage())
            case "enum" where isDeclarationLookahead():
                node.enums.append(try parseEnum())
            case "option", "reserved":
                try skipToSemicolon()
            case "oneof" where isDeclarationLookahead():
                try parseOneofMembers(into: &node)
            default:
                node.fields.append(try parseField(comment: comment))
            }
        }
        try expect(.closeBrace)
        return node
    }

    /// Parses a `oneof` block, adding its member fields to the enclosing
    /// message as ordinary fields — matching what the generated structs have
    /// always contained for oneof members.
    private mutating func parseOneofMembers(into node: inout MessageNode) throws {
        advance() // "oneof"
        advance() // name
        try expect(.openBrace)
        while peek().kind != .closeBrace {
            let comment = takeDocComments()
            if peek().kind == .closeBrace {
                break
            }
            if peek().kind == .semicolon { // empty statements are legal
                advance()
                continue
            }
            if case .identifier("option") = peek().kind {
                try skipToSemicolon()
                continue
            }
            node.fields.append(try parseField(comment: comment))
        }
        try expect(.closeBrace)
    }

    private mutating func parseField(comment: String?) throws -> FieldNode {
        var isOptional = false
        var isRepeated = false
        var isMap = false
        let type: String

        if case .identifier(let modifier) = peek().kind,
           ["optional", "repeated"].contains(modifier),
           isModifierLookahead() {
            isOptional = modifier == "optional"
            isRepeated = modifier == "repeated"
            advance()
        }

        if case .identifier("map") = peek().kind, peekNext().kind == .openAngle {
            isMap = true
            advance() // "map"
            try expect(.openAngle)
            let keyType = try parseTypeName()
            try expect(.comma)
            let valueType = try parseTypeName()
            try expect(.closeAngle)
            // Legacy model shape: map types are stored as "<key, value>".
            type = "<\(keyType), \(valueType)>"
        } else {
            type = try parseTypeName()
        }

        let name = try expectIdentifier(description: "a field name")
        try expect(.equals)
        guard case .intLiteral = peek().kind else {
            throw unexpected(expected: "a field number")
        }
        advance()

        let isDeprecated = try parseFieldOptions()
        try expect(.semicolon)

        return FieldNode(
            name: name,
            type: type,
            comment: comment,
            isOptional: isOptional,
            isRepeated: isRepeated,
            isMap: isMap,
            isDeprecated: isDeprecated
        )
    }

    /// Scans an optional `[...]` option list, extracting only `deprecated = true`.
    ///
    /// Everything else — parenthesized custom options, aggregate `{...}`
    /// values, float literals — is skipped without being understood, so an
    /// option this tool doesn't support can never fail the parse.
    private mutating func parseFieldOptions() throws -> Bool {
        guard peek().kind == .openBracket else { return false }
        advance()
        var isDeprecated = false
        var depth = 1
        // True only where an option NAME can start ([ or a depth-1 comma),
        // so the tail of a dotted custom option like (my.ext).deprecated
        // is never mistaken for the standard option.
        var atOptionName = true
        while depth > 0 {
            let kind = peek().kind
            switch kind {
            case .openBracket, .openBrace, .openParen, .openAngle:
                depth += 1
            case .closeBracket, .closeBrace, .closeParen, .closeAngle:
                depth -= 1
            case .identifier("deprecated") where depth == 1 && atOptionName:
                if peekNext().kind == .equals,
                   case .identifier("true") = peek(ahead: 2).kind {
                    isDeprecated = true
                }
            case .eof:
                throw unexpected(expected: "']'")
            default:
                break
            }
            atOptionName = kind == .comma && depth == 1
            advance()
        }
        return isDeprecated
    }

    private mutating func parseEnum() throws -> EnumNode {
        advance() // "enum"
        let name = try expectIdentifier(description: "an enum name")
        try expect(.openBrace)
        var node = EnumNode(name: name)

        while peek().kind != .closeBrace {
            _ = takeDocComments()
            if peek().kind == .closeBrace {
                break // dangling comment before the closing brace
            }
            if peek().kind == .semicolon { // empty statements are legal
                advance()
                continue
            }

            guard case .identifier(let word) = peek().kind else {
                throw unexpected(expected: "an enum case or '}'")
            }

            if ["option", "reserved"].contains(word), peekNext().kind != .equals {
                try skipToSemicolon()
                continue
            }

            let caseName = try expectIdentifier(description: "an enum case name")
            try expect(.equals)
            guard case .intLiteral(let value) = peek().kind else {
                throw unexpected(expected: "an enum case value")
            }
            advance()
            _ = try parseFieldOptions()
            try expect(.semicolon)
            node.cases.append(ProtoEnumCase(name: caseName, value: value))
        }
        try expect(.closeBrace)
        return node
    }

    /// Parses a possibly dotted type name like `google.protobuf.Timestamp`.
    /// A leading dot (absolute reference, `.foo.Bar`) is legal and normalized
    /// away — it names the same type.
    private mutating func parseTypeName() throws -> String {
        if peek().kind == .dot {
            advance()
        }
        var parts = [try expectIdentifier(description: "a type name")]
        while peek().kind == .dot {
            advance()
            parts.append(try expectIdentifier(description: "a type name"))
        }
        return parts.joined(separator: ".")
    }

    // MARK: - Skipping

    /// Skips to the statement-terminating semicolon, stepping over balanced
    /// `{...}` and `<...>` regions — both are legal aggregate option value
    /// delimiters and may contain semicolons — so an aggregate value can't
    /// end the skip early.
    private mutating func skipToSemicolon() throws {
        var depth = 0
        while true {
            switch peek().kind {
            case .semicolon where depth == 0:
                advance()
                return
            case .openBrace, .openAngle:
                depth += 1
            case .closeBrace, .closeAngle:
                depth -= 1
            case .eof:
                throw unexpected(expected: "';'")
            default:
                break
            }
            advance()
        }
    }

    /// Steps over an entire `service`/`extend` block by brace matching,
    /// without understanding its contents — `.unknown` tokens included.
    private mutating func skipUnsupportedBlock(named keyword: String) throws {
        if verbose {
            print("Warning: skipping unsupported '\(keyword)' block")
        }
        advance() // keyword
        // Skip everything up to the opening brace (names, rpc signatures, etc.).
        while peek().kind != .openBrace {
            if peek().kind == .eof {
                throw unexpected(expected: "'{'")
            }
            advance()
        }
        advance() // "{"
        var depth = 1
        while depth > 0 {
            switch peek().kind {
            case .openBrace: depth += 1
            case .closeBrace: depth -= 1
            case .eof:
                throw unexpected(expected: "'}'")
            default:
                break
            }
            advance()
        }
    }

    // MARK: - Lookahead

    /// True when the current keyword starts a nested declaration
    /// (`message Name {` / `enum Name {`) rather than acting as a field type.
    private func isDeclarationLookahead() -> Bool {
        guard case .identifier = peekNext().kind else { return false }
        return peek(ahead: 2).kind == .openBrace
    }

    /// True when `optional`/`repeated` is a modifier rather than a field of
    /// that name (`string optional = 1;`) — a modifier is followed by a type,
    /// never by `=`.
    private func isModifierLookahead() -> Bool {
        peekNext().kind != .equals
    }

    // MARK: - Token primitives

    private func peek(ahead: Int = 0) -> Token {
        let target = min(index + ahead, tokens.count - 1)
        return tokens[target]
    }

    private func peekNext() -> Token {
        peek(ahead: 1)
    }

    @discardableResult
    private mutating func advance() -> Token {
        let token = peek()
        if index < tokens.count - 1 {
            index += 1
        }
        return token
    }

    /// Consumes a run of consecutive doc comments, returning the last one —
    /// the comment adjacent to the declaration it documents.
    private mutating func takeDocComments() -> String? {
        var comment: String?
        while case .docComment(let text) = peek().kind {
            comment = text
            advance()
        }
        return comment
    }

    private mutating func expect(
        _ kind: TokenKind,
        description: String? = nil
    ) throws {
        guard peek().kind == kind else {
            throw unexpected(expected: description ?? kind.description)
        }
        advance()
    }

    private mutating func expectIdentifier(description: String) throws -> String {
        guard case .identifier(let text) = peek().kind else {
            throw unexpected(expected: description)
        }
        advance()
        return text
    }

    private func unexpected(expected: String) -> ParseError {
        let token = peek()
        return ParseError(
            line: token.line,
            column: token.column,
            expected: expected,
            found: token.kind.description
        )
    }
}
