import XCTest
@testable import SwiftBuffet

final class ParserTests: XCTestCase {
    func testParseSimpleMessage() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Person {
          string name = 1;
          int32 age = 2;
          bool is_active = 3;
        }
        """

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 1, "Expected to find 1 message, but got \(messages.count)")
        XCTAssertEqual(enums.count, 0, "Expected to find 0 enums, but got \(enums.count)")

        let personMessage = messages.first!
        XCTAssertEqual(personMessage.name, "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        XCTAssertNil(personMessage.parentName, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        XCTAssertEqual(personMessage.fields.count, 3, "Expected 3 fields, but got \(personMessage.fields.count)")

        let nameField = personMessage.fields[0]
        XCTAssertEqual(nameField.name, "name", "Expected field name to be 'name', but got '\(nameField.name)'")
        XCTAssertEqual(nameField.type, "string", "Expected field type to be 'string', but got '\(nameField.type)'")
        XCTAssertFalse(nameField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(nameField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(nameField.isMap, "Expected field to be non-map")
    }

    func testParseNestedMessage() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Person {
          string name = 1;
          int32 age = 2;
          Address address = 3;
        }

        message Address {
          string street = 1;
          string city = 2;
          string state = 3;
        }
        """

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 2, "Expected to find 2 messages, but got \(messages.count)")
        XCTAssertEqual(enums.count, 0, "Expected to find 0 enums, but got \(enums.count)")

        let personMessage = messages.first { $0.name == "Person" }!
        XCTAssertEqual(personMessage.name, "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        XCTAssertNil(personMessage.parentName, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        XCTAssertEqual(personMessage.fields.count, 3, "Expected 3 fields, but got \(personMessage.fields.count)")

        let addressMessage = messages.first { $0.name == "Address" }!
        XCTAssertEqual(addressMessage.name, "Address", "Expected message name to be 'Address', but got '\(addressMessage.name)'")
        XCTAssertNil(addressMessage.parentName, "Expected parent name to be nil, but got '\(addressMessage.parentName ?? "")'")
        XCTAssertEqual(addressMessage.fields.count, 3, "Expected 3 fields, but got \(addressMessage.fields.count)")
    }

    func testParseNestedEnumAndWellKnownTypes() throws {
        var protoFileContent = """
            syntax = "proto3";

            import "google/protobuf/duration.proto";
            import "google/protobuf/timestamp.proto";

            message Person {
              string name = 1;
              int32 age = 2;
              bool is_active = 3;
              enum Gender {
                UNKNOWN = 0;
                MALE = 1;
                FEMALE = 2;
              }
              Gender gender = 4;
              google.protobuf.Duration last_active = 5;
              google.protobuf.Timestamp created_at = 6;
            }
            """

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 1, "Expected to find 1 message, but got \(messages.count)")
        XCTAssertEqual(enums.count, 1, "Expected to find 1 enum, but got \(enums.count)")

        let personMessage = messages.first { $0.name == "Person" }!
        XCTAssertEqual(personMessage.name, "Person", "Expected message name to be 'Person', but got '\(personMessage.name)'")
        XCTAssertNil(personMessage.parentName, "Expected parent name to be nil, but got '\(personMessage.parentName ?? "")'")
        XCTAssertEqual(personMessage.fields.count, 6, "Expected 6 fields, but got \(personMessage.fields.count)")

        let genderEnum = enums.first { $0.name == "Gender" }!
        XCTAssertEqual(genderEnum.name, "Gender", "Expected enum name to be 'Gender', but got '\(genderEnum.name)'")
        XCTAssertEqual(genderEnum.parentName, "Person", "Expected parent name to be 'Person', but got '\(genderEnum.parentName ?? "")'")
        XCTAssertEqual(genderEnum.cases.count, 3, "Expected 3 enum cases, but got \(genderEnum.cases.count)")

        let genderField = personMessage.fields.first { $0.name == "gender" }!
        XCTAssertEqual(genderField.name, "gender", "Expected field name to be 'gender', but got '\(genderField.name)'")
        XCTAssertEqual(genderField.type, "Gender", "Expected field type to be 'Gender', but got '\(genderField.type)'")
        XCTAssertFalse(genderField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(genderField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(genderField.isMap, "Expected field to be non-map")

        let lastActiveField = personMessage.fields.first { $0.name == "last_active" }!
        XCTAssertEqual(lastActiveField.name, "last_active", "Expected field name to be 'last_active', but got '\(lastActiveField.name)'")
        XCTAssertEqual(lastActiveField.type, "google.protobuf.Duration", "Expected field type to be 'google.protobuf.Duration', but got '\(lastActiveField.type)'")
        XCTAssertFalse(lastActiveField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(lastActiveField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(lastActiveField.isMap, "Expected field to be non-map")

        let createdAtField = personMessage.fields.first { $0.name == "created_at" }!
        XCTAssertEqual(createdAtField.name, "created_at", "Expected field name to be 'created_at', but got '\(createdAtField.name)'")
        XCTAssertEqual(createdAtField.type, "google.protobuf.Timestamp", "Expected field type to be 'google.protobuf.Timestamp', but got '\(createdAtField.type)'")
        XCTAssertFalse(createdAtField.isOptional, "Expected field to be non-optional")
        XCTAssertFalse(createdAtField.isRepeated, "Expected field to be non-repeated")
        XCTAssertFalse(createdAtField.isMap, "Expected field to be non-map")
    }

    /// `oneof` member fields are mutually exclusive, so the parser must extract them
    /// into a separate `ProtoOneof` rather than letting them also be matched as
    /// ordinary top-level fields by the field-matching regex.
    func testParseMessageWithOneof() throws {
        var protoFileContent = """
        syntax = "proto3";

        message MultimediaSlide {
          oneof content {
            Image image = 1;
            Video video = 2;
          }
          optional string label = 3;
        }
        """

        let (messages, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.count, 1, "Expected to find 1 message, but got \(messages.count)")
        XCTAssertEqual(enums.count, 0, "Expected to find 0 enums, but got \(enums.count)")

        let slideMessage = messages.first!
        XCTAssertEqual(slideMessage.fields.count, 1, "The oneof's member fields should not also be parsed as top-level fields")
        XCTAssertEqual(slideMessage.fields.first?.name, "label", "The only top-level field should be 'label'")

        XCTAssertEqual(slideMessage.oneofs.count, 1, "Expected to find 1 oneof, but got \(slideMessage.oneofs.count)")
        let contentOneof = slideMessage.oneofs.first!
        XCTAssertEqual(contentOneof.name, "content", "Expected oneof name to be 'content', but got '\(contentOneof.name)'")
        XCTAssertEqual(contentOneof.fields.count, 2, "Expected 2 member fields in the oneof, but got \(contentOneof.fields.count)")

        let imageField = contentOneof.fields.first { $0.name == "image" }!
        XCTAssertEqual(imageField.type, "Image", "Expected field type to be 'Image', but got '\(imageField.type)'")
        XCTAssertFalse(imageField.isOptional, "Oneof member fields should not themselves be marked optional")

        let videoField = contentOneof.fields.first { $0.name == "video" }!
        XCTAssertEqual(videoField.type, "Video", "Expected field type to be 'Video', but got '\(videoField.type)'")
    }

    /// A naive `oneof ... { ... }` regex stops at the first `}`, so a brace inside a
    /// comment would end the block early and leak the remaining members out as
    /// ordinary top-level fields, losing mutual exclusivity.
    func testParseOneofWithBraceInComment() throws {
        var protoFileContent = """
        syntax = "proto3";

        message MultimediaSlide {
          oneof content {
            // JSON example: {}
            Image image = 1;
            Video video = 2;
          }
          optional string label = 3;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "MultimediaSlide" }!
        XCTAssertEqual(slideMessage.oneofs.count, 1, "Expected to find 1 oneof, but got \(slideMessage.oneofs.count)")
        XCTAssertEqual(slideMessage.oneofs.first?.fields.count, 2, "Both oneof members should be captured despite the braces in the comment")
        XCTAssertEqual(slideMessage.fields.count, 1, "Oneof members should not leak out as top-level fields")
        XCTAssertEqual(slideMessage.fields.first?.name, "label", "The only top-level field should be 'label'")
    }

    /// Aggregate options contain braces too, and must not terminate the oneof block.
    func testParseOneofWithAggregateOption() throws {
        var protoFileContent = """
        syntax = "proto3";

        message MultimediaSlide {
          oneof content {
            option (metadata) = { enabled: true };
            Image image = 1;
            Video video = 2;
          }
          optional string label = 3;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "MultimediaSlide" }!
        XCTAssertEqual(slideMessage.oneofs.count, 1, "Expected to find 1 oneof, but got \(slideMessage.oneofs.count)")

        let memberNames = slideMessage.oneofs.first?.fields.map(\.name) ?? []
        XCTAssertEqual(memberNames, ["image", "video"], "Both oneof members should be captured despite the braces in the aggregate option")
        XCTAssertEqual(slideMessage.fields.count, 1, "Oneof members should not leak out as top-level fields")
        XCTAssertEqual(slideMessage.fields.first?.name, "label", "The only top-level field should be 'label'")
    }

    /// A message can declare more than one oneof, and fields may appear between and
    /// after them — all of which must survive the block extraction.
    func testParseMessageWithMultipleOneofs() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Multi {
          string before = 1;
          oneof first {
            Image image = 2;
          }
          string between = 3;
          oneof second {
            Video video = 4;
          }
          string after = 5;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let multiMessage = messages.first { $0.name == "Multi" }!
        XCTAssertEqual(multiMessage.oneofs.map(\.name), ["first", "second"], "Both oneofs should be captured")
        XCTAssertEqual(multiMessage.oneofs.first?.fields.map(\.name), ["image"], "The first oneof should own 'image'")
        XCTAssertEqual(multiMessage.oneofs.last?.fields.map(\.name), ["video"], "The second oneof should own 'video'")
        XCTAssertEqual(multiMessage.fields.map(\.name), ["before", "between", "after"], "Fields surrounding the oneofs should be preserved")
    }

    /// A commented-out or quoted `oneof` header must not be treated as a real
    /// declaration, otherwise generation emits a phantom enum and references a
    /// `proto` member that doesn't exist.
    func testParseIgnoresOneofHeaderInsideComment() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          // Example: oneof ignored {}
          string title = 1;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "Slide" }!
        XCTAssertTrue(slideMessage.oneofs.isEmpty, "A oneof header inside a comment should not create a phantom oneof, but got \(slideMessage.oneofs.map(\.name))")
        XCTAssertEqual(slideMessage.fields.map(\.name), ["title"], "The real field should still be parsed")
    }

    /// The same applies to a `oneof` header inside a block comment or a string
    /// literal.
    ///
    /// Note: this only asserts that no phantom *oneof* is created. Fields that are
    /// themselves commented out (e.g. `string nope = 9;` inside a block comment) are
    /// still picked up by the field regex — a separate, pre-existing limitation of
    /// `fieldPattern`, which has never been comment-aware and which also affects
    /// ordinary messages.
    func testParseIgnoresOneofHeaderInsideBlockCommentAndString() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          /* oneof alsoIgnored { } */
          string title = 1;
          string example = 2 [json_name = "oneof quoted { }"];
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "Slide" }!
        XCTAssertTrue(
            slideMessage.oneofs.isEmpty,
            "A oneof header inside a block comment or string literal should not create a phantom oneof, but got \(slideMessage.oneofs.map(\.name))"
        )
    }

    /// An identifier that merely ends in "oneof" is not the `oneof` keyword.
    func testParseDoesNotTreatSimilarIdentifierAsOneof() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          string my_oneof = 1;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "Slide" }!
        XCTAssertTrue(slideMessage.oneofs.isEmpty, "'my_oneof' is a field name, not a oneof declaration")
        XCTAssertEqual(slideMessage.fields.map(\.name), ["my_oneof"], "The field should be parsed normally")
    }

    /// Members carrying general options (not just `[deprecated = ...]`) must still be
    /// captured, otherwise the generated enum is missing a case and its switch over
    /// SwiftProtobuf's enum is non-exhaustive.
    func testParseOneofMemberWithGeneralFieldOption() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          oneof content {
            string text = 1 [json_name = "body"];
            string other = 2;
          }
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "Slide" }!
        XCTAssertEqual(
            slideMessage.oneofs.first?.fields.map(\.name),
            ["text", "other"],
            "A member with a general option such as 'json_name' must not be silently dropped"
        )
    }

    /// Deprecation detection must survive the switch to general option parsing.
    func testParseFieldWithDeprecatedAndGeneralOptions() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          string legacy = 1 [deprecated = true];
          string renamed = 2 [json_name = "body"];
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "Slide" }!
        XCTAssertTrue(slideMessage.fields.first { $0.name == "legacy" }?.isDeprecated == true, "'[deprecated = true]' should still be detected")
        XCTAssertTrue(slideMessage.fields.first { $0.name == "renamed" }?.isDeprecated == false, "A non-deprecation option should not mark the field deprecated")
    }

    /// A oneof member carrying a multi-line option block must still be parsed.
    /// Dropping it would leave the generated switch missing a case that
    /// SwiftProtobuf's enum does have.
    func testParseOneofMemberWithMultiLineOption() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          oneof content {
            string text = 1;
            string html = 2 [
              (validate.rules).string.min_len = 1
            ];
            int32 number = 3;
          }
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slideMessage = messages.first { $0.name == "Slide" }!
        XCTAssertEqual(
            slideMessage.oneofs.first?.fields.map(\.name),
            ["text", "html", "number"],
            "A member whose options span multiple lines must not be dropped"
        )
    }

    /// The option group must not run past its own field. A greedy match would
    /// swallow a following declaration on the same line, dropping that field and
    /// borrowing its `deprecated` flag.
    func testParseTwoOptionBearingFieldsOnOneLine() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Mixed {
          string a = 1 [json_name = "a"]; string b = 2 [deprecated = true];
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let mixed = messages.first { $0.name == "Mixed" }!
        XCTAssertEqual(mixed.fields.map(\.name), ["a", "b"], "Neither field should be swallowed by the other's option group")
        XCTAssertEqual(mixed.fields.first { $0.name == "a" }?.isDeprecated, false, "'a' is not deprecated")
        XCTAssertEqual(mixed.fields.first { $0.name == "b" }?.isDeprecated, true, "'b' is deprecated")
    }

    /// `deprecated` must be matched as an option, not as arbitrary text that happens
    /// to appear inside another option's string value.
    func testDeprecatedInsideStringValueDoesNotMarkFieldDeprecated() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          string a = 1 [json_name = "not deprecated = true"];
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slide = messages.first { $0.name == "Slide" }!
        XCTAssertEqual(slide.fields.first?.name, "a", "The field should still be parsed")
        XCTAssertEqual(slide.fields.first?.isDeprecated, false, "Text inside a string value must not be read as a real 'deprecated' option")
    }

    /// A doc comment immediately before a `oneof` describes the oneof. It must be
    /// taken with the block, not left behind for the field regex to attach to
    /// whichever field happens to follow.
    func testOneofDocCommentIsNotTransplantedOntoNextField() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Doc {
          /** Documentation for the content oneof. */
          oneof content {
            string a = 1;
          }
          string trailing = 2;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let doc = messages.first { $0.name == "Doc" }!
        XCTAssertNil(doc.fields.first { $0.name == "trailing" }?.comment, "The oneof's doc comment must not be attached to the following field")
        XCTAssertEqual(doc.oneofs.first?.comment?.contains("Documentation for the content oneof"), true, "The doc comment should be carried by the oneof")
    }

    /// `messagePattern` used to require a literal `\n}`, so a message written on one
    /// line never terminated and swallowed everything after it.
    func testParseSingleLineMessage() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Point { int32 x = 1; }
        message Other { string name = 1; }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(messages.map(\.name).sorted(), ["Other", "Point"], "Both single-line messages should parse as separate messages")
        XCTAssertEqual(messages.first { $0.name == "Point" }?.fields.map(\.name), ["x"], "'Point' should own only its own field")
        XCTAssertEqual(messages.first { $0.name == "Other" }?.fields.map(\.name), ["name"], "'Other' should own only its own field")
    }

    /// CRLF files previously failed at the whole-message regex, producing no output
    /// at all.
    func testParseMessageWithCRLFLineEndings() throws {
        var protoFileContent = "syntax = \"proto3\";\r\n\r\nmessage Slide {\r\n  oneof content {\r\n    // pick one\r\n    Image image = 1;\r\n    Video video = 2;\r\n  }\r\n  optional string label = 3;\r\n}\r\n"

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slide = messages.first { $0.name == "Slide" }
        XCTAssertNotNil(slide, "A CRLF file should still parse its messages")
        XCTAssertEqual(slide?.oneofs.first?.fields.map(\.name), ["image", "video"], "Oneof members should parse with CRLF line endings")
        XCTAssertEqual(slide?.fields.map(\.name), ["label"], "Ordinary fields should parse with CRLF line endings")
    }

    /// Nested messages should be scoped by brace balancing, not by indentation luck.
    func testParseNestedMessageInsideMessage() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Outer {
          message Inner {
            string a = 1;
          }
          Inner inner = 1;
          string b = 2;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let outer = messages.first { $0.name == "Outer" }!
        let inner = messages.first { $0.name == "Inner" }!
        XCTAssertEqual(inner.parentName, "Outer", "'Inner' should be recorded as nested inside 'Outer'")
        XCTAssertEqual(inner.fields.map(\.name), ["a"], "'Inner' should own only its own field")
        XCTAssertEqual(outer.fields.map(\.name), ["inner", "b"], "'Outer' should not absorb the nested message's fields")
    }

    /// A commented-out field must not be generated as a real property, while a
    /// `/** ... */` doc comment must still be captured for the field it documents.
    func testParseIgnoresCommentedOutFieldsButKeepsDocComments() throws {
        var protoFileContent = """
        syntax = "proto3";

        message Slide {
          /** The title of the slide. */
          string title = 1;
          // string commentedOut = 2;
          /* string blockCommentedOut = 3; */
          string subtitle = 4;
        }
        """

        let (messages, _) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let slide = messages.first { $0.name == "Slide" }!
        XCTAssertEqual(slide.fields.map(\.name), ["title", "subtitle"], "Commented-out fields must not be parsed")
        XCTAssertEqual(slide.fields.first { $0.name == "title" }?.comment?.contains("The title of the slide"), true, "A doc comment should still be captured")
    }

    /// The same applies to commented-out enum cases.
    func testParseIgnoresCommentedOutEnumCases() throws {
        var protoFileContent = """
        syntax = "proto3";

        enum Status {
          STATUS_ACTIVE = 0;
          // STATUS_REMOVED = 1;
          STATUS_INACTIVE = 2;
        }
        """

        let (_, enums) = parseContent(
            &protoFileContent,
            parent: nil,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        let status = enums.first { $0.name == "Status" }!
        XCTAssertEqual(status.cases.map(\.name), ["STATUS_ACTIVE", "STATUS_INACTIVE"], "A commented-out enum case must not be parsed")
    }

    /// `\r\n` is a single Swift `Character`, so a scanner comparing against `"\n"`
    /// never leaves line-comment state and fails to find the closing brace, silently
    /// dropping the oneof. Exercised at the `parseOneofs` level because CRLF also
    /// defeats the (pre-existing, separate) whole-message regex.
    func testParseOneofWithCRLFLineEndings() throws {
        var body = "\r\n  oneof content {\r\n    // pick one\r\n    Image image = 1;\r\n    Video video = 2;\r\n  }\r\n  string label = 3;\r\n"

        let oneofs = parseOneofs(
            &body,
            with: "MyApp",
            verbose: false,
            quite: true
        )

        XCTAssertEqual(oneofs.count, 1, "The oneof should be found despite CRLF line endings")
        XCTAssertEqual(oneofs.first?.fields.map(\.name), ["image", "video"], "Both members should be captured past the CRLF-terminated comment")

        let remainingFields = parseMessageFields(from: body, with: "MyApp", verbose: false, quite: true)
        XCTAssertEqual(remainingFields.map(\.name), ["label"], "Oneof members must not leak out as ordinary fields")
    }
}
