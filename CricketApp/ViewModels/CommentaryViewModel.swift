import Foundation

// MARK: - Commentary View Model

/// Loads commentary with incremental updates and live polling.
@MainActor
final class CommentaryViewModel: ObservableObject {
    @Published private(set) var events: [BallEvent] = []
    @Published private(set) var state: ViewState<[BallEvent]> = .idle
    @Published private(set) var lastUpdated: Date?
    @Published var isPinnedToLatest = true

    let fixtureId: Int
    private let inningNumber: Int
    private let isLive: Bool
    private let repository: CommentaryRepositoryProtocol
    private let lifecycleManager: AppLifecycleManager

    private var lastOverNumber: Int?
    private var initialLoadTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private var isScreenVisible = false

    init(
        fixtureId: Int,
        inningNumber: Int,
        isLive: Bool,
        repository: CommentaryRepositoryProtocol,
        lifecycleManager: AppLifecycleManager = .shared
    ) {
        self.fixtureId = fixtureId
        self.inningNumber = inningNumber
        self.isLive = isLive
        self.repository = repository
        self.lifecycleManager = lifecycleManager
    }

    deinit {
        initialLoadTask?.cancel()
        pollingTask?.cancel()
    }

    var overGroups: [CommentaryOverGroup] {
        Dictionary(grouping: events, by: \.displayOverNumber)
            .map { CommentaryOverGroup(overNumber: $0.key, events: $0.value.sorted(by: BallEvent.chronologicalDescending)) }
            .sorted { $0.overNumber > $1.overNumber }
    }

    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    var latestEventID: String? { events.first?.id }

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
        // Finished / non-live matches: never poll or auto-refresh on resume.
        guard isLive else {
            pollingTask?.cancel()
            pollingTask = nil
            return
        }

        if isActive {
            Task { await load(force: true) }
            startPollingIfNeeded()
        } else {
            pollingTask?.cancel()
            pollingTask = nil
        }
    }

    func load(force: Bool = false) async {
        if force, events.isEmpty == false {
            state = .refreshing(events)
        } else if events.isEmpty {
            state = .loading
        }

        let cursor = force ? nil : lastOverNumber

        do {
            let result = try await BackgroundFetch.perform { [repository, fixtureId, inningNumber, cursor] in
                try await repository.comments(
                    fixtureId: fixtureId,
                    inningNumber: inningNumber,
                    lastOverNumber: cursor
                )
            }

            if force || lastOverNumber == nil {
                events = result.value
            } else if result.value.isEmpty == false {
                let existingIDs = Set(events.map(\.id))
                let newEvents = result.value.filter { existingIDs.contains($0.id) == false }
                events = newEvents + events
            }

            if let latestOver = events.map(\.apiOverNumber).max() {
                lastOverNumber = latestOver
            }

            lastUpdated = result.lastUpdated
            state = .loaded(events)
        } catch {
            if events.isEmpty {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func startPollingIfNeeded() {
        guard isLive, lifecycleManager.isActive, isScreenVisible else {
            pollingTask?.cancel()
            pollingTask = nil
            return
        }

        pollingTask?.cancel()
        pollingTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                guard await self?.isLive == true else {
                    await self?.stopPolling()
                    return
                }
                await self?.load(force: false)
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
