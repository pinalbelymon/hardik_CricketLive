import Foundation

// MARK: - Cricket Australia Mapper

enum CricketAUMapper {
    static func matches(from root: JSONValue, isBackward: Bool) -> [Match] {
        guard let top = root.objectValue,
              let dateGroups = top["compDateFixtures"]?.arrayValue else {
            return []
        }

        var results: [Match] = []
        var seenFixtureIds = Set<Int>()

        for dateGroup in dateGroups {
            guard let dateObject = dateGroup.objectValue,
                  let competitionGroups = dateObject["competitionFixtures"]?.arrayValue else {
                continue
            }

            let fixtureDate = parseFixtureDate(dateObject.string(for: ["startDate"]))

            for competitionGroup in competitionGroups {
                guard let competitionObject = competitionGroup.objectValue,
                      let fixtures = competitionObject["fixtures"]?.arrayValue else {
                    continue
                }

                for fixture in fixtures {
                    guard let fixtureObject = fixture.objectValue,
                          let match = makeMatch(from: fixtureObject, isBackward: isBackward, fixtureDate: fixtureDate),
                          seenFixtureIds.insert(match.fixtureId).inserted else {
                        continue
                    }
                    results.append(match)
                }
            }
        }

        return results.sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
    }

    static func scorecard(from root: JSONValue, fixtureId: Int) -> Scorecard {
        guard let top = root.objectValue,
              let fixture = top["fixture"]?.objectValue else {
            return emptyScorecard(fixtureId: fixtureId)
        }

        let players = playerLookup(from: top["players"]?.arrayValue ?? [])
        let homeTeam = team(from: fixture["homeTeam"]?.objectValue)
        let awayTeam = team(from: fixture["awayTeam"]?.objectValue)
        let innings = fixture["innings"]?.arrayValue?.compactMap { $0.objectValue } ?? []
        let currentInning = innings.max { ($0.int(for: ["inningNumber"]) ?? 0) < ($1.int(for: ["inningNumber"]) ?? 0) }
            ?? innings.last
        let inningsScorecards = scorecardInnings(from: innings, players: players, homeTeam: homeTeam, awayTeam: awayTeam)

        let battingTeamId = currentInning?.int(for: ["battingTeamId"])
        let bowlingTeamId = currentInning?.int(for: ["bowlingTeamId"])
        let battingTeam = teamName(for: battingTeamId, homeTeam: homeTeam, awayTeam: awayTeam)
        let bowlingTeam = teamName(for: bowlingTeamId, homeTeam: homeTeam, awayTeam: awayTeam)

        let batting = battingRows(from: currentInning?["batsmen"]?.arrayValue ?? [], players: players)
        let bowling = bowlingRows(from: currentInning?["bowlers"]?.arrayValue ?? [], players: players)
        let fallOfWickets = fallOfWickets(from: currentInning?["wickets"]?.arrayValue ?? [], players: players)
        let partnership = partnership(from: currentInning?["partnership"]?.objectValue, players: players)
        let extras = extrasText(from: currentInning)
        let summary = fixture.string(for: ["resultText", "gameStatus"])
            ?? currentInning?.string(for: ["status"]) ?? "Scorecard updates will appear here."

        return Scorecard(
            id: fixtureId,
            matchSummary: summary,
            batting: batting,
            bowling: bowling,
            extras: extras,
            fallOfWickets: fallOfWickets,
            partnerships: partnership.map { [$0] } ?? [],
            currentPartnership: partnership,
            lastWicket: fallOfWickets.last,
            currentRunRate: currentInning?.double(for: ["currentRunRate"]),
            requiredRunRate: currentInning?.double(for: ["requiredRunRate"]),
            battingTeamName: battingTeam,
            bowlingTeamName: bowlingTeam,
            innings: inningsScorecards
        )
    }

