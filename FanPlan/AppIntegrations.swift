import SwiftUI
import Firebase
import FirebaseAnalytics

// Helper struct for feedback button
struct FeedbackButtonModifier: ViewModifier {
    @State private var showFeedbackView = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    showFeedbackView = true
                }) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(red: 255/255, green: 192/255, blue: 203/255))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .sheet(isPresented: $showFeedbackView) {
                    FeedbackView()
                }
            }
    }
}

// Add this to your FanPlanApp.swift
extension FanPlanApp {
    func setupCrashReporting() {
        // Initialize Firebase (includes Crashlytics and Performance)
        FirebaseApp.configure()

        // Set up Crashlytics
        CrashlyticsService.shared.configure()

        // Initialize Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // If user is logged in, set their ID
        if let userId = AuthenticationService.shared.currentUser?.id {
            CrashlyticsService.shared.setUser(userId.uuidString)
            Analytics.setUserID(userId.uuidString)
        }

        // Track app version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            CrashlyticsService.shared.setValue(version, forKey: "app_version")
            Analytics.setUserProperty(version, forName: "app_version")
        }

        // Track app session start with AI features enabled
        AIInsightAnalyticsService.shared.logSessionStart(hasAIFeatures: true)

        print("✅ Crash reporting, performance monitoring, and analytics configured")
    }

}

// Quick Integration Helper
struct LaunchChecklistView: View {
    @State private var firebaseSetup = false
    @State private var feedbackWorking = false
    @State private var testFlightReady = false

    var body: some View {
        VStack(spacing: 20) {
            Text("🚀 Launch Checklist")
                .font(.largeTitle)
                .bold()

            ChecklistItem(
                title: "Firebase Crashlytics",
                isComplete: firebaseSetup,
                action: testFirebase
            )

            ChecklistItem(
                title: "Feedback System",
                isComplete: feedbackWorking,
                action: testFeedback
            )

            ChecklistItem(
                title: "TestFlight Build",
                isComplete: testFlightReady,
                instruction: "Archive → Upload to App Store Connect"
            )

            if firebaseSetup && feedbackWorking {
                Text("✅ Ready for launch!")
                    .foregroundColor(.green)
                    .font(.title2)
                    .padding()
            }
        }
        .padding()
    }

    func testFirebase() {
        // Test crash reporting
        CrashlyticsService.shared.recordError(
            NSError(domain: "TestError", code: 0, userInfo: ["test": "data"])
        )
        firebaseSetup = true
    }

    func testFeedback() {
        Task {
            do {
                try await FeedbackService.shared.submitFeedback(
                    type: .other,
                    subject: "Test Feedback",
                    message: "Testing feedback system",
                    screenName: "LaunchChecklist"
                )
                await MainActor.run {
                    feedbackWorking = true
                }
            } catch {
                print("Error testing feedback: \(error)")
                await MainActor.run {
                    feedbackWorking = false
                }
            }
        }
    }
}

struct ChecklistItem: View {
    let title: String
    let isComplete: Bool
    var action: (() -> Void)? = nil
    var instruction: String? = nil

    var body: some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? .green : .gray)

            Text(title)

            Spacer()

            if let action = action {
                Button("Test") {
                    action()
                }
                .buttonStyle(.bordered)
            } else if let instruction = instruction {
                Text(instruction)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}