import Foundation

struct MediaID: Sendable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    let rawValue: String

    init?(_ rawValue: String) {
        guard let normalized = Self.normalize(rawValue) else {
            return nil
        }
        self.rawValue = normalized
    }

    init?(rawValue: String) {
        self.init(rawValue)
    }

    init(stringLiteral value: String) {
        guard let normalized = Self.normalize(value) else {
            preconditionFailure("MediaID string literal must not be empty.")
        }
        self.rawValue = normalized
    }

    var description: String { rawValue }

    private static func normalize(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct StreamID: Sendable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    let rawValue: String

    init?(_ rawValue: String) {
        guard let normalized = Self.normalize(rawValue) else {
            return nil
        }
        self.rawValue = normalized
    }

    init?(rawValue: String) {
        self.init(rawValue)
    }

    init(stringLiteral value: String) {
        guard let normalized = Self.normalize(value) else {
            preconditionFailure("StreamID string literal must not be empty.")
        }
        self.rawValue = normalized
    }

    var description: String { rawValue }

    private static func normalize(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct AdID: Sendable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    let rawValue: String

    init?(_ rawValue: String) {
        guard let normalized = Self.normalize(rawValue) else {
            return nil
        }
        self.rawValue = normalized
    }

    init?(rawValue: String) {
        self.init(rawValue)
    }

    init(stringLiteral value: String) {
        guard let normalized = Self.normalize(value) else {
            preconditionFailure("AdID string literal must not be empty.")
        }
        self.rawValue = normalized
    }

    var description: String { rawValue }

    private static func normalize(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct SurfaceID: Sendable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    let rawValue: String

    init?(_ rawValue: String) {
        guard let normalized = Self.normalize(rawValue) else {
            return nil
        }
        self.rawValue = normalized
    }

    init?(rawValue: String) {
        self.init(rawValue)
    }

    init(stringLiteral value: String) {
        guard let normalized = Self.normalize(value) else {
            preconditionFailure("SurfaceID string literal must not be empty.")
        }
        self.rawValue = normalized
    }

    var description: String { rawValue }

    private static func normalize(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
