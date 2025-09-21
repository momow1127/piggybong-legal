import SwiftUI

// MARK: - Progressive AI Loading View
struct ProgressiveAILoading: View {
    @State private var progress: Double = 0.0
    @State private var currentStep = 0
    @State private var pulseScale: Double = 1.0

    let steps: [AILoadingStep]
    let onComplete: (() -> Void)?

    init(
        steps: [AILoadingStep] = AILoadingStep.defaultSteps,
        onComplete: (() -> Void)? = nil
    ) {
        self.steps = steps
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            // K-pop themed progress indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        PiggyLoadingTokens.skeletonColor,
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.piggyPrimary, Color.piggySecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: PiggyLoadingTokens.progressAnimationDuration), value: progress)

                // Center emoji with pulse animation
                Text(currentStepData.emoji)
                    .font(.title)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }

            // Current step message
            VStack(spacing: PiggySpacing.xs) {
                Text(currentStepData.title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)

                Text(currentStepData.subtitle)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Step indicators
            HStack(spacing: PiggySpacing.sm) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.piggyPrimary : PiggyLoadingTokens.skeletonColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentStep ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
        }
        .padding(PiggySpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.piggyPrimary.opacity(0.2), radius: 20)
        )
        .onAppear {
            startProgressAnimation()
            pulseScale = 1.2
        }
    }

    private var currentStepData: AILoadingStep {
        guard currentStep < steps.count else { return steps.last ?? AILoadingStep.defaultSteps.last! }
        return steps[currentStep]
    }

    private func startProgressAnimation() {
        // Animate through each step
        let stepDuration = 1.5
        let totalDuration = Double(steps.count) * stepDuration

        for (index, _) in steps.enumerated() {
            let delay = Double(index) * stepDuration

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentStep = index
                    progress = Double(index + 1) / Double(steps.count)
                }
            }
        }

        // Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            onComplete?()
        }
    }
}

// MARK: - AI Loading Step Model
struct AILoadingStep {
    let title: String
    let subtitle: String
    let emoji: String

    static let defaultSteps: [AILoadingStep] = [
        AILoadingStep(
            title: "Gathering Your Data",
            subtitle: "Reading your fan activities and spending patterns",
            emoji: "📊"
        ),
        AILoadingStep(
            title: "Analyzing Patterns",
            subtitle: "Understanding your K-pop preferences and habits",
            emoji: "🧠"
        ),
        AILoadingStep(
            title: "Generating Insights",
            subtitle: "Creating personalized recommendations just for you",
            emoji: "✨"
        ),
        AILoadingStep(
            title: "Almost Ready!",
            subtitle: "Putting the finishing touches on your insights",
            emoji: "🎤"
        )
    ]

    // Specialized step sets for different AI operations
    static let spendingAnalysisSteps: [AILoadingStep] = [
        AILoadingStep(
            title: "Collecting Purchase Data",
            subtitle: "Gathering your fan spending history",
            emoji: "💳"
        ),
        AILoadingStep(
            title: "Analyzing Spending Patterns",
            subtitle: "Understanding where your money goes",
            emoji: "📈"
        ),
        AILoadingStep(
            title: "Calculating Insights",
            subtitle: "Finding optimization opportunities",
            emoji: "💡"
        ),
        AILoadingStep(
            title: "Ready to View!",
            subtitle: "Your spending analysis is complete",
            emoji: "💰"
        )
    ]

    static let artistRecommendationSteps: [AILoadingStep] = [
        AILoadingStep(
            title: "Scanning Your Preferences",
            subtitle: "Understanding your favorite artists and genres",
            emoji: "🎵"
        ),
        AILoadingStep(
            title: "Exploring Similar Artists",
            subtitle: "Finding artists you might love",
            emoji: "🔍"
        ),
        AILoadingStep(
            title: "Personalizing Recommendations",
            subtitle: "Tailoring suggestions to your taste",
            emoji: "🎯"
        ),
        AILoadingStep(
            title: "Discoveries Await!",
            subtitle: "Your new artist recommendations are ready",
            emoji: "🌟"
        )
    ]
}

// MARK: - AI Loading Context Enum
enum AILoadingContext {
    case general
    case spendingAnalysis
    case artistRecommendation

    var steps: [AILoadingStep] {
        switch self {
        case .general:
            return AILoadingStep.defaultSteps
        case .spendingAnalysis:
            return AILoadingStep.spendingAnalysisSteps
        case .artistRecommendation:
            return AILoadingStep.artistRecommendationSteps
        }
    }
}

// MARK: - Preview
#Preview("Progressive AI Loading") {
    ZStack {
        PiggyGradients.background
            .ignoresSafeArea()

        VStack(spacing: PiggySpacing.xl) {
            Text("AI Insight Generation")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)

            ProgressiveAILoading(
                steps: AILoadingStep.defaultSteps
            ) {
                print("AI loading complete!")
            }
        }
    }
}