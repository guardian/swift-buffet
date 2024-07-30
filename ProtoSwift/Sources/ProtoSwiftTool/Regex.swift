import Foundation
import RegexBuilder

let messagePattern = 
#/message\s+(\w+)\s*\{([\s\S]*?)\n\}/#

let enumPattern = 
#/enum\s+(\w+)\s*\{([\s\S]*?)\n?\}/#

let fieldPattern = 
#/\s*(\/\*\*(.|\n)*?\*\/)?\s*(optional|repeated|map)?\s*(\s*<\s*\w+\s*,\s*\w+\s*>|[\w\.]+)\s+(\w+)\s*=\s*\d+;/#

let enumCasePattern = 
#/\s*(\w+)\s*=\s*(\d+);/#
