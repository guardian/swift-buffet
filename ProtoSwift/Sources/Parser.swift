import Foundation
import RegexBuilder

func parseProtoFile(at path: URL) throws -> ([ProtoMessage], [ProtoEnum]) {
    let content = try String(contentsOf: path)
    var messages: [ProtoMessage] = []
    var enums: [ProtoEnum] = []

    func parseContent(_ content: String, inMessage: Bool = false) -> ([ProtoMessage], [ProtoEnum]) {
        var localMessages: [ProtoMessage] = []
        var localEnums: [ProtoEnum] = []

        let messagePattern = Regex {
            "message"
            OneOrMore(.whitespace)
            Capture {
                OneOrMore(.word)
            }
            ZeroOrMore(.whitespace)
            "{"
            Capture {
                ZeroOrMore(.reluctant) {
                    CharacterClass.any
                }
            }
            "}"
        }

        let enumPattern = Regex {
            "enum"
            OneOrMore(.whitespace)
            Capture {
                OneOrMore(.word)
            }
            ZeroOrMore(.whitespace)
            "{"
            Capture {
                ZeroOrMore(.reluctant) {
                    CharacterClass.any
                }
            }
            "}"
        }

        let messageMatches = content.matches(of: messagePattern)
        print("\(messageMatches.count) messages found")

        for match in messageMatches {
            let messageName = String(match.output.1)
            let messageBody = String(match.output.2)
            print("Matched message: \(messageName)")
            print("Message body: \(messageBody)")

            let (nestedMessages, nestedEnums) = parseContent(messageBody, inMessage: true)

            if inMessage {
                localMessages.append(contentsOf: nestedMessages)
                localEnums.append(contentsOf: nestedEnums)
            } else {
                let fields = parseFields(from: messageBody)
                if !nestedEnums.isEmpty {
                    enums.append(contentsOf: nestedEnums)
                }
                localMessages.append(ProtoMessage(name: messageName, fields: fields))
            }
        }

        let enumMatches = content.matches(of: enumPattern)
        print("\(enumMatches.count) enums found")

        for match in enumMatches {
            let enumName = String(match.output.1)
            let enumBody = String(match.output.2)
            print("Matched enum: \(enumName)")
            print("Enum body: \(enumBody)")

            let cases = parseEnumCases(from: enumBody)
            localEnums.append(ProtoEnum(name: enumName, cases: cases))
        }

        return (localMessages, localEnums)
    }

    func parseFields(from content: String) -> [ProtoField] {
        var fields: [ProtoField] = []

        let fieldPattern = Regex {
            ZeroOrMore(.whitespace)
            Optionally("optional")
            Optionally("repeated")
            ZeroOrMore(.whitespace)
            Capture {
                OneOrMore(.word)
            }
            OneOrMore(.whitespace)
            Capture {
                OneOrMore(.word)
            }
            ZeroOrMore(.whitespace)
            "="
            ZeroOrMore(.whitespace)
            OneOrMore(.digit)
            ZeroOrMore(.whitespace)
            ";"
        }

        let fieldMatches = content.matches(of: fieldPattern)
        print("Field matches count: \(fieldMatches.count)")

        for match in fieldMatches {
            let fieldType = String(match.output.1)
            let fieldName = String(match.output.2)
            print("Matched field type: \(fieldType), field name: \(fieldName)")
            fields.append(ProtoField(name: fieldName, type: fieldType))
        }

        return fields
    }

    func parseEnumCases(from content: String) -> [ProtoEnumCase] {
        var cases: [ProtoEnumCase] = []

        let enumCasePattern = Regex {
            ZeroOrMore(.whitespace)
            Capture {
                OneOrMore(.word)
            }
            ZeroOrMore(.whitespace)
            "="
            ZeroOrMore(.whitespace)
            Capture {
                OneOrMore(.digit)
            }
            ZeroOrMore(.whitespace)
            ";"
        }

        let caseMatches = content.matches(of: enumCasePattern)
        print("Enum case matches count: \(caseMatches.count)")

        for match in caseMatches {
            let caseName = String(match.output.1)
            let caseValue = Int(match.output.2)!
            print("Matched enum case name: \(caseName), value: \(caseValue)")
            cases.append(ProtoEnumCase(name: caseName, value: caseValue))
        }

        return cases
    }

    print("Starting parsing of messages")
    let (parsedMessages, parsedEnums) = parseContent(content)
    messages = parsedMessages
    enums = parsedEnums
    print("Finished parsing of messages and enums")

    return (messages, enums)
}
