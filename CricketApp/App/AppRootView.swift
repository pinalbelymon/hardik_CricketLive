import SwiftUI

// MARK: - App Section

/// Primary app destinations.
enum AppSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case fixtures = "Fixtures"
 //   case rankings = "Rankings"
    case settings = "Settings"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .home:
            "house.fill"
        case .fixtures:
            "calendar"
//        case .rankings:
//            "chart.bar.xaxis"
        case .settings:
            "gearshape.fill"
        }
    }
}

// MARK: - Root View

/// Adaptive root navigation for iPhone and iPad.
struct AppRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var lifecycleManager = AppLifecycleManager.shared
    @StateObject private var reachabilityMonitor = ReachabilityMonitor()
    @State private var selectedSection: AppSection? = .home

    let container: DependencyContainer

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        Group {
            if horizontalSizeClass == .regular {
                splitView
            } else {
                tabView
            }
        }
        .background(palette.background)
        .tint(palette.primary)
        .task {
            reachabilityMonitor.start()
        }
        .onChange(of: scenePhase) { _, phase in
            lifecycleManager.handleScenePhase(phase)
        }
    }

    private var tabView: some View {
        TabView {
            HomeView(container: container)
                .tabItem { Label(AppSection.home.rawValue, systemImage: AppSection.home.symbolName) }

            FixturesView(container: container)
                .tabItem { Label(AppSection.fixtures.rawValue, systemImage: AppSection.fixtures.symbolName) }

//            RankingsView(repository: container.rankingsRepository)
//                .tabItem { Label(AppSection.rankings.rawValue, systemImage: AppSection.rankings.symbolName) }

            SettingsView(container: container)
                .tabItem { Label(AppSection.settings.rawValue, systemImage: AppSection.settings.symbolName) }
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.symbolName)
                    .tag(section)
            }
            .navigationTitle(AppConstants.appName)
        } detail: {
            selectedSectionView
        }
    }

    @ViewBuilder
    private var selectedSectionView: some View {
        switch selectedSection ?? .home {
        case .home:
            HomeView(container: container)
        case .fixtures:
            FixturesView(container: container)
//        case .rankings:
//            RankingsView(repository: container.rankingsRepository)
        case .settings:
            SettingsView(container: container)
        }
    }
}

// MARK: - Preview

#Preview {
    AppRootView(container: .preview())
        .environmentObject(ThemeManager())
}
