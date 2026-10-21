import Foundation
import RegexBuilder

let messageHeaderPattern =
#/message\s+(\w+)\s*\{/#

let enumHeaderPattern =
#/enum\s+(\w+)\s*\{/#

let oneofHeaderPattern =
#/oneof\s+(\w+)\s*\{/#

let fieldPattern = 
#/\s*(\/\*\*(.|\n)*?\*\/)?\s*(optional|repeated|map)?\s*(\s*<\s*\w+\s*,\s*\w+\s*>|[\w\.]+)\s+(\w+)\s*=\s*\d+\s*(\[[^\]]*\])?;/#

/// Matches a `deprecated = true` entry within a field's option list.
let deprecatedOptionPattern =
#/\bdeprecated\s*=\s*true\b/#

/// Matches a double-quoted string literal, used to blank out option *values* before
/// looking for option keys inside them.
let stringLiteralPattern =
#/"[^"]*"/#

let enumCasePattern = 
#/\s*(\w+)\s*=\s*(\d+);/#
