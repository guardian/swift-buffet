import Testing
import Foundation
@testable import SwiftBuffet

/// A single deliberately hostile — but entirely valid — proto3 file
/// exercising the full grammar surface in one pass: every scalar type,
/// hex/octal field numbers, single-quoted and escaped string literals,
/// empty statements, doc comments in every legal position, custom options
/// (parenthesized, dotted, aggregate `{...}` values with lists), oneof with
/// options, all map key kinds, leading-dot absolute type references,
/// three-level nesting, name-shadowed nested enums, negative enum values,
/// `allow_alias` duplicate values, reserved ranges/names, extend blocks,
/// and a streaming service.
@Suite struct TortureProtoTests {

    static let torture = #"""
    // SwiftBuffet torture fixture. Valid proto3 throughout.
    /* Plain block comment,
       not a doc comment. */
    syntax = "proto3";

    package buffet.torture.v1;

    import "google/protobuf/descriptor.proto";
    import "google/protobuf/timestamp.proto";
    import public "google/protobuf/duration.proto";

    option java_package = "com.buffet.torture";
    option java_outer_classname = 'Torture';
    option optimize_for = SPEED;
    ;

    extend google.protobuf.FieldOptions {
      string buffet_note = 51234;
      BuffetMeta buffet_meta = 51235;
    }

    extend google.protobuf.FileOptions {
      BuffetMeta file_meta = 51236;
    }

    option (file_meta) = { owner: "ben" versions: [1, 2, 3] };

    /** Metadata payload used by the custom options above. */
    message BuffetMeta {
      string owner = 1;
      repeated int32 versions = 2;
      bool deprecated = 3;
    }

    /** First doc comment. */
    /** Second consecutive doc comment wins. */
    message TorturePrimary {
      ;
      reserved 100 to 199, 250;
      reserved "ancient_field";
      option deprecated = true;

      double a_double = 1;
      float a_float = 2;
      int32 an_int32 = 3 [deprecated = true];
      int64 an_int64 = 4;
      uint32 a_uint32 = 5;
      uint64 a_uint64 = 6;
      sint32 a_sint32 = 7;
      sint64 a_sint64 = 8;
      fixed32 a_fixed32 = 9;
      fixed64 a_fixed64 = 0xA;
      sfixed32 a_sfixed32 = 013;
      sfixed64 a_sfixed64 = 12;
      bool a_bool = 14;
      string a_string = 15;
      bytes raw_bytes = 16;

      string message = 17;
      string enum_name = 18;
      string option_like = 19;

      oneof payload {
        option (buffet_note) = "oneof options are legal";
        string text_payload = 20;
        bytes blob_payload = 21;
        NestedLevel1 nested_payload = 22;
      }

      map<string, string> labels = 30;
      map<int32, NestedLevel1> children_by_id = 31;
      map<bool, string> flags = 32;
      map<sfixed64, double> metrics = 33;

      optional string maybe_name = 40;
      repeated NestedLevel1 children = 41;
      optional NestedLevel1 maybe_child = 42;
      optional bool maybe_flag = 43;
      repeated string image_urls = 44;
      string home_url = 45;
      optional string avatar_uri = 46;
      string description = 47;

      google.protobuf.Timestamp created_at = 50;
      .google.protobuf.Duration session_length = 51;

      /** A field exercising option soup. */
      string tricky = 60 [
        deprecated = true,
        (buffet_note) = "multi\nline \"quoted\" \\ backslash",
        (buffet_meta) = { owner: 'ben' versions: [1, 2, 3] }
      ];
      string innocent = 61 [(buffet_meta).deprecated = true, (buffet_note) = 'single quoted'];

      message NestedLevel1 {
        /** Doc on value. */
        string value = 1;

        message NestedLevel2 {
          string value = 1;

          enum DeepEnum {
            DEEP_ENUM_UNSPECIFIED = 0;
            DEEP_ENUM_NEGATIVE = -1;
            DEEP_ENUM_DEEP = 2;
          }

          DeepEnum deep = 2;
        }

        NestedLevel2 next = 2;
      }

      /** Dangling comment before the closing brace. */
    }

    message Alpha {
      enum Status { STATUS_UNSPECIFIED = 0; STATUS_OK = 1; }
      Status status = 1;
    }

    message Beta {
      enum Status {
        STATUS_UNSPECIFIED = 0;
        STATUS_DEGRADED = 1;
      }
      Status status = 1;
    }

    message Tiny{bool on=1;}

    enum SingleValue { SINGLE_VALUE_UNSPECIFIED = 0; }

    enum Version {
      VERSION_UNSPECIFIED = 0;
      VERSION_1 = 1;
      VERSION_2 = 2;
    }

