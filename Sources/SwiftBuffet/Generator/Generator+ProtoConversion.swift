import Foundation

/// How one field converts from its SwiftProtobuf representation inside
/// `init?(proto:)`. Classification is separate from rendering so the full
/// taxonomy is visible in one place.
enum ProtoConversion {
    /// `self.x = proto.x.compactMap { ... }`
    case repeated
    /// `self.x = proto.x.reduce(into: [K: V]()) { ... }`
    case map
    /// `self.x = proto.x.timeInterval` (google.protobuf.Duration)
    case timeInterval
    /// `self.x = proto.x.date` (google.protobuf.Timestamp)
    case date
    /// `self.x = URL(string: proto.x)`, failable when the field is required
    case url
    /// `self.x = Int(proto.x)` / `UInt(proto.x)`
    case integer
    /// `self.x = proto.x` — no conversion needed
    case passthrough
    /// `self.x = AppOther(proto: proto.x)` — chains through the other
    /// type's own `init?(proto:)`, failable when the field is required
    case message

    /// Note: order matters and mirrors the legacy generator — `repeated`
    /// and `map` first (they wrap the other conversions), well-known types
    /// before the URL name heuristic, integers before the general
    /// passthrough set.
    init(for field: ProtoField) {
        if field.isRepeated {
            self = .repeated
        } else if field.isMap {
            self = .map
        } else if field.caseCorrectedBaseType == "TimeInterval" {
            self = .timeInterval
        } else if field.caseCorrectedBaseType == "Date" {
            self = .date
        } else if field.isURL {
            self = .url
        } else if field.isIntType {
            self = .integer
        } else if field.isPrimitiveType {
            self = .passthrough
        } else {
            self = .message
        }
    }
}

/// The statement assigning one field inside `init?(proto:)`.
///
/// Statements are rendered as plain-text templates rather than nested syntax
/// builders — for this branchy code the templates read better, and every
/// statement still passes through the parser (and the whole-file re-parse
/// gate) before reaching the output.
func conversionStatement(for field: ProtoField) -> String {
    let name = field.caseCorrectName
    let protoName = field.caseCorrectProtoName
    let baseType = field.caseCorrectedBaseType

    var statement: String
    switch ProtoConversion(for: field) {
    case .repeated:
        let transform = if field.isURL {
            "URL(string: $0)"
        } else if field.isPrimitiveType || field.isIntType {
            "\(baseType)($0)"
        } else {
            "\(baseType)(proto: $0)"
        }
        statement = "self.\(name) = proto.\(protoName).compactMap { \(transform) }"

    case .map:
        statement = "self.\(name) = proto.\(protoName).reduce(into: \(field.caseCorrectedType)()) { result, element in result[element.key] = element.value }"

    case .timeInterval:
        statement = "self.\(name) = proto.\(protoName).timeInterval"

    case .date:
        statement = "self.\(name) = proto.\(protoName).date"

    case .url:
        statement = field.isOptional
            ? "self.\(name) = URL(string: proto.\(protoName))"
            : requiredAssignment(of: name, to: "URL(string: proto.\(protoName))")

    case .integer:
        statement = "self.\(name) = \(baseType)(proto.\(protoName))"

    case .passthrough:
        statement = "self.\(name) = proto.\(protoName)"

    case .message:
        statement = field.isOptional
            ? "self.\(name) = \(baseType)(proto: proto.\(protoName))"
            : requiredAssignment(of: name, to: "\(baseType)(proto: proto.\(protoName))")
    }

    if field.isOptional {
        let defaultValue = if field.isRepeated {
            "[]"
        } else if field.type == "bool" {
            "false"
        } else {
            "nil"
        }
        statement = """
        if proto.has\(protoName.capitalizingFirstLetter()) {
            \(indentedOneLevel(statement))
        } else {
            self.\(name) = \(defaultValue)
        }
        """
    }

    return statement
}

/// An `if let` binding that assigns the unwrapped value or fails the
/// initializer — the shape shared by every conversion that can fail.
func requiredAssignment(of name: String, to expression: String) -> String {
    """
    if let \(name) = \(expression) {
        self.\(name) = \(name)
    } else {
        return nil
    }
    """
}

/// Re-indents an already-rendered multi-line statement one level deeper for
/// nesting inside the `has`-check wrapper. BasicFormat respects existing
/// trivia, so multi-line templates must carry their own indentation.
private func indentedOneLevel(_ code: String) -> String {
    code.split(separator: "\n").joined(separator: "\n    ")
}
