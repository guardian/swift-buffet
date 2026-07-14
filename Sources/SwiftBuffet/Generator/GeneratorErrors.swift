import Foundation
import SwiftSyntax

/// Thrown when the generated source fails to re-parse as valid Swift.
/// This is the final validation gate: codegen fails here rather than in the
/// consumer's build.
struct GenerationError: Error, CustomStringConvertible {
    let line: Int?
    let excerpt: String

    var description: String {
        let location = line.map { " at line \($0)" } ?? ""
        return "Internal error: generated Swift failed to parse\(location). Please report this. Context:\n\(excerpt)"
    }

    init(generated: String, tree: SourceFileSyntax) {
        let finder = FirstSyntaxErrorFinder(viewMode: .all)
        finder.walk(tree)

        if let position = finder.position {
            let converter = SourceLocationConverter(
                fileName: "generated.swift",
                tree: tree
            )
            let errorLine = converter.location(for: position).line
            let lines = generated.split(separator: "\n", omittingEmptySubsequences: false)
            let window = lines[max(0, errorLine - 6)..<min(lines.count, errorLine + 5)]
            self.line = errorLine
            self.excerpt = window.joined(separator: "\n")
        } else {
            self.line = nil
            self.excerpt = generated
        }
    }
}

/// Finds the position of the first missing or unexpected token in a tree.
///
/// SwiftParser never fails outright — broken input is represented in the tree
/// as zero-length "missing" tokens and `UnexpectedNodesSyntax` islands. The
/// `hasError` check prunes healthy subtrees so the walk descends straight
/// toward the damage.
final class FirstSyntaxErrorFinder: SyntaxAnyVisitor {
    var position: AbsolutePosition?

    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        if position != nil || node.hasError == false {
            return .skipChildren
        }
        if node.is(UnexpectedNodesSyntax.self)
            || node.as(TokenSyntax.self)?.presence == .missing {
            position = node.positionAfterSkippingLeadingTrivia
            return .skipChildren
        }
        return .visitChildren
    }
}

/// Thrown when two proto types would flatten to the same Swift type name.
///
/// All structs are generated at the top level, so `Brunch.Scone` and
/// `Teatime.Scone` would both become `<prefix>Scone` — a duplicate-symbol
/// compile error in the consumer's build if it were allowed through.
struct DuplicateTypeNameError: Error, CustomStringConvertible {
    let swiftName: String
    let protoNames: [String]
    var description: String {
        "Cannot generate: \(protoNames.joined(separator: " and ")) would both produce the Swift type '\(swiftName)'. Rename one of them."
    }
}
