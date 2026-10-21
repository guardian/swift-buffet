import Foundation

/// Represents a protocol buffer message.
struct ProtoMessage {
    /// The name of the message.
    let name: String
    /// The fields of the message.
    let fields: [ProtoField]
    /// The name of the parent message, if nested.
    let parentName: String?
    /// The `oneof` blocks declared directly within the message. A oneof's member
    /// fields are mutually exclusive, so they're represented separately from
    /// `fields` and generated as a single enum rather than independent optional
    /// properties.
    var oneofs: [ProtoOneof] = []

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
    /// Indicates if the field has been marked as deprecated in the proto file.
    let isDeprecated: Bool

    /// The case-corrected name of the field, converted to camelCase.
    var caseCorrectName: String {
        caseCorrectIdentifier(name)
    }

    var caseCorrectProtoName: String {
        if name == "description" {
            return "description_p"
        }
        return caseCorrectIdentifier(name)
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

    /// Indicates if the field maps to a Swift integer type (`Int`/`UInt`).
    var isIntegerType: Bool {
        if isMap {
            return false
        } else {
            return integerProtoTypes.contains(type)
        }
    }
}

/// Represents a `oneof` block within a protocol buffer message. A oneof's member
/// fields are mutually exclusive — at most one can be set at a time — so unlike
/// regular fields, they're generated as a single Swift enum with one case per
/// member, rather than as independent optional properties.
struct ProtoOneof {
    /// The name of the oneof block (e.g. `content`).
    let name: String
    /// The member fields declared inside the oneof block.
    let fields: [ProtoField]

    /// The case-corrected name of the oneof, converted to camelCase.
    var caseCorrectName: String {
        caseCorrectIdentifier(name)
    }

    /// The case-corrected name used to access the oneof's generated proto property.
    var caseCorrectProtoName: String {
        if name == "description" {
            return "description_p"
        }
        return caseCorrectIdentifier(name)
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
