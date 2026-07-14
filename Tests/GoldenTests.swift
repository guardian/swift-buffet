import Testing
import Foundation
@testable import SwiftBuffet

/// Full-pipeline golden snapshots: proto source → parseProto → generateSwiftCode.
///
/// Baselines reflect the SwiftSyntax generator's formatted output.
@Suite struct GoldenTests {

    private func generate(
        _ proto: String,
        localIDMessages: [String]? = nil,
        backingData: Bool = false
    ) throws -> String {
        let (messages, enums) = try parseProto(proto, swiftPrefix: "App")
        return try generateSwiftCode(
            from: messages,
            enums: enums,
            with: "App",
            includeProto: true,
            includeLocalIDFor: localIDMessages,
            includeBackingData: backingData,
            with: "Proto"
        )
    }

    @Test func `Golden example proto`() throws {
        let proto = """
        syntax = "proto3";

        message Person {
            string name = 1;
            int32 id = 2;
            string email = 3;
        }

        message AddressBook {
            repeated Person people = 1;
            optional bool is_current = 2;
        }

        message Address {
            string street = 1 [deprecated = true];
        }
        """

        let generated = try generate(
            proto,
            localIDMessages: ["Person"],
            backingData: true
        )

        let expected = #"""
        import Foundation

        // MARK: - Structs
        public struct AppAddress: Hashable, Equatable, Sendable {
            /// This property has been marked as **deprecated** in the proto file
            public let street: String
            public private(set) var _backingData: Data?
            public init(street: String) {
                self.street = street
            }
            public init?(data: Data) {
                if let proto = try? ProtoAddress(serializedBytes: data) {
                    self.init(proto: proto)
                    self._backingData = data
                } else {
                    return nil
                }
            }
            internal init?(proto: ProtoAddress) {
                self.street = proto.street
            }
        }

        public struct AppAddressBook: Hashable, Equatable, Sendable {
            public let people: [AppPerson]
            public let isCurrent: Bool
            public private(set) var _backingData: Data?
            public init(people: [AppPerson], isCurrent: Bool) {
                self.people = people
                self.isCurrent = isCurrent
            }
            public init?(data: Data) {
                if let proto = try? ProtoAddressBook(serializedBytes: data) {
                    self.init(proto: proto)
                    self._backingData = data
                } else {
                    return nil
                }
            }
            internal init?(proto: ProtoAddressBook) {
                self.people = proto.people.compactMap {
                    AppPerson(proto: $0)
                }
                if proto.hasIsCurrent {
                    self.isCurrent = proto.isCurrent
                } else {
                    self.isCurrent = false
                }
            }
        }

        public struct AppPerson: Hashable, Equatable, Sendable {
            public let name: String
            public let id: Int
            public let email: String
            public let _localID = UUID()
            public private(set) var _backingData: Data?
            public init(name: String, id: Int, email: String) {
                self.name = name
                self.id = id
                self.email = email
            }
            public init?(data: Data) {
                if let proto = try? ProtoPerson(serializedBytes: data) {
                    self.init(proto: proto)
                    self._backingData = data
                } else {
                    return nil
                }
            }
            internal init?(proto: ProtoPerson) {
                self.name = proto.name
                self.id = Int(proto.id)
                self.email = proto.email
            }
        }

        """#

        #expect(generated == expected)
    }

    @Test func `Golden kitchen sink`() throws {
        let proto = """
        syntax = "proto3";
        package com.example;
        import "google/protobuf/duration.proto";
        import "google/protobuf/timestamp.proto";

        message Profile {
            /** Display name shown in the UI. */
            string display_name = 1;
            optional string nickname = 2;
            repeated string tags = 3;
            map<string, int32> scores = 4;
            string avatar_url = 5;
            google.protobuf.Duration session_length = 6;
            google.protobuf.Timestamp created_at = 7;
            Status status = 8;
            enum Status {
                STATUS_UNSPECIFIED = 0;
                STATUS_ACTIVE = 1;
                STATUS_BANNED = 2;
              }
        }

        enum Plan {
            PLAN_UNSPECIFIED = 0;
            PLAN_FREE = 1;
            PLAN_PAID = 2;
        }
        """

        let generated = try generate(proto)

        let expected = #"""
        import Foundation

        // MARK: - Structs
        public struct AppProfile: Hashable, Equatable, Sendable {
            // Display name shown in the UI.
            public let displayName: String
            public let nickname: String?
            public let tags: [String]
            public let scores: [String: Int]
            public let avatarURL: URL
            public let sessionLength: TimeInterval
            public let createdAt: Date
            public let status: AppStatus
            public init(displayName: String, nickname: String?, tags: [String], scores: [String: Int], avatarURL: URL, sessionLength: TimeInterval, createdAt: Date, status: AppStatus) {
                self.displayName = displayName
                self.nickname = nickname
                self.tags = tags
                self.scores = scores
                self.avatarURL = avatarURL
                self.sessionLength = sessionLength
                self.createdAt = createdAt
                self.status = status
            }
            public init?(data: Data) {
                if let proto = try? ProtoProfile(serializedBytes: data) {
                    self.init(proto: proto)
                } else {
                    return nil
                }
            }
            internal init?(proto: ProtoProfile) {
                self.displayName = proto.displayName
                if proto.hasNickname {
                    self.nickname = proto.nickname
                } else {
                    self.nickname = nil
                }
                self.tags = proto.tags.compactMap {
                    String($0)
                }
                self.scores = proto.scores.reduce(into: [String: Int]()) { result, element in
                    result[element.key] = element.value
                }
                if let avatarURL = URL(string: proto.avatarURL) {
                    self.avatarURL = avatarURL
                } else {
                    return nil
                }
                self.sessionLength = proto.sessionLength.timeInterval
                self.createdAt = proto.createdAt.date
                if let status = AppStatus(proto: proto.status) {
                    self.status = status
                } else {
                    return nil
                }
            }
        }

        // MARK: - Enums
        public enum AppPlan: Int, CaseIterable, Hashable, Equatable, Sendable {
            case unspecified = 0
            case free = 1
            case paid = 2
            internal init?(proto: ProtoPlan) {
                self.init(rawValue: proto.rawValue)
            }
        }

        extension AppProfile {
            public enum AppStatus: Int, CaseIterable, Hashable, Equatable, Sendable {
                case unspecified = 0
                case active = 1
                case banned = 2
                internal init?(proto: ProtoProfile.Status) {
                    self.init(rawValue: proto.rawValue)
                }
            }
        }

        """#

        #expect(generated == expected)
    }
}