    static func comments(from root: JSONValue) -> [BallEvent] {
        guard let top = root.objectValue else {
            return []
        }

        let innings = top["innings"]?.arrayValue?.compactMap { $0.objectValue } ?? []
        let currentInning = innings.max { ($0.int(for: ["inningNumber"]) ?? 0) < ($1.int(for: ["inningNumber"]) ?? 0) }
            ?? innings.last

        guard let inningObject = currentInning,
              let overs = inningObject["overs"]?.arrayValue else {
            return []
        }

        var events: [BallEvent] = []

        for overValue in overs {
            guard let overObject = overValue.objectValue,
                  let overNumber = overObject.int(for: ["overNumber"]),
                  let balls = overObject["balls"]?.arrayValue else {
                continue
            }

            for ballValue in balls {
                guard let ballObject = ballValue.objectValue,
                      let comments = ballObject["comments"]?.arrayValue else {
                    continue
                }

                let apiBallNumber = ballObject.int(for: ["ballNumber"]) ?? 0
                let completedOvers = max(0, overNumber - 1)
                let ballLabel = String(format: "%d.%d", completedOvers, apiBallNumber)
                let isWicket = ballObject["isWicket"]?.boolValue ?? false
                let timestamp = parseDate(ballObject.string(for: ["ballDateTime"]))
                let ballDateKey = ballObject.string(for: ["ballDateTime"]) ?? UUID().uuidString

                for commentValue in comments {
                    guard let commentObject = commentValue.objectValue,
                          let message = commentObject.string(for: ["message", "Message", "commentText"]) else {
                        continue
                    }

                    let commentType = commentObject.string(for: ["commentTypeId", "CommentTypeId"]) ?? ""
                    if commentType == "EndOfOver" {
                        continue
                    }

                    let eventType = eventType(
                        commentType: commentType,
                        runs: ballObject.int(for: ["runs", "runsScored", "teamRuns"]) ?? 0,
                        isWicket: isWicket,
                        ballObject: ballObject
                    )

                    let runs = runsForDisplay(from: ballObject, eventType: eventType)

                    events.append(
                        BallEvent(
                            id: "\(overNumber)-\(ballDateKey)-\(commentType)",
                            over: Double(completedOvers) + (Double(apiBallNumber) / 10.0),
                            ballLabel: ballLabel,
                            text: message,
                            runs: runs,
                            type: eventType,
                            timestamp: timestamp
                        )
                    )
                }
            }
        }

        return events.sorted { lhs, rhs in
            if lhs.over != rhs.over {
                return lhs.over > rhs.over
            }
            return BallEvent.chronologicalDescending(lhs, rhs)
        }
    }

    static func match(from scorecardRoot: JSONValue, fixtureId: Int) -> Match? {
        guard let top = scorecardRoot.objectValue,
              let fixture = top["fixture"]?.objectValue else {
            return nil
        }

        return makeMatch(from: fixture, isBackward: false, fixtureIdOverride: fixtureId)
    }

    // MARK: - Fixture Parsing

