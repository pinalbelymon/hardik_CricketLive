import Foundation

// MARK: - Dependency Container

/// Lightweight dependency graph for production services and previews.
@MainActor
struct DependencyContainer {
    let fixturesRepository: FixturesRepositoryProtocol
    let scorecardRepository: ScorecardRepositoryProtocol
    let commentaryRepository: CommentaryRepositoryProtocol
    let rankingsRepository: RankingsRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let updateRepository: UpdateRepositoryProtocol
    let adsRepository: AdsRepositoryProtocol
    let purchaseManager: PurchaseManager
    let adsManager: AdsManager

    static func live() -> DependencyContainer {
        let apiClient = APIClient()
        let cricketService = CricketAUService(apiClient: apiClient)
        let rankingsService = RankingsService(apiClient: apiClient)
        let settingsRepository = SettingsRepository()
        let updateService = AppUpdateService(apiClient: apiClient)
        let adsRepository = AdsRepository(
            configService: FirestoreAdConfigService(),
            mobileAdsService: MobileAdsService()
        )
        let purchaseManager = PurchaseManager()
        let adsManager = AdsManager(
            adsRepository: adsRepository,
            purchaseManager: purchaseManager
        )

        return DependencyContainer(
            fixturesRepository: FixturesRepository(cricketService: cricketService),
            scorecardRepository: ScorecardRepository(cricketService: cricketService),
            commentaryRepository: CommentaryRepository(cricketService: cricketService),
            rankingsRepository: RankingsRepository(service: rankingsService),
            settingsRepository: settingsRepository,
            updateRepository: UpdateRepository(service: updateService, settingsRepository: settingsRepository),
            adsRepository: adsRepository,
            purchaseManager: purchaseManager,
            adsManager: adsManager
        )
    }

    static func preview() -> DependencyContainer {
        let fixturesRepository = PreviewFixturesRepository()
        let scorecardRepository = PreviewScorecardRepository()
        let commentaryRepository = PreviewCommentaryRepository()
        let rankingsRepository = PreviewRankingsRepository()
        let settingsRepository = SettingsRepository()
        let adsRepository = PreviewAdsRepository()
        let purchaseManager = PurchaseManager()

        return DependencyContainer(
            fixturesRepository: fixturesRepository,
            scorecardRepository: scorecardRepository,
            commentaryRepository: commentaryRepository,
            rankingsRepository: rankingsRepository,
            settingsRepository: settingsRepository,
            updateRepository: PreviewUpdateRepository(),
            adsRepository: adsRepository,
            purchaseManager: purchaseManager,
            adsManager: AdsManager(adsRepository: adsRepository, purchaseManager: purchaseManager)
        )
    }
}

// MARK: - Preview Repositories

private final class PreviewFixturesRepository: FixturesRepositoryProtocol {
    func liveMatches() async throws -> RepositoryResult<[Match]> {
        RepositoryResult(value: [PreviewData.liveMatch], lastUpdated: .now, isFromCache: false)
    }

    func upcomingMatches(from date: Date) async throws -> RepositoryResult<[Match]> {
        RepositoryResult(value: PreviewData.upcomingMatches, lastUpdated: .now, isFromCache: false)
    }

    func previousMatches(from date: Date) async throws -> RepositoryResult<[Match]> {
        RepositoryResult(value: [PreviewData.liveMatch], lastUpdated: .now, isFromCache: false)
    }
}

private final class PreviewScorecardRepository: ScorecardRepositoryProtocol {
    func scorecard(fixtureId: Int, isLive: Bool) async throws -> RepositoryResult<Scorecard> {
        RepositoryResult(value: PreviewData.scorecard, lastUpdated: .now, isFromCache: false)
    }

    func matchSummary(fixtureId: Int) async throws -> RepositoryResult<Match?> {
        RepositoryResult(value: PreviewData.liveMatch, lastUpdated: .now, isFromCache: false)
    }
}

private final class PreviewCommentaryRepository: CommentaryRepositoryProtocol {
    func comments(fixtureId: Int, inningNumber: Int, lastOverNumber: Int?) async throws -> RepositoryResult<[BallEvent]> {
        RepositoryResult(value: PreviewData.ballEvents, lastUpdated: .now, isFromCache: false)
    }
}

private final class PreviewRankingsRepository: RankingsRepositoryProtocol {
    func rankings(format: CricketFormat, category: RankingCategory) async throws -> RepositoryResult<[RankingEntry]> {
        RepositoryResult(value: PreviewData.rankings, lastUpdated: .now, isFromCache: false)
    }
}

private final class PreviewUpdateRepository: UpdateRepositoryProtocol {
    func checkForUpdate() async throws -> AppUpdate? {
        nil
    }
}

private final class PreviewAdsRepository: AdsRepositoryProtocol {
    func loadConfiguration() async -> AdConfiguration {
        .disabled
    }

    func startAds() async {
    }
}
