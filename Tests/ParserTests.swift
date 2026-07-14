import Testing
import Foundation
@testable import SwiftBuffet

@Suite struct ParserTests {
    @Test func `Parse simple message`() throws {
        let protoFileContent = """
        syntax = "proto3";

        message Person {
          string name = 1;
          int32 age = 2;
          bool is_active = 3;
        }
        """

        let (messages, enums) = try parseProto(protoFileContent, swiftPrefix: "MyApp")

        #expect(messages.count == 1, "Expected to find 1 message, but got \(messages.count)")
        #expect(enums.count == 0, "Expected to find 0 enums, but got \(enums.count)")

        let personMessage = messages.first!
        #expect(personMessage.name == "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        #expect(personMessage.parentName == nil, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        #expect(personMessage.fields.count == 3, "Expected 3 fields, but got \(personMessage.fields.count)")

        let nameField = personMessage.fields[0]
        #expect(nameField.name == "name", "Expected field name to be 'name', but got '\(nameField.name)'")
        #expect(nameField.type == "string", "Expected field type to be 'string', but got '\(nameField.type)'")
        #expect(nameField.isOptional == false, "Expected field to be non-optional")
        #expect(nameField.isRepeated == false, "Expected field to be non-repeated")
        #expect(nameField.isMap == false, "Expected field to be non-map")
    }

    @Test func `Parse nested message`() throws {
        let protoFileContent = """
        syntax = "proto3";

        message Person {
          string name = 1;
          int32 age = 2;
          Address address = 3;
        }

        message Address {
          string street = 1;
          string city = 2;
          string state = 3;
        }
        """

        let (messages, enums) = try parseProto(protoFileContent, swiftPrefix: "MyApp")

        #expect(messages.count == 2, "Expected to find 2 messages, but got \(messages.count)")
        #expect(enums.count == 0, "Expected to find 0 enums, but got \(enums.count)")

        let personMessage = messages.first { $0.name == "Person" }!
        #expect(personMessage.name == "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        #expect(personMessage.parentName == nil, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        #expect(personMessage.fields.count == 3, "Expected 3 fields, but got \(personMessage.fields.count)")

        let addressMessage = messages.first { $0.name == "Address" }!
        #expect(addressMessage.name == "Address", "Expected message name to be 'Address', but got '\(addressMessage.name)'")
        #expect(addressMessage.parentName == nil, "Expected parent name to be nil, but got '\(addressMessage.parentName ?? "")'")
        #expect(addressMessage.fields.count == 3, "Expected 3 fields, but got \(addressMessage.fields.count)")
    }

