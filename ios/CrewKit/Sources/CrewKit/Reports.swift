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
    /// Where the worker stood and which way they faced. The server rounds the position to
    /// ~100 m. All optional: a report without location permission still goes.
    public let lat: Double?
    public let lon: Double?
    public let accuracyM: Double?
    public let headingDeg: Double?
    /// The sky check the report came from, if any.
    public let sky: SkySummary?

    public init(
        place: String, date: String, shift: String, kind: ReportKind, note: String,
        origin: ReportOrigin.Input? = nil, sky: SkySummary? = nil
    ) {
        self.place = place
        self.date = date
        self.shift = shift
        self.kind = kind
        self.note = note
        lat = origin?.lat
        lon = origin?.lon
        accuracyM = origin?.accuracyM
        headingDeg = origin?.headingDeg
        self.sky = sky
    }

    enum CodingKeys: String, CodingKey {
        case place, date, shift, kind, note, lat, lon, sky
        case accuracyM = "accuracy_m"
        case headingDeg = "heading_deg"
    }
}

/// The sky check a report carries: `{smoke, smoke_call, verdict}`.
public struct SkySummary: Codable, Sendable, Equatable {
    public let smoke: Double
    public let smokeCall: String
    public let verdict: String

    public init(smoke: Double, smokeCall: String, verdict: String) {
        self.smoke = smoke
        self.smokeCall = smokeCall
        self.verdict = verdict
    }

    public init(_ result: SkyCheckResult) {
        self.init(smoke: result.smoke, smokeCall: result.smokeCall.rawValue, verdict: result.verdict)
    }

    enum CodingKeys: String, CodingKey {
        case smoke, verdict
        case smokeCall = "smoke_call"
    }
}

/// `evidence.from`: where the report was made and which way the worker faced, as the server
/// stored it (position rounded, compass point and "toward the fire" worked out).
public struct ReportOrigin: Codable, Sendable, Equatable {
    /// What the phone knows when the report is made.
    public struct Input: Sendable, Equatable {
        public let lat: Double?
        public let lon: Double?
        public let accuracyM: Double?
        public let headingDeg: Double?

        public init(lat: Double?, lon: Double?, accuracyM: Double?, headingDeg: Double?) {
            self.lat = lat
            self.lon = lon
            self.accuracyM = accuracyM
            self.headingDeg = headingDeg
        }

        public var isEmpty: Bool { lat == nil && headingDeg == nil }
    }

    public let position: Position?
    public let facing: Facing?
    public let sky: SkySummary?

    public init(position: Position?, facing: Facing?, sky: SkySummary?) {
        self.position = position
        self.facing = facing
        self.sky = sky
    }

    enum CodingKeys: String, CodingKey {
        case facing, sky
        case position = "where"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        position = try? c.decodeIfPresent(Position.self, forKey: .position)
        facing = try? c.decodeIfPresent(Facing.self, forKey: .facing)
        sky = try? c.decodeIfPresent(SkySummary.self, forKey: .sky)
    }
}

public struct Position: Codable, Sendable, Equatable {
    public let lat: Double
    public let lon: Double
    public let accuracyM: Double?

    public init(lat: Double, lon: Double, accuracyM: Double?) {
        self.lat = lat
        self.lon = lon
        self.accuracyM = accuracyM
    }

    enum CodingKeys: String, CodingKey {
        case lat, lon
        case accuracyM = "accuracy_m"
    }
}

public struct Facing: Codable, Sendable, Equatable {
    public let headingDeg: Double
    public let compass: String?
    public let towardFire: Bool?

    public init(headingDeg: Double, compass: String?, towardFire: Bool?) {
        self.headingDeg = headingDeg
        self.compass = compass
        self.towardFire = towardFire
    }

    enum CodingKeys: String, CodingKey {
        case compass
        case headingDeg = "heading_deg"
        case towardFire = "toward_fire"
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
    /// "open", "handled", or "unsent" for one that never left the phone.
    public let status: String
    public let handledAt: String?
    public let handledNote: String?
    /// What the plan said at the hour the report was made, attached by the server.
    public let evidence: Evidence?

    public init(
        id: String, createdAt: String, kind: ReportKind, note: String?, status: String,
        handledAt: String? = nil, handledNote: String? = nil, evidence: Evidence? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.note = note
        self.status = status
        self.handledAt = handledAt
        self.handledNote = handledNote
        self.evidence = evidence
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, note, status, evidence
        case createdAt = "created_at"
        case handledAt = "handled_at"
        case handledNote = "handled_note"
    }

