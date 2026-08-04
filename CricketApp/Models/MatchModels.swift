import Foundation

// MARK: - Match State

/// Broad lifecycle state used by fixtures and live screens.
enum MatchState: String, CaseIterable, Sendable, Codable {
    case live
    case upcoming
    case completed

    var title: String {
        switch self {
        case .live:
            "Live"
        case .upcoming:
            "Upcoming"
        case .completed:
            "Result"
        }
    }
}

// MARK: - Team

/// Cricket team identity and current score summary.
struct Team: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let name: String
    let shortName: String
    let logoURL: URL?
    let score: Score?

    init(id: String? = nil, name: String, shortName: String? = nil, logoURL: URL? = nil, score: Score? = nil) {
        self.name = name
        self.shortName = shortName ?? String(name.prefix(3)).uppercased()
        self.logoURL = logoURL
        self.score = score
        self.id = id ?? name.normalizedIdentifier
    }
}

// MARK: - Score

/// Compact innings score displayed throughout the app.
struct Score: Hashable, Sendable, Codable {
    let runs: Int
    let wickets: Int
    let overs: Double

    var displayText: String {
        "\(runs)/\(wickets)"
    }

    var overText: String {
        String(format: "%.1f ov", overs)
    }
}

// MARK: - Match

/// Normalized fixture or live match model independent from provider schemas.
struct Match: Identifiable, Hashable, Sendable, Codable {
    let id: Int
    let fixtureId: Int
    let title: String
    let competition: String
    let competitionImageURL: URL?
    let venue: String
    let startDate: Date?
    /// Calendar day from the fixtures API group, aligned with the user's timezone offset.
    let fixtureDate: Date?
    let state: MatchState
    let homeTeam: Team
    let awayTeam: Team
    let toss: String?
    let status: String
    let gameStatus: String
    let isCompleted: Bool
    let isLive: Bool
    let target: Int?
    let currentRunRate: Double?
    let requiredRunRate: Double?
    let winningProbability: Double?
    let partnership: String?
    let lastWicket: String?
    let battingTeamName: String?
    let bowlingTeamName: String?
    let currentInningNumber: Int
    let recentBalls: [BallEvent]

    var teamsText: String {
        "\(homeTeam.shortName) vs \(awayTeam.shortName)"
    }

    /// Best calendar day for fixtures filtering and grouping.
    var scheduleDay: Date? {
        if let fixtureDate {
            return fixtureDate
        }
        guard let startDate else { return nil }
        return Calendar.current.startOfDay(for: startDate)
    }

    func isScheduled(on date: Date) -> Bool {
        guard let scheduleDay else { return true }
        return Calendar.current.isDate(scheduleDay, inSameDayAs: date)
    }

    /// Local kickoff label for cards and detail screens.
    var displayScheduleLabel: String? {
        guard let startDate else { return nil }
        return DateFormatters.scheduleLabel(for: startDate, fixtureDate: fixtureDate, isLive: isLiveMatch)
    }

    var shouldPollLiveUpdates: Bool {
        // Finished / abandoned / upcoming matches must never poll.
        guard isCompleted == false,
              isTerminalStatus == false,
              state != .completed,
              state != .upcoming else {
            return false
        }

        if isLive || state == .live { return true }

        let normalized = gameStatus.lowercased()
        // Avoid bare "innings"/"progress" — completed summaries often include those words.
        return normalized.contains("live")
            || normalized.contains("in progress")
            || normalized.contains("inprogress")
    }

    /// Whether the match should display live UI treatment.
    var isLiveMatch: Bool {
        shouldPollLiveUpdates || state == .live
    }

    var isTerminalStatus: Bool {
        let normalized = gameStatus.lowercased()
        return normalized.contains("completed")
            || normalized.contains("result")
            || normalized.contains("abandon")
            || normalized.contains("cancel")
            || normalized.contains("no result")
            || normalized.contains("finished")
            || normalized.contains("ended")
    }
}

// MARK: - Fixture Filter

/// Calendar filter used by the fixtures screen.
enum FixtureFilter: String, CaseIterable, Identifiable, Sendable {
    case today = "Today"
    case upcoming = "Upcoming"
    case previous = "Previous"

    var id: String { rawValue }
}

// MARK: - Fixture Date Group

/// Fixtures grouped by calendar day for the fixtures screen.
struct FixtureDateGroup: Identifiable, Hashable, Sendable, Codable {
    let date: Date
    let title: String
    let matches: [Match]

    var id: String { title }
}

// MARK: - Identifier Helpers

private extension String {
    var normalizedIdentifier: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "")
    }
}
