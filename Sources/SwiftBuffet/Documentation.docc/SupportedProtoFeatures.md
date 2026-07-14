# Supported Proto Features
Which parts of the proto language Swift Buffet understands, skips, or rejects.

## Overview
Swift Buffet parses proto files with a real lexer and recursive-descent parser. The design rule is: **lenient about what it skips, strict about what it generates from.** Constructs the generator has no use for are stepped over without failing the build; malformed syntax in constructs it *does* consume produces an error with a line and column.

## Fully supported
- **Messages**, nested to any depth, with any brace placement or formatting.
- **Enums**, top-level or nested, including negative values, `allow_alias`, and per-value options.
- **All scalar types** (`double`, `float`, all ten integer flavors, `bool`, `string`, `bytes`).
- **Field modifiers:** proto3 `optional` and `repeated`.
- **Maps** with any valid key type, including message-typed values.
- **`oneof`** — member fields are generated as ordinary properties of the enclosing message. The exclusivity semantics are not modeled; all members are present as regular fields.
- **Doc comments** (`/** ... */`) in any legal position; the comment directly above a field is attached to it. Line comments (`//`) and plain block comments (`/* ... */`) are ignored everywhere.
- **Field options:** `[deprecated = true]` is recognized. All other options — including parenthesized custom options (`[(validate.rules).string.min_len = 1]`), aggregate `{ ... }` / `< ... >` values, and float literals — are skipped without affecting parsing.
- **Well-known types:** `google.protobuf.Timestamp` → `Date`, `google.protobuf.Duration` → `TimeInterval`.
- **Numeric literal forms:** decimal, hex (`0x1F`), and octal (`017`) field numbers and enum values.
- **String literal forms:** double- or single-quoted, with C-style escapes.
- **Leading-dot absolute type references** (`.google.protobuf.Timestamp`), normalized to the same type.
- **Empty statements** (stray `;`) at any scope.

## Consumed and ignored
These parse cleanly but produce no output:
- `syntax`, `package`, `import` (including `import public`), and `option` statements at any level.
- `reserved` ranges and names in messages and enums.

## Skipped with a warning
Logged when running with `--verbose`, otherwise silent:
- `service` blocks (including streaming RPCs).
- `extend` blocks (custom option definitions).

## Limitations
- **Qualified type references** to nested types (`Other.Inner field = 1;`) map to `<prefix>Other.Inner` in Swift, which does not match the flattened/extension-based layout of generated types. Prefer referencing nested types from within their own hierarchy, or flatten the proto definition.
- **Name collisions:** because generated structs are flattened to the top level, two messages with the same simple name (or a message and a top-level enum sharing a name) cannot coexist; generation fails with a clear error rather than emitting duplicate Swift symbols.
- **proto2-isms** such as `group`, `extensions 100 to 199;`, and `required` are not supported and produce a parse error.
- **`oneof` exclusivity** is not represented in the generated types (members are plain fields).
- `json_name`, custom option *semantics*, and `services` are out of scope.

## A taste of what parses
The package's test suite includes a "torture" fixture proving the breadth above — this is all one valid file:
```proto
syntax = "proto3";
option java_outer_classname = 'Torture';
;

message TorturePrimary {
  reserved 100 to 199, 250;
  fixed64 a_fixed64 = 0xA;
  sfixed32 a_sfixed32 = 013;
  string message = 17;

  oneof payload {
    string text_payload = 20;
    bytes blob_payload = 21;
  }

  map<sfixed64, double> metrics = 33;
  .google.protobuf.Duration session_length = 51;

  string tricky = 60 [
    deprecated = true,
    (buffet_note) = "multi\nline \"quoted\"",
    (buffet_meta) = { owner: 'ben' versions: [1, 2, 3] }
  ];
}
```
