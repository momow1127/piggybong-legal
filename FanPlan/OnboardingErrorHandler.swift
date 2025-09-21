import SwiftUI

// MARK: - Onboarding Error Handler
@MainActor
class OnboardingErrorHandler: ObservableObject {
    @Published var currentError: OnboardingError?
    @Published var isShowingError: Bool = false
    @Published var errorQueue: [OnboardingError] = []
    
    static let shared = OnboardingErrorHandler()
    
    private init() {}
    
    // MARK: - Error Display
    func handle(_ error: OnboardingError, step: OnboardingStep) {
        // Track error for analytics
        OnboardingAnalytics.trackError(error, step: step)
        
        // Add to queue if already showing an error
        if isShowingError {
            errorQueue.append(error)
            return
        }
        
        // Show error immediately
        currentError = error
        isShowingError = true
        
        // Auto-dismiss recoverable errors after 3 seconds
        if error.isRecoverable {
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                dismissCurrentError()
            }
        }
        
        print("😱 Stan emergency at \(step.rawValue): \(error.localizedDescription)")
    }
    
    func dismissCurrentError() {
        guard isShowingError else { return }
        
        withAnimation(.easeOut(duration: 0.3)) {
            currentError = nil
            isShowingError = false
        }
        
        // Show next error in queue
        if !errorQueue.isEmpty {
            let nextError = errorQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentError = nextError
                self.isShowingError = true
            }
        }
    }
    
    func clearAllErrors() {
        currentError = nil
        isShowingError = false
        errorQueue.removeAll()
    }
    
    // MARK: - Error Recovery Actions
    func retryAction(for error: OnboardingError, step: OnboardingStep, action: @escaping () async throws -> Void) {
        dismissCurrentError()
        
        Task {
            do {
                try await action()
            } catch {
                let newError = OnboardingError.from(error)
                handle(newError, step: step)
            }
        }
    }
    
    func skipAction(for error: OnboardingError, step: OnboardingStep, skipAction: @escaping () -> Void) {
        dismissCurrentError()
        skipAction()
        
        print("🏃‍♀️ Skipping stan step \(step.rawValue) - we'll comeback to this! Error: \(error.id)")
    }
}

// MARK: - Error Extension
extension OnboardingError {
    static func from(_ error: Error) -> OnboardingError {
        if let onboardingError = error as? OnboardingError {
            return onboardingError
        }
        
        // Convert common errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .networkError("No internet connection")
            case .timedOut:
                return .networkError("Request timed out")
            case .cannotFindHost:
                return .networkError("Server not found")
            default:
                return .networkError(urlError.localizedDescription)
            }
        }
        
        return .unknownError(error.localizedDescription)
    }
}

// MARK: - Error Alert View
struct OnboardingErrorAlert: View {
    @ObservedObject var errorHandler: OnboardingErrorHandler
    let currentStep: OnboardingStep
    let onRetry: (() async throws -> Void)?
    let onSkip: (() -> Void)?
    
