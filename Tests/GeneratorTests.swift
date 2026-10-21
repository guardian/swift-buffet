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

    /// `oneof` fields are mutually exclusive, so they should be generated as a single
    /// optional enum property (one case per member) rather than as several
    /// independent, non-optional struct properties.
    func testGenerateMessageWithOneof() {
        let contentOneof = ProtoOneof(
            name: "content",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "image",
                    type: "Image",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "video",
                    type: "Video",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ]
        )

        let slideProtoMessage = ProtoMessage(
            name: "MultimediaSlide",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "label",
                    type: "string",
                    comment: nil,
                    isOptional: true,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil,
            oneofs: [contentOneof]
        )

        let generatedCode = generateSwiftCode(
            from: [slideProtoMessage],
            enums: [],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("extension AppMultimediaSlide {"), "The oneof enum should be nested in an extension of its owning message")
        XCTAssertTrue(generatedCode.contains("public enum OneOf_Content: Hashable, Equatable, Sendable {"), "The generated code should contain the nested 'OneOf_Content' enum")
        XCTAssertTrue(generatedCode.contains("indirect case image(AppImage)"), "The oneof enum should contain the 'image' case")
        XCTAssertTrue(generatedCode.contains("indirect case video(AppVideo)"), "The oneof enum should contain the 'video' case")

        XCTAssertTrue(generatedCode.contains("public let content: AppMultimediaSlide.OneOf_Content?"), "The message struct should contain an optional 'content' property of the nested oneof enum type")
        XCTAssertTrue(generatedCode.contains("public let label: String?"), "The message struct should still contain its regular 'label' property")

        XCTAssertFalse(generatedCode.contains("public let image:"), "Oneof member fields should not also be generated as independent struct properties")
        XCTAssertFalse(generatedCode.contains("public let video:"), "Oneof member fields should not also be generated as independent struct properties")

        XCTAssertTrue(generatedCode.contains("internal init?(proto: ProtoMultimediaSlide.OneOf_Content)"), "The oneof enum should have a failable initializer from the generated protobuf 'OneOf_Content' enum")
        XCTAssertTrue(generatedCode.contains("case .image(let value):"), "The proto initializer should switch over the proto's 'image' case")
        XCTAssertTrue(generatedCode.contains("case .video(let value):"), "The proto initializer should switch over the proto's 'video' case")

        XCTAssertTrue(generatedCode.contains("if let contentProto = proto.content {"), "The message's proto initializer should read the raw oneof value from the proto")
        XCTAssertTrue(generatedCode.contains("if let content = AppMultimediaSlide.OneOf_Content(proto: contentProto) {"), "The message's proto initializer should convert the raw oneof value using the generated enum's initializer")
    }

    /// Declaring the oneof enum at the top level by concatenating the message and
    /// oneof names could collide with a separate message of that same concatenated
    /// name — `message Foo { oneof bar {...} }` alongside `message FooBar` would both
    /// want to be `AppFooBar`. Nesting the enum inside its owning message keeps the
    /// two namespaces distinct.
    func testOneofTypeDoesNotCollideWithSimilarlyNamedMessage() {
        let fooMessage = ProtoMessage(
            name: "Foo",
            fields: [],
            parentName: nil,
            oneofs: [
                ProtoOneof(
                    name: "bar",
                    fields: [
                        ProtoField(
                            swiftPrefix: "App",
                            name: "value",
                            type: "string",
                            comment: nil,
                            isOptional: false,
                            isRepeated: false,
                            isMap: false,
                            isDeprecated: false
                        )
                    ]
                )
            ]
        )

        let fooBarMessage = ProtoMessage(
            name: "FooBar",
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

        let generatedCode = generateSwiftCode(
            from: [fooMessage, fooBarMessage],
            enums: [],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("public struct AppFooBar: Hashable, Equatable, Sendable {"), "The 'FooBar' message should still generate its struct")
        XCTAssertFalse(generatedCode.contains("public enum AppFooBar"), "The oneof enum must not be declared as a top-level 'AppFooBar', which would redeclare the 'FooBar' struct")
        XCTAssertTrue(generatedCode.contains("public enum OneOf_Bar: Hashable, Equatable, Sendable {"), "The oneof enum should be nested and namespaced by its owning message")
        XCTAssertTrue(generatedCode.contains("public let bar: AppFoo.OneOf_Bar?"), "The oneof property should reference the nested enum type")
    }

    /// Protobuf's integer scalars are surfaced by SwiftProtobuf as fixed-width types
    /// (`Int32`/`UInt32`/`Int64`/`UInt64`), so they need converting to the `Int`/`UInt`
    /// the generated case declares. A substring check for "int" both misses types like
    /// `fixed32` and wrongly matches message types such as `Point`.
    func testOneofIntegerPayloadsConvertToDeclaredType() {
        let valuesMessage = ProtoMessage(
            name: "Values",
            fields: [],
            parentName: nil,
            oneofs: [
                ProtoOneof(
                    name: "value",
                    fields: [
                        ProtoField(
                            swiftPrefix: "App",
                            name: "signed",
                            type: "int32",
                            comment: nil,
                            isOptional: false,
                            isRepeated: false,
                            isMap: false,
                            isDeprecated: false
                        ),
                        ProtoField(
                            swiftPrefix: "App",
                            name: "unsigned",
                            type: "uint64",
                            comment: nil,
                            isOptional: false,
                            isRepeated: false,
                            isMap: false,
                            isDeprecated: false
                        ),
                        ProtoField(
                            swiftPrefix: "App",
                            name: "fixed",
                            type: "fixed32",
                            comment: nil,
                            isOptional: false,
                            isRepeated: false,
                            isMap: false,
                            isDeprecated: false
                        ),
                        ProtoField(
                            swiftPrefix: "App",
                            name: "point",
                            type: "Point",
                            comment: nil,
                            isOptional: false,
                            isRepeated: false,
                            isMap: false,
                            isDeprecated: false
                        )
                    ]
                )
            ]
        )

        let pointMessage = ProtoMessage(
            name: "Point",
            fields: [],
            parentName: nil
        )

        let generatedCode = generateSwiftCode(
            from: [valuesMessage, pointMessage],
            enums: [],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        XCTAssertTrue(generatedCode.contains("indirect case signed(Int)"), "'int32' should surface as 'Int'")
        XCTAssertTrue(generatedCode.contains("indirect case unsigned(UInt)"), "'uint64' should surface as 'UInt'")
        XCTAssertTrue(generatedCode.contains("indirect case fixed(UInt)"), "'fixed32' should surface as 'UInt'")

        XCTAssertTrue(generatedCode.contains("if let converted = Int(exactly: value) {"), "'int32' should convert to the declared 'Int' type")
        XCTAssertTrue(generatedCode.contains("if let converted = UInt(exactly: value) {"), "Unsigned types should convert to the declared 'UInt' type, not 'Int'")
        XCTAssertFalse(generatedCode.contains("Int(exactly: value)!"), "Integer conversion should not force-unwrap, which traps on out-of-range values")

        XCTAssertTrue(
            generatedCode.contains("if let converted = AppPoint(proto: value) as AppPoint? {"),
            "A message type whose name merely contains 'int' (e.g. 'Point') must not be treated as an integer"
        )
    }
}
