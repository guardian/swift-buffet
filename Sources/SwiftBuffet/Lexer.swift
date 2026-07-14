import Foundation

/// An error produced while lexing or parsing a .proto file.
struct ParseError: Error, CustomStringConvertible, Equatable {
    let line: Int
    let column: Int
    let expected: String
    let found: String

    var description: String {
        "Parse error at line \(line), column \(column): expected \(expected), found \(found)"
    }
}

/// The kinds of token a .proto file can contain.
///
/// Keywords are not distinguished from identifiers; the parser decides meaning
/// by context, which is what allows keyword-named fields.
enum TokenKind: Equatable {
    case identifier(String)
    case intLiteral(Int)
    case stringLiteral(String)
    /// A `/** ... */` comment, captured verbatim including its delimiters.
    case docComment(String)
    case openBrace
    case closeBrace
    case equals
    case semicolon
    case openAngle
    case closeAngle
    case comma
    case openBracket
    case closeBracket
    case openParen
    case closeParen
    case dot
    /// A character with no meaning in the supported grammar (e.g. ':' inside
    /// an aggregate option value). Kept as a token so skipped regions can
    /// contain it; the parser throws if one appears where it parses strictly.
    case unknown(Character)
    case eof
}

extension TokenKind: CustomStringConvertible {
    /// The user-facing spelling used in parse error messages.
    var description: String {
        switch self {
        case .identifier(let text): "'\(text)'"
        case .intLiteral(let value): "'\(value)'"
        case .stringLiteral(let text): "\"\(text)\""
        case .docComment: "a comment"
        case .openBrace: "'{'"
        case .closeBrace: "'}'"
        case .equals: "'='"
        case .semicolon: "';'"
        case .openAngle: "'<'"
        case .closeAngle: "'>'"
        case .comma: "','"
        case .openBracket: "'['"
        case .closeBracket: "']'"
        case .openParen: "'('"
        case .closeParen: "')'"
        case .dot: "'.'"
        case .unknown(let character): "'\(character)'"
        case .eof: "end of file"
        }
    }
}

/// A token with its 1-based source position.
struct Token: Equatable {
    let kind: TokenKind
    let line: Int
    let column: Int
}

/// Converts .proto source text into a token stream.
struct Lexer {
    static func tokenize(_ source: String) throws -> [Token] {
        var lexer = Lexer(source: source)
        return try lexer.run()
    }

    private let characters: [Character]
    private var index = 0
    private var line = 1
    private var column = 1
    private var tokens: [Token] = []

    private init(source: String) {
        self.characters = Array(source)
    }

    private mutating func run() throws -> [Token] {
        while let character = peek() {
            switch character {
            case " ", "\t", "\r", "\n":
                advance()
            case "{": appendAndAdvance(.openBrace)
            case "}": appendAndAdvance(.closeBrace)
            case "=": appendAndAdvance(.equals)
            case ";": appendAndAdvance(.semicolon)
            case "<": appendAndAdvance(.openAngle)
            case ">": appendAndAdvance(.closeAngle)
            case ",": appendAndAdvance(.comma)
            case "[": appendAndAdvance(.openBracket)
            case "]": appendAndAdvance(.closeBracket)
            case "(": appendAndAdvance(.openParen)
            case ")": appendAndAdvance(.closeParen)
            case ".": appendAndAdvance(.dot)
            case "\"", "'":
                try lexStringLiteral(delimiter: character)
            case "/":
                try lexComment()
            case "-":
                try lexNumber()
            default:
                if character.isNumber {
                    try lexNumber()
                } else if character.isLetter || character == "_" {
                    lexIdentifier()
                } else {
                    appendAndAdvance(.unknown(character))
                }
            }
        }
        tokens.append(Token(kind: .eof, line: line, column: column))
        return tokens
    }

    // MARK: - Lexing helpers

