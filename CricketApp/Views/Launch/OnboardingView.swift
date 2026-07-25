import SwiftUI

// MARK: - Onboarding Page

private struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let floatingSymbols: [String]
}

// MARK: - Onboarding View

/// Three-step animated first-launch walkthrough.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var contentVisible = false
    @State private var iconBounce = false
    @State private var floatingPhase = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Live Cricket",
            subtitle: "Follow matches in real time with blinking live tags, scores, and ball-by-ball updates.",
            systemImage: "dot.radiowaves.left.and.right",
            accent: Color.red,
            floatingSymbols: ["sportscourt.fill", "bolt.fill", "circle.fill"]
        ),
        OnboardingPage(
            id: 1,
            title: "Fixtures & Schedule",
            subtitle: "Browse today’s games, upcoming fixtures, and recent results in one place.",
            systemImage: "calendar.badge.clock",
            accent: Color(hex: 0x1294FF),
            floatingSymbols: ["calendar", "clock.fill", "list.bullet.rectangle"]
        ),
        OnboardingPage(
            id: 2,
            title: "Your Cricket Hub",
            subtitle: "Dive into scorecards, commentary, overs, and everything you need — all in one app.",
            systemImage: "sparkles",
            accent: Color(hex: 0x35D07F),
            floatingSymbols: ["chart.bar.xaxis", "text.bubble.fill", "gearshape.fill"]
        )
    ]

    var body: some View {
        let palette = Theme.palette(for: colorScheme)
        let page = pages[currentPage]

        ZStack {
            palette.background.ignoresSafeArea()

            ambientGlow(for: page, palette: palette)

            VStack(spacing: 0) {
                header

                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        pageContent(page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : AppAnimation.spring, value: currentPage)

                pageIndicator
                    .padding(.bottom, Spacing.large)

                actionButton
                    .padding(.horizontal, Spacing.large)
                    .padding(.bottom, Spacing.xxLarge)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                contentVisible = true
            }
            startFloatingAnimation()
        }
        .onChange(of: currentPage) {
            iconBounce.toggle()
            floatingPhase.toggle()
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    finish()
                }
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Theme.palette(for: colorScheme).secondaryText)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.medium)
        .frame(height: 44)
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        let palette = Theme.palette(for: colorScheme)

        return VStack(spacing: Spacing.xxLarge) {
            Spacer()

            ZStack {
                ForEach(Array(page.floatingSymbols.enumerated()), id: \.offset) { index, symbol in
                    Image(systemName: symbol)
                        .font(.system(size: index == 0 ? 22 : 18, weight: .semibold))
                        .foregroundStyle(page.accent.opacity(0.55))
                        .offset(floatingOffset(for: index))
                        .rotationEffect(.degrees(floatingPhase ? Double(index * 12) : Double(-index * 10)))
                        .animation(reduceMotion ? nil : AppAnimation.gentlePulse.delay(Double(index) * 0.15), value: floatingPhase)
                }

                ZStack {
                    Circle()
                        .fill(page.accent.opacity(0.16))
                        .frame(width: 200, height: 200)
                        .scaleEffect(floatingPhase ? 1.06 : 0.94)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [page.accent, page.accent.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 128, height: 128)
                        .shadow(color: page.accent.opacity(0.4), radius: 20, y: 10)

                    Image(systemName: page.systemImage)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: iconBounce)
                }
                .scaleEffect(contentVisible ? 1 : 0.6)
                .opacity(contentVisible ? 1 : 0)
            }
            .frame(height: 240)

            VStack(spacing: Spacing.medium) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.text)
                    .multilineTextAlignment(.center)
                    .offset(y: contentVisible ? 0 : 20)
                    .opacity(contentVisible ? 1 : 0)

                Text(page.subtitle)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Spacing.xLarge)
                    .offset(y: contentVisible ? 0 : 16)
                    .opacity(contentVisible ? 1 : 0)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.large)
    }

    private var pageIndicator: some View {
        let palette = Theme.palette(for: colorScheme)

        return HStack(spacing: Spacing.small) {
            ForEach(pages) { page in
                Capsule()
                    .fill(currentPage == page.id ? palette.primary : palette.divider)
                    .frame(width: currentPage == page.id ? 28 : 8, height: 8)
                    .animation(reduceMotion ? nil : AppAnimation.playful, value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        let palette = Theme.palette(for: colorScheme)
        let isLastPage = currentPage == pages.count - 1

        return Button {
            if isLastPage {
                finish()
            } else {
                withAnimation(AppAnimation.spring) {
                    currentPage += 1
                }
            }
        } label: {
            HStack(spacing: Spacing.small) {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(Typography.headline)

                Image(systemName: isLastPage ? "arrow.right.circle.fill" : "chevron.right")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.large)
            .background(
                LinearGradient(
                    colors: [palette.primary, palette.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
            )
            .shadow(color: palette.primary.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(OnboardingButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft), trigger: currentPage)
    }

    private func ambientGlow(for page: OnboardingPage, palette: ColorPalette) -> some View {
        Circle()
            .fill(page.accent.opacity(0.2))
            .frame(width: 340, height: 340)
            .blur(radius: 80)
            .offset(y: -120)
            .animation(reduceMotion ? nil : AppAnimation.launchFade, value: currentPage)
    }

    private func floatingOffset(for index: Int) -> CGSize {
        let radius: CGFloat = floatingPhase ? 92 : 78
        let angle = Double(index) * (360.0 / 3.0) - 90
        let radians = angle * .pi / 180
        return CGSize(
            width: cos(radians) * radius,
            height: sin(radians) * radius
        )
    }

    private func startFloatingAnimation() {
        guard reduceMotion == false else { return }
        withAnimation(AppAnimation.gentlePulse) {
            floatingPhase = true
        }
    }

    private func finish() {
        OnboardingStore.markCompleted()
        withAnimation(AppAnimation.spring) {
            onComplete()
        }
    }
}

// MARK: - Button Style

private struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {}
        .environmentObject(ThemeManager())
}
