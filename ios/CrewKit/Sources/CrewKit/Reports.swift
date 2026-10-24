import Foundation

/// What a worker can flag to the crew lead.
public enum ReportKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case smoke, ash, symptoms
    case noN95 = "no_n95"
    case noShade = "no_shade"
    case noWater = "no_water"
    case other

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .smoke: "Smoke"
        case .ash: "Ash falling"
        case .symptoms: "Symptoms"
        case .noN95: "No N95"
        case .noShade: "No shade"
        case .noWater: "No water"
        case .other: "Other"
        }
    }
}

/// Body of `POST /api/crew/report`.
public struct ReportRequest: Codable, Sendable, Equatable {
    public let place: String
    public let date: String
    public let shift: String
    public let kind: ReportKind
    public let note: String

    public init(place: String, date: String, shift: String, kind: ReportKind, note: String) {
        self.place = place
        self.date = date
        self.shift = shift
        self.kind = kind
        self.note = note
    }
}

/// Reply of `POST /api/crew/report`.
public struct ReportReceipt: Codable, Sendable, Equatable {
    public let id: String
    public let createdAt: String
    public let status: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case createdAt = "created_at"
    }
}

public struct Report: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let createdAt: String
    public let kind: ReportKind
    public let note: String?
    public let status: String
    public let handledAt: String?

    public init(id: String, createdAt: String, kind: ReportKind, note: String?, status: String, handledAt: String?) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.note = note
        self.status = status
        self.handledAt = handledAt
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, note, status
        case createdAt = "created_at"
        case handledAt = "handled_at"
    }

    public var isOpen: Bool { status == "open" }
}

/// Reply of `GET /api/crew/reports`.
public struct ReportList: Codable, Sendable, Equatable {
    public let reports: [Report]
}

extension ReportReceipt {
    /// The id may arrive as a number; accept both.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleID(forKey: .id)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        status = try c.decode(String.self, forKey: .status)
    }
}

extension Report {
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleID(forKey: .id)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        kind = (try? c.decode(ReportKind.self, forKey: .kind)) ?? .other
        note = try c.decodeIfPresent(String.self, forKey: .note)
        status = try c.decode(String.self, forKey: .status)
        handledAt = try c.decodeIfPresent(String.self, forKey: .handledAt)
    }
}

extension KeyedDecodingContainer {
    /// An id sent as a string or as a number, read as a string.
    func decodeFlexibleID(forKey key: Key) throws -> String {
        if let s = try? decode(String.self, forKey: key) { return s }
        return String(try decode(Int.self, forKey: key))
    }
}
