import Testing
import Foundation
@testable import SwiftBuffet

@Suite struct GeneratorTests {
    @Test func `Generate simple message`() throws {
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

        let generatedCode = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: ["Person"],
            includeBackingData: false,
            with: "Proto"
        )

        #expect(
            generatedCode.contains("public struct AppPerson"),
            "The generated code should contain the 'AppPerson' struct"
        )
        #expect(
            generatedCode.contains("public let name: String"),
            "The generated code should contain the 'name' property"
        )
        #expect(
            generatedCode.contains("public let age: Int"),
            "The generated code should contain the 'age' property"
        )
        #expect(
            generatedCode.contains("public let isActive: Bool"),
            "The generated code should contain the 'isActive' property"
        )
        #expect(
            generatedCode.contains("public init("),
            "The generated code should contain the 'init' method"
        )
        #expect(
            generatedCode.contains("self.name = name"),
            "The generated code should initialize the 'name' property"
        )
        #expect(
            generatedCode.contains("self.age = age"),
            "The generated code should initialize the 'age' property"
        )
        #expect(
            generatedCode.contains("self.isActive = isActive"),
            "The generated code should initialize the 'isActive' property"
        )
        #expect(
            generatedCode.contains("internal init?(proto: ProtoPerson)"),
            "The generated code should contain the 'init?(proto:)' method"
        )
        #expect(
            generatedCode.contains("public let _localID = UUID()"),
            "The generated code should a `localID` property"
        )
    }

    @Test func `Generate nested message`() throws {
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

        let generatedCode = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        #expect(
            generatedCode.contains("public struct AppPerson"),
            "The generated code should contain the 'AppPerson' struct"
        )
        #expect(
            generatedCode.contains("public let name: String"),
            "The generated code should contain the 'name' property"
        )
        #expect(
            generatedCode.contains("public let age: Int"),
            "The generated code should contain the 'age' property"
        )
        #expect(
            generatedCode.contains("public let address: AppAddress"),
            "The generated code should contain the 'address' property"
        )
        #expect(
            generatedCode.contains("public struct AppAddress"),
            "The generated code should contain the 'AppAddress' struct"
        )
        #expect(
            generatedCode.contains("public let street: String"),
            "The generated code should contain the 'street' property"
        )
        #expect(
            generatedCode.contains("public let city: String"),
            "The generated code should contain the 'city' property"
        )
        #expect(
            generatedCode.contains("public let state: String"),
            "The generated code should contain the 'state' property"
        )
        #expect(
            generatedCode.contains("public init("),
            "The generated code should contain the 'init' method"
        )
        #expect(
            generatedCode.contains("internal init?(proto: ProtoPerson)"),
            "The generated code should contain the 'init?(proto:)' method for 'ProtoPerson'"
        )
        #expect(
            generatedCode.contains("internal init?(proto: ProtoAddress)"),
            "The generated code should contain the 'init?(proto:)' method for 'ProtoAddress'"
        )
    }

    @Test func `Generate nested enum and well known types`() throws {
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

        let generatedCode = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        #expect(
            generatedCode.contains("public struct AppPerson"),
            "The generated code should contain the 'AppPerson' struct"
        )
        #expect(
            generatedCode.contains("public let name: String"),
            "The generated code should contain the 'name' property"
        )
        #expect(
            generatedCode.contains("public let age: Int"),
            "The generated code should contain the 'age' property"
        )
        #expect(
            generatedCode.contains("public let isActive: Bool"),
            "The generated code should contain the 'isActive' property"
        )
        #expect(
            generatedCode.contains("public enum AppGender: Int"),
            "The generated code should contain the 'Gender' enum"
        )
        #expect(
            generatedCode.contains("case unknown = 0"),
            "The 'Gender' enum should contain the 'unknown' case"
        )
        #expect(
            generatedCode.contains("case male = 1"),
            "The 'Gender' enum should contain the 'male' case"
        )
        #expect(
            generatedCode.contains("case female = 2"),
            "The 'Gender' enum should contain the 'female' case"
        )
        #expect(
            generatedCode.contains("public let gender: AppGender"),
            "The generated code should contain the 'gender' property"
        )
        #expect(
            generatedCode.contains("public let lastActive: TimeInterval"),
            "The generated code should contain the 'lastActive' property"
        )
        #expect(
            generatedCode.contains("public let createdAt: Date"),
            "The generated code should contain the 'createdAt' property"
        )
        #expect(
            generatedCode.contains("internal init?(proto: ProtoPerson)"),
            "The generated code should contain the 'init?(proto:)' method"
        )
    }

    @Test func `Integer conversion uses matching swift type`() throws {
        let message = ProtoMessage(
            name: "Stats",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "view_count",
                    type: "uint64",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "rank",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let generated = try generateSwiftCode(
            from: [message],
            enums: [],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        #expect(
            generated.contains("!") == false,
            "Integer conversion must not force-unwrap"
        )
        #expect(
            generated.contains("Int(exactly:") == false
        )
        #expect(
            generated.contains("self.viewCount = UInt(proto.viewCount)"),
            "uint64 must convert via its own Swift type, not Int"
        )
        #expect(
            generated.contains("self.rank = Int(proto.rank)")
        )
    }

    @Test func `Message type name containing int is not treated as integer`() throws {
        let message = ProtoMessage(
            name: "Job",
            fields: [
                ProtoField(
                    swiftPrefix: "App",
                    name: "print_job",
                    type: "PrintJob",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false,
                    isDeprecated: false
                )
            ],
            parentName: nil
        )

        let generated = try generateSwiftCode(
            from: [message],
            enums: [],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        #expect(
            generated.contains("Int(exactly:") == false,
            "A message type whose name contains 'int' must not take the integer branch"
        )
        #expect(
            generated.contains("if let printJob = AppPrintJob(proto: proto.printJob)")
        )
    }

    @Test func `Nested message proto init uses full proto type name`() throws {
        let inner = ProtoMessage(
            name: "Inner",
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
            ],
            parentPath: ["Outer", "Middle"]
        )

        let generated = try generateSwiftCode(
            from: [inner],
            enums: [],
            with: "App",
            includeProto: true,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )

        #expect(
            generated.contains("internal init?(proto: ProtoOuter.Middle.Inner)"),
            "Nested messages must reference the fully-qualified SwiftProtobuf type"
        )
        #expect(
            generated.contains("try? ProtoOuter.Middle.Inner(serializedBytes: data)")
        )
        #expect(
            generated.contains("ProtoInner") == false
        )
    }

    @Test func `Duplicate swift type names throw`() {
        let field = ProtoField(
            swiftPrefix: "App",
            name: "value",
            type: "string",
            comment: nil,
            isOptional: false,
            isRepeated: false,
            isMap: false,
            isDeprecated: false
        )
        let first = ProtoMessage(name: "Item", fields: [field], parentPath: ["Order"])
        let second = ProtoMessage(name: "Item", fields: [field], parentPath: ["Invoice"])

        let error = #expect(throws: DuplicateTypeNameError.self) {
            try generateSwiftCode(
                from: [first, second],
                enums: [],
                with: "App",
                includeProto: false,
                includeLocalIDFor: nil,
                includeBackingData: false,
                with: "Proto"
            )
        }
        
        let description = String(describing: error)
        #expect(description.contains("AppItem"))
        #expect(description.contains("Order.Item"))
        #expect(description.contains("Invoice.Item"))
    }

    @Test func `Message and top level enum name collision throws`() {
        let nestedMessage = ProtoMessage(
            name: "Status",
            fields: [],
            parentPath: ["Person"]
        )
        let topLevelEnum = ProtoEnum(
            name: "Status",
            cases: [ProtoEnumCase(name: "S_UNKNOWN", value: 0)],
            parentPath: []
        )

        let error = #expect(throws: DuplicateTypeNameError.self) {
            try generateSwiftCode(
                from: [nestedMessage],
                enums: [topLevelEnum],
                with: "App",
                includeProto: false,
                includeLocalIDFor: nil,
                includeBackingData: false,
                with: "Proto"
            )
        }
        #expect(String(describing: error).contains("AppStatus"))
    }

    @Test func `Nested enum does not collide with top level type`() throws {
        // A nested enum lives inside an extension of its parent, so it
        // occupies a different namespace than top-level types.
        let message = ProtoMessage(name: "Status", fields: [], parentPath: [])
        let nestedEnum = ProtoEnum(
            name: "Status",
            cases: [ProtoEnumCase(name: "S_UNKNOWN", value: 0)],
            parentPath: ["Person"]
        )
        let parent = ProtoMessage(name: "Person", fields: [], parentPath: [])

        _ = try generateSwiftCode(
            from: [message, parent],
            enums: [nestedEnum],
            with: "App",
            includeProto: false,
            includeLocalIDFor: nil,
            includeBackingData: false,
            with: "Proto"
        )
    }

    @Test func `Local IDs`() throws {
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

        let generatedCode = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: ["Person"],
            includeBackingData: false,
            with: "Proto"
        )

        func containsExactlyOneInstance(
            of substring: String,
            in string: String
        ) -> Bool {
            let components = string.components(separatedBy: substring)
            return components.count == 2
        }

        #expect(
            containsExactlyOneInstance(
                of: "public let _localID = UUID()",
                in: generatedCode
            )
        )
    }
}