    enum Aliased {
      option allow_alias = true;
      ALIASED_UNSPECIFIED = 0;
      ALIASED_ACTIVE = 1;
      ALIASED_ENABLED = 1 [deprecated = true];
      reserved 10 to 14;
      reserved "ALIASED_OLD";
      ;
    }

    /** Service blocks are skipped entirely. */
    service TortureService {
      option deprecated = true;
      rpc Echo (TorturePrimary) returns (TorturePrimary);
      rpc Pour (stream TorturePrimary) returns (stream Beta) {
        option (buffet_note) = "streaming { with braces } inside";
      }
    }

    /** Trailing file-level comment. */
    """#

    @Test func `Parses every construct`() throws {
        let (messages, enums) = try parseProto(Self.torture, swiftPrefix: "App")

        #expect(Set(messages.map(\.name)) == ["BuffetMeta", "TorturePrimary", "NestedLevel1", "NestedLevel2",
             "Alpha", "Beta", "Tiny"])
        #expect(Set(enums.map(\.name)) == ["DeepEnum", "Status", "SingleValue", "Version", "Aliased"])
        #expect(enums.count == 6, "Both shadowed Status enums must survive")
    }

    @Test func `Primary message fields`() throws {
        let (messages, _) = try parseProto(Self.torture, swiftPrefix: "App")
        let primary = messages.first { $0.name == "TorturePrimary" }!
        let fieldsByName = Dictionary(
            uniqueKeysWithValues: primary.fields.map { ($0.name, $0) }
        )

        #expect(primary.fields.count == 37)

        // Hex and octal field numbers lex correctly (presence proves it).
        #expect(fieldsByName["a_fixed64"] != nil)
        #expect(fieldsByName["a_sfixed32"] != nil)

        // Keyword-like names are ordinary fields.
        #expect(fieldsByName["message"] != nil)
        #expect(fieldsByName["option_like"] != nil)

        // oneof members are fields of the enclosing message.
        #expect(fieldsByName["text_payload"] != nil)
        #expect(fieldsByName["nested_payload"] != nil)

        // Option soup: plain deprecated sticks, dotted custom option doesn't.
        #expect(fieldsByName["an_int32"]!.isDeprecated)
        #expect(fieldsByName["tricky"]!.isDeprecated)
        #expect(fieldsByName["innocent"]!.isDeprecated == false)

        // Maps with each key kind.
        #expect(fieldsByName["labels"]!.caseCorrectedBaseType == "[String: String]")
        #expect(fieldsByName["children_by_id"]!.caseCorrectedBaseType == "[Int: AppNestedLevel1]")
        #expect(fieldsByName["flags"]!.caseCorrectedBaseType == "[Bool: String]")
        #expect(fieldsByName["metrics"]!.caseCorrectedBaseType == "[Int: Double]")

        // Leading-dot absolute reference normalizes to the well-known type.
        #expect(fieldsByName["session_length"]!.type == "google.protobuf.Duration")
        #expect(fieldsByName["session_length"]!.caseCorrectedBaseType == "TimeInterval")
    }

    @Test func `Deep nesting and enum values`() throws {
        let (_, enums) = try parseProto(Self.torture, swiftPrefix: "App")

        let deep = enums.first { $0.name == "DeepEnum" }!
        #expect(deep.parentPath == ["TorturePrimary", "NestedLevel1", "NestedLevel2"])
        #expect(deep.fullName == "TorturePrimary.NestedLevel1.NestedLevel2.DeepEnum")
        #expect(deep.cases.map(\.value) == [0, -1, 2])

        let aliased = enums.first { $0.name == "Aliased" }!
        #expect(aliased.cases.map(\.value) == [0, 1, 1])
    }

    @Test func `Generates valid swift`() throws {
        let (messages, enums) = try parseProto(Self.torture, swiftPrefix: "App")

        // The internal SwiftParser gate throws if the output is not valid Swift.
        let code = try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: ["TorturePrimary"],
            includeBackingData: true,
            with: "Proto"
        )

        // Shadowed nested enums live in separate extensions.
        #expect(code.contains("extension AppAlpha"))
        #expect(code.contains("extension AppBeta"))

        // Deep nesting uses the full proto type path.
        #expect(code.contains("internal init?(proto: ProtoTorturePrimary.NestedLevel1.NestedLevel2)"))

        // Aliased enum values collapse to one case per raw value.
        #expect(code.contains("case active = 1"))
        #expect(code.contains("case enabled = 1") == false, "allow_alias duplicates must not produce duplicate raw values")

        // URL conveniences.
        #expect(code.contains("public let imageURLs: [URL]"))
        #expect(code.contains("public let homeURL: URL"))
        #expect(code.contains("public let avatarUri: URL?"))
    }
}
