import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// One enum per proto enum, sorted by name, with a `// MARK: - Enums`
/// section comment on the first.
func enumDeclarations(
    from enums: [ProtoEnum],
    swiftPrefix: String,
    includeProto: Bool,
    protoPrefix: String
) throws -> [DeclSyntax] {
    let sortedEnums = enums.sorted { $0.name < $1.name }
    return try sortedEnums.enumerated().map { index, protoEnum in
        var declaration = try `enum`(
            from: protoEnum,
            swiftPrefix: swiftPrefix,
            includeProto: includeProto,
            protoPrefix: protoPrefix
        )
        declaration.leadingTrivia = sectionTrivia(
            mark: index == 0 ? "Enums" : nil
        )
        return declaration
    }
}

/// The complete enum for one proto enum — wrapped in an extension of its
/// parent struct when nested.
///
/// Generates:
/// ```swift
/// extension AppTrifle { // nested enums only
///     public enum AppLayer: Int, CaseIterable, Hashable, Equatable, Sendable {
///         case sponge = 0
///         case custard = 1
///         internal init?(proto: ProtoTrifle.Layer) { // includeProto
///             self.init(rawValue: proto.rawValue)
///         }
///     }
/// }
/// ```
func `enum`(
    from protoEnum: ProtoEnum,
    swiftPrefix: String,
    includeProto: Bool,
    protoPrefix: String
) throws -> DeclSyntax {
    // allow_alias permits several proto cases with one value; a Swift enum
    // permits one case per raw value, so only the first name survives.
    var seenValues = Set<Int>()
    let cases = zip(
        stripCommonPrefix(from: protoEnum.cases).map(\.name),
        protoEnum.cases.map(\.value)
    ).filter { seenValues.insert($0.1).inserted }

    let declaration = try EnumDeclSyntax(
        "public enum \(raw: swiftPrefix)\(raw: protoEnum.name): Int, CaseIterable, Hashable, Equatable, Sendable"
    ) {
        for (caseName, caseValue) in cases {
            DeclSyntax("case \(raw: caseName) = \(raw: String(caseValue))")
        }
        if includeProto {
            try InitializerDeclSyntax(
                "internal init?(proto: \(raw: protoPrefix)\(raw: protoEnum.fullName))"
            ) {
                ExprSyntax("self.init(rawValue: proto.rawValue)")
            }
        }
    }

    if let parent = protoEnum.parentName {
        let wrapped = try ExtensionDeclSyntax(
            "extension \(raw: swiftPrefix)\(raw: parent)"
        ) {
            declaration
        }
        return DeclSyntax(wrapped)
    } else {
        return DeclSyntax(declaration)
    }
}
