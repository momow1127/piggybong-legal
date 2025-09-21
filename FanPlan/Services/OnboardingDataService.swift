import Foundation
import SwiftUI

// MARK: - Goal Category Enum
enum DBGoalCategory: String, CaseIterable, Codable {
    case concert = "Concert"
    case merchandise = "Merchandise"
    case album = "Album"
    case travel = "Travel"
    case savings = "Savings"
    case experience = "Experience"
    case fanmeet = "Fan Meet"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .concert: return "music.note"
        case .merchandise: return "tshirt"
        case .album: return "opticaldisc"
        case .travel: return "airplane"
        case .savings: return "arrow.up.circle"
        case .experience: return "star"
        case .fanmeet: return "person.3.fill"
        case .other: return "circle"
        }
    }
    
    var color: Color {
        switch self {
        case .concert: return .purple
        case .merchandise: return .orange
        case .album: return .blue
        case .travel: return .green
        case .savings: return .mint
        case .experience: return .yellow
        case .fanmeet: return .pink
        case .other: return .gray
        }
    }
}

// MARK: - Onboarding Data Models
struct OnboardingProgress: Codable {
    let userId: UUID
    var currentStep: String
    var completedSteps: [String]
    var isCompleted: Bool
    var artistPreferences: [UUID]
    var biasGoalPreferences: [BiasGoalTemplate]
    let createdAt: Date
    var updatedAt: Date
}

struct BiasGoalTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: DBGoalCategory
    let suggestedAmount: Double
    let description: String
    let iconName: String
    let isPopular: Bool
    let priorityLevel: BiasPriority
    
    init(
        id: UUID = UUID(),
        name: String,
        category: DBGoalCategory,
        suggestedAmount: Double,
        description: String,
        iconName: String,
        isPopular: Bool = false,
        priorityLevel: BiasPriority
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.suggestedAmount = suggestedAmount
        self.description = description
        self.iconName = iconName
        self.isPopular = isPopular
        self.priorityLevel = priorityLevel
    }
}

struct FanPlanningPreferences: Codable {
    var notificationsEnabled: Bool
    var comebackAlerts: Bool
    var tourAnnouncements: Bool
    var merchDropAlerts: Bool
    var preferredCurrency: String
    var privacyLevel: PrivacyLevel
    var biasPriorityMode: BiasPriorityMode
    
    enum PrivacyLevel: String, Codable, CaseIterable {
        case `public` = "public"
        case friends = "friends"
        case `private` = "private"
    }
    
    static let `default` = FanPlanningPreferences(
        notificationsEnabled: true,
        comebackAlerts: true,
        tourAnnouncements: true,
        merchDropAlerts: false,
        preferredCurrency: "USD",
        privacyLevel: .`private`,
        biasPriorityMode: .balanced
    )
}

// MARK: - Onboarding Data Service
@MainActor
class OnboardingDataService: ObservableObject {
    @Published var progress: OnboardingProgress?
    @Published var preferences = FanPlanningPreferences.default
    
    private let supabaseService = SupabaseService.shared
    private let userDefaults = UserDefaults.standard
    
    func saveProgress(_ progress: OnboardingProgress) async {
        do {
            let progressData = try JSONEncoder().encode(progress)
            userDefaults.set(progressData, forKey: "onboarding_progress_\(progress.userId)")
            self.progress = progress
        } catch {
            print("Failed to save onboarding progress: \(error)")
        }
    }
    
    func loadProgress(for userId: UUID) -> OnboardingProgress? {
        guard let data = userDefaults.data(forKey: "onboarding_progress_\(userId)"),
              let progress = try? JSONDecoder().decode(OnboardingProgress.self, from: data) else {
            return nil
        }
        self.progress = progress
        return progress
    }
    
    func savePreferences() async {
        do {
            let preferencesData = try JSONEncoder().encode(preferences)
            userDefaults.set(preferencesData, forKey: "fan_planning_preferences")
        } catch {
            print("Failed to save preferences: \(error)")
        }
    }
    
    func loadPreferences() {
        guard let data = userDefaults.data(forKey: "fan_planning_preferences"),
              let savedPreferences = try? JSONDecoder().decode(FanPlanningPreferences.self, from: data) else {
            return
        }
        preferences = savedPreferences
    }
    
    func markStepCompleted(_ step: String) {
        guard var currentProgress = progress else { return }
        
        if !currentProgress.completedSteps.contains(step) {
            currentProgress.completedSteps.append(step)
            currentProgress.currentStep = step
            currentProgress.updatedAt = Date()
            
            Task {
                await saveProgress(currentProgress)
            }
        }
    }
    
    func completeOnboarding(for userId: UUID) async {
        guard var currentProgress = progress else {
            let newProgress = OnboardingProgress(
                userId: userId,
                currentStep: "completed",
                completedSteps: ["welcome", "intro", "name", "budget", "artists", "goals", "notifications", "completion"],
                isCompleted: true,
                artistPreferences: [],
                biasGoalPreferences: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            await saveProgress(newProgress)
            return
        }
        
        currentProgress.isCompleted = true
        currentProgress.currentStep = "completed"
        currentProgress.updatedAt = Date()
        await saveProgress(currentProgress)

        // Track onboarding completion analytics
        AIInsightAnalyticsService.shared.logOnboardingCompleted(
            artistsSelected: currentProgress.artistPreferences.count,
            budgetSet: 0.0, // TODO: Get actual budget from user preferences
            aiEnabled: true
        )
    }
}

// MARK: - Supporting Enums
enum BiasPriority: String, Codable, CaseIterable {
    case ultimate = "ultimate"
    case high = "high"
    case medium = "medium"
    case casual = "casual"
    
    var displayName: String {
        switch self {
        case .ultimate: return "Ultimate Bias"
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .casual: return "Casual Follow"
        }
    }
}

enum BiasPriorityMode: String, Codable, CaseIterable {
    case focused = "focused"     // Prioritize 1-2 main artists
    case balanced = "balanced"   // Equal attention to all followed artists
    case flexible = "flexible"   // Adjust priorities based on comebacks
    
    var description: String {
        switch self {
        case .focused: return "Focus spending on your ultimate bias"
        case .balanced: return "Balance spending across all your artists"
        case .flexible: return "Adjust priorities based on comeback timing"
        }
    }
}