import SwiftUI

// MARK: - Premium Paywall

/// Lifetime Remove Ads paywall — premium presentation + Apple-compliant footer.
struct PremiumPaywallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject var purchaseManager: PurchaseManager

    @State private var appeared = false
    @State private var ctaPulse = false
    @State private var showSuccess = false

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xLarge) {
                        hero
                        benefits
                        purchaseCard
                        legalFooter
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.xxLarge)
                }

                if showSuccess {
                    successOverlay(palette: palette)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text("PREMIUM")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: 0xC9A227))
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.xSmall)
                        .background(Color(hex: 0xC9A227).opacity(0.16), in: Capsule())
                        .accessibilityLabel("Premium")
                }
            }
//            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbarBackground(palette.background.opacity(0.92), for: .navigationBar)
        }
        .task {
            if purchaseManager.lifetimeProduct == nil {
                await purchaseManager.loadProducts()
            }
            withAnimation(AppAnimation.spring) { appeared = true }
            withAnimation(AppAnimation.gentlePulse) { ctaPulse = true }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { purchaseManager.errorMessage != nil },
            set: { if $0 == false { purchaseManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseManager.errorMessage ?? "")
        }
        .alert("Purchase", isPresented: Binding(
            get: { purchaseManager.statusMessage != nil && showSuccess == false },
            set: { if $0 == false { purchaseManager.statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseManager.statusMessage ?? "")
        }
    }

    // MARK: - Background

    private var background: some View {
        let palette = Theme.palette(for: colorScheme)

        return ZStack {
            palette.background.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(hex: 0x0B1B3A).opacity(colorScheme == .dark ? 0.95 : 0.12),
                    palette.background.opacity(0),
                    Color(hex: 0xC9A227).opacity(colorScheme == .dark ? 0.18 : 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0xC9A227).opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 140, y: -220)
                .allowsHitTesting(false)

            Circle()
                .fill(palette.primary.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: -130, y: 320)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        let palette = Theme.palette(for: colorScheme)

        return VStack(spacing: Spacing.large) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0xC9A227).opacity(0.45), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(ctaPulse ? 1.08 : 0.92)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF2D56B), Color(hex: 0xC9A227), Color(hex: 0x8A6A12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color(hex: 0xC9A227).opacity(0.45), radius: 18, y: 8)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(appeared ? 1 : 0.85)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: Spacing.small) {
                Text("Play Without Limits")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.text)
                    .multilineTextAlignment(.center)

                Text("One-time unlock. Remove every ad forever and enjoy pure cricket.")
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.small)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
        }
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(spacing: Spacing.medium) {
            benefitRow(
                icon: "nosign",
                title: "Ad-free forever",
                subtitle: "No banners, natives, or interstitials",
                delay: 0.05
            )
            benefitRow(
                icon: "bolt.horizontal.circle.fill",
                title: "Faster match browsing",
                subtitle: "Jump between scorecards without interruptions",
                delay: 0.12
            )
            benefitRow(
                icon: "checkmark.seal.fill",
                title: "Lifetime access",
                subtitle: "Pay once — keep Premium on this Apple ID",
                delay: 0.19
            )
        }
    }

    private func benefitRow(icon: String, title: String, subtitle: String, delay: Double) -> some View {
        let palette = Theme.palette(for: colorScheme)

        return HStack(spacing: Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(Color(hex: 0xC9A227).opacity(0.16))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(hex: 0xC9A227))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(palette.text)
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.medium)
        .background(palette.card.opacity(0.92), in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(Color(hex: 0xC9A227).opacity(0.22), lineWidth: 1)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(AppAnimation.spring.delay(delay), value: appeared)
    }

    // MARK: - Purchase CTA

    private var purchaseCard: some View {
        let palette = Theme.palette(for: colorScheme)

        return VStack(spacing: Spacing.medium) {
            if purchaseManager.isPremium {
                Label("Premium Active", systemImage: "checkmark.seal.fill")
                    .font(Typography.headline)
                    .foregroundStyle(palette.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.large)
                    .background(palette.success.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.xLarge, style: .continuous))
            } else {
                Button {
                    Task { await purchase() }
                } label: {
                    HStack(spacing: Spacing.small) {
                        if purchaseManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.body.weight(.bold))
                            Text("Remove Ads Forever")
                                .font(.headline.weight(.bold))
                            Text("·")
                            Text(purchaseManager.displayPrice)
                                .font(.headline.weight(.bold))
                        }
                    }
                    .foregroundStyle(Color(hex: 0x1A1205))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.large)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xF2D56B), Color(hex: 0xC9A227)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: CornerRadius.xLarge, style: .continuous)
                    )
                    .shadow(color: Color(hex: 0xC9A227).opacity(ctaPulse ? 0.55 : 0.25), radius: ctaPulse ? 22 : 10, y: 8)
                    .scaleEffect(ctaPulse ? 1.015 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(purchaseManager.isBusy)
                .accessibilityLabel("Remove ads forever for \(purchaseManager.displayPrice)")
            }

            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                HStack(spacing: Spacing.small) {
                    if purchaseManager.isRestoring {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Restore Purchases")
                        .font(Typography.body.weight(.semibold))
                }
                .foregroundStyle(palette.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isBusy)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(AppAnimation.spring.delay(0.25), value: appeared)
    }

    // MARK: - Apple-compliant footer

    private var legalFooter: some View {
        let palette = Theme.palette(for: colorScheme)

        return VStack(spacing: Spacing.medium) {
            Text("Remove Ads is a one-time (lifetime) In-App Purchase. Payment will be charged to your Apple ID account at confirmation of purchase. This purchase is non-consumable and does not auto-renew.")
                .font(.caption2)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.small) {
                footerLink("Privacy Policy", url: AppConstants.IAP.privacyPolicyURL)
                Text("·").foregroundStyle(palette.secondaryText)
                footerLink("Terms of Use", url: AppConstants.IAP.termsOfUseURL)
                Text("·").foregroundStyle(palette.secondaryText)
                footerLink("EULA", url: AppConstants.IAP.appleEULAURL)
            }
            .font(.caption.weight(.semibold))

            Text("Already purchased? Use Restore Purchases above.")
                .font(.caption2)
                .foregroundStyle(palette.secondaryText.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.small)
        .opacity(appeared ? 1 : 0)
    }

    private func footerLink(_ title: String, url: URL) -> some View {
        Button(title) {
            openURL(url)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.palette(for: colorScheme).primary)
    }

    // MARK: - Success

    private func successOverlay(palette: ColorPalette) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: Spacing.large) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(palette.success)
                    .scaleEffect(showSuccess ? 1 : 0.6)

                Text("You're Premium")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Ads are removed across the app.")
                    .font(Typography.body)
                    .foregroundStyle(.white.opacity(0.8))

                Button("Continue") {
                    dismiss()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(hex: 0x1A1205))
                .padding(.horizontal, Spacing.xxLarge)
                .padding(.vertical, Spacing.medium)
                .background(Color(hex: 0xF2D56B), in: Capsule())
            }
            .padding(Spacing.xxLarge)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xLarge, style: .continuous))
            .padding(Spacing.xLarge)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func purchase() async {
        let success = await purchaseManager.purchaseLifetime()
        guard success else { return }
        withAnimation(AppAnimation.spring) {
            showSuccess = true
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumPaywallView(purchaseManager: PurchaseManager())
}
