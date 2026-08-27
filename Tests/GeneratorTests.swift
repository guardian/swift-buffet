import XCTest
@testable import SwiftBuffet

final class GeneratorTests: XCTestCase {
    func testGenerateSimpleMessage() {
        let simpleMessageProtoMessage = ProtoMessage(
            name: "Person",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "name",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "age",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "is_active",
                    type: "bool",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let messages = [simpleMessageProtoMessage]
        let enums: [ProtoEnum] = []

        let generatedCode = generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: ["Person"],
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("public struct AppPerson"), "The generated code should contain the 'AppPerson' struct")
        XCTAssertTrue(generatedCode.contains("public let name: String"), "The generated code should contain the 'name' property")
        XCTAssertTrue(generatedCode.contains("public let age: Int"), "The generated code should contain the 'age' property")
        XCTAssertTrue(generatedCode.contains("public let isActive: Bool"), "The generated code should contain the 'isActive' property")
        XCTAssertTrue(generatedCode.contains("public init("), "The generated code should contain the 'init' method")
        XCTAssertTrue(generatedCode.contains("self.name = name"), "The generated code should initialize the 'name' property")
        XCTAssertTrue(generatedCode.contains("self.age = age"), "The generated code should initialize the 'age' property")
        XCTAssertTrue(generatedCode.contains("self.isActive = isActive"), "The generated code should initialize the 'isActive' property")
        XCTAssertTrue(generatedCode.contains("internal init?(proto: ProtoPerson)"), "The generated code should contain the 'init?(proto:)' method")
        XCTAssertTrue(generatedCode.contains("public let _localID = UUID()"), "The generated code should a `localID` property")
    }

