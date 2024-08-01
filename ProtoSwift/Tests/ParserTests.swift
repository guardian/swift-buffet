import XCTest
@testable import ProtoSwiftTool

final class ParserTests: XCTestCase {

    // Test `mapProtoTypeToSwift`
    func testMapProtoTypeToSwift() {
        XCTAssertEqual(mapProtoTypeToSwift("double"), "Double")
        XCTAssertEqual(mapProtoTypeToSwift("string"), "String")
        XCTAssertEqual(mapProtoTypeToSwift("google.protobuf.Timestamp"), "Date")
        XCTAssertEqual(mapProtoTypeToSwift("unknownType"), "BlueprintunknownType")
    }

    // Test `snakeToCamelCase`
    func testSnakeToCamelCase() {
        XCTAssertEqual(snakeToCamelCase("snake_case_string"), "snakeCaseString")
        XCTAssertEqual(snakeToCamelCase("another_example_here"), "anotherExampleHere")
        XCTAssertEqual(snakeToCamelCase("simple"), "simple")
    }

    // Test `stripCommonPrefix`
    func testStripCommonPrefix() {
        let cases = [
            ProtoEnumCase(name: "TEST_ENUM_ONE", value: 1),
            ProtoEnumCase(name: "TEST_ENUM_TWO", value: 2),
        ]
        let stripped = stripCommonPrefix(from: cases)
        XCTAssertEqual(stripped.map { $0.name }, ["one", "two"])
    }

    // Test `findCommonPrefix`
    func testFindCommonPrefix() {
        XCTAssertEqual(findCommonPrefix(in: ["prefixOne", "prefixTwo"]), "prefix")
        XCTAssertNil(findCommonPrefix(in: ["one", "two"]))
    }

    // Test `parseMessageFields`
    func testParseMessageFields() {
        let content = """
        optional int32 field1 = 1;
        repeated string field2 = 2;
        """
        let fields = parseMessageFields(from: content)
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(fields[0].name, "field1")
        XCTAssertEqual(fields[0].type, "int32")
        XCTAssertTrue(fields[0].isOptional)
        XCTAssertFalse(fields[0].isRepeated)

        XCTAssertEqual(fields[1].name, "field2")
        XCTAssertEqual(fields[1].type, "string")
        XCTAssertFalse(fields[1].isOptional)
        XCTAssertTrue(fields[1].isRepeated)
    }

    // Test `parseEnumCases`
    func testParseEnumCases() {
        let content = """
        TEST_ENUM_ONE = 1;
        TEST_ENUM_TWO = 2;
        """
        let cases = parseEnumCases(from: content)
        XCTAssertEqual(cases.count, 2)
        XCTAssertEqual(cases[0].name, "TEST_ENUM_ONE")
        XCTAssertEqual(cases[0].value, 1)
        XCTAssertEqual(cases[1].name, "TEST_ENUM_TWO")
        XCTAssertEqual(cases[1].value, 2)
    }

    // Test `processEnum`
    func testProcessEnum() {
        var body = """
        TEST_ENUM_ONE = 1;
        TEST_ENUM_TWO = 2;
        """
        var localMessages = [ProtoMessage]()
        var localEnums = [ProtoEnum]()
        processEnum("TestEnum", &body, &localMessages, &localEnums, nil)

        XCTAssertEqual(localEnums.count, 1)
        XCTAssertEqual(localEnums[0].name, "TestEnum")
        XCTAssertEqual(localEnums[0].cases.count, 2)
        XCTAssertEqual(localEnums[0].cases[0].name, "TEST_ENUM_ONE")
        XCTAssertEqual(localEnums[0].cases[0].value, 1)
        XCTAssertEqual(localEnums[0].cases[1].name, "TEST_ENUM_TWO")
        XCTAssertEqual(localEnums[0].cases[1].value, 2)
    }

    // Test `processMessage`
    func testProcessMessage() {
        var body = """
        optional int32 field1 = 1;
        repeated string field2 = 2;
        """
        var localMessages = [ProtoMessage]()
        var localEnums = [ProtoEnum]()
        processMessage("TestMessage", &body, &localMessages, &localEnums, nil)

        XCTAssertEqual(localMessages.count, 1)
        XCTAssertEqual(localMessages[0].name, "TestMessage")
        XCTAssertEqual(localMessages[0].fields.count, 2)
        XCTAssertEqual(localMessages[0].fields[0].name, "field1")
        XCTAssertEqual(localMessages[0].fields[1].name, "field2")
    }

    // Test `generateSwiftCode`
    func testGenerateSwiftCode() {
        let messages = [
            ProtoMessage(name: "TestMessage", fields: [
                ProtoField(name: "field1", type: "int32", comment: nil, isOptional: true, isRepeated: false, isMap: false),
                ProtoField(name: "field2", type: "string", comment: nil, isOptional: false, isRepeated: true, isMap: false)
            ], parentName: nil)
        ]
        let enums = [
            ProtoEnum(name: "TestEnum", cases: [
                ProtoEnumCase(name: "ONE", value: 1),
                ProtoEnumCase(name: "TWO", value: 2)
            ], parentName: nil)
        ]
        let generatedCode = generateSwiftCode(from: messages, enums: enums)
        XCTAssertTrue(generatedCode.contains("public struct BlueprintTestMessage"))
        XCTAssertTrue(generatedCode.contains("public enum BlueprintTestEnum: Int, Codable"))
    }
}