    public var isOpen: Bool { status == "open" }
    public var isHandled: Bool { status == "handled" }
    public var isUnsent: Bool { status == "unsent" }
}

/// The facts a report carries: the NowCast hour, the nearest satellite fire, the ground monitor.
public struct Evidence: Codable, Sendable, Equatable {
    public let hour: String?
    public let metrics: Metrics?
    public let fire: Fire?
    public let ground: Ground?
    /// Where the worker stood and which way they faced; nil for reports sent without either.
    public let from: ReportOrigin?

    public init(
        hour: String? = nil, metrics: Metrics? = nil, fire: Fire? = nil, ground: Ground? = nil,
        from: ReportOrigin? = nil
    ) {
        self.hour = hour
        self.metrics = metrics
        self.fire = fire
        self.ground = ground
        self.from = from
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hour = try? c.decodeIfPresent(String.self, forKey: .hour)
        metrics = try? c.decodeIfPresent(Metrics.self, forKey: .metrics)
        fire = try? c.decodeIfPresent(Fire.self, forKey: .fire)
        ground = try? c.decodeIfPresent(Ground.self, forKey: .ground)
        from = try? c.decodeIfPresent(ReportOrigin.self, forKey: .from)
    }
}

/// Body of `POST /api/crew/report` when the crew lead closes one.
public struct HandleRequest: Codable, Sendable, Equatable {
    public let place: String
    public let date: String
    public let action: String
    public let id: Int
    public let note: String

    public init(place: String, date: String, id: Int, note: String) {
        self.place = place
        self.date = date
        self.action = "handle"
        self.id = id
        self.note = note
    }
}

/// Reply to a handle: `{id, status: "handled"}`.
public struct HandleReceipt: Codable, Sendable, Equatable {
    public let status: String

    public init(status: String) { self.status = status }
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
        handledNote = try? c.decodeIfPresent(String.self, forKey: .handledNote)
        evidence = try? c.decodeIfPresent(Evidence.self, forKey: .evidence)
    }
}

extension KeyedDecodingContainer {
    /// An id sent as a string or as a number, read as a string.
    func decodeFlexibleID(forKey key: Key) throws -> String {
        if let s = try? decode(String.self, forKey: key) { return s }
        return String(try decode(Int.self, forKey: key))
    }
}

/// The 30-minute ladder: a report the crew lead has not fixed in this long can go further.
public enum ReportClock {
    public static let escalateAfterMinutes = 30

    /// Parses the server's ISO timestamps, with or without fractional seconds.
    public static func date(_ iso: String) -> Date? {
        let full = ISO8601DateFormatter()
        full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = full.date(from: iso) { return d }
        return ISO8601DateFormatter().date(from: iso)
    }

    /// Whole minutes since the report was made, never negative.
    public static func minutesWaiting(since iso: String, now: Date) -> Int? {
        date(iso).map { max(0, Int(now.timeIntervalSince($0) / 60)) }
    }

    /// Minutes until it can be escalated, 0 once it can.
    public static func minutesUntilEscalation(since iso: String, now: Date) -> Int? {
        minutesWaiting(since: iso, now: now).map { max(0, escalateAfterMinutes - $0) }
    }
}

/// `GET /api/crew/complaint?report=`: a Cal/OSHA complaint drafted from a report's evidence.
/// The worker fills the [brackets] and files it themselves; the app sends nothing.
public struct ComplaintDraft: Codable, Sendable, Equatable {
    public let complaint: String
    public let fileAt: URL?
    public let rules: String?
    /// Where it can be filed: the place's state plan first, then Federal OSHA.
    public let agencies: [Agency]?

    public init(complaint: String, fileAt: URL?, rules: String?, agencies: [Agency]? = nil) {
        self.complaint = complaint
        self.fileAt = fileAt
        self.rules = rules
        self.agencies = agencies
    }

    enum CodingKeys: String, CodingKey {
        case complaint, rules, agencies
        case fileAt = "file_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        complaint = try c.decode(String.self, forKey: .complaint)
        fileAt = try? c.decodeIfPresent(URL.self, forKey: .fileAt)
        rules = try? c.decodeIfPresent(String.self, forKey: .rules)
        agencies = try? c.decodeIfPresent([Agency].self, forKey: .agencies)
    }
}

/// An agency that takes worker safety complaints.
public struct Agency: Codable, Sendable, Equatable, Hashable {
    public let name: String
    public let url: URL
    public let how: String?

    public init(name: String, url: URL, how: String?) {
        self.name = name
        self.url = url
        self.how = how
    }
}