    var body: some View {
        EmptyView()
            .alert(
                errorHandler.currentError?.localizedDescription ?? "An error occurred",
                isPresented: $errorHandler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                // Primary action based on error type
                if error.isRecoverable {
                    if let onRetry = onRetry {
                        Button("Try Again") {
                            errorHandler.retryAction(for: error, step: currentStep, action: onRetry)
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    
                    if let onSkip = onSkip {
                        Button("Skip", role: .cancel) {
                            errorHandler.skipAction(for: error, step: currentStep, skipAction: onSkip)
                        }
                    } else {
                        Button("OK", role: .cancel) {
                            errorHandler.dismissCurrentError()
                        }
                    }
                } else {
                    // Non-recoverable errors
                    Button("OK") {
                        errorHandler.dismissCurrentError()
                    }
                    .keyboardShortcut(.defaultAction)
                    
                    if let onSkip = onSkip {
                        Button("Continue Anyway", role: .destructive) {
                            errorHandler.skipAction(for: error, step: currentStep, skipAction: onSkip)
                        }
                    }
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                    }
                    
                    if !errorHandler.errorQueue.isEmpty {
                        Text("\(errorHandler.errorQueue.count) more error(s) pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

// MARK: - Error Toast View
struct OnboardingErrorToast: View {
    @ObservedObject var errorHandler: OnboardingErrorHandler
    
    var body: some View {
        ZStack {
            if let error = errorHandler.currentError, errorHandler.isShowingError {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Error icon
                        ZStack {
                            Circle()
                                .fill(error.isRecoverable ? Color.orange : Color.red)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: error.isRecoverable ? "exclamationmark.triangle.fill" : "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Error message
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(getKpopErrorMessage(error))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Text(getKpopErrorEmoji(error))
                                    .font(.title2)
                            }
                            
                            if let recovery = error.recoverySuggestion {
                                Text("Don't worry bestie, \(recovery.lowercased()) 💪")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        // Dismiss button
                        Button(action: {
                            errorHandler.dismissCurrentError()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Above bottom button
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: errorHandler.isShowingError)
            }
        }
        .allowsHitTesting(errorHandler.isShowingError)
    }
}

// MARK: - Haptic Feedback Helper
@MainActor
struct HapticFeedback {
    static func error() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }

    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
}

// MARK: - View Extensions for Error Handling
// MARK: - K-pop Error Messages
func getKpopErrorMessage(_ error: OnboardingError) -> String {
    switch error {
    case .networkError(let message):
        if message.contains("internet") {
            return "Your WiFi said 'not today bestie'!"
        } else if message.contains("timeout") {
            return "Server is being a slow bias wrecker..."
        } else {
            return "Network is having a moment, like us during comeback season"
        }
    case .validationError(let field):
        if field.contains("name") {
            return "Your stan name needs more love!"
        } else if field.contains("artist") {
            return "Too many biases? We get it, but calm down bestie"
        } else {
            return "Something's not quite right with your \(field)..."
        }
    case .userCreationFailed:
        return "Login said 'nope' - user creation failed"
    case .artistLoadingFailed:
        return "Couldn't load your biases - they're being shy"
    case .goalCreationFailed:
        return "Goal creation failed - even our servers have commitment issues"
    case .permissionDenied(let message):
        return "Permission denied - \(message)"
    case .serviceUnavailable:
        return "Our servers are having a main character moment"
    case .unknownError(_):
        return "Something went wrong and we're as confused as you are"
    }
}

func getKpopErrorEmoji(_ error: OnboardingError) -> String {
    switch error {
    case .networkError:
        return "📵"
    case .validationError:
        return "🤔"
    case .userCreationFailed:
        return "🙅‍♀️"
    case .artistLoadingFailed:
        return "😔"
    case .goalCreationFailed:
        return "💔"
    case .permissionDenied:
        return "🚫"
    case .serviceUnavailable:
        return "😴"
    case .unknownError:
        return "😵‍💫"
    }
}

extension View {
    func onboardingErrorHandling(
        errorHandler: OnboardingErrorHandler,
        currentStep: OnboardingStep,
        onRetry: (() async throws -> Void)? = nil,
        onSkip: (() -> Void)? = nil,
        showToast: Bool = false
    ) -> some View {
        self
            .background {
                if showToast {
                    OnboardingErrorToast(errorHandler: errorHandler)
                } else {
                    OnboardingErrorAlert(
                        errorHandler: errorHandler,
                        currentStep: currentStep,
                        onRetry: onRetry,
                        onSkip: onSkip
                    )
                }
            }
            .onChange(of: errorHandler.currentError) { _, error in
                if error != nil {
                    HapticFeedback.error()
                }
            }
    }
    
    func handleOnboardingError<T>(
        _ result: Result<T, Error>,
        step: OnboardingStep,
        errorHandler: OnboardingErrorHandler
    ) {
        switch result {
        case .success:
            break
        case .failure(let error):
            let onboardingError = OnboardingError.from(error)
            errorHandler.handle(onboardingError, step: step)
        }
    }
}

// MARK: - Network Connectivity Monitor
@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    
    enum ConnectionType {
        case wifi
        case cellular
        case none
    }
    
    static let shared = NetworkMonitor()
    
    private init() {
        // In a real implementation, this would use Network framework
        // For now, assume connected
        checkConnection()
    }
    
    private func checkConnection() {
        // Mock implementation
        // In real app, use NWPathMonitor
    }
    
    func hasConnection() -> Bool {
        return isConnected
    }
}

// MARK: - Validation Helpers
struct OnboardingValidation {
    @MainActor
    static func validateStep(_ step: OnboardingStep, data: OnboardingData) -> OnboardingError? {
        switch step {
        case .welcome, .intro:
            return nil
            
        case .name:
            if data.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .validationError("name")
            }
            if data.name.count < 2 {
                return .validationError("name (minimum 2 characters)")
            }
            return nil
            
        case .artistSelection:
            if data.selectedArtists.isEmpty {
                return nil // Artist selection is optional
            }
            if data.selectedArtists.count > OnboardingConstants.maxArtistsSelection {
                return .validationError("artist selection (maximum \(OnboardingConstants.maxArtistsSelection))")
            }
            return nil
            
        case .prioritySetting:
            return nil // Priority setting is optional
            
        case .goalSetting:
            if data.selectedGoals.isEmpty {
                return nil // Goal setting is optional
            }
            if data.selectedGoals.count > OnboardingConstants.maxGoalsSelection {
                return .validationError("goal selection (maximum \(OnboardingConstants.maxGoalsSelection))")
            }
            return nil
            
        case .bridge:
            return nil // Bridge screen has no validation requirements
            
        case .permissions:
            return nil // Permissions are optional
            
        case .insights:
            return nil // Insights are always valid
            
        case .authentication:
            return nil // Authentication will be handled by sign-in flow
            
        case .notifications:
            return nil // Notifications are optional
        }
    }
}