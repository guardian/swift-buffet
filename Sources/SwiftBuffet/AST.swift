import Foundation

/// The parsed representation of a .proto file as a tree.
///
/// The tree mirrors the nesting in the source file; `flatten` converts it to
/// the flat `parentPath`-based models the generator consumes.
struct ProtoFileNode {
    var messages: [MessageNode] = []
    var enums: [EnumNode] = []
}

struct MessageNode {
    let name: String
    var fields: [FieldNode] = []
    var messages: [MessageNode] = []
    var enums: [EnumNode] = []
}

struct EnumNode {
    let name: String
    var cases: [ProtoEnumCase] = []
}

struct FieldNode {
    let name: String
    /// Map fields use the legacy `"<key, value>"` shape expected by `ProtoField`.
    let type: String
    let comment: String?
    let isOptional: Bool
    let isRepeated: Bool
    let isMap: Bool
    let isDeprecated: Bool
}

/// Flattens a parsed file tree into the generator's flat model arrays.
func flatten(
    _ file: ProtoFileNode,
    swiftPrefix: String
) -> ([ProtoMessage], [ProtoEnum]) {
    var messages: [ProtoMessage] = []
    var enums: [ProtoEnum] = []

    func visit(_ node: MessageNode, parentPath: [String]) {
        let childPath = parentPath + [node.name]
        for child in node.messages {
            visit(child, parentPath: childPath)
        }
        for childEnum in node.enums {
            enums.append(
                ProtoEnum(
                    name: childEnum.name,
                    cases: childEnum.cases,
                    parentPath: childPath
                )
            )
        }
        messages.append(
            ProtoMessage(
                name: node.name,
                fields: node.fields.map { field in
                    ProtoField(
                        swiftPrefix: swiftPrefix,
                        name: field.name,
                        type: field.type,
                        comment: field.comment,
                        isOptional: field.isOptional,
                        isRepeated: field.isRepeated,
                        isMap: field.isMap,
                        isDeprecated: field.isDeprecated
                    )
                },
                parentPath: parentPath
            )
        )
    }

    for message in file.messages {
        visit(message, parentPath: [])
    }
    for topLevelEnum in file.enums {
        enums.append(
            ProtoEnum(
                name: topLevelEnum.name,
                cases: topLevelEnum.cases,
                parentPath: []
            )
        )
    }

    return (messages, enums)
}
