import Foundation

// MARK: - Batting Row

/// Batting line item for a scorecard innings.
struct BattingRow: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let playerName: String
    let dismissal: String
    let runs: Int
    let balls: Int
    let fours: Int
    let sixes: Int
    let strikeRate: Double

    init(id: String = UUID().uuidString, playerName: String, dismissal: String, runs: Int, balls: Int, fours: Int, sixes: Int, strikeRate: Double) {
        self.id = id
        self.playerName = playerName
        self.dismissal = dismissal
        self.runs = runs
        self.balls = balls
        self.fours = fours
        self.sixes = sixes
        self.strikeRate = strikeRate
    }
}

// MARK: - Bowling Row

/// Bowling line item for a scorecard innings.
struct BowlingRow: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let playerName: String
    let overs: Double
    let maidens: Int
    let runs: Int
    let wickets: Int
    let economy: Double

    init(id: String = UUID().uuidString, playerName: String, overs: Double, maidens: Int, runs: Int, wickets: Int, economy: Double) {
        self.id = id
        self.playerName = playerName
        self.overs = overs
        self.maidens = maidens
        self.runs = runs
        self.wickets = wickets
        self.economy = economy
    }
}

// MARK: - Fall Of Wicket

/// Fall of wicket event in an innings.
struct FallOfWicket: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let score: String
    let playerName: String
    let over: Double

    init(id: String = UUID().uuidString, score: String, playerName: String, over: Double) {
        self.id = id
        self.score = score
        self.playerName = playerName
        self.over = over
    }
}

// MARK: - Partnership

/// Partnership summary for a batting pair.
struct Partnership: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let batters: String
    let runs: Int
    let balls: Int

    init(id: String = UUID().uuidString, batters: String, runs: Int, balls: Int) {
        self.id = id
        self.batters = batters
        self.runs = runs
        self.balls = balls
    }
}

// MARK: - Scorecard

/// Full scorecard surface model.
struct Scorecard: Identifiable, Hashable, Sendable, Codable {
    let id: Int
    let matchSummary: String
    let batting: [BattingRow]
    let bowling: [BowlingRow]
    let extras: String
    let fallOfWickets: [FallOfWicket]
    let partnerships: [Partnership]
    let currentPartnership: Partnership?
    let lastWicket: FallOfWicket?
    let currentRunRate: Double?
    let requiredRunRate: Double?
    let battingTeamName: String?
    let bowlingTeamName: String?
    let innings: [ScorecardInnings]

    /// Fingerprint used to detect score changes without full UI reload.
    var scoreSignature: String {
        let battingSignature = batting.map { "\($0.playerName):\($0.runs):\($0.balls)" }.joined(separator: "|")
        let wicketSignature = fallOfWickets.map(\.score).joined(separator: "|")
        let partnershipSignature = currentPartnership.map { "\($0.batters):\($0.runs)" } ?? ""
        let inningsSignature = innings.map { "\($0.inningNumber):\($0.batting.map(\.runs).reduce(0, +))" }.joined(separator: "|")
        return "\(battingSignature)#\(wicketSignature)#\(partnershipSignature)#\(inningsSignature)"
    }
}

// MARK: - Innings Scorecard

/// A complete batting/bowling snapshot for one innings. Matches can contain one to four innings.
struct ScorecardInnings: Identifiable, Hashable, Sendable, Codable {
    let inningNumber: Int
    let batting: [BattingRow]
    let bowling: [BowlingRow]
    let extras: String
    let fallOfWickets: [FallOfWicket]
    let partnerships: [Partnership]
    let battingTeamName: String?
    let bowlingTeamName: String?

    var id: Int { inningNumber }

    var title: String {
        let team = battingTeamName?.replacingOccurrences(of: " Men", with: "").replacingOccurrences(of: " Women", with: "") ?? "Innings"
        return "\(team) · Innings \(inningNumber)"
    }
}
