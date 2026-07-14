import Testing
import Foundation
@testable import SwiftBuffet

@Suite struct ProtoParserErrorTests {

    /// Asserts `source` fails to parse and returns the typed error for
    /// inspection. `#expect(throws:)` records the failure itself if no
    /// `ParseError` is thrown.
    private func parseError(_ source: String) -> ParseError? {
        #expect(throws: ParseError.self) {
            try ProtoParser.parse(source, verbose: false)
        }
    }

    @Test func `Missing semicolon after field`() {
        let proto = """
        message A {
        string x = 1
        }
        """
        let error = parseError(proto)
        #expect(error?.line == 3)
        #expect(error?.expected == "';'")
    }

    @Test func `Missing brace after message name`() {
        let proto = "message A string x = 1; }"
        let error = parseError(proto)
        #expect(error?.line == 1)
        #expect(error?.expected == "'{'")
    }

    @Test func `Missing field number`() {
        let proto = """
        message A {
        string x = ;
        }
        """
        let error = parseError(proto)
        #expect(error?.line == 2)
        #expect(error?.expected == "a field number")
    }

    @Test func `Unexpected end of file inside message`() {
        let proto = """
        message A {
        string x = 1;
        """
        let error = parseError(proto)
        #expect(error?.found == "end of file")
    }

    @Test func `Unknown top level statement`() {
        let proto = "rpc Foo (Bar) returns (Baz);"
        _ = parseError(proto)
    }

    @Test func `Oneof members are parsed as fields`() throws {
        let proto = """
        message A {
        string x = 1;
        oneof choice {
        string a = 2;
        int32 b = 3;
        }
        string y = 4;
        }
        """
        let file = try ProtoParser.parse(proto, verbose: false)
        #expect(file.messages.count == 1)
        #expect(file.messages[0].fields.map(\.name) == ["x", "a", "b", "y"])
    }

    @Test func `Service is skipped without error`() throws {
        let proto = """
        service Greeter {
        rpc SayHello (HelloRequest) returns (HelloReply);
        }

        message HelloRequest {
        string name = 1;
        }
        """
        let file = try ProtoParser.parse(proto, verbose: false)
        #expect(file.messages.map(\.name) == ["HelloRequest"])
    }

    @Test func `Reserved is skipped silently`() throws {
        let proto = """
        message A {
        reserved 2, 15;
        reserved "foo", "bar";
        string x = 1;
        }
        """
        let file = try ProtoParser.parse(proto, verbose: false)
        #expect(file.messages[0].fields.map(\.name) == ["x"])
    }
}
