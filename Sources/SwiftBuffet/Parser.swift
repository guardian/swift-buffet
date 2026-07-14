import Foundation

/// Parses a protocol buffer file from the given URL path.
///
/// - Parameters:
///   - path: The URL of the .proto file to be parsed.
///   - swiftPrefix: The prefix applied to generated Swift type names.
///   - verbose: Prints every parsed message, field, and enum when `true`.
/// - Returns: A tuple containing arrays of `ProtoMessage` and `ProtoEnum`.
/// - Throws: An error if the file cannot be read, or `ParseError` (with line
///   and column) if the proto source is malformed.
internal func parseProtoFile(
    at path: URL,
    with swiftPrefix: String,
    verbose: Bool
) throws -> ([ProtoMessage], [ProtoEnum]) {
    let content = try String(contentsOf: path)
    return try parseProto(
        content,
        swiftPrefix: swiftPrefix,
        verbose: verbose
    )
}

/// Stable parsing entry point: lexes and parses the .proto source, then
/// flattens the resulting tree into the generator's model arrays.
///
/// - Throws: `ParseError` with line/column information for malformed input.
func parseProto(
    _ content: String,
    swiftPrefix: String,
    verbose: Bool = false
) throws -> ([ProtoMessage], [ProtoEnum]) {
    let file = try ProtoParser.parse(content, verbose: verbose)
    let (messages, enums) = flatten(file, swiftPrefix: swiftPrefix)

    if verbose {
        for message in messages {
            print("Matched message: \(message.name)")
            for field in message.fields {
                print("Matched field type: \(field.type), field name: \(field.name), isOptional: \(field.isOptional), isRepeated: \(field.isRepeated), isMap: \(field.isMap))")
            }
        }
        for protoEnum in enums {
            print("Matched enum: \(protoEnum.name)")
        }
    }

    return (messages, enums)
}
