import Foundation

struct ProtoMessage {
    let name: String
    let fields: [ProtoField]
}

struct ProtoField {
    let name: String
    let type: String
    let isOptional: Bool
    let isRepeated: Bool
}

struct ProtoEnum {
    let name: String
    let cases: [ProtoEnumCase]
}

struct ProtoEnumCase {
    let name: String
    let value: Int
}