    private static func makeMatch(
        from fixture: [String: JSONValue],
        isBackward: Bool,
        fixtureIdOverride: Int? = nil,
        fixtureDate: Date? = nil
    ) -> Match? {
        guard let fixtureId = fixtureIdOverride ?? fixture.int(for: ["id", "fixtureId"]) else {
            return nil
        }

        let homeObject = fixture["homeTeam"]?.objectValue
        let awayObject = fixture["awayTeam"]?.objectValue
        let homeTeam = team(from: homeObject)
        let awayTeam = team(from: awayObject)
        let competitionObject = fixture["competition"]?.objectValue
        let venueObject = fixture["venue"]?.objectValue

        let innings = fixture["innings"]?.arrayValue?.compactMap { $0.objectValue } ?? []
        let currentInning = innings.max { ($0.int(for: ["inningNumber"]) ?? 0) < ($1.int(for: ["inningNumber"]) ?? 0) }
        let homeScore = score(for: homeTeam.id, in: innings)
        let awayScore = score(for: awayTeam.id, in: innings)

        let homeTeamWithScore = Team(
            id: homeTeam.id,
            name: homeTeam.name,
            shortName: homeTeam.shortName,
            logoURL: homeTeam.logoURL,
            score: homeScore
        )
        let awayTeamWithScore = Team(
            id: awayTeam.id,
            name: awayTeam.name,
            shortName: awayTeam.shortName,
            logoURL: awayTeam.logoURL,
            score: awayScore
        )

        let gameStatus = fixture.string(for: ["gameStatus"]) ?? ""
        let isCompleted = fixture["isCompleted"]?.boolValue ?? false
        let isLive = fixture["isLive"]?.boolValue ?? false
        let isInProgress = fixture["isInProgress"]?.boolValue ?? false
        let state = matchState(isLive: isLive || isInProgress, isCompleted: isCompleted, gameStatus: gameStatus, isBackward: isBackward)

        let battingTeamId = currentInning?.int(for: ["battingTeamId"])
        let bowlingTeamId = currentInning?.int(for: ["bowlingTeamId"])
        let players = playerLookup(from: fixture["players"]?.arrayValue ?? [])
        let partnership = partnership(from: currentInning?["partnership"]?.objectValue, players: players)
        let lastWicket = fallOfWickets(from: currentInning?["wickets"]?.arrayValue ?? [], players: players).last

        let venueName = [venueObject?.string(for: ["name"]), venueObject?.string(for: ["city"])].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")
        let target = targetRuns(innings: innings, currentInning: currentInning)

        return Match(
            id: fixtureId,
            fixtureId: fixtureId,
            title: fixture.string(for: ["name"]) ?? "\(homeTeam.name) vs \(awayTeam.name)",
            competition: competitionObject?.string(for: ["name"]) ?? fixture.string(for: ["gameType"]) ?? "Cricket",
            competitionImageURL: url(from: competitionObject?.string(for: ["imageUrl"])),
            venue: venueName.isEmpty ? "Venue TBC" : venueName,
            startDate: parseFixtureStartDateTime(fixture.string(for: ["startDateTime"]), venue: venueObject),
            fixtureDate: fixtureDate,
            state: state,
            homeTeam: homeTeamWithScore,
            awayTeam: awayTeamWithScore,
            toss: fixture.string(for: ["tossResult"]),
            status: fixture.string(for: ["resultText"]) ?? gameStatus,
            gameStatus: gameStatus,
            isCompleted: isCompleted,
            isLive: isLive || isInProgress,
            target: target,
            currentRunRate: currentInning?.double(for: ["currentRunRate"]),
            requiredRunRate: currentInning?.double(for: ["requiredRunRate"]),
            winningProbability: nil,
            partnership: partnership.map { "\($0.batters): \($0.runs) (\($0.balls))" },
            lastWicket: lastWicket.map { "\($0.score) \($0.playerName)" },
            battingTeamName: teamName(for: battingTeamId, homeTeam: homeTeam, awayTeam: awayTeam),
            bowlingTeamName: teamName(for: bowlingTeamId, homeTeam: homeTeam, awayTeam: awayTeam),
            currentInningNumber: currentInning?.int(for: ["inningNumber"]) ?? 1,
            recentBalls: []
        )
    }

    // MARK: - Helpers

    private static func team(from object: [String: JSONValue]?) -> Team {
        guard let object else {
            return Team(name: "Team", shortName: "TBD")
        }

        let id = object.int(for: ["id"]).map(String.init) ?? object.string(for: ["name"]) ?? UUID().uuidString
        return Team(
            id: id,
            name: object.string(for: ["name", "nameOverride"]) ?? "Team",
            shortName: object.string(for: ["shortName"]) ?? String((object.string(for: ["name"]) ?? "T").prefix(3)).uppercased(),
            logoURL: url(from: object.string(for: ["logoUrl", "teambadgeImageUrl"]))
        )
    }

    private static func teamName(for teamId: Int?, homeTeam: Team, awayTeam: Team) -> String? {
        guard let teamId else { return nil }
        if homeTeam.id == String(teamId) { return homeTeam.name }
        if awayTeam.id == String(teamId) { return awayTeam.name }
        return nil
    }

