import SwiftUI

// MARK: - Launch Phase

private enum LaunchPhase {
    case splash
    case onboarding
    case main
}

// MARK: - App Launch View

/// Orchestrates splash, onboarding, and the main app experience.
struct AppLaunchView: View {
    @AppStorage(OnboardingStore.storageKey) private var hasCompletedOnboarding = false
    @State private var phase: LaunchPhase = .splash

    let container: DependencyContainer

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashView {
                    transitionFromSplash()
                }
                .transition(.opacity)
                .zIndex(2)

            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    withAnimation(AppAnimation.spring) {
                        phase = .main
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale(scale: 0.96).combined(with: .opacity)
                ))
                .zIndex(1)

            case .main:
                AppRootView(container: container)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.98).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(0)
            }
        }
        .animation(AppAnimation.spring, value: phase)
        .environmentObject(container.adsManager)
        .environmentObject(container.purchaseManager)
        .task {
            // Start early so cached / StoreKit entitlements are ready before ads bootstrap.
            await container.purchaseManager.start()
        }
        .task(id: phase) {
            guard phase == .main else { return }
            await container.purchaseManager.refreshEntitlements()
            await container.adsManager.prepare()
            // Cold-start app open after splash → main (skipped for premium / policy).
            _ = await container.adsManager.handleAppOpenOpportunity(isColdStart: true)
        }
    }

    private func transitionFromSplash() {
        withAnimation(AppAnimation.launchFade) {
            phase = hasCompletedOnboarding ? .main : .onboarding
        }
    }
}

// MARK: - Preview

#Preview("First Launch") {
    AppLaunchView(container: .preview())
        .environmentObject(ThemeManager())
}

#Preview("Returning User") {
    AppLaunchView(container: .preview())
        .environmentObject(ThemeManager())
        .onAppear {
            OnboardingStore.markCompleted()
        }
}