    private mutating func lexIdentifier() {
        let startLine = line
        let startColumn = column
        var text = ""
        while let character = peek(),
              character.isLetter || character.isNumber || character == "_" {
            text.append(character)
            advance()
        }
        tokens.append(
            Token(kind: .identifier(text), line: startLine, column: startColumn)
        )
    }

    /// Lexes an integer literal. Proto allows decimal, hex (`0x1F`), and
    /// octal (`017`) forms.
    private mutating func lexNumber() throws {
        let startLine = line
        let startColumn = column
        var negative = false
        if peek() == "-" {
            negative = true
            advance()
        }

        var digits = ""
        var radix = 10
        if peek() == "0" && (peek(ahead: 1) == "x" || peek(ahead: 1) == "X") {
            radix = 16
            advance()
            advance()
            while let character = peek(), character.isHexDigit {
                digits.append(character)
                advance()
            }
        } else {
            while let character = peek(), character.isNumber {
                digits.append(character)
                advance()
            }
            if digits.count > 1 && digits.hasPrefix("0") {
                radix = 8
            }
        }

        guard let magnitude = Int(digits, radix: radix) else {
            throw ParseError(
                line: startLine,
                column: startColumn,
                expected: "an integer literal",
                found: digits.isEmpty ? "-" : digits
            )
        }
        let value = negative ? -magnitude : magnitude
        tokens.append(
            Token(kind: .intLiteral(value), line: startLine, column: startColumn)
        )
    }

    /// Lexes a string literal. Proto allows both `"` and `'` delimiters and
    /// C-style escape sequences.
    private mutating func lexStringLiteral(delimiter: Character) throws {
        let startLine = line
        let startColumn = column
        advance() // opening quote
        var text = ""
        while let character = peek() {
            if character == delimiter {
                advance()
                tokens.append(
                    Token(
                        kind: .stringLiteral(text),
                        line: startLine,
                        column: startColumn
                    )
                )
                return
            }
            if character == "\\", let escaped = peek(ahead: 1) {
                switch escaped {
                case "n": text.append("\n")
                case "t": text.append("\t")
                case "r": text.append("\r")
                default: text.append(escaped)
                }
                advance()
                advance()
                continue
            }
            text.append(character)
            advance()
        }
        throw ParseError(
            line: startLine,
            column: startColumn,
            expected: "a closing '\(delimiter)'",
            found: "end of file"
        )
    }

    private mutating func lexComment() throws {
        let startLine = line
        let startColumn = column
        if peek(ahead: 1) == "/" {
            // Line comment: skip to end of line.
            while let character = peek(), character != "\n" {
                advance()
            }
        } else if peek(ahead: 1) == "*" {
            let isDocComment = peek(ahead: 2) == "*" && peek(ahead: 3) != "/"
            var text = ""
            advance() // "/"
            advance() // "*"
            text = "/*"
            while index < characters.count {
                if peek() == "*" && peek(ahead: 1) == "/" {
                    advance()
                    advance()
                    text += "*/"
                    if isDocComment {
                        tokens.append(
                            Token(
                                kind: .docComment(text),
                                line: startLine,
                                column: startColumn
                            )
                        )
                    }
                    return
                }
                text.append(characters[index])
                advance()
            }
            throw ParseError(
                line: startLine,
                column: startColumn,
                expected: "a closing '*/'",
                found: "end of file"
            )
        } else {
            throw error(expected: "a comment", found: "/")
        }
    }

    // MARK: - Cursor

    private func peek(ahead: Int = 0) -> Character? {
        let target = index + ahead
        guard target < characters.count else { return nil }
        return characters[target]
    }

    private mutating func advance() {
        guard index < characters.count else { return }
        if characters[index] == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
        index += 1
    }

    private mutating func appendAndAdvance(_ kind: TokenKind) {
        tokens.append(Token(kind: kind, line: line, column: column))
        advance()
    }

    private func error(expected: String, found: String) -> ParseError {
        ParseError(line: line, column: column, expected: expected, found: found)
    }
}