    private static func score(for teamId: String, in innings: [[String: JSONValue]]) -> Score? {
        guard let teamNumericId = Int(teamId) else { return nil }

        let teamInnings = innings.filter { $0.int(for: ["battingTeamId"]) == teamNumericId }
        guard let latest = teamInnings.max(by: { ($0.int(for: ["inningNumber"]) ?? 0) < ($1.int(for: ["inningNumber"]) ?? 0) }) else {
            return nil
        }

        guard let runs = latest.int(for: ["runsScored", "totalRuns"]),
              let wickets = latest.int(for: ["numberOfWicketsFallen"]) else {
            return nil
        }

        return Score(
            runs: runs,
            wickets: wickets,
            overs: oversValue(from: latest.string(for: ["oversBowled"])) ?? 0
        )
    }

    private static func targetRuns(innings: [[String: JSONValue]], currentInning: [String: JSONValue]?) -> Int? {
        guard innings.count >= 2,
              let currentInning,
              (currentInning.int(for: ["inningNumber"]) ?? 1) >= 2,
              let firstInning = innings.first(where: { ($0.int(for: ["inningNumber"]) ?? 0) == 1 }),
              let firstRuns = firstInning.int(for: ["runsScored", "totalRuns"]) else {
            return nil
        }
        return firstRuns + 1
    }

    private static func playerLookup(from players: [JSONValue]) -> [Int: String] {
        var lookup: [Int: String] = [:]
        for player in players {
            guard let object = player.objectValue,
                  let id = object.int(for: ["id"]),
                  let name = object.string(for: ["displayName", "name"]) else {
                continue
            }
            lookup[id] = name
        }
        return lookup
    }

    private static func battingRows(from values: [JSONValue], players: [Int: String]) -> [BattingRow] {
        values.compactMap { value -> BattingRow? in
            guard let object = value.objectValue,
                  let playerId = object.int(for: ["playerId"]),
                  let runs = object.int(for: ["runsScored", "runs"]) else {
                return nil
            }

            let balls = object.int(for: ["ballsFaced", "balls"]) ?? 0
            let name = players[playerId] ?? "Player \(playerId)"
            let dismissal = object.string(for: ["dismissalText", "dismissal"]) ?? (object["isOut"]?.boolValue == true ? "out" : "not out")

            return BattingRow(
                id: "\(playerId)",
                playerName: name,
                dismissal: dismissal,
                runs: runs,
                balls: balls,
                fours: object.int(for: ["foursScored", "fours"]) ?? 0,
                sixes: object.int(for: ["sixesScored", "sixes"]) ?? 0,
                strikeRate: object.double(for: ["strikeRate"]) ?? (balls == 0 ? 0 : Double(runs) / Double(balls) * 100)
            )
        }
        .sorted { ($0.runs, $0.balls) > ($1.runs, $1.balls) }
    }

    private static func scorecardInnings(
        from innings: [[String: JSONValue]],
        players: [Int: String],
        homeTeam: Team,
        awayTeam: Team
    ) -> [ScorecardInnings] {
        innings.compactMap { inning in
            let inningNumber = inning.int(for: ["inningNumber"]) ?? 0
            guard inningNumber > 0 else { return nil }

            let battingTeam = teamName(for: inning.int(for: ["battingTeamId"]), homeTeam: homeTeam, awayTeam: awayTeam)
            let bowlingTeam = teamName(for: inning.int(for: ["bowlingTeamId"]), homeTeam: homeTeam, awayTeam: awayTeam)

            return ScorecardInnings(
                inningNumber: inningNumber,
                batting: battingRows(from: inning["batsmen"]?.arrayValue ?? [], players: players),
                bowling: bowlingRows(from: inning["bowlers"]?.arrayValue ?? [], players: players),
                extras: extrasText(from: inning),
                fallOfWickets: fallOfWickets(from: inning["wickets"]?.arrayValue ?? [], players: players),
                partnerships: partnership(from: inning["partnership"]?.objectValue, players: players).map { [$0] } ?? [],
                battingTeamName: battingTeam,
                bowlingTeamName: bowlingTeam
            )
        }
        .sorted { $0.inningNumber < $1.inningNumber }
    }

