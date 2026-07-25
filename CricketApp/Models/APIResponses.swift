import Foundation

// MARK: - JSON Value

/// Flexible JSON representation used where third-party schemas are undocumented.
enum JSONValue: Decodable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }
}

// MARK: - JSON Access

extension JSONValue {
    var stringValue: String? {
        switch self {
        case let .string(value):
            value
        case let .number(value):
            value.formatted()
        case let .bool(value):
            value ? "true" : "false"
        case .array, .object, .null:
            nil
        }
    }

    var intValue: Int? {
        switch self {
        case let .number(value):
            Int(value)
        case let .string(value):
            Int(value)
        case .array, .bool, .object, .null:
            nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case let .number(value):
            value
        case let .string(value):
            Double(value)
        case .array, .bool, .object, .null:
            nil
        }
    }

    var objectValue: [String: JSONValue]? {
        if case let .object(value) = self {
            value
        } else {
            nil
        }
    }

    var arrayValue: [JSONValue]? {
        if case let .array(value) = self {
            value
        } else {
            nil
        }
    }

    var boolValue: Bool? {
        if case let .bool(value) = self {
            value
        } else if case let .string(value) = self {
            switch value.lowercased() {
            case "true", "yes", "1":
                true
            case "false", "no", "0":
                false
            default:
                nil
            }
        } else {
            nil
        }
    }

    func allObjects() -> [[String: JSONValue]] {
        switch self {
        case let .object(object):
            [object] + object.values.flatMap { $0.allObjects() }
        case let .array(values):
            values.flatMap { $0.allObjects() }
        case .bool, .null, .number, .string:
            []
        }
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    func value(for keys: [String]) -> JSONValue? {
        for key in keys {
            if let exact = self[key] {
                return exact
            }

            if let match = first(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
                return match.value
            }
        }

        return nil
    }

    func string(for keys: [String]) -> String? {
        value(for: keys)?.stringValue
    }

    func int(for keys: [String]) -> Int? {
        value(for: keys)?.intValue
    }

    func double(for keys: [String]) -> Double? {
        value(for: keys)?.doubleValue
    }
}

// MARK: - Cricket Australia Envelope

/// Root envelope for Cricket.com.au responses.
struct CricketAUEnvelope: Decodable, Sendable {
    let root: JSONValue

    init(from decoder: Decoder) throws {
        root = try JSONValue(from: decoder)
    }
}

// MARK: - Cricnet Ranking Response

/// Root envelope for Cricnet ranking responses.
struct CricnetRankingEnvelope: Decodable, Sendable {
    let root: JSONValue

    init(from decoder: Decoder) throws {
        root = try JSONValue(from: decoder)
    }
}

// MARK: - iTunes Lookup Response

/// Apple Lookup API response.
struct ITunesLookupResponse: Decodable, Sendable {
    let resultCount: Int
    let results: [ITunesLookupResult]
}

/// App Store metadata row.
struct ITunesLookupResult: Decodable, Sendable {
    let version: String
    let trackViewUrl: URL?
}
