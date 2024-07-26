import Foundation

struct ProtoMessage {
    let name: String
    let fields: [ProtoField]
}

struct ProtoField {
    let name: String
    let type: String
    let isOptional: Bool
    let isRepeated: Bool
    let isMap: Bool

    var caseCorrectName: String {
        snakeToCamelCase(name)
    }

    var caseCorrectedType: String {
        let caseCorrectedType = mapProtoTypeToSwift(type, isMap: isMap)
        if isMap {
            // Handle map fields
            let mapTypes = type
                .dropFirst()
                .dropLast()
                .split(separator: ",")
            let keyType = mapProtoTypeToSwift(String(mapTypes[0]).trimmingCharacters(in: .whitespaces))
            let valueType = mapProtoTypeToSwift(String(mapTypes[1]).trimmingCharacters(in: .whitespaces))
            return "[\(keyType): \(valueType)]?"
        } else if isRepeated {
            return "[\(caseCorrectedType)]?"
        } else if isOptional {
            return "\(caseCorrectedType)?"
        } else {
            return "\(caseCorrectedType)"
        }
    }
}

struct ProtoEnum {
    let name: String
    let cases: [ProtoEnumCase]
}

struct ProtoEnumCase {
    let name: String
    let value: Int
}
