# Anatomy of the Generated Code
What Swift Buffet produces for each proto construct, and the naming and type-mapping rules it applies.

## Type mapping
| Proto type | Swift type |
| --- | --- |
| `double` | `Double` |
| `float` | `Float` |
| `int32`, `sint32`, `sfixed32`, `int64`, `sint64`, `sfixed64` | `Int` |
| `uint32`, `fixed32`, `uint64`, `fixed64` | `UInt` |
| `bool` | `Bool` |
| `string` | `String` |
| `bytes` | `Data` |
| `google.protobuf.Timestamp` | `Date` |
| `google.protobuf.Duration` | `TimeInterval` |
| `map<K, V>` | `[K': V']` (both sides mapped recursively) |
| message / enum reference | `<swiftPrefix><Name>` |
| `repeated T` | `[T']` |
| proto3 `optional T` | `T'?` (except `bool`, which stays non-optional and defaults to `false`) |

## Naming rules
- Field names convert from `snake_case` to `camelCase`: `is_active` → `isActive`.
- Names containing `_url` or `_id` get their abbreviations capitalized: `home_url` → `homeURL`, `user_id` → `userID`.
- **URL convenience:** a `string` field whose corrected name ends in `URL` or `URI` is typed as `URL` instead of `String` (and `[URL]` for `repeated` fields whose name ends in `URLS`/`URIS`). Conversion happens in `init?(proto:)` via `URL(string:)` and fails the initializer for required fields with unparseable values.
- The field name `description` is accessed as `description_p` on SwiftProtobuf types, matching SwiftProtobuf's escaping.

## Messages
Each message becomes a top-level `public struct` conforming to `Hashable`, `Equatable`, and `Sendable`, with `let` properties and a memberwise initializer. Proto doc comments (`/** ... */`) on fields carry over as comments on the generated properties, and `[deprecated = true]` adds a deprecation notice comment.

With `--include-protobuf`, two more initializers are generated:
```swift
public init?(data: Data) {
    if let proto = try? ProtoFingerSandwich(serializedBytes: data) {
        self.init(proto: proto)
    } else {
        return nil
    }
}

internal init?(proto: ProtoFingerSandwich) {
    self.filling = proto.filling
    self.bread = proto.bread
    if proto.hasQuarters {
        self.quarters = Int(proto.quarters)
    } else {
        self.quarters = nil
    }
}
```
Conversion rules inside `init?(proto:)`:

- **Optional fields** are guarded with SwiftProtobuf's `has<Field>` check; absent values default to `nil` (`false` for `bool`, `[]` for `repeated`).
- **Repeated fields** map element-wise with `compactMap`.
- **Map fields** copy via `reduce(into:)`.
- **Integer scalars** convert through their Swift type (`Int(proto.x)` / `UInt(proto.x)`).
- **Message-typed fields** chain through the nested type's own `init?(proto:)`; a failed required conversion fails the whole initializer.
- **`Timestamp`/`Duration`** use SwiftProtobuf's `.date` / `.timeInterval`.

## Enums
Enums become `Int`-raw-value enums conforming to `CaseIterable`, `Hashable`, `Equatable`, and `Sendable`:
```proto
enum Filling {
    FILLING_UNKNOWN = 0;
    FILLING_CUCUMBER = 1;
    FILLING_JAM = 2;
    FILLING_SMOKED_SALMON = 3;
}
```

```swift
public enum AppFilling: Int, CaseIterable, Hashable, Equatable, Sendable {
    case unknown = 0
    case cucumber = 1
    case jam = 2
    case smokedSalmon = 3
}
```
- The shared `SCREAMING_SNAKE` prefix is stripped, but only at an underscore boundary, never for single-case enums, and never when stripping would leave an empty or digit-leading name (those cases keep their full name: `VERSION_1` → `version1`).
- `allow_alias` duplicates collapse to one Swift case per raw value — the first name wins.
- With `--include-protobuf`, enums gain `init?(proto:)` bridging by raw value.

## Nesting
Generated structs are always emitted at the top level, regardless of proto nesting — a nested message `Outer.Inner` becomes `struct <prefix>Inner`. Nested **enums** are emitted inside an `extension` of their parent struct, so proto `Trifle.Layer` is Swift `AppTrifle.AppLayer`. Protobuf bridging always references the fully qualified SwiftProtobuf name (`ProtoOuter.Inner`).
Because the Swift namespace is flattened, two messages with the same name under different parents would collide; generation fails with an error naming both types.

## Optional extras
- `--local-id-messages FingerSandwich` adds `public let _localID = UUID()` to `FingerSandwich` — a stable identity for SwiftUI's `Identifiable`/`ForEach` even when the decoded content is equal.
- `--store-backing-data` adds `public private(set) var _backingData: Data?`, populated with the original bytes by `init?(data:)` — useful for re-serializing or caching without a round trip.
