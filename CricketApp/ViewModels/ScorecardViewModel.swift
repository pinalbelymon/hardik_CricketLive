import Foundation

// MARK: - Scorecard View Model

/// Loads scorecard details for a selected fixture with live polling when needed.
@MainActor
final class ScorecardViewModel: ObservableObject {
    @Published private(set) var scorecard: Scorecard?
    @Published private(set) var state: ViewState<Scorecard> = .idle
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var scoreSignature: String?

    private let fixtureId: Int
    private let isLive: Bool
    private let repository: ScorecardRepositoryProtocol
    private let lifecycleManager: AppLifecycleManager

    private var pollingTask: Task<Void, Never>?
    private var initialLoadTask: Task<Void, Never>?
    private var isScreenVisible = false

    init(
        fixtureId: Int,
        isLive: Bool,
        repository: ScorecardRepositoryProtocol,
        lifecycleManager: AppLifecycleManager = .shared
    ) {
        self.fixtureId = fixtureId
        self.isLive = isLive
        self.repository = repository
        self.lifecycleManager = lifecycleManager
    }

    deinit {
        initialLoadTask?.cancel()
        pollingTask?.cancel()
    }

    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    var isOffline: Bool { state.isOffline }

    func onAppear() {
        isScreenVisible = true
        initialLoadTask?.cancel()
        initialLoadTask = Task { await load(force: true) }
        startPollingIfNeeded()
    }

    func onDisappear() {
        isScreenVisible = false
        initialLoadTask?.cancel()
        initialLoadTask = nil
        pollingTask?.cancel()
        pollingTask = nil
    }

    func handleAppLifecycle(isActive: Bool) {
        guard isScreenVisible else { return }

        if isActive {
            Task { await load(force: true) }
            startPollingIfNeeded()
        } else {
            pollingTask?.cancel()
            pollingTask = nil
        }
    }

    func load(force: Bool = false) async {
        if force, let current = scorecard {
            state = .refreshing(current)
        } else if scorecard == nil {
            state = .loading
        }

        do {
            let result = try await BackgroundFetch.perform { [repository, fixtureId, isLive] in
                try await repository.scorecard(fixtureId: fixtureId, isLive: isLive)
            }
            applyScorecardIfChanged(result.value)
            lastUpdated = result.lastUpdated

            if result.isFromCache, let updated = result.lastUpdated {
                state = .offline(result.value, lastUpdated: updated)
            } else {
                state = .loaded(result.value)
            }
        } catch {
            if let current = scorecard, let updated = lastUpdated {
                state = .offline(current, lastUpdated: updated)
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func startPollingIfNeeded() {
        guard isLive, lifecycleManager.isActive, isScreenVisible else { return }

        pollingTask?.cancel()
        pollingTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.load(force: false)
            }
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
}
