import Foundation

// MARK: - Commentary Event Type

/// Visual event categories for ball-by-ball commentary.
enum CommentaryEventType: String, CaseIterable, Sendable, Codable {
    case four
    case six
    case wicket
    case dot
    case wide
    case noBall
    case run
    case note

    var label: String {
        switch self {
        case .four:
            "Four"
        case .six:
            "Six"
        case .wicket:
            "Wicket"
        case .dot:
            "Dot"
        case .wide:
            "Wide"
        case .noBall:
            "No Ball"
        case .run:
            "Run"
        case .note:
            "Note"
        }
    }

    var symbolName: String {
        switch self {
        case .four:
            "cricket.ball.fill"
        case .six:
            "paperplane.fill"
        case .wicket:
            "xmark.octagon.fill"
        case .dot:
            "circle.fill"
        case .wide:
            "exclamationmark.circle.fill"
        case .noBall:
            "flag.fill"
        case .run:
            "figure.run"
        case .note:
            "text.bubble.fill"
        }
    }
}

// MARK: - Ball Event

/// Normalized ball event shown in live strips and commentary groups.
struct BallEvent: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let over: Double
    let ballLabel: String
    let text: String
    let runs: Int
    let type: CommentaryEventType
    let timestamp: Date?

    init(
        id: String = UUID().uuidString,
        over: Double,
        ballLabel: String,
        text: String,
        runs: Int,
        type: CommentaryEventType,
        timestamp: Date? = nil
    ) {
        self.id = id
        self.over = over
        self.ballLabel = ballLabel
        self.text = text
        self.runs = runs
        self.type = type
        self.timestamp = timestamp
    }

    /// Completed full overs before this ball (`0` for deliveries `0.1`–`0.6`).
    var completedOversBeforeBall: Int {
        Int(over.rounded(.down))
    }

    /// 1-based over index for section headers (`Over 1`, `Over 50`).
    var displayOverNumber: Int {
        completedOversBeforeBall + 1
    }

    /// Incremental commentary API cursor (matches feed `overNumber`).
    var apiOverNumber: Int {
        displayOverNumber
    }

    /// Wide and no-ball deliveries do not consume a legal ball in the over.
    var isExtraDelivery: Bool {
        type == .wide || type == .noBall
    }

    static func chronologicalAscending(_ lhs: BallEvent, _ rhs: BallEvent) -> Bool {
        let leftTime = lhs.timestamp ?? .distantPast
        let rightTime = rhs.timestamp ?? .distantPast
        if leftTime != rightTime {
            return leftTime < rightTime
        }
        return lhs.id < rhs.id
    }

    static func chronologicalDescending(_ lhs: BallEvent, _ rhs: BallEvent) -> Bool {
        chronologicalAscending(rhs, lhs)
    }
}

// MARK: - Commentary Group

/// Commentary items grouped by completed over for scannable presentation.
struct CommentaryOverGroup: Identifiable, Hashable, Sendable {
    let overNumber: Int
    let events: [BallEvent]

    var id: Int { overNumber }
}
