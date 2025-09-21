import SwiftUI

struct OverlayLoadingView: View {
    let message: String
    let isSimpleMode: Bool

    @State private var isAnimating = false
    @State private var glowIntensity: Double = 0.3

    var body: some View {
        ZStack {
            if isSimpleMode {
                // Simple loading mode
                VStack(spacing: PiggySpacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)

                    if !message.isEmpty {
                        Text(message)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(PiggySpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 20)
                )
            } else {
                // Beautiful K-pop themed loading
                VStack(spacing: PiggySpacing.lg) {
                    // Animated music note
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.purple.opacity(0.8),
                                        Color.pink.opacity(0.6),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .opacity(glowIntensity)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .animation(
                                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: glowIntensity
                            )

                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isAnimating ? 10 : -10))
                            .animation(
                                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }

                    // Loading message
                    if !message.isEmpty {
                        Text(message)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1.0 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }

                    // Animated dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
                .padding(PiggySpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .purple.opacity(0.3), radius: 20)
                )
            }
        }
        .onAppear {
            isAnimating = true
            glowIntensity = 0.8
        }
    }
}

#Preview("Simple Mode") {
    ZStack {
        Color.black
        OverlayLoadingView(message: "Loading your K-pop budget...", isSimpleMode: true)
    }
}

#Preview("Beautiful Mode") {
    ZStack {
        Color.black
        OverlayLoadingView(message: "Syncing your fan activities...", isSimpleMode: false)
    }
}