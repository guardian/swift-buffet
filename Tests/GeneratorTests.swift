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
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "age",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "is_active",
                    type: "bool",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
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
            includeLocalID: false,
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
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "city",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "state",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
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
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "age",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "address",
                    type: "Address",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
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
            includeLocalID: false,
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
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "age",
                    type: "int32",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "is_active",
                    type: "bool",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "gender",
                    type: "Gender",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "last_active",
                    type: "google.protobuf.Duration",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    swiftPrefix: "App",
                    name: "created_at",
                    type: "google.protobuf.Timestamp",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
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
            includeLocalID: false,
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
}