    private static func bowlingRows(from values: [JSONValue], players: [Int: String]) -> [BowlingRow] {
        values.compactMap { value -> BowlingRow? in
            guard let object = value.objectValue,
                  let playerId = object.int(for: ["playerId"]),
                  let wickets = object.int(for: ["wicketsTaken", "wickets"]) else {
                return nil
            }

            let overs = oversValue(from: object.string(for: ["oversBowled"])) ?? object.double(for: ["overs"]) ?? 0
            let runs = object.int(for: ["runsConceded", "runs"]) ?? 0
            let name = players[playerId] ?? "Player \(playerId)"

            return BowlingRow(
                id: "\(playerId)",
                playerName: name,
                overs: overs,
                maidens: object.int(for: ["maidensBowled", "maidens"]) ?? 0,
                runs: runs,
                wickets: wickets,
                economy: object.double(for: ["economy"]) ?? (overs == 0 ? 0 : Double(runs) / overs)
            )
        }
    }

    private static func fallOfWickets(from values: [JSONValue], players: [Int: String]) -> [FallOfWicket] {
        values.compactMap { value -> FallOfWicket? in
            guard let object = value.objectValue,
                  let playerId = object.int(for: ["playerId"]),
                  let runs = object.int(for: ["runs"]) else {
                return nil
            }

            let overDisplay = object.string(for: ["overBallDisplay", "over"]) ?? "0.0"
            let playerName = players[playerId] ?? "Player \(playerId)"
            let order = object.int(for: ["order"]) ?? 0

            return FallOfWicket(
                id: "\(order)-\(playerId)",
                score: "\(runs)/\(order)",
                playerName: playerName,
                over: oversValue(from: overDisplay) ?? 0
            )
        }
        .sorted { $0.over < $1.over }
    }

    private static func partnership(from object: [String: JSONValue]?, players: [Int: String]) -> Partnership? {
        guard let object,
              let firstId = object.int(for: ["firstPlayerId"]),
              let secondId = object.int(for: ["secondPlayerId"]),
              let runs = object.int(for: ["totalRunsScored", "runs"]) else {
            return nil
        }

        let firstName = players[firstId] ?? "Batter"
        let secondName = players[secondId] ?? "Batter"
        let balls = object.int(for: ["totalBallsFaced", "balls"]) ?? 0

        return Partnership(
            id: "\(firstId)-\(secondId)",
            batters: "\(firstName) / \(secondName)",
            runs: runs,
            balls: balls
        )
    }

    private static func extrasText(from inning: [String: JSONValue]?) -> String {
        guard let inning else { return "No extras listed" }
        let byes = inning.int(for: ["byesRuns"]) ?? 0
        let legByes = inning.int(for: ["legByesRuns"]) ?? 0
        let wides = inning.int(for: ["wideBalls"]) ?? 0
        let noBalls = inning.int(for: ["noBalls"]) ?? 0
        let penalties = inning.int(for: ["penalties"]) ?? 0
        let total = inning.int(for: ["totalExtras"]) ?? (byes + legByes + wides + noBalls + penalties)
        return "\(total) (b \(byes), lb \(legByes), w \(wides), nb \(noBalls), p \(penalties))"
    }

    private static func matchState(isLive: Bool, isCompleted: Bool, gameStatus: String, isBackward: Bool) -> MatchState {
        let normalized = gameStatus.lowercased()

        if isCompleted
            || normalized.contains("result")
            || normalized.contains("completed")
            || normalized.contains("abandon")
            || normalized.contains("cancel")
            || normalized.contains("no result") {
            return .completed
        }

        if isLive || normalized.contains("live") || normalized.contains("progress") || normalized.contains("innings") {
            return .live
        }

        return isBackward ? .completed : .upcoming
    }

