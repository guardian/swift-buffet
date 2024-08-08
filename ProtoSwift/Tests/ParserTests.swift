import XCTest
@testable import ProtoSwiftTool

final class ParserTests: XCTestCase {
    func testParseSimpleMessage() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Person {
          string name = 1;
          int32 age = 2;
          bool is_active = 3;
        }
        """

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 1, "Expected to find 1 message, but got \(messages.count)")
        XCTAssertEqual(enums.count, 0, "Expected to find 0 enums, but got \(enums.count)")

        let personMessage = messages.first!
        XCTAssertEqual(personMessage.name, "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        XCTAssertNil(personMessage.parentName, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        XCTAssertEqual(personMessage.fields.count, 3, "Expected 3 fields, but got \(personMessage.fields.count)")

        let nameField = personMessage.fields[0]
        XCTAssertEqual(nameField.name, "name", "Expected field name to be 'name', but got '\(nameField.name)'")
        XCTAssertEqual(nameField.type, "string", "Expected field type to be 'string', but got '\(nameField.type)'")
        XCTAssertFalse(nameField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(nameField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(nameField.isMap, "Expected field to be non-map")
    }

    func testParseNestedMessage() throws {
        var protoFileContent = """
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

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 2, "Expected to find 2 messages, but got \(messages.count)")
        XCTAssertEqual(enums.count, 0, "Expected to find 0 enums, but got \(enums.count)")

        let personMessage = messages.first { $0.name == "Person" }!
        XCTAssertEqual(personMessage.name, "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        XCTAssertNil(personMessage.parentName, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        XCTAssertEqual(personMessage.fields.count, 3, "Expected 3 fields, but got \(personMessage.fields.count)")

        let addressMessage = messages.first { $0.name == "Address" }!
        XCTAssertEqual(addressMessage.name, "Address", "Expected message name to be 'Address', but got '\(addressMessage.name)'")
        XCTAssertNil(addressMessage.parentName, "Expected parent name to be nil, but got '\(addressMessage.parentName ?? "")'")
        XCTAssertEqual(addressMessage.fields.count, 3, "Expected 3 fields, but got \(addressMessage.fields.count)")
    }

    func testParseNestedEnumAndWellKnownTypes() throws {
        var protoFileContent = """
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

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 1, "Expected to find 1 message, but got \(messages.count)")
        XCTAssertEqual(enums.count, 1, "Expected to find 1 enum, but got \(enums.count)")

        let personMessage = messages.first { $0.name == "Person" }!
        XCTAssertEqual(personMessage.name, "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        XCTAssertNil(personMessage.parentName, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        XCTAssertEqual(personMessage.fields.count, 6, "Expected 6 fields, but got \(personMessage.fields.count)")

        let genderEnum = enums.first { $0.name == "Gender" }!
        XCTAssertEqual(genderEnum.name, "Gender", "Expected enum name to be 'Gender', but got '\(genderEnum.name)'")
        XCTAssertEqual(genderEnum.parentName, "Person", "Expected parent name to be 'Person', but got '\(genderEnum.parentName ?? "")'")
        XCTAssertEqual(genderEnum.cases.count, 3, "Expected 3 enum cases, but got \(genderEnum.cases.count)")

        let genderField = personMessage.fields.first { $0.name == "gender" }!
        XCTAssertEqual(genderField.name, "gender", "Expected field name to be 'gender', but got '\(genderField.name)'")
        XCTAssertEqual(genderField.type, "Gender", "Expected field type to be 'Gender', but got '\(genderField.type)'")
        XCTAssertFalse(genderField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(genderField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(genderField.isMap, "Expected field to be non-map")

        let lastActiveField = personMessage.fields.first { $0.name == "last_active" }!
        XCTAssertEqual(lastActiveField.name, "last_active", "Expected field name to be 'last_active', but got '\(lastActiveField.name)'")
        XCTAssertEqual(lastActiveField.type, "google.protobuf.Duration", "Expected field type to be 'google.protobuf.Duration', but got '\(lastActiveField.type)'")
        XCTAssertFalse(lastActiveField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(lastActiveField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(lastActiveField.isMap, "Expected field to be non-map")

        let createdAtField = personMessage.fields.first { $0.name == "created_at" }!
        XCTAssertEqual(createdAtField.name, "created_at", "Expected field name to be 'created_at', but got '\(createdAtField.name)'")
        XCTAssertEqual(createdAtField.type, "google.protobuf.Timestamp", "Expected field type to be 'google.protobuf.Timestamp', but got '\(createdAtField.type)'")
        XCTAssertFalse(createdAtField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(createdAtField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(createdAtField.isMap, "Expected field to be non-map")
    }
}
