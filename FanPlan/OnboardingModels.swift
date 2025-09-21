import Foundation
import SwiftUI

// Import necessary files that define our types
// Note: Artist type comes from another file in the project

// Resolve Artist type ambiguity - alias to prevent conflicts
typealias OBArtist = Artist

// MARK: - Priority Level
enum PriorityLevel: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium" 
    case low = "Low"
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    var emoji: String {
        switch self {
        case .high: return "🔥"
        case .medium: return "⭐"
        case .low: return "💙"
        }
    }
}

// MARK: - Onboarding Data Container
@MainActor
class OnboardingData: ObservableObject {
    @Published var name: String = "Fan"  // Default name since we skip input
    @Published var monthlyBudget: Double = 0.0  // Removed - no longer using budget
    // ID-based selection for persistence across searches
    @Published var selectedArtistIDs: [UUID] = [] // Ordered for badge positions
    private var artistByID: [UUID: OBArtist] = [:] // Cache for O(1) lookup
    private var selectedIDsSet: Set<UUID> = Set() // O(1) membership check
    
    @Published var selectedGoals: [BiasGoalTemplate] = []  // Wishlist priorities
    @Published var selectedSpendingCategories: Set<String> = []
    @Published var categoryPriorities: [String: PriorityLevel] = [:]
    @Published var priorityRanking: [FanCategory] = []  // User's priority order
    @Published var customGoalAmounts: [UUID: Double] = [:]
    @Published var preferences: FanPlanningPreferences = .default
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading: Bool = false
    @Published var error: OnboardingError?
    
    // Validation states
    @Published var isNameValid: Bool = false
    @Published var hasSelectedArtists: Bool = false
    @Published var hasSelectedGoals: Bool = false
    @Published var hasSetPriorities: Bool = false
    
    init() {
        setupValidation()
    }
    
    private func setupValidation() {
        // Name validation
        $name
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$isNameValid)
        
        // Budget validation removed - no longer needed
        
        // Artists selection validation
        $selectedArtistIDs
            .map { !$0.isEmpty }
            .assign(to: &$hasSelectedArtists)
        
        // Goals selection validation
        $selectedGoals
            .map { !$0.isEmpty }
            .assign(to: &$hasSelectedGoals)
        
