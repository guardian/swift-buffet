import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// One struct per message, sorted by name, with a `// MARK: - Structs`
/// section comment on the first.
func structDeclarations(
    from messages: [ProtoMessage],
    swiftPrefix: String,
    includeProto: Bool,
    localIDMessages: [String]?,
    includeBackingData: Bool,
    protoPrefix: String
) throws -> [DeclSyntax] {
    let sortedMessages = messages.sorted { $0.name < $1.name }
    return try sortedMessages.enumerated().map { index, message in
        var declaration = DeclSyntax(
            try `struct`(
                from: message,
                swiftPrefix: swiftPrefix,
                includeProto: includeProto,
                includeLocalID: localIDMessages?.contains(message.name) ?? false,
                includeBackingData: includeBackingData,
                protoPrefix: protoPrefix
            )
        )
        declaration.leadingTrivia = sectionTrivia(
            mark: index == 0 ? "Structs" : nil
        )
        return declaration
    }
}

/// The complete struct for one message.
///
/// Generates:
/// ```swift
/// public struct AppFingerSandwich: Hashable, Equatable, Sendable {
///     public let filling: String
///     public let _localID = UUID()                       // includeLocalID
///     public private(set) var _backingData: Data?        // includeBackingData
///     public init(filling: String) { ... }
///     public init?(data: Data) { ... }                   // includeProto
///     internal init?(proto: ProtoFingerSandwich) { ... } // includeProto
/// }
/// ```
func `struct`(
    from message: ProtoMessage,
    swiftPrefix: String,
    includeProto: Bool,
    includeLocalID: Bool,
    includeBackingData: Bool,
    protoPrefix: String
) throws -> StructDeclSyntax {
    try StructDeclSyntax(
        "public struct \(raw: swiftPrefix)\(raw: message.name): Hashable, Equatable, Sendable"
    ) {
        for field in message.fields {
            property(for: field)
        }
        if includeLocalID {
            DeclSyntax("public let _localID = UUID()")
        }
        if includeBackingData {
            DeclSyntax("public private(set) var _backingData: Data?")
        }

        try memberwiseInitializer(for: message)

        if includeProto {
            try dataInitializer(
                for: message,
                includeBackingData: includeBackingData,
                protoPrefix: protoPrefix
            )
            try protoInitializer(for: message, protoPrefix: protoPrefix)
        }
    }
}

/// A stored property for a message field, preceded by its proto doc comment
/// (with the `/** */` markers stripped) and a deprecation notice when the
/// field carries `[deprecated = true]`.
func property(for field: ProtoField) -> DeclSyntax {
    var lines: [String] = []

    if let comment = field.comment {
        let commentLines = comment
            .replacingOccurrences(of: "/**", with: "")
            .replacingOccurrences(of: "*/", with: "")
            .replacingOccurrences(of: "*", with: "")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false }
        lines.append(contentsOf: commentLines.map { "// \($0)" })
    }
    if field.isDeprecated {
        lines.append("/// This property has been marked as **deprecated** in the proto file")
    }
    lines.append("public let \(field.caseCorrectName): \(field.caseCorrectedType)")

    return DeclSyntax("\(raw: lines.joined(separator: "\n"))")
}

/// `public init(name: String, age: Int) { self.name = name; ... }`
func memberwiseInitializer(for message: ProtoMessage) throws -> InitializerDeclSyntax {
    let parameters = message.fields
        .map { "\($0.caseCorrectName): \($0.caseCorrectedType)" }
        .joined(separator: ", ")

    return try InitializerDeclSyntax("public init(\(raw: parameters))") {
        for field in message.fields {
            ExprSyntax("self.\(raw: field.caseCorrectName) = \(raw: field.caseCorrectName)")
        }
    }
}

/// `init?(data: Data)` — decodes the SwiftProtobuf type from serialized
/// bytes and delegates to `init?(proto:)`.
///
/// Generates:
/// ```swift
/// public init?(data: Data) {
///     if let proto = try? ProtoFingerSandwich(serializedBytes: data) {
///         self.init(proto: proto)
///         self._backingData = data    // includeBackingData
///     } else {
///         return nil
///     }
/// }
/// ```
func dataInitializer(
    for message: ProtoMessage,
    includeBackingData: Bool,
    protoPrefix: String
) throws -> InitializerDeclSyntax {
    try InitializerDeclSyntax("public init?(data: Data)") {
        try IfExprSyntax(
            "if let proto = try? \(raw: protoPrefix)\(raw: message.fullName)(serializedBytes: data)"
        ) {
            ExprSyntax("self.init(proto: proto)")
            if includeBackingData {
                ExprSyntax("self._backingData = data")
            }
        } else: {
            StmtSyntax("return nil")
        }
    }
}

/// `init?(proto:)` — one conversion statement per field; the statement
/// shapes live in `Generator+ProtoConversion.swift`.
func protoInitializer(
    for message: ProtoMessage,
    protoPrefix: String
) throws -> InitializerDeclSyntax {
    try InitializerDeclSyntax(
        "internal init?(proto: \(raw: protoPrefix)\(raw: message.fullName))"
    ) {
        for field in message.fields {
            ExprSyntax("\(raw: conversionStatement(for: field))")
        }
    }
}
