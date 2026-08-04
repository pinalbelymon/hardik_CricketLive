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
    private let adsManager: AdsManager

    init(
        settingsRepository: SettingsRepositoryProtocol,
        updateRepository: UpdateRepositoryProtocol,
        adsManager: AdsManager
    ) {
        self.updateRepository = updateRepository
        self.adsManager = adsManager
        appVersion = settingsRepository.appVersion
        let appStoreURL = "https://apps.apple.com/app/\(AppConstants.appId)"

        shareMessage = """
        Follow live cricket scores, fixtures, and rankings with \(AppConstants.appName).

        Download now:
        \(appStoreURL)
        """
        privacyPolicyURL = AppConstants.IAP.privacyPolicyURL
        termsURL = AppConstants.IAP.termsOfUseURL
    }

    func load() async {
        // Idempotent — primary bootstrap runs at launch.
        await adsManager.prepare()
    }

    func openAdsPrivacyOptions() async {
        await adsManager.presentPrivacyOptionsIfNeeded()
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
