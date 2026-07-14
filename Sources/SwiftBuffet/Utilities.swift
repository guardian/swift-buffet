import Foundation

/// Maps a protocol buffer type to its corresponding Swift type.
///
/// Scalars and the supported well-known types map to standard library types.
/// Anything else is assumed to be a message or enum reference and is prefixed
/// with `swiftPrefix` to form the generated Swift type name.
///
/// - Parameters:
///   - type: The protocol buffer type as written in the proto source.
///   - swiftPrefix: The prefix applied to generated Swift type names.
/// - Returns: The corresponding Swift type as a string.
func swiftType(from type: String, with swiftPrefix: String) -> String {
    switch type {
    case "double": return "Double"
    case "float": return "Float"
    case "int32", "sint32", "sfixed32": return "Int"
    case "int64", "sint64", "sfixed64": return "Int"
    case "uint32", "fixed32": return "UInt"
    case "uint64", "fixed64": return "UInt"
    case "bool": return "Bool"
    case "string": return "String"
    case "bytes": return "Data"
    case "google.protobuf.Timestamp": return "Date"
    case "google.protobuf.Duration": return "TimeInterval"
    default: return "\(swiftPrefix)\(type)" // Handle nested messages and enums if needed
    }
}


/// Proto types whose values pass straight through in `init?(proto:)` with no
/// conversion. Deliberately excludes `int32`/`int64`/`uint32`/`uint64` and
/// friends — those need an `Int`/`UInt` conversion and are classified by
/// `signedIntTypes`/`unsignedIntTypes` instead.
let primitiveTypes = [
   "double",
   "float",
   "sint32",
   "sfixed32",
   "sint64",
   "sfixed64",
   "fixed32",
   "fixed64",
   "bool",
   "string",
   "bytes"
]

/// Proto integer types that map to `Int`.
let signedIntTypes = [
    "int32",
    "sint32",
    "sfixed32",
    "int64",
    "sint64",
    "sfixed64"
]

/// Proto integer types that map to `UInt`.
let unsignedIntTypes = [
    "uint32",
    "fixed32",
    "uint64",
    "fixed64"
]

/// Converts a snake_case string to camelCase.
///
/// - Parameter string: The snake_case string to be converted.
/// - Returns: The camelCase version of the input string.
func snakeToCamelCase(_ string: String) -> String {
    let components = string.split(separator: "_")
    guard let first = components.first else {
        return string.lowercased()
    }
    return components
        .dropFirst()
        .reduce(String(first).lowercased()) {
            $0 + $1.capitalized
        }
}

/// Strips the common prefix from a list of enum cases and converts them to camelCase.
///
/// The prefix is only stripped at an underscore boundary, and only when there is
/// more than one case (a single case is its own common prefix). A case is left
/// unstripped when stripping would empty it or leave it starting with a digit.
///
/// - Parameter cases: An array of `ProtoEnumCase` to be processed.
/// - Returns: An array of `ProtoEnumCase` with the common prefix removed and names converted to camelCase.
func stripCommonPrefix(from cases: [ProtoEnumCase]) -> [ProtoEnumCase] {
    var prefix = ""
    if cases.count > 1 {
        let commonPrefix = findCommonPrefix(in: cases.map { $0.name }) ?? ""
        // Trim back to the last underscore so we only strip whole words,
        // e.g. MALE/MARRIED share "MA" but no word prefix.
        if let lastUnderscore = commonPrefix.lastIndex(of: "_") {
            prefix = String(commonPrefix[...lastUnderscore])
        }
    }
    return cases.map { enumCase in
        var strippedName = String(enumCase.name.dropFirst(prefix.count))
        if strippedName.isEmpty || strippedName.first?.isNumber == true {
            strippedName = enumCase.name
        }
        return ProtoEnumCase(
            name: snakeToCamelCase(strippedName),
            value: enumCase.value
        )
    }
}

/// Finds the common prefix in an array of strings.
///
/// - Parameter strings: An array of strings to find the common prefix in.
/// - Returns: The common prefix as a string, or `nil` if there is no common prefix.
func findCommonPrefix(in strings: [String]) -> String? {
    guard var prefix = strings.first else {
        return nil
    }
    for string in strings {
        while !string.hasPrefix(prefix) {
            prefix = String(prefix.dropLast())
            if prefix.isEmpty {
                return nil
            }
        }
    }
    return prefix
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
