import SwiftUI
import FirebaseAppCheck

// MARK: - App Check Test View for Development
struct AppCheckTestView: View {
    @StateObject private var feedbackService = FeedbackService.shared
    @StateObject private var secureFeedbackService = SecureFeedbackService.shared
    @State private var testResults: [String] = []
    @State private var isRunningTests = false

    var body: some View {
        NavigationView {
            VStack(spacing: PiggySpacing.lg) {
                Text("🔒 App Check Integration Test")
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)

                // Test Status
                VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                    Text("Test Results:")
                        .font(PiggyFont.captionEmphasized)
                        .foregroundColor(.piggyTextSecondary)

                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(PiggyFont.caption1)
                            .foregroundColor(result.contains("✅") ? .piggySuccess :
                                           result.contains("❌") ? .piggyError : .piggyTextPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(PiggySpacing.sm)

                // Test Actions
                VStack(spacing: PiggySpacing.md) {
                    PiggyButton(
                        title: "Test App Check Token",
                        action: testAppCheckToken,
                        style: .primary,
                        size: .medium,
                        isLoading: isRunningTests,
                        isDisabled: isRunningTests
                    )

                    PiggyButton(
                        title: "Test Feedback Submission",
                        action: testFeedbackSubmission,
                        style: .secondary,
                        size: .medium,
                        isLoading: isRunningTests,
                        isDisabled: isRunningTests
                    )

                    PiggyButton(
                        title: "Clear Results",
                        action: clearResults,
                        style: .tertiary,
                        size: .medium,
                        isDisabled: isRunningTests
                    )
                }

                Spacer()
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Test Actions

    private func testAppCheckToken() {
        isRunningTests = true
        addTestResult("🔄 Testing App Check token...")

        Task {
            let result = await secureFeedbackService.testAppCheckToken()

            DispatchQueue.main.async {
                self.addTestResult(result.message)
                self.isRunningTests = false
            }
        }
    }

    private func testFeedbackSubmission() {
        isRunningTests = true
        addTestResult("🔄 Testing secure feedback submission...")

        Task {
            do {
                try await secureFeedbackService.submitSecureFeedback(
                    type: .other,
                    subject: "App Check Test",
                    message: "Testing App Check integration with Supabase",
                    screenName: "AppCheckTestView"
                )

                DispatchQueue.main.async {
                    self.addTestResult("✅ Secure feedback submitted successfully!")
                    self.addTestResult("🔒 Request was verified with App Check token")
                    self.isRunningTests = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.addTestResult("❌ Feedback submission failed: \(error.localizedDescription)")
                    self.isRunningTests = false
                }
            }
        }
    }

    private func clearResults() {
        testResults.removeAll()
    }

    private func addTestResult(_ result: String) {
        let timestamp = DateFormatter.timeFormatter.string(from: Date())
        testResults.append("[\(timestamp)] \(result)")
    }
}

// MARK: - Helper Extensions
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

// MARK: - Preview
#Preview("App Check Test") {
    AppCheckTestView()
}