import Foundation

// MARK: - Settings View Model

/// Coordinates settings metadata and app update checks.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var availableUpdate: AppUpdate?
    @Published var isCheckingUpdate = false
    @Published var showUpdateAlert = false
    @Published var updateAlertMessage: String?

    let appVersion: String
    let shareMessage: String
    let privacyPolicyURL: URL
    let termsURL: URL

    private let updateRepository: UpdateRepositoryProtocol
    private let adsRepository: AdsRepositoryProtocol

    init(settingsRepository: SettingsRepositoryProtocol, updateRepository: UpdateRepositoryProtocol, adsRepository: AdsRepositoryProtocol) {
        self.updateRepository = updateRepository
        self.adsRepository = adsRepository
        appVersion = settingsRepository.appVersion
        let appStoreURL = "https://apps.apple.com/app/\(AppConstants.appId)"

        shareMessage = """
        Follow live cricket scores, fixtures, and rankings with \(AppConstants.appName).

        Download now:
        \(appStoreURL)
        """
        privacyPolicyURL = URL(string: "https://belymoninfotech.com/app/cricplus/privacypolicy.html") ?? AppConstants.API.iTunesLookupURL
        termsURL = URL(string: "https://belymoninfotech.com/app/cricplus/termsofuse.html") ?? AppConstants.API.iTunesLookupURL
    }

    func load() async {
        adsRepository.startAds()
    }

    func checkForUpdate() async {
        guard isCheckingUpdate == false else { return }

        isCheckingUpdate = true
        updateAlertMessage = nil

        do {
            if let update = try await updateRepository.checkForUpdate(), update.isAvailable {
                availableUpdate = update
            } else {
                updateAlertMessage = "You're on the latest version of \(AppConstants.appName)."
                showUpdateAlert = true
            }
        } catch {
            updateAlertMessage = error.localizedDescription
            showUpdateAlert = true
        }

        isCheckingUpdate = false
    }
}
