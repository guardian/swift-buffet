import Testing
import Foundation
@testable import SwiftBuffet

/// Characterization corpus for `parseProto`.
///
/// These tests pin the parsing contract established before the regex →
/// recursive-descent migration, including inputs the regex parser mishandled.
@Suite struct ParserCorpusTests {

    @Test func `Empty message single line`() throws {
        let proto = "message Empty {}"
        let (messages, enums) = try parseProto(proto, swiftPrefix: "")
        #expect(enums.count == 0)
        #expect(messages.count == 1)
        #expect(messages.first?.name == "Empty")
        #expect(messages.first?.fields.count == 0)
    }

    @Test func `Simple message field types`() throws {
        let proto = """
        message Person {
            string name = 1;
            int32 age = 2;
            bool is_active = 3;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        let fields = messages[0].fields
        #expect(fields.map(\.name) == ["name", "age", "is_active"])
        #expect(fields.map(\.type) == ["string", "int32", "bool"])
        #expect(fields.allSatisfy { $0.isOptional == false })
        #expect(fields.allSatisfy { $0.isRepeated == false })
        #expect(fields.allSatisfy { $0.isMap == false })
        #expect(fields.allSatisfy { $0.isDeprecated == false })
    }

    @Test func `Multiple top level declarations`() throws {
        let proto = """
        message A {
            string x = 1;
        }

        enum Color {
            COLOR_UNSPECIFIED = 0;
            COLOR_RED = 1;
        }

        message B {
            int32 y = 1;
        }
        """
        let (messages, enums) = try parseProto(proto, swiftPrefix: "")
        #expect(Set(messages.map(\.name)) == ["A", "B"])
        #expect(enums.map(\.name) == ["Color"])
        #expect(enums.first?.cases.count == 2)
        #expect(messages.first?.parentName == nil)
        #expect(enums.first?.parentName == nil)
    }

    @Test func `Nested message two levels`() throws {
        let proto = """
        message Outer {
            string a = 1;
            message Middle {
                string b = 1;
                message Inner {
                    string c = 1;
                }
           }
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 3)
        let outer = messages.first { $0.name == "Outer" }
        let middle = messages.first { $0.name == "Middle" }
        let inner = messages.first { $0.name == "Inner" }
        #expect(outer?.parentName == nil)
        #expect(middle?.parentName == "Outer")
        #expect(inner?.parentName == "Middle")
        #expect(outer?.fields.map(\.name) == ["a"])
        #expect(middle?.fields.map(\.name) == ["b"])
        #expect(inner?.fields.map(\.name) == ["c"])
    }

    @Test func `Nested enum in message`() throws {
        let proto = """
        message Person {
            enum Gender {
                GENDER_UNKNOWN = 0;
                GENDER_MALE = 1;
            }
            Gender gender = 1;
        }
        """
        let (messages, enums) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(enums.count == 1)
        #expect(enums.first?.parentName == "Person")
        #expect(enums.first?.cases.map(\.value) == [0, 1])
        #expect(messages.first?.fields.map(\.type) == ["Gender"])
    }

    @Test func `Optional and repeated fields`() throws {
        let proto = """
        message Bag {
            optional string label = 1;
            repeated int32 counts = 2;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        let fields = messages[0].fields
        #expect(fields[0].isOptional)
        #expect(fields[0].isRepeated == false)
        #expect(fields[1].isRepeated)
        #expect(fields[1].isOptional == false)
    }

    @Test func `Map fields`() throws {
        let proto = """
        message Lookup {
            map<string, int32> scores = 1;
            map<string, Person> people = 2;
        }

        message Person {
            string name = 1;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        let lookup = messages.first { $0.name == "Lookup" }!
        #expect(lookup.fields[0].isMap)
        #expect(lookup.fields[0].caseCorrectedBaseType == "[String: Int]")
        #expect(lookup.fields[1].isMap)
        #expect(lookup.fields[1].caseCorrectedBaseType == "[String: Person]")
    }

    @Test func `Deprecated field option`() throws {
        let proto = """
        message Address {
            string street = 1 [deprecated = true];
            string city = 2;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages[0].fields[0].isDeprecated)
        #expect(messages[0].fields[1].isDeprecated == false)
    }

    @Test func `Doc comment on field`() throws {
        let proto = """
        message Person {
            /** The person's legal name. */
            string name = 1;
            int32 age = 2;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        let nameField = messages[0].fields.first { $0.name == "name" }!
        #expect(nameField.comment != nil)
        #expect(nameField.comment?.contains("legal name") == true)
        let ageField = messages[0].fields.first { $0.name == "age" }!
        #expect(ageField.comment == nil)
    }

    @Test func `Enum common prefix cases`() throws {
        let proto = """
        enum Gender {
            GENDER_UNKNOWN = 0;
            GENDER_MALE = 1;
            GENDER_FEMALE = 2;
        }
        """
        let (_, enums) = try parseProto(proto, swiftPrefix: "")
        #expect(enums.count == 1)
        #expect(enums[0].cases.map(\.name) == ["GENDER_UNKNOWN", "GENDER_MALE", "GENDER_FEMALE"])
        #expect(enums[0].cases.map(\.value) == [0, 1, 2])
        let stripped = stripCommonPrefix(from: enums[0].cases)
        #expect(stripped.map(\.name) == ["unknown", "male", "female"])
    }

    @Test func `Single case enum keeps a usable name`() throws {
        let stripped = stripCommonPrefix(from: [
            ProtoEnumCase(name: "S_UNKNOWN", value: 0)
        ])
        #expect(
            stripped.map(\.name) == ["sUnknown"],
            "A single case is its own common prefix and must not be stripped"
        )
    }

    @Test func `Prefix equal to whole case name is not stripped`() throws {
        let stripped = stripCommonPrefix(from: [
            ProtoEnumCase(name: "GENDER", value: 0),
            ProtoEnumCase(name: "GENDER_MALE", value: 1)
        ])
        #expect(
            stripped.map(\.name) == ["gender", "genderMale"],
            "Stripping must back off entirely when it would empty a name"
        )
    }

