import Testing
import Foundation
@testable import SwiftBuffet

@Suite struct LexerTests {

    private func kinds(_ source: String) throws -> [TokenKind] {
        try Lexer.tokenize(source).map(\.kind)
    }

    @Test func punctuation() throws {
        #expect(
            try kinds("{ } = ; < > , [ ] ( ) .") == [
                .openBrace,
                .closeBrace,
                .equals,
                .semicolon,
                .openAngle,
                .closeAngle,
                .comma,
                .openBracket,
                .closeBracket,
                .openParen,
                .closeParen,
                .dot,
                .eof
            ]
        )
    }

    @Test func `Identifiers and keywords are identifiers`() throws {
        #expect(
            try kinds("message optional foo_bar Baz9") == [
                .identifier("message"),
                .identifier("optional"),
                .identifier("foo_bar"),
                .identifier("Baz9"),
                .eof
            ]
        )
    }

    @Test func `Int literals`() throws {
        #expect(
            try kinds("0 42 -7") == [
                .intLiteral(0),
                .intLiteral(42),
                .intLiteral(-7),
                .eof
            ]
        )
    }

    @Test func `String literal`() throws {
        #expect(
            try kinds(#"import "google/protobuf/duration.proto";"#) == [
                .identifier("import"),
                .stringLiteral("google/protobuf/duration.proto"),
                .semicolon,
                .eof
            ]
        )
    }

    @Test func `Doc comment captured verbatim`() throws {
        #expect(
            try kinds("/** hi there */ string") == [
                .docComment("/** hi there */"),
                .identifier("string"),
                .eof
            ]
        )
    }

    @Test func `Line comments skipped`() throws {
        #expect(
            try kinds("foo // comment text ; { }\nbar") == [
                .identifier("foo"),
                .identifier("bar"),
                .eof
            ]
        )
    }

    @Test func `Plain block comments skipped`() throws {
        #expect(
            try kinds("foo /* not a doc comment */ bar") == [
                .identifier("foo"),
                .identifier("bar"),
                .eof
            ]
        )
    }

    @Test func positions() throws {
        let tokens = try Lexer.tokenize("message Person {\n  string name = 1;\n}")
        let message = tokens[0]
        #expect(message.line == 1)
        #expect(message.column == 1)
        let string = tokens[3]
        #expect(string.kind == .identifier("string"))
        #expect(string.line == 2)
        #expect(string.column == 3)
        let closeBrace = tokens[tokens.count - 2]
        #expect(closeBrace.kind == .closeBrace)
        #expect(closeBrace.line == 3)
        #expect(closeBrace.column == 1)
    }

    @Test func `Unterminated string throws`() {
        let error = #expect(throws: ParseError.self) {
            try Lexer.tokenize(#"option x = "unclosed"#)
        }
        #expect(error?.line == 1)
    }

    @Test func `Unterminated block comment throws`() {
        #expect(throws: ParseError.self) {
            try Lexer.tokenize("foo /** never closed")
        }
    }

    @Test func `Unknown characters become tokens`() throws {
        #expect(
            try kinds("get: \"/v1\"") == [
                .identifier("get"),
                .unknown(":"),
                .stringLiteral("/v1"),
                .eof
            ]
        )
    }

    @Test func `Unknown character in parsed position throws`() {
        let error = #expect(throws: ParseError.self) {
            try ProtoParser.parse(
                "message § {}",
                verbose: false
            )
        }
        #expect(error?.column == 9)
    }
}
