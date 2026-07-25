import StoreKit
import SwiftUI

// MARK: - Settings View

/// Preferences, app actions, and legal links.
struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel: SettingsViewModel

    init(container: DependencyContainer) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                settingsRepository: container.settingsRepository,
                updateRepository: container.updateRepository,
                adsRepository: container.adsRepository
            )
        )
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                    SettingsHeroHeader(version: viewModel.appVersion)

                    appearanceSection

                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        SectionHeader("General", subtitle: "App actions", systemImage: "slider.horizontal.3")

                        SettingsGroupCard {
                            SettingsActionRow(title: "Rate App", subtitle: "Enjoying Cricket? Leave a review", systemImage: "star.fill", tint: .yellow) {
                                requestReview()
                            }

                            SettingsDivider()

                            ShareLink(item: viewModel.shareMessage) {
                                SettingsRowLabel(
                                    title: "Share App",
                                    subtitle: "Tell friends about Cricket",
                                    systemImage: "square.and.arrow.up",
                                    tint: palette.accent,
                                    showsChevron: true
                                )
                            }
                            .buttonStyle(.plain)

                            SettingsDivider()

                            SettingsActionRow(
                                title: "Check for Updates",
                                subtitle: viewModel.isCheckingUpdate ? "Checking App Store…" : "See if a new version is available",
                                systemImage: "arrow.down.circle.fill",
                                tint: palette.primary,
                                showsProgress: viewModel.isCheckingUpdate
                            ) {
                                Task { await viewModel.checkForUpdate() }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        SectionHeader("Legal", subtitle: "Policies and terms", systemImage: "doc.text.fill")

                        SettingsGroupCard {
                            SettingsLinkRow(
                                title: "Privacy Policy",
                                subtitle: nil,//"How your data is handled"
                                systemImage: "hand.raised.fill",
                                url: viewModel.privacyPolicyURL
                            )

                            SettingsDivider()

                            SettingsLinkRow(
                                title: "Terms of Service",
                                subtitle: nil ,//"Usage terms and conditions"
                                systemImage: "doc.plaintext.fill",
                                url: viewModel.termsURL
                            )
                        }
                    }

                    Text("Cricket v\(viewModel.appVersion)")
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.small)
                }
                .padding(Spacing.large)
            }
            .background(palette.background)
            .navigationTitle("Settings")
            .task {
                await viewModel.load()
            }
            .sheet(item: $viewModel.availableUpdate) { update in
                UpdateSheet(update: update)
            }
            .alert("App Update", isPresented: $viewModel.showUpdateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.updateAlertMessage ?? "")
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Appearance", subtitle: "Choose your theme", systemImage: "paintpalette.fill")

            HStack(spacing: Spacing.medium) {
                ForEach(AppAppearance.allCases) { appearance in
                    SettingsThemeOption(
                        appearance: appearance,
                        isSelected: themeManager.appearance == appearance
                    ) {
                        withAnimation(AppAnimation.spring) {
                            themeManager.appearance = appearance
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hero Header

private struct SettingsHeroHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let version: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        GlassCard {
            HStack(spacing: Spacing.large) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [palette.primary, palette.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(AppConstants.appName)
                        .font(Typography.title)
                        .foregroundStyle(palette.text)

                    Text("Live scores, fixtures, and rankings")
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)

                    Text("Version \(version)")
                        .font(Typography.caption)
                        .foregroundStyle(palette.primary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Theme Option

private struct SettingsThemeOption: View {
    @Environment(\.colorScheme) private var colorScheme

    let appearance: AppAppearance
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        Button(action: action) {
            VStack(spacing: Spacing.small) {
                Image(systemName: appearance.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? palette.primary : palette.secondaryText)
                    .frame(height: 28)

                Text(appearance.title)
                    .font(Typography.caption)
                    .foregroundStyle(isSelected ? palette.text : palette.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(isSelected ? palette.primary.opacity(0.14) : palette.elevatedBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isSelected ? palette.primary.opacity(0.55) : palette.divider.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Group Card

private struct SettingsGroupCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder let content: Content

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .background(palette.card, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(palette.divider.opacity(0.55), lineWidth: 1)
        }
        .modifier(AppShadow.card(palette))
    }
}

// MARK: - Row Components

private struct SettingsRowLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color
    let showsChevron: Bool
    let showsProgress: Bool

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color? = nil,
        showsChevron: Bool = false,
        showsProgress: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint ?? Color.primary
        self.showsChevron = showsChevron
        self.showsProgress = showsProgress
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(spacing: Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 36, height: 36)

                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(palette.text)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: Spacing.small)

            if showsProgress {
                ProgressView()
                    .controlSize(.small)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(.vertical, Spacing.medium)
        .contentShape(Rectangle())
    }
}

private struct SettingsActionRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color
    let showsProgress: Bool
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color,
        showsProgress: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.showsProgress = showsProgress
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: tint,
                showsChevron: !showsProgress,
                showsProgress: showsProgress
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let url: URL

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        Button {
            openURL(url)
        } label: {
            SettingsRowLabel(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: palette.primary,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        Divider()
            .overlay(palette.divider.opacity(0.65))
            .padding(.leading, 48)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(container: .preview())
        .environmentObject(ThemeManager())
}
