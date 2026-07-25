import SwiftUI

// MARK: - Splash View

/// Animated launch screen shown on every cold start.
struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinished: () -> Void

    @State private var lottieOpacity: Double = 0
    @State private var lottieScale: CGFloat = 0.88
    @State private var titleOffset: CGFloat = 28
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var didFinish = false

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        ZStack {
            background(palette)

            VStack(spacing: Spacing.large) {
                Spacer()

                LottieView(
                    resourceName: SplashLottie.bouncingCricketBall,
                    loopMode: .loop,
                    animationSpeed: reduceMotion ? 0.75 : 1
                )
                .frame(width: 180, height: 180)
                .scaleEffect(lottieScale)
                .opacity(lottieOpacity)
                .accessibilityLabel("Cricket ball animation")

                VStack(spacing: Spacing.small) {
                    Text(AppConstants.appName)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.text)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Live scores. Real cricket energy.")
                        .font(Typography.body)
                        .foregroundStyle(palette.secondaryText)
                        .opacity(subtitleOpacity)
                }

                Spacer()

                SplashLoadingDots()
                    .opacity(subtitleOpacity)
                    .padding(.bottom, Spacing.xxLarge)
            }
            .padding(Spacing.large)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
            scheduleFinish()
        }
    }

    private func background(_ palette: ColorPalette) -> some View {
        ZStack {
            palette.background.ignoresSafeArea()

            Circle()
                .fill(palette.primary.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -120, y: -240)

            Circle()
                .fill(palette.accent.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 140, y: 280)
        }
    }

    private func startAnimations() {
        if reduceMotion {
            lottieScale = 1
            lottieOpacity = 1
            titleOffset = 0
            titleOpacity = 1
            subtitleOpacity = 1
            return
        }

        withAnimation(AppAnimation.playful) {
            lottieScale = 1
            lottieOpacity = 1
        }

        withAnimation(AppAnimation.spring.delay(0.25)) {
            titleOffset = 0
            titleOpacity = 1
        }

        withAnimation(AppAnimation.launchFade.delay(0.55)) {
            subtitleOpacity = 1
        }
    }

    private func scheduleFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard didFinish == false else { return }
            didFinish = true
            onFinished()
        }
    }
}

// MARK: - Loading Dots

private struct SplashLoadingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        if reduceMotion {
            HStack(spacing: Spacing.small) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(palette.primary)
                        .frame(width: 8, height: 8)
                }
            }
        } else {
            PhaseAnimator([0, 1, 2]) { activeIndex in
                HStack(spacing: Spacing.small) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(palette.primary)
                            .frame(width: activeIndex == index ? 10 : 7, height: activeIndex == index ? 10 : 7)
                            .opacity(activeIndex == index ? 1 : 0.45)
                    }
                }
            } animation: { _ in
                .easeInOut(duration: 0.38)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView {}
        .environmentObject(ThemeManager())
}
