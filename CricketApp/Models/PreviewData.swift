import Foundation

// MARK: - Preview Data

/// Rich sample data for SwiftUI previews and graceful empty-state demos.
enum PreviewData {
    static let ballEvents = [
        BallEvent(over: 18.1, ballLabel: "18.1", text: "Driven through extra cover with perfect timing.", runs: 4, type: .four),
        BallEvent(over: 18.2, ballLabel: "18.2", text: "Short ball pulled deep into the stand.", runs: 6, type: .six),
        BallEvent(over: 18.3, ballLabel: "18.3", text: "Defended back to the bowler.", runs: 0, type: .dot),
        BallEvent(over: 18.4, ballLabel: "18.4", text: "Slower ball, outside off stump.", runs: 1, type: .wide),
        BallEvent(over: 18.5, ballLabel: "18.5", text: "Edge taken cleanly at slip.", runs: 0, type: .wicket)
    ]

    static let liveMatch = Match(
        id: 1001,
        fixtureId: 1001,
        title: "India tour of Australia",
        competition: "ODI Series",
        competitionImageURL: nil,
        venue: "Melbourne Cricket Ground",
        startDate: .now,
        fixtureDate: Calendar.current.startOfDay(for: .now),
        state: .live,
        homeTeam: Team(name: "Australia", shortName: "AUS", score: Score(runs: 268, wickets: 6, overs: 42.3)),
        awayTeam: Team(name: "India", shortName: "IND", score: Score(runs: 242, wickets: 5, overs: 39.4)),
        toss: "India won the toss and elected to field",
        status: "India need 27 from 62 balls",
        gameStatus: "Live",
        isCompleted: false,
        isLive: true,
        target: 269,
        currentRunRate: 6.10,
        requiredRunRate: 2.61,
        winningProbability: 62,
        partnership: "Rahul / Pandya 74 (68)",
        lastWicket: "Kohli c Smith b Starc 88",
        battingTeamName: "India",
        bowlingTeamName: "Australia",
        currentInningNumber: 2,
        recentBalls: ballEvents
    )

    static let upcomingMatches = [
        Match(
            id: 1002,
            fixtureId: 1002,
            title: "The Ashes",
            competition: "Test",
            competitionImageURL: nil,
            venue: "Lord's",
            startDate: Calendar.current.date(byAdding: .day, value: 1, to: .now),
            fixtureDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)),
            state: .upcoming,
            homeTeam: Team(name: "England", shortName: "ENG"),
            awayTeam: Team(name: "Australia", shortName: "AUS"),
            toss: nil,
            status: "Starts tomorrow",
            gameStatus: "Fixture",
            isCompleted: false,
            isLive: false,
            target: nil,
            currentRunRate: nil,
            requiredRunRate: nil,
            winningProbability: nil,
            partnership: nil,
            lastWicket: nil,
            battingTeamName: nil,
            bowlingTeamName: nil,
            currentInningNumber: 1,
            recentBalls: []
        ),
        Match(
            id: 1003,
            fixtureId: 1003,
            title: "T20 Tri-Series",
            competition: "T20",
            competitionImageURL: nil,
            venue: "Eden Gardens",
            startDate: Calendar.current.date(byAdding: .day, value: 2, to: .now),
            fixtureDate: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: .now)),
            state: .upcoming,
            homeTeam: Team(name: "Pakistan", shortName: "PAK"),
            awayTeam: Team(name: "South Africa", shortName: "SA"),
            toss: nil,
            status: "Fixture confirmed",
            gameStatus: "Fixture",
            isCompleted: false,
            isLive: false,
            target: nil,
            currentRunRate: nil,
            requiredRunRate: nil,
            winningProbability: nil,
            partnership: nil,
            lastWicket: nil,
            battingTeamName: nil,
            bowlingTeamName: nil,
            currentInningNumber: 1,
            recentBalls: []
        )
    ]

    static let scorecard = Scorecard(
        id: 1001,
        matchSummary: "India need 27 runs from 62 balls with 5 wickets remaining.",
        batting: [
            BattingRow(playerName: "KL Rahul", dismissal: "not out", runs: 64, balls: 71, fours: 5, sixes: 1, strikeRate: 90.14),
            BattingRow(playerName: "Hardik Pandya", dismissal: "not out", runs: 42, balls: 36, fours: 3, sixes: 2, strikeRate: 116.67)
        ],
        bowling: [
            BowlingRow(playerName: "Mitchell Starc", overs: 8.0, maidens: 0, runs: 46, wickets: 2, economy: 5.75),
            BowlingRow(playerName: "Adam Zampa", overs: 9.4, maidens: 0, runs: 58, wickets: 1, economy: 6.00)
        ],
        extras: "14 (lb 4, w 9, nb 1)",
        fallOfWickets: [
            FallOfWicket(score: "36/1", playerName: "Rohit Sharma", over: 6.2),
            FallOfWicket(score: "168/4", playerName: "Virat Kohli", over: 31.5)
        ],
        partnerships: [
            Partnership(batters: "KL Rahul / Hardik Pandya", runs: 74, balls: 68)
        ],
        currentPartnership: Partnership(batters: "KL Rahul / Hardik Pandya", runs: 74, balls: 68),
        lastWicket: FallOfWicket(score: "168/4", playerName: "Virat Kohli", over: 31.5),
        currentRunRate: 6.10,
        requiredRunRate: 2.61,
        battingTeamName: "India",
        bowlingTeamName: "Australia",
        innings: [
            ScorecardInnings(
                inningNumber: 1,
                batting: [
                    BattingRow(playerName: "KL Rahul", dismissal: "not out", runs: 64, balls: 71, fours: 5, sixes: 1, strikeRate: 90.14),
                    BattingRow(playerName: "Hardik Pandya", dismissal: "not out", runs: 42, balls: 36, fours: 3, sixes: 2, strikeRate: 116.67)
                ],
                bowling: [
                    BowlingRow(playerName: "Mitchell Starc", overs: 8.0, maidens: 0, runs: 46, wickets: 2, economy: 5.75),
                    BowlingRow(playerName: "Adam Zampa", overs: 9.4, maidens: 0, runs: 58, wickets: 1, economy: 6.00)
                ],
                extras: "14 (lb 4, w 9, nb 1)",
                fallOfWickets: [FallOfWicket(score: "36/1", playerName: "Rohit Sharma", over: 6.2)],
                partnerships: [Partnership(batters: "KL Rahul / Hardik Pandya", runs: 74, balls: 68)],
                battingTeamName: "India",
                bowlingTeamName: "Australia"
            )
        ]
    )

    static let rankings = [
        RankingEntry(rank: 1, name: "Babar Azam", country: "PAK", rating: 824, movement: 1),
        RankingEntry(rank: 2, name: "Shubman Gill", country: "IND", rating: 801, movement: -1),
        RankingEntry(rank: 3, name: "Rassie van der Dussen", country: "SA", rating: 768, movement: nil)
    ]
}
