import Testing
import Foundation
@testable import SwiftBuffet

@Suite struct UtilitiesTests {

    @Test func `Strip common prefix at underscore boundary`() {
        let cases = [
            ProtoEnumCase(name: "GENDER_UNKNOWN", value: 0),
            ProtoEnumCase(name: "GENDER_MALE", value: 1),
            ProtoEnumCase(name: "GENDER_FEMALE", value: 2)
        ]

        let stripped = stripCommonPrefix(from: cases)
        #expect(stripped.map(\.name) == ["unknown", "male", "female"])
        #expect(stripped.map(\.value) == [0, 1, 2])
    }

    @Test func `Strip common prefix ignores partial word prefix`() {
        let cases = [
            ProtoEnumCase(name: "MALE", value: 0),
            ProtoEnumCase(name: "MARRIED", value: 1)
        ]

        let stripped = stripCommonPrefix(from: cases)
        #expect(stripped.map(\.name) == ["male", "married"], "A shared 'MA' is not a word prefix and should not be stripped")
    }

    @Test func `Strip common prefix single case is untouched`() {
        let cases = [ProtoEnumCase(name: "UNKNOWN", value: 0)]

        let stripped = stripCommonPrefix(from: cases)
        #expect(stripped.map(\.name) == ["unknown"], "A single case should not be stripped to an empty name")
    }

    @Test func `Strip common prefix does not produce digit leading names`() {
        let cases = [
            ProtoEnumCase(name: "VERSION_1", value: 0),
            ProtoEnumCase(name: "VERSION_2", value: 1)
        ]

        let stripped = stripCommonPrefix(from: cases)
        #expect(stripped.map(\.name) == ["version1", "version2"], "Stripping must not leave identifiers starting with a digit")
    }

    @Test func `Snake to camel case conversion`() {
        #expect(snakeToCamelCase("is_active") == "isActive")
        #expect(snakeToCamelCase("name") == "name")
        #expect(snakeToCamelCase("HOME_URL") == "homeUrl")
    }
}
