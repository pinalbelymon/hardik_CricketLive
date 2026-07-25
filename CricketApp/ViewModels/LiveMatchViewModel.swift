import Foundation

// MARK: - Live Match View Model

/// Refreshes live scorecard and commentary data using independent polling intervals.
@MainActor
final class LiveMatchViewModel: ObservableObject {
    @Published private(set) var match: Match
    @Published private(set) var scorecard: Scorecard?
    @Published private(set) var commentary: [BallEvent] = []
    @Published private(set) var state: ViewState<Match> = .loading
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var scoreSignature: String?

    private let scorecardRepository: ScorecardRepositoryProtocol
    private let commentaryRepository: CommentaryRepositoryProtocol
    private let lifecycleManager: AppLifecycleManager
    private let pollingController = LiveMatchPollingController()

    private var lastOverNumber: Int?
    private var loadTask: Task<Void, Never>?
    private var isScreenVisible = false

    init(
        match: Match,
        scorecardRepository: ScorecardRepositoryProtocol,
        commentaryRepository: CommentaryRepositoryProtocol,
        lifecycleManager: AppLifecycleManager = .shared
    ) {
        self.match = match
        self.scorecardRepository = scorecardRepository
        self.commentaryRepository = commentaryRepository
        self.lifecycleManager = lifecycleManager
        self.state = .loaded(match)
        commentary = match.recentBalls
    }

    deinit {
        loadTask?.cancel()
    }

    var errorMessage: String? { state.errorMessage }
    var isOffline: Bool { state.isOffline }

    func onAppear() {
        isScreenVisible = true
        startPollingIfNeeded()
        loadTask?.cancel()
        loadTask = Task { await refreshAll(force: true) }
    }

    func onDisappear() {
        isScreenVisible = false
        pollingController.stop()
        loadTask?.cancel()
    }

    func handleAppLifecycle(isActive: Bool) {
        guard isScreenVisible else { return }

        if isActive {
            Task { await refreshAll(force: true) }
            startPollingIfNeeded()
        } else {
            pollingController.stop()
        }
    }

    func refresh() async {
        await refreshAll(force: true)
    }

    private func startPollingIfNeeded() {
        guard match.shouldPollLiveUpdates, lifecycleManager.isActive else {
            pollingController.stop()
            return
        }

        pollingController.start(
            isLive: { @MainActor [weak self] in
                self?.match.shouldPollLiveUpdates ?? false
            },
            shouldStop: { @MainActor [weak self] in
                guard let self else { return true }
                return self.match.isTerminalStatus || self.match.isCompleted
            },
            isAppActive: { @MainActor [weak self] in
                self?.lifecycleManager.isActive ?? false
            },
            refreshScorecard: { @MainActor [weak self] in
                await self?.refreshScorecardAndSummary()
            },
            refreshCommentary: { @MainActor [weak self] in
                await self?.refreshCommentaryIncremental()
            }
        )
    }

    private func refreshAll(force: Bool) async {
        if force || scorecard == nil {
            state = scorecard == nil ? .loading : .refreshing(match)
        }

        await refreshScorecardAndSummary()
        await refreshCommentaryIncremental(forceFullLoad: force)

        if scorecard != nil || commentary.isEmpty == false {
            if case .offline = state {
                // Preserve offline state set by repository refresh.
            } else {
                state = .loaded(match)
            }
        } else if let message = state.errorMessage {
            state = .error(message)
        }
    }

    private func refreshScorecardAndSummary() async {
        let fixtureId = match.fixtureId
        let pollLive = match.shouldPollLiveUpdates
        let repository = scorecardRepository

        do {
            let (loadedScorecard, loadedSummary) = try await BackgroundFetch.perform {
                async let scorecardResult = repository.scorecard(fixtureId: fixtureId, isLive: pollLive)
                async let summaryResult = repository.matchSummary(fixtureId: fixtureId)
                return (try await scorecardResult, try await summaryResult)
            }

            applyScorecardIfChanged(loadedScorecard.value)
            if let updatedMatch = loadedSummary.value {
                match = mergeMatch(updatedMatch, preservingCommentaryFrom: match)
            }
            lastUpdated = loadedScorecard.lastUpdated ?? loadedSummary.lastUpdated

            if loadedScorecard.isFromCache || loadedSummary.isFromCache, let updated = lastUpdated {
                state = .offline(match, lastUpdated: updated)
            } else {
                state = .loaded(match)
            }

            if match.shouldPollLiveUpdates == false {
                pollingController.stop()
            }
        } catch {
            if let updated = lastUpdated {
                state = .offline(match, lastUpdated: updated)
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func refreshCommentaryIncremental(forceFullLoad: Bool = false) async {
        guard match.shouldPollLiveUpdates || forceFullLoad else { return }

        let fixtureId = match.fixtureId
        let inningNumber = match.currentInningNumber
        let incrementalOver = forceFullLoad ? nil : lastOverNumber
        let repository = commentaryRepository

        do {
            let events = try await BackgroundFetch.perform {
                try await repository.comments(
                    fixtureId: fixtureId,
                    inningNumber: inningNumber,
                    lastOverNumber: incrementalOver
                )
            }

            if forceFullLoad || lastOverNumber == nil {
                commentary = events.value
            } else if events.value.isEmpty == false {
                let existingIDs = Set(commentary.map(\.id))
                let newEvents = events.value.filter { existingIDs.contains($0.id) == false }
                commentary = newEvents + commentary
            }

            if let latestOver = commentary.map(\.apiOverNumber).max() {
                lastOverNumber = latestOver
            }

            match = mergeMatch(match, preservingCommentaryFrom: match)
        } catch {
            // Commentary failures should not replace an already loaded live screen.
        }
    }

    private func applyScorecardIfChanged(_ updated: Scorecard) {
        if scoreSignature != updated.scoreSignature {
            scorecard = updated
            scoreSignature = updated.scoreSignature
        } else if scorecard == nil {
            scorecard = updated
            scoreSignature = updated.scoreSignature
        }
    }

    private func mergeMatch(_ updated: Match, preservingCommentaryFrom previous: Match) -> Match {
        Match(
            id: updated.id,
            fixtureId: updated.fixtureId,
            title: updated.title,
            competition: updated.competition,
            competitionImageURL: updated.competitionImageURL,
            venue: updated.venue,
            startDate: updated.startDate,
            fixtureDate: updated.fixtureDate ?? previous.fixtureDate,
            state: updated.state,
            homeTeam: updated.homeTeam,
            awayTeam: updated.awayTeam,
            toss: updated.toss ?? previous.toss,
            status: updated.status,
            gameStatus: updated.gameStatus,
            isCompleted: updated.isCompleted,
            isLive: updated.isLive,
            target: updated.target ?? previous.target,
            currentRunRate: updated.currentRunRate ?? scorecard?.currentRunRate,
            requiredRunRate: updated.requiredRunRate ?? scorecard?.requiredRunRate,
            winningProbability: updated.winningProbability,
            partnership: updated.partnership ?? scorecard?.currentPartnership.map { "\($0.batters): \($0.runs) (\($0.balls))" },
            lastWicket: updated.lastWicket ?? scorecard?.lastWicket.map { "\($0.score) \($0.playerName)" },
            battingTeamName: updated.battingTeamName ?? scorecard?.battingTeamName,
            bowlingTeamName: updated.bowlingTeamName ?? scorecard?.bowlingTeamName,
            currentInningNumber: updated.currentInningNumber,
            recentBalls: commentary.prefix(12).map { $0 }
        )
    }
}