    func testGenerateNestedMessage() {
        let addressProtoMessage = ProtoMessage(
            name: "Address",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "street",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "city",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "state",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let personProtoMessage = ProtoMessage(
            name: "Person",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "name",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "age",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "address",
                    type: "Address",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let messages = [personProtoMessage, addressProtoMessage]
        let enums: [ProtoEnum] = []

        let generatedCode = generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("public struct AppPerson"), "The generated code should contain the 'AppPerson' struct")
        XCTAssertTrue(generatedCode.contains("public let name: String"), "The generated code should contain the 'name' property")
        XCTAssertTrue(generatedCode.contains("public let age: Int"), "The generated code should contain the 'age' property")
        XCTAssertTrue(generatedCode.contains("public let address: AppAddress"), "The generated code should contain the 'address' property")
        XCTAssertTrue(generatedCode.contains("public struct AppAddress"), "The generated code should contain the 'AppAddress' struct")
        XCTAssertTrue(generatedCode.contains("public let street: String"), "The generated code should contain the 'street' property")
        XCTAssertTrue(generatedCode.contains("public let city: String"), "The generated code should contain the 'city' property")
        XCTAssertTrue(generatedCode.contains("public let state: String"), "The generated code should contain the 'state' property")
        XCTAssertTrue(generatedCode.contains("public init("), "The generated code should contain the 'init' method")
        XCTAssertTrue(generatedCode.contains("internal init?(proto: ProtoPerson)"), "The generated code should contain the 'init?(proto:)' method for 'ProtoPerson'")
        XCTAssertTrue(generatedCode.contains("internal init?(proto: ProtoAddress)"), "The generated code should contain the 'init?(proto:)' method for 'ProtoAddress'")
    }

    func testGenerateNestedEnumAndWellKnownTypes() {
        let personProtoMessage = ProtoMessage(
            name: "Person",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "name",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "age",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "is_active",
                    type: "bool",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "gender",
                    type: "Gender",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "last_active",
                    type: "google.protobuf.Duration",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "created_at",
                    type: "google.protobuf.Timestamp",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let genderProtoEnum = ProtoEnum(
            name: "Gender",
            cases: [
                ProtoEnumCase(name: "UNKNOWN", value: 0),
                ProtoEnumCase(name: "MALE", value: 1),
                ProtoEnumCase(name: "FEMALE", value: 2)
            ],
            parentName: nil
        )

        let messages = [personProtoMessage]
        let enums = [genderProtoEnum]

        let generatedCode = generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("public struct AppPerson"), "The generated code should contain the 'AppPerson' struct")
        XCTAssertTrue(generatedCode.contains("public let name: String"), "The generated code should contain the 'name' property")
        XCTAssertTrue(generatedCode.contains("public let age: Int"), "The generated code should contain the 'age' property")
        XCTAssertTrue(generatedCode.contains("public let isActive: Bool"), "The generated code should contain the 'isActive' property")
        XCTAssertTrue(generatedCode.contains("public enum AppGender: Int"), "The generated code should contain the 'Gender' enum")
        XCTAssertTrue(generatedCode.contains("case unknown = 0"), "The 'Gender' enum should contain the 'unknown' case")
        XCTAssertTrue(generatedCode.contains("case male = 1"), "The 'Gender' enum should contain the 'male' case")
        XCTAssertTrue(generatedCode.contains("case female = 2"), "The 'Gender' enum should contain the 'female' case")
        XCTAssertTrue(generatedCode.contains("public let gender: AppGender"), "The generated code should contain the 'gender' property")
        XCTAssertTrue(generatedCode.contains("public let lastActive: TimeInterval"), "The generated code should contain the 'lastActive' property")
        XCTAssertTrue(generatedCode.contains("public let createdAt: Date"), "The generated code should contain the 'createdAt' property")
        XCTAssertTrue(generatedCode.contains("internal init?(proto: ProtoPerson)"), "The generated code should contain the 'init?(proto:)' method")
    }

    func testLocalIDs() {
        let simpleMessageProtoMessage = ProtoMessage(
            name: "Person",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "name",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let simpleMessageProtoMessageNoLocalID = ProtoMessage(
            name: "Dog",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "breed",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )


        let messages = [simpleMessageProtoMessage, simpleMessageProtoMessageNoLocalID]
        let enums: [ProtoEnum] = []

        let generatedCode = generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: ["Person"],
            includeBackingData: false,
            with: "Proto"
        )

        func containsExactlyOneInstance(of substring: String, in string: String) -> Bool {
            let components = string.components(separatedBy: substring)
            return components.count == 2
        }

        XCTAssert(containsExactlyOneInstance(of: "public let _localID = UUID()", in: generatedCode))
    }

    /// Enums should gain a synthetic `unrecognized` case with a non-failable `init(proto:)`
    /// that falls back to `.unrecognized` for any raw value it doesn't recognize, so that
    /// new proto cases added server-side don't break older clients. This intentionally
    /// mirrors SwiftProtobuf's own `.UNRECOGNIZED(rawValue)` convention, rather than
    /// conflating it with a proto-defined "unspecified" zero case.
    func testEnumUnrecognizedCaseFallback() {
        let statusProtoEnum = ProtoEnum(
            name: "Status",
            cases: [
                ProtoEnumCase(name: "STATUS_ACTIVE", value: 0),
                ProtoEnumCase(name: "STATUS_INACTIVE", value: 1)
            ],
            parentName: nil
        )

        let generatedCode = generateSwiftCode(
            from: [],
            enums: [statusProtoEnum],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("case active = 0"), "The enum should contain the 'active' case")
        XCTAssertTrue(generatedCode.contains("case inactive = 1"), "The enum should contain the 'inactive' case")
        XCTAssertTrue(generatedCode.contains("case unrecognized = 9999"), "The enum should gain a synthetic 'unrecognized' fallback case")
        XCTAssertTrue(generatedCode.contains("internal init(proto: ProtoStatus)"), "The proto initializer should be non-failable")
        XCTAssertFalse(generatedCode.contains("internal init?(proto: ProtoStatus)"), "The proto initializer should not be failable")
        XCTAssertTrue(generatedCode.contains("self = .unrecognized"), "Unrecognized raw values should fall back to '.unrecognized'")
        XCTAssertTrue(generatedCode.contains("Self(rawValue: proto.rawValue)"), "The fallback check should use 'Self(rawValue:)' rather than a nested 'self.init' delegation, which fails to compile inside a non-failable initializer")
    }

    /// A proto enum could conceivably declare its own case that already strips down to
    /// `unrecognized`. In that case the generator must not also emit a synthetic
    /// `case unrecognized`, or the enum fails to compile due to a duplicate case name.
    func testEnumWithExistingUnrecognizedCaseAvoidsDuplicateCase() {
        let statusProtoEnum = ProtoEnum(
            name: "Status",
            cases: [
                ProtoEnumCase(name: "STATUS_UNRECOGNIZED", value: 0),
                ProtoEnumCase(name: "STATUS_ACTIVE", value: 1),
                ProtoEnumCase(name: "STATUS_INACTIVE", value: 2)
            ],
            parentName: nil
        )

        let generatedCode = generateSwiftCode(
            from: [],
            enums: [statusProtoEnum],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("case unrecognized = 0"), "The pre-existing 'unrecognized' case should be preserved")
        let occurrences = generatedCode.components(separatedBy: "case unrecognized").count - 1
        XCTAssertEqual(occurrences, 1, "There should be exactly one 'unrecognized' case, not a duplicate synthetic one")
        XCTAssertFalse(generatedCode.contains("case unrecognized = 9999"), "No synthetic 'unrecognized' case should be added when one already exists")
    }

    /// Regression test: a message with a non-optional field of an enum type must still
    /// produce code that compiles. Enums now have a non-failable `init(proto:)` while
    /// messages keep a failable one, so the shared "if let x = Type(proto:) {...}"
    /// pattern needs the "as Type?" cast to remain valid for both — without it, this
    /// fails with "Initializer for conditional binding must have Optional type".
    func testMessageWithNonOptionalEnumFieldUsesOptionalCast() {
        let statusProtoEnum = ProtoEnum(
            name: "Status",
            cases: [
                ProtoEnumCase(name: "STATUS_UNKNOWN", value: 0),
                ProtoEnumCase(name: "STATUS_ACTIVE", value: 1),
                ProtoEnumCase(name: "STATUS_INACTIVE", value: 2)
            ],
            parentName: nil
        )

        let accountProtoMessage = ProtoMessage(
            name: "Account",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "name",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "status",
                    type: "Status",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let generatedCode = generateSwiftCode(
            from: [accountProtoMessage],
            enums: [statusProtoEnum],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(
            generatedCode.contains("if let status = AppStatus(proto: proto.status) as AppStatus? {"),
            "A non-optional enum-typed field must use an 'as Type?' cast so the binding compiles whether the nested init is failable (messages) or not (enums)"
        )
    }
}
