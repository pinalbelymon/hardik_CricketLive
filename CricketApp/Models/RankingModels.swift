import Foundation

// MARK: - Cricket Format

/// Supported ranking formats from the Cricnet endpoint.
enum CricketFormat: String, CaseIterable, Identifiable, Sendable {
    case test = "Test"
    case odi = "ODI"
    case t20 = "T20"

    var id: String { rawValue }
}

// MARK: - Ranking Category

/// Supported player and team ranking categories.
enum RankingCategory: String, CaseIterable, Identifiable, Sendable {
    case batting = "Batsman"
    case bowling = "Bowler"
    case allRounder = "All-Rounder"
    case team = "Team"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .batting:
            "Batting"
        case .bowling:
            "Bowling"
        case .allRounder:
            "All Rounder"
        case .team:
            "Team"
        }
    }
}

// MARK: - Ranking Entry

/// Normalized ranking row from Cricnet.
struct RankingEntry: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let rank: Int
    let name: String
    let country: String
    let rating: Int
    let movement: Int?
    let imageURL: URL?

    init(id: String = UUID().uuidString, rank: Int, name: String, country: String, rating: Int, movement: Int? = nil, imageURL: URL? = nil) {
        self.id = id
        self.rank = rank
        self.name = name
        self.country = country
        self.rating = rating
        self.movement = movement
        self.imageURL = imageURL
    }
}
