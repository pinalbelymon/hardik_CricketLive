import Foundation

// MARK: - Rankings Service Protocol

/// Fetches ICC-style rankings from the Cricnet endpoint.
protocol RankingsServiceProtocol: Sendable {
    func rankings(format: CricketFormat, category: RankingCategory) async throws -> [RankingEntry]
}

// MARK: - Rankings Service

final class RankingsService: RankingsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func rankings(format: CricketFormat, category: RankingCategory) async throws -> [RankingEntry] {
        let requestBody = RankingRequestBody(catname: format.rawValue, subcatname: category.rawValue)
        let body = try JSONEncoder().encode(requestBody)
        let endpoint = Endpoint(
            baseURL: AppConstants.API.cricnetRankingsURL,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: body,
            timeout: 5
        )

        let envelope: CricnetRankingEnvelope = try await apiClient.send(endpoint, decoder: JSONDecoder())
        return RankingMapper.rankings(from: envelope.root)
    }
}

// MARK: - Ranking Request Body

private struct RankingRequestBody: Encodable {
    let catname: String
    let subcatname: String
}

// MARK: - Ranking Mapper

private enum RankingMapper {
    static func rankings(from root: JSONValue) -> [RankingEntry] {
        let entries = root.allObjects().compactMap { object -> RankingEntry? in
            guard let rank = object.int(for: ["Rank", "rank", "Position", "position"]),
                  let name = object.string(for: ["PlayerName", "playerName", "TeamName", "teamName", "Name", "name"]) else {
                return nil
            }

            return RankingEntry(
                id: object.string(for: ["Id", "id"]) ?? "\(rank)-\(name)",
                rank: rank,
                name: name,
                country: object.string(for: ["Country", "country", "Team", "team"]) ?? "",
                rating: object.int(for: ["Rating", "rating", "Points", "points"]) ?? 0,
                movement: object.int(for: ["Movement", "movement", "RankChange"]),
                imageURL: URL(string: object.string(for: ["Image", "image", "ImageURL", "imageUrl"]) ?? "")
            )
        }

        return entries.sorted { $0.rank < $1.rank }
    }
}