    @Test func `Parse nested enum and well known types`() throws {
        let protoFileContent = """
            syntax = "proto3";

            import "google/protobuf/duration.proto";
            import "google/protobuf/timestamp.proto";

            message Person {
              string name = 1;
              int32 age = 2;
              bool is_active = 3;
              enum Gender {
                UNKNOWN = 0;
                MALE = 1;
                FEMALE = 2;
              }
              Gender gender = 4;
              google.protobuf.Duration last_active = 5;
              google.protobuf.Timestamp created_at = 6;
            }
            """

        let (messages, enums) = try parseProto(protoFileContent, swiftPrefix: "MyApp")

        #expect(messages.count == 1, "Expected to find 1 message, but got \(messages.count)")
        #expect(enums.count == 1, "Expected to find 1 enum, but got \(enums.count)")

        let personMessage = messages.first { $0.name == "Person" }!
        #expect(personMessage.name == "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        #expect(personMessage.parentName == nil, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        #expect(personMessage.fields.count == 6, "Expected 6 fields, but got \(personMessage.fields.count)")

        let genderEnum = enums.first { $0.name == "Gender" }!
        #expect(genderEnum.name == "Gender", "Expected enum name to be 'Gender', but got '\(genderEnum.name)'")
        #expect(genderEnum.parentName == "Person", "Expected parent name to be 'Person', but got '\(genderEnum.parentName ?? "")'")
        #expect(genderEnum.cases.count == 3, "Expected 3 enum cases, but got \(genderEnum.cases.count)")

        let genderField = personMessage.fields.first { $0.name == "gender" }!
        #expect(genderField.name == "gender", "Expected field name to be 'gender', but got '\(genderField.name)'")
        #expect(genderField.type == "Gender", "Expected field type to be 'Gender', but got '\(genderField.type)'")
        #expect(genderField.isOptional == false, "Expected field to be non-optional")
        #expect(genderField.isRepeated == false, "Expected field to be non-repeated")
        #expect(genderField.isMap == false, "Expected field to be non-map")

        let lastActiveField = personMessage.fields.first { $0.name == "last_active" }!
        #expect(lastActiveField.name == "last_active", "Expected field name to be 'last_active', but got '\(lastActiveField.name)'")
        #expect(lastActiveField.type == "google.protobuf.Duration", "Expected field type to be 'google.protobuf.Duration', but got '\(lastActiveField.type)'")
        #expect(lastActiveField.isOptional == false, "Expected field to be non-optional")
        #expect(lastActiveField.isRepeated == false, "Expected field to be non-repeated")
        #expect(lastActiveField.isMap == false, "Expected field to be non-map")

        let createdAtField = personMessage.fields.first { $0.name == "created_at" }!
        #expect(createdAtField.name == "created_at", "Expected field name to be 'created_at', but got '\(createdAtField.name)'")
        #expect(createdAtField.type == "google.protobuf.Timestamp", "Expected field type to be 'google.protobuf.Timestamp', but got '\(createdAtField.type)'")
        #expect(createdAtField.isOptional == false, "Expected field to be non-optional")
        #expect(createdAtField.isRepeated == false, "Expected field to be non-repeated")
        #expect(createdAtField.isMap == false, "Expected field to be non-map")
    }

    @Test func `Parse field modifiers`() throws {
        let protoFileContent = """
        syntax = "proto3";

        message Person {
          /** The person's nickname */
          optional string nick_name = 1;
          repeated string tags = 2;
          map<string, string> labels = 3;
          string old_field = 4 [deprecated = true];
        }
        """

        let (messages, _) = try parseProto(protoFileContent, swiftPrefix: "MyApp")

        let fields = messages.first!.fields
        #expect(fields.count == 4)

        let nickName = fields.first { $0.name == "nick_name" }!
        #expect(nickName.isOptional)
        #expect(nickName.comment?.contains("The person's nickname") == true)

        let tags = fields.first { $0.name == "tags" }!
        #expect(tags.isRepeated)
        #expect(tags.isOptional == false)

        let labels = fields.first { $0.name == "labels" }!
        #expect(labels.isMap)
        #expect(labels.type == "<string, string>")

        let oldField = fields.first { $0.name == "old_field" }!
        #expect(oldField.isDeprecated)
    }

    @Test func `Parse and generate example proto`() throws {
        let protoFileContent = """
        syntax = "proto3";

        message Person {
            string name = 1;
            int32 id = 2;
            string email = 3;
        }

        message AddressBook {
            repeated Person people = 1;
            optional bool is_current = 2;
        }

        message Address {
            string street = 1 [deprecated = true];
        }
        """

        let (messages, enums) = try parseProto(protoFileContent, swiftPrefix: "")

        #expect(messages.count == 3)
        #expect(enums.count == 0)

        let code = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        func normalized(_ string: String) -> String {
            string.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }
        let normalizedCode = normalized(code)

        #expect(code.contains("public struct Person: Hashable, Equatable, Sendable {"))
        #expect(code.contains("public let id: Int"))
        #expect(code.contains("self.id = Int(proto.id)"))
        #expect(code.contains("public let people: [Person]"))
        #expect(normalizedCode.contains(normalized("self.people = proto.people.compactMap { Person(proto: $0) }")))
        #expect(code.contains("public let isCurrent: Bool"))
        #expect(code.contains("/// This property has been marked as **deprecated** in the proto file"))
        #expect(code.contains("public init?(data: Data) {"))
    }
}
