import SwiftUI

// MARK: - PiggyLoading Design System Tokens
struct PiggyLoadingTokens {

    // MARK: - Visual Tokens
    static let spinnerColor = Color.piggyPrimary
    static let skeletonColor = Color.piggyTextTertiary.opacity(0.1)
    static let skeletonHighlight = Color.piggyTextTertiary.opacity(0.2)
    static let contextualBackground = Color.piggyCardBackground.opacity(0.8)
    static let overlayBackground = Color.black.opacity(0.3)

    // MARK: - Animation Tokens
    static let animationDuration: Double = 0.3
    static let skeletonAnimationDuration: Double = 1.5
    static let progressAnimationDuration: Double = 0.6

    // MARK: - Size Tokens
    enum LoadingSize {
        case small, medium, large

        var scale: Double {
            switch self {
            case .small: return 0.8
            case .medium: return 1.0
            case .large: return 1.2
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
    }

    // MARK: - Consistent Spinner Component
    static func spinner(size: LoadingSize = .medium, color: Color? = nil) -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: color ?? spinnerColor))
            .scaleEffect(size.scale)
    }

    // MARK: - Skeleton Rectangle
    static func skeletonRectangle(
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = 4
    ) -> some View {
        SkeletonShape(width: width, height: height, cornerRadius: cornerRadius)
    }

    // MARK: - Skeleton Circle
    static func skeletonCircle(diameter: CGFloat) -> some View {
        SkeletonShape(width: diameter, height: diameter, cornerRadius: diameter / 2)
    }
}

// MARK: - Skeleton Shape Component
private struct SkeletonShape: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var animatedGradient = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        PiggyLoadingTokens.skeletonColor,
                        PiggyLoadingTokens.skeletonHighlight,
                        PiggyLoadingTokens.skeletonColor
                    ],
                    startPoint: animatedGradient ? .trailing : .leading,
                    endPoint: animatedGradient ? UnitPoint(x: 1.5, y: 0) : UnitPoint(x: -0.5, y: 0)
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: PiggyLoadingTokens.skeletonAnimationDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    animatedGradient = true
                }
            }
    }
}

// MARK: - Loading Context Types
enum LoadingContext {
    case fullScreen(blocking: Bool)
    case contextual(showProgress: Bool)
    case skeleton(replaceContent: Bool)
    case inline(withinElement: Bool)
}

enum LoadingImpact {
    case appWide        // Full screen required
    case screenLevel    // Contextual or skeleton
    case componentLevel // Inline or contextual
    case actionLevel    // Button/form inline
}

// MARK: - Preview
#Preview("Loading Tokens") {
    VStack(spacing: PiggySpacing.lg) {
        // Spinners
        HStack(spacing: PiggySpacing.md) {
            PiggyLoadingTokens.spinner(size: .small)
            PiggyLoadingTokens.spinner(size: .medium)
            PiggyLoadingTokens.spinner(size: .large)
        }

        // Skeleton shapes
        VStack(spacing: PiggySpacing.sm) {
            PiggyLoadingTokens.skeletonRectangle(width: 200, height: 20)
            PiggyLoadingTokens.skeletonRectangle(width: 150, height: 16)
            PiggyLoadingTokens.skeletonCircle(diameter: 50)
        }
    }
    .padding()
    .background(PiggyGradients.background)
}