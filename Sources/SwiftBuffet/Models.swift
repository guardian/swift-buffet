import Foundation

/// Represents a protocol buffer message.
struct ProtoMessage {
    /// The name of the message.
    let name: String
    /// The fields of the message.
    let fields: [ProtoField]
    /// The names of the enclosing messages, outermost first.
    let parentPath: [String]

    init(name: String, fields: [ProtoField], parentPath: [String]) {
        self.name = name
        self.fields = fields
        self.parentPath = parentPath
    }

    /// Convenience for a message with at most one enclosing message.
    init(name: String, fields: [ProtoField], parentName: String?) {
        self.init(
            name: name,
            fields: fields,
            parentPath: parentName.map { [$0] } ?? []
        )
    }

    /// The name of the immediately enclosing message, if nested.
    var parentName: String? {
        parentPath.last
    }

    /// The fully-qualified dotted name, matching SwiftProtobuf's nesting.
    var fullName: String {
        (parentPath + [name]).joined(separator: ".")
    }
}

/// Represents a field within a protocol buffer message.
struct ProtoField {
    /// The prefix applied to generated Swift type names. Stored per field so
    /// the type-mapping properties below can prefix message and enum
    /// references without further context.
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

    /// The generated Swift property name: camelCase, with `Url`/`Id` from
    /// `_url`/`_id` field names capitalized to `URL`/`ID`.
    var caseCorrectName: String {
        var newName = snakeToCamelCase(name)
        if name.contains("_url") {
            newName = newName.replacingOccurrences(of: "Url", with: "URL")
        }
        if name.contains("_id") {
            newName = newName.replacingOccurrences(of: "Id", with: "ID")
        }
        return newName
    }

    /// The property name as exposed on the SwiftProtobuf-generated type.
    /// Usually identical to `caseCorrectName`, but SwiftProtobuf escapes
    /// names that collide with its own API (`description` → `description_p`).
    var caseCorrectProtoName: String {
        var newName = caseCorrectName
        if name == "description" {
            newName = "description_p"
        }
        return newName
    }

    /// The base type of the field, mapped to Swift types.
    var caseCorrectedBaseType: String {
        if isMap {
            // Map fields store their type as "<key, value>" (see
            // ProtoParser.parseField); unpack and map each side.
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

    /// Whether this string field is generated as `URL` instead of `String`,
    /// based on its name ending in URL/URI (URLS/URIS when repeated).
    var isURL: Bool {
        guard type == "string" else {
            return false
        }
        let upperName = caseCorrectName.uppercased()
        let suffixes = isRepeated ? ["URLS", "URIS"] : ["URL", "URI"]
        return suffixes.contains(where: upperName.hasSuffix)
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

    /// Indicates if the field is a proto integer type (signed or unsigned).
    var isIntType: Bool {
        signedIntTypes.contains(type) || unsignedIntTypes.contains(type)
    }
}

/// Represents a protocol buffer enum.
struct ProtoEnum {
    /// The name of the enum.
    let name: String
    /// The cases of the enum.
    let cases: [ProtoEnumCase]
    /// The names of the enclosing messages, outermost first.
    let parentPath: [String]

    init(name: String, cases: [ProtoEnumCase], parentPath: [String]) {
        self.name = name
        self.cases = cases
        self.parentPath = parentPath
    }

    /// Convenience for an enum with at most one enclosing message.
    init(name: String, cases: [ProtoEnumCase], parentName: String?) {
        self.init(
            name: name,
            cases: cases,
            parentPath: parentName.map { [$0] } ?? []
        )
    }

    /// The name of the immediately enclosing message, if nested.
    var parentName: String? {
        parentPath.last
    }

    /// The fully-qualified dotted name, matching SwiftProtobuf's nesting.
    var fullName: String {
        (parentPath + [name]).joined(separator: ".")
    }
}

/// Represents a case within a protocol buffer enum.
struct ProtoEnumCase {
    /// The name of the enum case.
    let name: String
    /// The value of the enum case.
    let value: Int
}
