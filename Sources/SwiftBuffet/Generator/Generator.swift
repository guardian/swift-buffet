import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

/// Generates a complete Swift source file from parsed proto messages and enums.
///
/// - Parameters:
///   - messages: The messages to generate structs for.
///   - enums: The enums to generate, nested ones wrapped in parent extensions.
///   - swiftPrefix: Prefix applied to every generated Swift type name.
///   - includeProto: When `true`, adds `init?(proto:)` and `init?(data:)`
///     bridging from SwiftProtobuf-generated types.
///   - localIDMessages: Messages that gain a `_localID = UUID()` property.
///   - includeBackingData: When `true`, structs keep the serialized bytes
///     they were decoded from in a `_backingData` property.
///   - protoPrefix: The Swift name prefix of the SwiftProtobuf-generated
///     types referenced by the bridging initializers.
/// - Returns: Formatted Swift source.
/// - Throws: `DuplicateTypeNameError` when two types would flatten to the
///   same Swift name; `GenerationError` if the output fails to re-parse.
func generateSwiftCode(
    from messages: [ProtoMessage],
    enums: [ProtoEnum],
    with swiftPrefix: String,
    includeProto: Bool,
    includeLocalIDFor localIDMessages: [String]?,
    includeBackingData: Bool,
    with protoPrefix: String
) throws -> String {
    try checkForTypeNameCollisions(
        messages: messages,
        enums: enums,
        swiftPrefix: swiftPrefix
    )

    var declarations = [DeclSyntax]()
    
    declarations += [DeclSyntax("import Foundation")]
    
    declarations += try structDeclarations(
        from: messages,
        swiftPrefix: swiftPrefix,
        includeProto: includeProto,
        localIDMessages: localIDMessages,
        includeBackingData: includeBackingData,
        protoPrefix: protoPrefix
    )
    
    declarations += try enumDeclarations(
        from: enums,
        swiftPrefix: swiftPrefix,
        includeProto: includeProto,
        protoPrefix: protoPrefix
    )

    return try renderValidatedSource(from: declarations)
}

/// Every message becomes a top-level struct, and top-level enums share that
/// namespace, so duplicate simple names would emit duplicate Swift symbols.
/// Nested enums live inside extensions of their parent and cannot collide.
private func checkForTypeNameCollisions(
    messages: [ProtoMessage],
    enums: [ProtoEnum],
    swiftPrefix: String
) throws {
    let topLevelNames = messages
        .map { (name: $0.name, fullName: $0.fullName) }
        + enums
        .filter(\.parentPath.isEmpty)
        .map { (name: $0.name, fullName: $0.fullName) }

    let duplicates = Dictionary(grouping: topLevelNames) { $0.name }
        .filter { $0.value.count > 1 }
    if let (name, collisions) = duplicates
        .min(by: { $0.key < $1.key }) {
        throw DuplicateTypeNameError(
            swiftName: "\(swiftPrefix)\(name)",
            protoNames: collisions.map(\.fullName).sorted()
        )
    }
}

/// Assembles the file, lets BasicFormat lay it out, and re-parses the result
/// — the validation gate that keeps invalid Swift out of consumers' builds.
private func renderValidatedSource(
    from declarations: [DeclSyntax]
) throws -> String {
    let source = SourceFileSyntax {
        for declaration in declarations {
            declaration
        }
    }

    var text = source.formatted().description
    if text.hasSuffix("\n") == false {
        text += "\n"
    }

    let reparsed = SwiftParser.Parser.parse(source: text)
    guard reparsed.hasError == false else {
        throw GenerationError(generated: text, tree: reparsed)
    }

    return text
}

/// Comments are not syntax nodes — a `// MARK:` line travels as leading
/// trivia on the declaration that follows it.
func sectionTrivia(mark: String?) -> Trivia {
    if let mark {
        return [
            .newlines(2),
            .lineComment("// MARK: - \(mark)"),
            .newlines(1)
        ]
    } else {
        return [.newlines(2)]
    }
}
