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
    let swiftPrefix: String

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
        var newName = snakeToCamelCase(name)
        if name.contains("_url") {
            newName = newName.replacingOccurrences(of: "Url", with: "URL")
        }
//        if name.contains("_uri") {
//            newName = newName.replacingOccurrences(of: "Uri", with: "URL")
//        }
        if name.contains("_id") {
            newName = newName.replacingOccurrences(of: "Id", with: "ID")
        }
        return newName
    }

    var caseCorrectProtoName: String {
        var newName = snakeToCamelCase(name)
        if name.contains("_url") {
            newName = newName.replacingOccurrences(of: "Url", with: "URL")
        }
//        if name.contains("_uri") {
//            newName.replacingOccurrences(of: "Uri", with: "URL")
//        }
        if name.contains("_id") {
            newName = newName.replacingOccurrences(of: "Id", with: "ID")
        }

        if name == "description" {
            newName = "description_p"
        }
        return newName
    }

    /// The base type of the field, mapped to Swift types.
    var caseCorrectedBaseType: String {
        if isMap { // Skip map types since they are handled separately
            let mapTypes = type
                .dropFirst()
                .dropLast()
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            let keyType = swiftType(from: String(mapTypes[0]), with: swiftPrefix)
            let valueType = swiftType(from: String(mapTypes[1]), with: swiftPrefix)
            return "[\(keyType): \(valueType)]"
        } else if isURL {
            return "URL"
        } else {
            return swiftType(from: type, with: swiftPrefix)
        }
    }

    var isURL: Bool {
        (caseCorrectName.uppercased().hasSuffix("URL")
         || caseCorrectName.uppercased().hasSuffix("URI"))
        && type == "string"
    }

    /// The fully case-corrected type of the field, including optional and repeated modifiers.
    var caseCorrectedType: String {
        let caseCorrectedType = caseCorrectedBaseType
        if isMap { // map types are handled by caseCorrectedBaseType
            return caseCorrectedType
        } else if isRepeated {
            return "[\(caseCorrectedType)]"
        } else if type == "bool" {
            return "Bool" // Bools should never be optional
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
