import Foundation
import RegexBuilder

let messageHeaderPattern =
#/message\s+(\w+)\s*\{/#

let enumHeaderPattern =
#/enum\s+(\w+)\s*\{/#

let oneofHeaderPattern =
#/oneof\s+(\w+)\s*\{/#

let fieldPattern = 
#/\s*(\/\*\*(.|\n)*?\*\/)?\s*(optional|repeated|map)?\s*(\s*<\s*\w+\s*,\s*\w+\s*>|[\w\.]+)\s+(\w+)\s*=\s*\d+\s*(\[deprecated = .*\])?;/#

let enumCasePattern = 
#/\s*(\w+)\s*=\s*(\d+);/#
