import Lottie
import SwiftUI
import UIKit

// MARK: - Lottie View

/// SwiftUI bridge for bundled Lottie JSON animations.
struct LottieView: UIViewRepresentable {
    let resourceName: String
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: CGFloat = 1
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let animationView = LottieAnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.backgroundColor = .clear
        animationView.clipsToBounds = false

        containerView.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
           let animation = LottieAnimation.filepath(url.path) {
            animationView.animation = animation
            animationView.play()
        }

        context.coordinator.animationView = animationView
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }

        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = contentMode

        if animationView.isAnimationPlaying == false {
            animationView.play()
        }
    }

    final class Coordinator {
        var animationView: LottieAnimationView?
    }
}

// MARK: - Splash Lottie

enum SplashLottie {
    static let bouncingCricketBall = "Bouncing Cricket Ball"
}
