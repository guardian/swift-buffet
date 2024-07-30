import Foundation

struct ProtoMessage {
    let name: String
    let fields: [ProtoField]  
    let parentName: String?

    var fullName: String {
        if let parentName {
            "\(parentName).\(name)"
        } else {
            name
        }
    }
}

struct ProtoField {
    let name: String
    let type: String
    let coment: String?
    let isOptional: Bool
    let isRepeated: Bool
    let isMap: Bool

    var caseCorrectName: String {
        snakeToCamelCase(name)
            .replacingOccurrences(of: "Url", with: "URL")
            .replacingOccurrences(of: "Id", with: "ID")
            .replacingOccurrences(of: "description", with: "description_p")
    }

    var caseCorrectedBaseType: String {
        mapProtoTypeToSwift(type, isMap: isMap)
    }

    var caseCorrectedType: String {
        let caseCorrectedType = caseCorrectedBaseType
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

    var isPrimitiveType: Bool {
        if isMap { 
            false
        } else {
            primitiveTypes.contains(type)
        }
    }
}

struct ProtoEnum {
    let name: String
    let cases: [ProtoEnumCase]
    let parentName: String?

    var fullName: String {
        if let parentName {
            "\(parentName).\(name)"
        } else {
            name
        }
    }
}

struct ProtoEnumCase {
    let name: String
    let value: Int
}
