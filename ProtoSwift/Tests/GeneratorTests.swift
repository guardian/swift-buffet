import XCTest
@testable import ProtoSwiftTool

final class GeneratorTests: XCTestCase {

    // Test `generateSwiftCode`
    func testGenerateSwiftCode() {
        let messages = [
            ProtoMessage(
                name: "TestMessage",
                fields: [
                    ProtoField(
                        name: "field1",
                        type: "int32",
                        comment: nil,
                        isOptional: true,
                        isRepeated: false,
                        isMap: false
                    ),
                    ProtoField(
                        name: "field2",
                        type: "string",
                        comment: nil,
                        isOptional: false,
                        isRepeated: true,
                        isMap: false
                    )
                ],
                parentName: nil
            )
        ]
        let enums = [
            ProtoEnum(
                name: "TestEnum",
                cases: [
                    ProtoEnumCase(
                        name: "ONE",
                        value: 1
                    ),
                    ProtoEnumCase(
                        name: "TWO",
                        value: 2
                    )
                ],
                parentName: nil
            )
        ]

        let output = generateSwiftCode(from: messages, enums: enums)

        XCTAssertTrue(
            output.contains(
                "public struct BlueprintTestMessage"
            ),
            "Generated code does not contain expected struct declaration for BlueprintTestMessage. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "public enum BlueprintTestEnum: Int, Codable"
            ),
            "Generated code does not contain expected enum declaration for BlueprintTestEnum. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "public let field1: Int32?"
            ),
            "Generated code does not contain expected property for field1. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "public let field2: [String]"
            ),
            "Generated code does not contain expected property for field2. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "case ONE = 1"
            ),
            "Generated code does not contain expected case for ONE in TestEnum. \(output)"
        )
        XCTAssertTrue(
            output.contains("case TWO = 2"),
            "Generated code does not contain expected case for TWO in TestEnum. \(output)"
        )
    }

    // Test `write` for enums
    func testWriteEnums() {
        var output = ""
        let enums = [
            ProtoEnum(
                name: "TestEnum",
                cases: [
                    ProtoEnumCase(
                        name: "ONE",
                        value: 1
                    ),
                    ProtoEnumCase(name: "TWO", value: 2)
                ],
                parentName: nil
            )
        ]

        write(enums, to: &output)

        XCTAssertTrue(
            output.contains(
                "public enum BlueprintTestEnum: Int, Codable"
            ),
            "Output does not contain expected enum declaration for BlueprintTestEnum. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "case ONE = 1"
            ),
            "Output does not contain expected case for ONE in TestEnum. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "case TWO = 2"
            ),
            "Output does not contain expected case for TWO in TestEnum. \(output)"
        )
    }

    // Test `writeEnumProtoInit`
    func testWriteEnumProtoInit() {
        var output = ""
        let protoEnum = ProtoEnum(
            name: "TestEnum",
            cases: [
                ProtoEnumCase(
                    name: "ONE",
                    value: 1
                ),
                ProtoEnumCase(
                    name: "TWO",
                    value: 2
                )
            ],
            parentName: nil
        )

        writeEnumProtoInit(for: protoEnum, to: &output)

        XCTAssertTrue(
            output.contains(
                "init?(_ proto: ProtoTestEnum)"
            ),
            "Output does not contain expected initializer for ProtoTestEnum. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "self.init(rawValue: proto.rawValue)"
            ),
            "Output does not contain expected rawValue initializer for ProtoTestEnum. \(output)"
        )
    }

    // Test `write` for messages
    func testWriteMessages() {
        var output = ""
        let messages = [
            ProtoMessage(
                name: "TestMessage",
                fields: [
                    ProtoField(
                        name: "field1",
                        type: "int32",
                        comment: nil,
                        isOptional: true,
                        isRepeated: false,
                        isMap: false
                    ),
                    ProtoField(
                        name: "field2",
                        type: "string",
                        comment: nil,
                        isOptional: false,
                        isRepeated: true,
                        isMap: false
                    )
                ],
                parentName: nil
            )
        ]

        write(messages, to: &output)

        XCTAssertTrue(
            output.contains(
                "public struct BlueprintTestMessage: Codable"
            ),
            "Output does not contain expected struct declaration for BlueprintTestMessage. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "public let field1: Int32?"
            ),
            "Output does not contain expected property for field1 in BlueprintTestMessage. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "public let field2: [String]"
            ),
            "Output does not contain expected property for field2 in BlueprintTestMessage. \(output)"
        )
    }

    // Test `writeProperties`
    func testWriteProperties() {
        var output = ""
        let message = ProtoMessage(
            name: "TestMessage",
            fields: [
                ProtoField(
                    name: "field1",
                    type: "int32",
                    comment: "Field 1 comment",
                    isOptional: true,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    name: "field2",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: true,
                    isMap: false
                )
            ],
            parentName: nil
        )

        let hasTimeInterval = writeProperties(for: message, to: &output)

        XCTAssertTrue(
            output.contains(
                "public let field1: Int32?"
            ),
            "Output does not contain expected property for field1 in TestMessage. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "public let field2: [String]"
            ),
            "Output does not contain expected property for field2 in TestMessage. \(output)"
        )
        XCTAssertFalse(
            hasTimeInterval,
            "hasTimeInterval should be false when no time interval fields are present. \(output)"
        )
    }

    // Test `addBasicInit`
    func testAddBasicInit() {
        var output = ""
        let message = ProtoMessage(
            name: "TestMessage",
            fields: [
                ProtoField(
                    name: "field1",
                    type: "int32",
                    comment: nil,
                    isOptional: true,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    name: "field2",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: true,
                    isMap: false
                )
            ],
            parentName: nil
        )

        writeBasicInit(for: message, to: &output)

        let hasInit = output.contains(
            "init(field1: Int32? = nil"
        )
        XCTAssertTrue(
            hasInit,
            "No initializer found for field1 in TestMessage. \(output)"
        )
        let hasInitSecondLine = output.contains(
            "field2: [String] = []"
        )
        XCTAssertTrue(
            hasInitSecondLine,
            "Initializer does not contain expected default value for field2 in TestMessage. \(output)"
        )
    }

    // Test `writeMessageProtoInit`
    func testWriteMessageProtoInit() {
        var output = ""
        let message = ProtoMessage(
            name: "TestMessage",
            fields: [
                ProtoField(
                    name: "field1",
                    type: "int32",
                    comment: nil,
                    isOptional: true,
                    isRepeated: false,
                    isMap: false
                ),
                ProtoField(
                    name: "field2",
                    type: "string",
                    comment: nil,
                    isOptional: false,
                    isRepeated: true,
                    isMap: false
                )
            ],
            parentName: nil
        )

        writeMessageProtoInit(for: message, to: &output)

        XCTAssertTrue(
            output.contains(
                "init?(_ proto: ProtoTestMessage)"
            ),
            "Output does not contain expected initializer for ProtoTestMessage. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "self.field1 = proto.field1"
            ),
            "Output does not contain expected field1 assignment from proto. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "self.field2 = proto.field2.compactMap { String($0) }"
            ),
            "Output does not contain expected field2 assignment from proto with compactMap. \(output)"
        )
    }

    // Test `writeDurationInit`
    func testWriteDurationInit() {
        var output = ""
        let message = ProtoMessage(
            name: "TestMessage",
            fields: [
                ProtoField(
                    name: "field1",
                    type: "google.protobuf.Duration",
                    comment: nil,
                    isOptional: false,
                    isRepeated: false,
                    isMap: false
                )
            ],
            parentName: nil
        )

        writeCodableInit(for: message, to: &output)

        XCTAssertTrue(
            output.contains(
                "let field1String = try container.decode(String.self, forKey: .field1)"
            ),
            "Output does not contain expected decode logic for field1String. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "self.field1 = TimeInterval(from: field1String) ?? 0"
            ),
            "Output does not contain expected TimeInterval conversion for field1. \(output)"
        )
    }

    // Test `writeTimeIntervalHelper`
    func testWriteTimeIntervalHelper() {
        var output = ""
        let messages = [
            ProtoMessage(
                name: "TestMessage",
                fields: [
                    ProtoField(
                        name: "field1",
                        type: "google.protobuf.Duration",
                        comment: nil,
                        isOptional: false,
                        isRepeated: false,
                        isMap: false
                    )
                ],
                parentName: nil
            )
        ]

        writeTimeIntervalHelper(messages, to: &output)

        XCTAssertTrue(
            output.contains(
                "// MARK: - TimeInterval Extension"
            ),
            "Output does not contain expected TimeInterval extension mark. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "extension TimeInterval {"
            ),
            "Output does not contain expected TimeInterval extension. \(output)"
        )
        XCTAssertTrue(
            output.contains(
                "init?(from string: String)"
            ),
            "Output does not contain expected initializer from durationString in TimeInterval extension. \(output)"
        )
    }
}