        // Priority ranking validation
        $priorityRanking
            .map { !$0.isEmpty }
            .assign(to: &$hasSetPriorities)
    }
    
    // MARK: - Step Validation
    func canProceedFromStep(_ step: OnboardingStep) -> Bool {
        switch step {
        case .welcome, .intro:
            return true
        case .name:
            return isNameValid
        case .artistSelection:
            return hasSelectedArtists
        case .prioritySetting:
            return hasSetPriorities
        case .goalSetting:
            return true  // Always allow skipping goal setting
        case .bridge:
            return true // Always can proceed from bridge
        case .permissions:
            return true // Always can proceed from permissions
        case .insights:
            return true // Always can proceed from insights
        case .authentication:
            return true // Always can proceed from authentication (after successful login)
        case .notifications:
            return true // Always can proceed from notifications
        }
    }
    
    // MARK: - Artist ID Cache Management
    func updateArtistCache(with artists: [OBArtist]) {
        for artist in artists {
            artistByID[artist.id] = artist
        }
    }
    
    // MARK: - Computed Properties
    var selectedArtists: [OBArtist] {
        return selectedArtistIDs.compactMap { artistByID[$0] }
    }
    
    // MARK: - Goal Amount Management
    func setCustomAmount(for goalId: UUID, amount: Double) {
        customGoalAmounts[goalId] = amount
    }
    
    func getAmount(for goal: BiasGoalTemplate) -> Double {
        return customGoalAmounts[goal.id] ?? goal.suggestedAmount
    }
    
    // MARK: - Artist Management (ID-based)
    func toggleArtist(_ artist: OBArtist) {
        // Update cache with this artist
        artistByID[artist.id] = artist
        
        if let index = selectedArtistIDs.firstIndex(of: artist.id) {
            // Deselect: remove from ordered list
            selectedArtistIDs.remove(at: index)
            selectedIDsSet.remove(artist.id)
        } else if selectedArtistIDs.count < OnboardingConstants.maxArtistsSelection {
            // Select: append to end (becomes 1st/2nd/3rd)
            selectedArtistIDs.append(artist.id)
            selectedIDsSet.insert(artist.id)
        }
        // If at limit, do nothing (rejection handled in ArtistSelectionView)
    }
    
    func getArtistSelectionOrder(_ artist: OBArtist) -> Int? {
        guard let index = selectedArtistIDs.firstIndex(of: artist.id) else { return nil }
        return index + 1 // 1-based for display (1st, 2nd, 3rd)
    }
    
    func isArtistSelected(_ artist: OBArtist) -> Bool {
        return selectedIDsSet.contains(artist.id) // O(1) lookup
    }
    
    func canSelectMoreArtists() -> Bool {
        return selectedArtistIDs.count < OnboardingConstants.maxArtistsSelection
    }
    
    func enforceArtistLimit() {
        // If somehow more than max artists are selected, keep only the first 3
        if selectedArtistIDs.count > OnboardingConstants.maxArtistsSelection {
            let removedIDs = Array(selectedArtistIDs.dropFirst(OnboardingConstants.maxArtistsSelection))
            selectedArtistIDs = Array(selectedArtistIDs.prefix(OnboardingConstants.maxArtistsSelection))
            
            // Update set to match
            for id in removedIDs {
                selectedIDsSet.remove(id)
            }
        }
    }
    
    // MARK: - Goal Management
    func toggleGoal(_ goal: BiasGoalTemplate) {
        if selectedGoals.contains(where: { $0.id == goal.id }) {
            selectedGoals.removeAll { $0.id == goal.id }
            customGoalAmounts.removeValue(forKey: goal.id)
        } else {
            selectedGoals.append(goal)
        }
    }
    
    func isGoalSelected(_ goal: BiasGoalTemplate) -> Bool {
        selectedGoals.contains(where: { $0.id == goal.id })
    }
    
    // MARK: - Priority Management
    func setPriorityRanking(_ categories: [FanCategory]) {
        priorityRanking = categories
    }
    
    func syncCategoryPrioritiesFromRanking() {
        categoryPriorities = [:]
        for (index, category) in priorityRanking.enumerated() {
            switch index {
            case 0...1: categoryPriorities[category.priorityChartCategoryId] = .high
            case 2...3: categoryPriorities[category.priorityChartCategoryId] = .medium
            default: categoryPriorities[category.priorityChartCategoryId] = .low
            }
        }
        print("🔗 Synced category priorities: \(categoryPriorities)")
    }
    
    func movePriorityCategory(from source: IndexSet, to destination: Int) {
        priorityRanking.move(fromOffsets: source, toOffset: destination)
    }
    
    func resetPriorities() {
        priorityRanking = []
    }
    
    // MARK: - Reset
    func reset() {
        name = "Fan"  // Default name
        selectedArtistIDs = []
        artistByID = [:]
        selectedIDsSet = Set()
        selectedGoals = []
        selectedSpendingCategories = []
        categoryPriorities = [:]
        priorityRanking = []
        customGoalAmounts = [:]
        preferences = .default
        currentStep = .welcome
        isLoading = false
        error = nil
    }
}

