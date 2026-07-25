import Foundation

// MARK: - Cricket Australia Service Protocol

/// Fetches fixtures, scorecards, and comments from Cricket.com.au.
protocol CricketAUServiceProtocol: Sendable {
    func fixtures(startDate: Date, isBackward: Bool, timeZone: TimeZone) async throws -> [Match]
    func scorecard(fixtureId: Int) async throws -> Scorecard
    func comments(fixtureId: Int, inningNumber: Int, overLimit: Int, lastOverNumber: Int?) async throws -> [BallEvent]
    func matchSummary(fixtureId: Int) async throws -> Match?
}

// MARK: - Cricket Australia Service

final class CricketAUService: CricketAUServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fixtures(startDate: Date, isBackward: Bool, timeZone: TimeZone = .current) async throws -> [Match] {
        let endpoint = Endpoint(
            baseURL: AppConstants.API.cricketAustraliaBaseURL,
            path: "fixturesdateformatted",
            queryItems: [
                URLQueryItem(name: "StartDateTime", value: DateFormatters.cricketAustraliaDateString(from: startDate, timeZone: timeZone)),
                URLQueryItem(name: "IsBackward", value: isBackward ? "true" : "false"),
                URLQueryItem(name: "TimeOffSetSec", value: String(timeZone.secondsFromGMT())),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "jsconfig", value: "eccn")
            ]
        )

        let envelope: CricketAUEnvelope = try await apiClient.send(endpoint, decoder: Self.decoder)
        return CricketAUMapper.matches(from: envelope.root, isBackward: isBackward)
    }

    func scorecard(fixtureId: Int) async throws -> Scorecard {
        let endpoint = Endpoint(
            baseURL: AppConstants.API.cricketAustraliaBaseURL,
            path: "scorecard",
            queryItems: [
                URLQueryItem(name: "FixtureId", value: String(fixtureId)),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "jsconfig", value: "eccn")
            ]
        )

        let envelope: CricketAUEnvelope = try await apiClient.send(endpoint, decoder: Self.decoder)
        return CricketAUMapper.scorecard(from: envelope.root, fixtureId: fixtureId)
    }

    func comments(fixtureId: Int, inningNumber: Int = 1, overLimit: Int = 50, lastOverNumber: Int? = nil) async throws -> [BallEvent] {
        var queryItems = [
            URLQueryItem(name: "FixtureId", value: String(fixtureId)),
            URLQueryItem(name: "InningNumber", value: String(inningNumber)),
            URLQueryItem(name: "OverLimit", value: String(overLimit)),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jsconfig", value: "eccn")
        ]

        if let lastOverNumber {
            queryItems.append(URLQueryItem(name: "LastOverNumber", value: String(lastOverNumber)))
        }

        let endpoint = Endpoint(
            baseURL: AppConstants.API.cricketAustraliaBaseURL,
            path: "comments",
            queryItems: queryItems
        )

        let envelope: CricketAUEnvelope = try await apiClient.send(endpoint, decoder: Self.decoder)
        return CricketAUMapper.comments(from: envelope.root)
    }

    func matchSummary(fixtureId: Int) async throws -> Match? {
        let endpoint = Endpoint(
            baseURL: AppConstants.API.cricketAustraliaBaseURL,
            path: "scorecard",
            queryItems: [
                URLQueryItem(name: "FixtureId", value: String(fixtureId)),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "jsconfig", value: "eccn")
            ]
        )

        let envelope: CricketAUEnvelope = try await apiClient.send(endpoint, decoder: Self.decoder)
        return CricketAUMapper.match(from: envelope.root, fixtureId: fixtureId)
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