    @Test func `Header statements ignored`() throws {
        let proto = """
        syntax = "proto3";
        package com.example.app;
        import "google/protobuf/timestamp.proto";
        option java_package = "com.example";

        message Person {
            google.protobuf.Timestamp created_at = 1;
        }
        """
        let (messages, enums) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(enums.count == 0)
        #expect(messages[0].fields[0].type == "google.protobuf.Timestamp")
    }

    @Test func `Varied whitespace`() throws {
        let proto = "message A {\n\tstring x = 1;\n\n\n  int32   y   =   2 ;\n}"
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages[0].fields.map(\.name) == ["x", "y"])
    }

    @Test func `Closing brace on same line as field`() throws {
        let proto = "message A { string x = 1; }"
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages.first?.fields.map(\.name) == ["x"])
    }

    @Test func `Closing brace indented`() throws {
        let proto = """
        message A {
            string x = 1;
            }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages.first?.fields.map(\.name) == ["x"])
    }

    @Test func `Doc comments in all positions`() throws {
        let proto = """
        /** File-level overview comment. */
        message Person {
            /** first */
            /** second comment wins */
            string name = 1;
            int32 age = 2;
            /** dangling comment before close */
        }
        
        /** between declarations */
        enum Plan {
            /** case comment */
            PLAN_FREE = 0;
            /** dangling in enum */
        }
        """
        let (messages, enums) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(enums.count == 1)
        #expect(messages[0].fields.map(\.name) == ["name", "age"])
        #expect(messages[0].fields[0].comment?.contains("second comment wins") == true)
        #expect(messages[0].fields[1].comment == nil)
        #expect(enums[0].cases.map(\.name) == ["PLAN_FREE"])
    }

    @Test func `Custom parenthesized field options`() throws {
        let proto = """
        message User {
            string email = 1 [(validate.rules).string.min_len = 1];
            string name = 2 [(validate.rules).string = { min_len: 1, max_len: 64 }];
            float ratio = 3 [some_option = 0.5];
            string street = 4 [deprecated = true, (custom.opt) = "x"];
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages[0].fields.map(\.name) == ["email", "name", "ratio", "street"])
        #expect(messages[0].fields[0].isDeprecated == false)
        #expect(messages[0].fields[2].isDeprecated == false)
        #expect(messages[0].fields[3].isDeprecated)
    }

    @Test func `Aggregate option values ignored`() throws {
        let proto = """
        syntax = "proto3";
        option (my.file_option) = { key: "value" nested: { flag: true } };
        option (my.angle_option) = < a: 1; b: 2 >;

        message Api {
            string path = 1;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages[0].fields.map(\.name) == ["path"])
    }

    @Test func `Dotted custom option ending in deprecated is not deprecated`() throws {
        let proto = """
        message M {
            int32 a = 1 [(my.ext).deprecated = true];
            int32 b = 2 [(custom.opt) = 5, deprecated = true];
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages[0].fields[0].isDeprecated == false, "A dotted custom option ending in .deprecated is not the standard option")
        #expect(messages[0].fields[1].isDeprecated, "deprecated = true after a comma is the standard option")
    }

    @Test func `Oneof members become fields`() throws {
        let proto = """
        message Event {
            string id = 1;
            oneof payload {
                string click = 2;
                int32 view = 3;
            }
            string source = 4;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages[0].fields.map(\.name) == ["id", "click", "view", "source"])
    }

    @Test func `Deep nesting preserves full parent path`() throws {
        let proto = """
        message A {
           message B {
                enum Status {
                    STATUS_UNSPECIFIED = 0;
                }
                Status status = 1;
            }
        }
        """
        let (messages, enums) = try parseProto(proto, swiftPrefix: "")
        let b = messages.first { $0.name == "B" }!
        #expect(b.parentName == "A")
        #expect(b.fullName == "A.B")
        let status = enums.first { $0.name == "Status" }!
        #expect(status.parentName == "B")
        #expect(status.fullName == "A.B.Status")
    }

    @Test func `Keyword like field names`() throws {
        let proto = """
        message Config {
            string message_text = 1;
            string option = 2;
        }
        """
        let (messages, _) = try parseProto(proto, swiftPrefix: "")
        #expect(messages.count == 1)
        #expect(messages[0].fields.map(\.name) == ["message_text", "option"])
    }
}
