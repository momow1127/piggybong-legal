import SwiftUI

// MARK: - Firebase Crashlytics Test View
// This view provides a simple way to test Firebase Crashlytics integration
// Only available in DEBUG builds for testing purposes

#if DEBUG
struct TestCrashView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Piggy Bong gradient background
                PiggyGradients.background
                    .ignoresSafeArea()

                VStack(spacing: PiggySpacing.xl) {
                    // Header
                    VStack(spacing: PiggySpacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)

                        Text("Firebase Crashlytics Test")
                            .font(PiggyFont.title1)
                            .foregroundColor(.piggyTextPrimary)
                            .multilineTextAlignment(.center)

                        Text("Tap the button below to trigger a test crash and verify your Firebase Crashlytics setup.")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PiggySpacing.lg)
                    }

                    // Test Crash Button
                    PiggyButton(
                        title: "Test Crash",
                        action: {
                            triggerTestCrash()
                        },
                        style: .destructive,
                        size: .large
                    )
                    .padding(.horizontal, PiggySpacing.lg)

                    // Warning Text
                    VStack(spacing: PiggySpacing.sm) {
                        Text("⚠️ WARNING ⚠️")
                            .font(PiggyFont.body.weight(.bold))
                            .foregroundColor(.red)

                        Text("This will intentionally crash the app to test Firebase Crashlytics. The app will close immediately.")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PiggySpacing.lg)
                    }
                    .padding(PiggySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.red.opacity(0.1))
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, PiggySpacing.lg)

                    Spacer()
                }
                .padding(.top, PiggySpacing.xl)
            }
            .navigationTitle("Crashlytics Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Test Crash Function
    private func triggerTestCrash() {
        print("💥 Firebase Crashlytics Test Crash - This is intentional!")

        // Log custom information before crashing
        CrashlyticsService.shared.log("Test crash triggered from TestCrashView")
        CrashlyticsService.shared.setValue("TestCrashView", forKey: "crash_source")
        CrashlyticsService.shared.setValue("manual_test", forKey: "crash_type")

        // Add a small delay to ensure logging completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Force a test crash (array index out of bounds)
            let numbers = [0]
            let _ = numbers[1] // This will crash the app
        }
    }
}

// MARK: - Preview
#Preview {
    TestCrashView()
}

#endif