// MARK: - Enhanced Onboarding Steps
enum OnboardingStep: String, CaseIterable, Codable {
    case welcome
    case intro
    case name
    case artistSelection
    case prioritySetting  // Priority ranking step (no goal creation)
    case goalSetting  // Keep for backward compatibility but skip in flow
    case bridge
    case permissions
    case insights
    case authentication
    case notifications
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .intro: return "Introduction"
        case .name: return "About You"
        case .artistSelection: return "Choose Artists"
        case .prioritySetting: return "Priority Categories"
        case .goalSetting: return "Wishlist Priorities"
        case .bridge: return "You're All Set!"
        case .permissions: return "Permissions"
        case .insights: return "Your Plan"
        case .authentication: return "Sign In"
        case .notifications: return "Stay Updated"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "Your K-pop journey starts here"
        case .intro: return "Let's get you started"
        case .name: return "Personalize your experience"
        case .artistSelection: return "Follow your favorite K-pop artists"
        case .prioritySetting: return "Rank your spending priorities"
        case .goalSetting: return "What's on your K-pop wishlist?"
        case .bridge: return "Ready to start your K-pop journey"
        case .permissions: return "Stay updated with notifications"
        case .insights: return "Your smart fan setup is ready"
        case .authentication: return "Create an account to save your progress"
        case .notifications: return "Never miss a comeback"
        }
    }
    
    var iconName: String {
        switch self {
        case .welcome: return "star.fill"
        case .intro: return "info.circle.fill"
        case .name: return "person.fill"
        case .artistSelection: return "music.note"
        case .prioritySetting: return "list.number"
        case .goalSetting: return "heart.fill"
        case .bridge: return "checkmark.circle.fill"
        case .permissions: return "bell.fill"
        case .insights: return "lightbulb.fill"
        case .authentication: return "person.badge.key.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    var progressValue: Double {
        // Skip name step in progress calculation, add prioritySetting
        let stepOrder: [OnboardingStep] = [.welcome, .intro, .artistSelection, .prioritySetting, .insights, .authentication, .notifications]  // goalSetting removed from flow
        let totalSteps = Double(stepOrder.count)
        let currentIndex = Double(stepOrder.firstIndex(of: self) ?? 0)
        return (currentIndex + 1) / totalSteps
    }
    
    var nextStep: OnboardingStep? {
        switch self {
        case .welcome:
            return .intro
        case .intro:
            return .artistSelection  // Skip name step
        case .name:
            return .artistSelection
        case .artistSelection:
            return .prioritySetting  // Go to priority setting
        case .prioritySetting:
            return .insights  // Skip goal setting - go directly to insights
        case .goalSetting:
            return .insights  // Goal setting bypassed
        case .bridge:
            return nil  // Final step
        case .insights:
            return .authentication
        case .authentication:
            return .notifications
        case .permissions:
            return .insights
        case .notifications:
            return nil  // Final step - goes to dashboard
        }
    }
    
    var previousStep: OnboardingStep? {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: self),
              currentIndex > 0 else {
            return nil
        }
        return OnboardingStep.allCases[currentIndex - 1]
    }
}

// MARK: - Onboarding Errors
enum OnboardingError: LocalizedError, Identifiable, Equatable {
    case networkError(String)
    case validationError(String)
    case serviceUnavailable
    case userCreationFailed
    case artistLoadingFailed
    case goalCreationFailed
    case permissionDenied(String)
    case unknownError(String)
    