    private static let wicketCommentTypes: Set<String> = [
        "Wicket",
        "Catch",
        "Bowled",
        "LBW",
        "RunOut",
        "Stumped",
        "HitWicket",
        "RetiredOut",
        "ObstructingField",
        "HandledBall"
    ]

    private static func runsForDisplay(from ballObject: [String: JSONValue], eventType: CommentaryEventType) -> Int {
        switch eventType {
        case .wide:
            if let wide = ballObject.int(for: ["runsWide"]), wide > 0 {
                return wide
            }
            if let conceded = ballObject.int(for: ["runsConceded"]), conceded > 0 {
                return conceded
            }
            return ballObject.int(for: ["teamRuns", "runs"]) ?? 1
        case .noBall:
            if let noBallRuns = ballObject.int(for: ["runs"]), noBallRuns > 0 {
                return noBallRuns
            }
            return ballObject.int(for: ["runsConceded", "teamRuns"]) ?? 1
        default:
            return ballObject.int(for: ["runs", "runsScored", "teamRuns"]) ?? 0
        }
    }

    private static func eventType(
        commentType: String,
        runs: Int,
        isWicket: Bool,
        ballObject: [String: JSONValue]
    ) -> CommentaryEventType {
        if isWicket || wicketCommentTypes.contains(commentType) {
            return .wicket
        }

        switch commentType {
        case "DotBall":
            return .dot
        case "Four":
            return .four
        case "Six":
            return .six
        case "Wide":
            return .wide
        case "NoBall", "NoBallBye", "NoBallLegBye":
            return .noBall
        case "One", "Two", "Three", "Five", "Seven", "Eight", "Nine":
            return .run
        default:
            break
        }

        if ballObject["isWide"]?.boolValue == true {
            return .wide
        }
        if ballObject["isNoBall"]?.boolValue == true {
            return .noBall
        }

        switch runs {
        case 6:
            return .six
        case 4:
            return .four
        case 0:
            return .dot
        default:
            return .run
        }
    }

    private static func oversValue(from value: String?) -> Double? {
        guard let value, value.isEmpty == false else { return nil }
        let parts = value.split(separator: ".")
        guard let whole = parts.first.flatMap({ Double($0) }) else { return nil }
        let fractional = parts.count > 1 ? (Double(parts[1]) ?? 0) / 10.0 : 0
        return whole + fractional
    }

    private static func parseDate(_ value: String?) -> Date? {
        parseInstantDate(value)
    }

    /// Parses fixture kickoff times. Cricket Australia often sends venue local wall-clock with a trailing `Z`.
    private static func parseFixtureStartDateTime(_ value: String?, venue: [String: JSONValue]?) -> Date? {
        guard let value, value.isEmpty == false else { return nil }

        if value.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) != nil {
            return parseInstantDate(value)
        }

        let venueTimeZone = VenueTimeZone.timeZone(for: venue)
        let stripped = value.hasSuffix("Z") ? String(value.dropLast()) : value

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = venueTimeZone

        if let venueLocal = formatter.date(from: stripped) {
            return venueLocal
        }

        return parseInstantDate(value)
    }

    private static func parseInstantDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }

        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value)
    }

    private static func parseFixtureDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: value)
    }

    private static func url(from value: String?) -> URL? {
        guard let value, value.isEmpty == false else { return nil }
        return URL(string: value)
    }

    private static func emptyScorecard(fixtureId: Int) -> Scorecard {
        Scorecard(
            id: fixtureId,
            matchSummary: "Scorecard unavailable",
            batting: [],
            bowling: [],
            extras: "No extras listed",
            fallOfWickets: [],
            partnerships: [],
            currentPartnership: nil,
            lastWicket: nil,
            currentRunRate: nil,
            requiredRunRate: nil,
            battingTeamName: nil,
            bowlingTeamName: nil,
            innings: []
        )
    }
}
