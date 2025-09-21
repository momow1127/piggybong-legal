import SwiftUI
import Foundation

// MARK: - Loading Request Model
struct LoadingRequest: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let isSimpleMode: Bool
    let priority: LoadingPriority
    let timeoutDuration: TimeInterval?
    let timestamp: Date

    init(message: String = "", isSimpleMode: Bool = false, priority: LoadingPriority = .normal, timeout: TimeInterval? = nil) {
        self.message = message
        self.isSimpleMode = isSimpleMode
        self.priority = priority
        self.timeoutDuration = timeout
        self.timestamp = Date()
    }
}

// MARK: - Loading Priority
enum LoadingPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: LoadingPriority, rhs: LoadingPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Global Loading Manager
class GlobalLoadingManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isVisible: Bool = false
    @Published var message: String = ""
    @Published var isSimpleMode: Bool = false

    // MARK: - Private Properties
    private var loadingQueue: [LoadingRequest] = []
    private var currentRequest: LoadingRequest?
    private var timeoutWorkItem: DispatchWorkItem?

    // MARK: - Singleton
    static let shared = GlobalLoadingManager()
    private init() {}

    // MARK: - Public Methods

    /// Show loading with message and options
    func show(
        _ message: String = "",
        simpleMode: Bool = false,
        priority: LoadingPriority = .normal,
        timeout: TimeInterval? = nil
    ) {
        let finalTimeout = timeout ?? defaultTimeout(for: priority)
        let finalMessage = message.isEmpty ? priority.defaultMessage : message

        let request = LoadingRequest(
            message: finalMessage,
            isSimpleMode: simpleMode,
            priority: priority,
            timeout: finalTimeout
        )

        addToQueue(request)
        processQueue()
    }

    /// Default timeout based on priority level
    private func defaultTimeout(for priority: LoadingPriority) -> TimeInterval {
        switch priority {
        case .critical: return 30.0  // Account deletion, onboarding
        case .high: return 15.0      // Logout, authentication
        case .normal: return 10.0    // AI insights, data sync
        case .low: return 5.0        // Background updates
        }
    }

    /// Hide current loading (if any)
    func hide() {
        guard !loadingQueue.isEmpty else { return }

        // Remove current request if it exists
        if let current = currentRequest {
            loadingQueue.removeAll { $0.id == current.id }
        }

        processQueue()
    }

    /// Hide loading with specific message (useful for specific operations)
    func hide(message: String) {
        loadingQueue.removeAll { $0.message == message }
        processQueue()
    }

    /// Force hide all loading (emergency use)
    func hideAll() {
        loadingQueue.removeAll()
        cancelTimeout()
        updateUI(visible: false, message: "", simpleMode: false)
        currentRequest = nil
    }

    /// Quick methods for common scenarios
    func showSimple(_ message: String = "Loading...") {
        show(message, simpleMode: true, priority: .normal)
    }

    func showCritical(_ message: String) {
        show(message, simpleMode: false, priority: .critical, timeout: 30.0)
    }

    // MARK: - Private Methods

    private func addToQueue(_ request: LoadingRequest) {
        // Remove any existing request with same message to avoid duplicates
        loadingQueue.removeAll { $0.message == request.message }

        // Add new request
        loadingQueue.append(request)

        // Sort by priority (highest first)
        loadingQueue.sort { $0.priority > $1.priority }

        print("🔄 GlobalLoading: Added request '\(request.message)' (Priority: \(request.priority))")
    }

    private func processQueue() {
        // Get highest priority request
        guard let nextRequest = loadingQueue.first else {
            // No more requests, hide loading
            cancelTimeout()
            updateUI(visible: false, message: "", simpleMode: false)
            currentRequest = nil
            print("🔄 GlobalLoading: Queue empty, hiding loading")
            return
        }

        // If this is the same request as current, don't update
        if let current = currentRequest, current.id == nextRequest.id {
            return
        }

        currentRequest = nextRequest
        updateUI(
            visible: true,
            message: nextRequest.message,
            simpleMode: nextRequest.isSimpleMode
        )

        // Setup timeout if specified
        setupTimeout(for: nextRequest)

        print("🔄 GlobalLoading: Showing '\(nextRequest.message)' (Priority: \(nextRequest.priority))")
    }

    private func updateUI(visible: Bool, message: String, simpleMode: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isVisible = visible
            self.message = message
            self.isSimpleMode = simpleMode
        }
    }

    private func setupTimeout(for request: LoadingRequest) {
        cancelTimeout()

        guard let timeout = request.timeoutDuration else { return }

        let workItem = DispatchWorkItem { [weak self] in
            print("⏰ GlobalLoading: Timeout reached for '\(request.message)'")
            self?.hide(message: request.message)
        }

        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    private func cancelTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
}

// MARK: - Critical Operations Only Extensions
extension GlobalLoadingManager {

    /// Critical operations that require full-screen blocking
    static let criticalOperations: Set<LoadingOperation> = [
        .authentication, .logout, .accountDeletion, .onboarding
    ]

    /// Check if an operation should use global (full-screen) loading
    func shouldUseGlobal(for operation: LoadingOperation) -> Bool {
        return Self.criticalOperations.contains(operation)
    }

    /// CRITICAL ONLY: Authentication flows
    func showAuthentication() {
        show(LoadingMessage.authentication, simpleMode: false, priority: .high)
    }

    /// CRITICAL ONLY: Account deletion (security operation)
    func showAccountDeletion() {
        show(LoadingMessage.accountDeletion, simpleMode: true, priority: .critical)
    }

    /// CRITICAL ONLY: User logout (security operation)
    func showLogout() {
        show(LoadingMessage.logout, simpleMode: true, priority: .high)
    }

    /// CRITICAL ONLY: Onboarding completion (app initialization)
    func showOnboardingCompletion() {
        show(LoadingMessage.onboardingFinalization, simpleMode: true, priority: .critical)
    }

    /// CRITICAL ONLY: RevenueCat subscription changes (payment-related)
    func showRevenueCat() {
        show(LoadingMessage.subscription, simpleMode: true, priority: .high)
    }

    // MARK: - Deprecated Methods (Use Contextual Loading Instead)

    @available(*, deprecated, message: "Use ContextualLoadingView for data sync operations")
    func showDataSync() {
        // For backward compatibility, but should be migrated to contextual loading
        show(LoadingMessage.dataSync, simpleMode: false, priority: .normal)
    }

    @available(*, deprecated, message: "Use ProgressiveAILoading for AI insight generation")
    func showAIInsight() {
        // For backward compatibility, but should be migrated to progressive loading
        show(LoadingMessage.aiInsight, simpleMode: false, priority: .normal)
    }

    /// Show loading using operation enum
    func show(for operation: LoadingOperation, simpleMode: Bool = false) {
        let message = LoadingMessage.forOperation(operation)
        let priority: LoadingPriority = {
            switch operation {
            case .accountDeletion, .onboarding: return .critical
            case .authentication, .logout, .payment: return .high
            case .aiInsight, .dataSync, .events: return .normal
            case .general: return .normal
            }
        }()

        show(message, simpleMode: simpleMode, priority: priority)
    }
}

// MARK: - Debug Extension
extension GlobalLoadingManager {
    var debugInfo: String {
        """
        GlobalLoadingManager Debug:
        - Visible: \(isVisible)
        - Current Message: "\(message)"
        - Simple Mode: \(isSimpleMode)
        - Queue Count: \(loadingQueue.count)
        - Current Request: \(currentRequest?.message ?? "None")
        """
    }
}