    var id: String {
        switch self {
        case .networkError(let message): return "network_\(message)"
        case .validationError(let field): return "validation_\(field)"
        case .serviceUnavailable: return "service_unavailable"
        case .userCreationFailed: return "user_creation_failed"
        case .artistLoadingFailed: return "artist_loading_failed"
        case .goalCreationFailed: return "goal_creation_failed"
        case .permissionDenied(let permission): return "permission_\(permission)"
        case .unknownError(let message): return "unknown_\(message)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .validationError(let field):
            return "Please check your \(field) and try again"
        case .serviceUnavailable:
            return "Service is temporarily unavailable. Please try again later."
        case .userCreationFailed:
            return "Failed to create your profile. Please try again."
        case .artistLoadingFailed:
            return "Unable to load artists. Please check your connection."
        case .goalCreationFailed:
            return "Failed to create your goals. Please try again."
        case .permissionDenied(let permission):
            return "\(permission) permission is required for the best experience"
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .validationError:
            return "Please review your input and correct any errors"
        case .serviceUnavailable:
            return "Please wait a moment and try again"
        case .userCreationFailed:
            return "Try restarting the app or contact support"
        case .artistLoadingFailed:
            return "Pull to refresh or check your internet connection"
        case .goalCreationFailed:
            return "You can set up goals later in the app settings"
        case .permissionDenied:
            return "You can enable this later in Settings"
        case .unknownError:
            return "Please restart the app or contact support"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .networkError, .serviceUnavailable, .artistLoadingFailed:
            return true
        case .validationError, .permissionDenied:
            return true
        case .userCreationFailed, .goalCreationFailed, .unknownError:
            return false
        }
    }
}

// MARK: - Artist Selection State
enum ArtistSelectionMode: Equatable, Hashable {
    case popular
    case trending
    case search(String)
    case mySelection
    
    var title: String {
        switch self {
        case .popular: return "Popular Artists"
        case .trending: return "Trending Now"
        case .search(let query): return "Results for \"\(query)\""
        case .mySelection: return "My Artists"
        }
    }
    
    var rawValue: String {
        switch self {
        case .popular: return "popular"
        case .trending: return "trending" 
        case .search: return "search"
        case .mySelection: return "mySelection"
        }
    }
}

// MARK: - Goal Category Extensions
extension FanCategory {
    // Note: color property is defined in DashboardModels.swift
    
    var gradientColors: [Color] {
        switch self {
        case .concerts:
            return [.purple, .pink]
        case .albums:
            return [.blue, .cyan]
        case .merch:
            return [.orange, .yellow]
        case .events:
            return [.pink, .red]
        case .subscriptions:
            return [.purple, .indigo]
        // Removed - albums case covers photocards
        case .other:
            return [.gray, .secondary]
        }
    }
}

// MARK: - Onboarding Analytics
struct OnboardingAnalytics {
    static func trackStepCompleted(_ step: OnboardingStep, timeSpent: TimeInterval) {
        print("📊 Analytics: Step \(step.rawValue) completed in \(timeSpent) seconds")
        // In real implementation, send to analytics service
    }
    
    static func trackArtistSelected(_ artist: OBArtist, selectionMethod: String) {
        print("📊 Analytics: Artist \(artist.name) selected via \(selectionMethod)")
    }
    
    static func trackGoalSelected(_ goal: BiasGoalTemplate, customAmount: Double?) {
        let amount = customAmount ?? goal.suggestedAmount
        print("📊 Analytics: Goal \(goal.name) selected with amount $\(amount)")
    }
    
    static func trackOnboardingCompleted(totalTime: TimeInterval, stepsCompleted: Int) {
        print("📊 Analytics: Onboarding completed in \(totalTime) seconds, \(stepsCompleted) steps")
    }
    
    static func trackError(_ error: OnboardingError, step: OnboardingStep) {
        print("📊 Analytics: Error \(error.id) at step \(step.rawValue)")
    }
}

// MARK: - Onboarding Constants
enum OnboardingConstants {
    static let maxArtistsSelection = 3
    static let maxGoalsSelection = 5
    static let minBudget: Double = 50
    static let maxBudget: Double = 10000
    static let defaultBudgetPresets = [100, 200, 300, 500, 1000]
    
    enum AnimationDurations {
        static let cardFlip: Double = 0.6
        static let slideTransition: Double = 0.4
        static let buttonPress: Double = 0.15
        static let errorShake: Double = 0.5
    }
    
    enum Colors {
        static let primaryGradient = [Color.piggyPrimary, Color.piggySecondary]
        static let successGreen = Color.green
        static let warningYellow = Color.yellow
        static let errorRed = Color.red
    }
}