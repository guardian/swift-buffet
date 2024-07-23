import Foundation

func generateSwiftCode(from messages: [ProtoMessage], enums: [ProtoEnum]) -> String {
    var code = ""

    for message in messages {
        code += "struct \(message.name) {\n"
        for field in message.fields {
            let swiftType = mapProtoTypeToSwift(field.type)
            let fieldDeclaration: String
            if field.isRepeated {
                fieldDeclaration = "    var \(field.name): [\(swiftType)]"
            } else if field.isOptional {
                fieldDeclaration = "    var \(field.name): \(swiftType)?"
            } else {
                fieldDeclaration = "    var \(field.name): \(swiftType)"
            }
            code += "\(fieldDeclaration)\n"
        }
        code += "}\n\n"
    }

    for protoEnum in enums {
        code += "enum \(protoEnum.name): Int {\n"
        for enumCase in protoEnum.cases {
            code += "    case \(enumCase.name) = \(enumCase.value)\n"
        }
        code += "}\n\n"
    }

    return code
}

func mapProtoTypeToSwift(_ type: String) -> String {
    switch type {
    case "double": return "Double"
    case "float": return "Float"
    case "int32", "sint32", "sfixed32": return "Int32"
    case "int64", "sint64", "sfixed64": return "Int64"
    case "uint32", "fixed32": return "UInt32"
    case "uint64", "fixed64": return "UInt64"
    case "bool": return "Bool"
    case "string": return "String"
    case "bytes": return "Data"
    default: return type // Handle nested messages and enums if needed
    }
}
