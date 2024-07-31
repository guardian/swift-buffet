import Foundation

/// Represents a protocol buffer message.
struct ProtoMessage {
    /// The name of the message.
    let name: String
    /// The fields of the message.
    let fields: [ProtoField]
    /// The name of the parent message, if nested.
    let parentName: String?

    /// The full name of the message, including parent name if nested.
    var fullName: String {
        if let parentName {
            return "\(parentName).\(name)"
        } else {
            return name
        }
    }
}

/// Represents a field within a protocol buffer message.
struct ProtoField {
    /// The name of the field.
    let name: String
    /// The type of the field.
    let type: String
    /// An optional comment describing the field.
    let comment: String?
    /// Indicates if the field is optional.
    let isOptional: Bool
    /// Indicates if the field is a repeated field.
    let isRepeated: Bool
    /// Indicates if the field is a map type.
    let isMap: Bool

    /// The case-corrected name of the field, converted to camelCase.
    var caseCorrectName: String {
        snakeToCamelCase(name)
            .replacingOccurrences(of: "Url", with: "URL")
            .replacingOccurrences(of: "Id", with: "ID")
            .replacingOccurrences(of: "description", with: "description_p")
    }

    /// The base type of the field, mapped to Swift types.
    var caseCorrectedBaseType: String {
        mapProtoTypeToSwift(type, isMap: isMap)
    }

    /// The fully case-corrected type of the field, including optional and repeated modifiers.
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
            return "[\(keyType): \(valueType)]"
        } else if isRepeated {
            return "[\(caseCorrectedType)]"
        } else if isOptional {
            return "\(caseCorrectedType)?"
        } else {
            return "\(caseCorrectedType)"
        }
    }

    /// Indicates if the field is of a primitive type.
    var isPrimitiveType: Bool {
        if isMap {
            return false
        } else {
            return primitiveTypes.contains(type)
        }
    }
}

/// Represents a protocol buffer enum.
struct ProtoEnum {
    /// The name of the enum.
    let name: String
    /// The cases of the enum.
    let cases: [ProtoEnumCase]
    /// The name of the parent message, if any.
    let parentName: String?

    /// The full name of the enum, including parent name if present.
    var fullName: String {
        if let parentName {
            return "\(parentName).\(name)"
        } else {
            return name
        }
    }
}

/// Represents a case within a protocol buffer enum.
struct ProtoEnumCase {
    /// The name of the enum case.
    let name: String
    /// The value of the enum case.
    let value: Int
}
