import SwiftUI
import Foundation

// MARK: - Fan Dashboard Data Model
struct FanDashboardData {
    var user: DashboardUser
    let fanArtists: [FanArtist]
    // fanGoals removed - no longer using goal functionality
    let aiTip: AITip?
    let recentActivity: [FanActivity]
    let totalMonthlyBudget: Double
    let totalMonthSpent: Double
    let upcomingEvents: [UpcomingEvent]
    // activeGoals removed - no longer using goal functionality
    let recentTransactions: [DashboardTransaction]
    var insights: [Insight]
    var monthSummary: MonthSummary
    
    // Legacy properties for backward compatibility
    let artists: [DashboardArtist]
    let achievements: [Achievement]
    let monthlyBudget: Double
    let spentThisMonth: Double
    let currentSavings: Double
    
    init(user: DashboardUser, fanArtists: [FanArtist], aiTip: AITip?, recentActivity: [FanActivity], totalMonthlyBudget: Double, totalMonthSpent: Double, upcomingEvents: [UpcomingEvent], recentTransactions: [DashboardTransaction], insights: [Insight], monthSummary: MonthSummary) {
        self.user = user
        self.fanArtists = fanArtists
        self.aiTip = aiTip
        self.recentActivity = recentActivity
        self.totalMonthlyBudget = totalMonthlyBudget
        self.totalMonthSpent = totalMonthSpent
        self.upcomingEvents = upcomingEvents
        self.recentTransactions = recentTransactions
        self.insights = insights
        self.monthSummary = monthSummary
        self.artists = fanArtists.map { fanArtist in
            DashboardArtist(
                id: fanArtist.id,
                name: fanArtist.name,
                imageURL: fanArtist.imageURL,
                upcomingEvents: 0,
                budgetAllocated: fanArtist.monthlyAllocation,
                budgetSpent: fanArtist.monthSpent
            )
        }
        self.achievements = []
        self.monthlyBudget = totalMonthlyBudget
        self.spentThisMonth = totalMonthSpent
        self.currentSavings = max(totalMonthlyBudget - totalMonthSpent, 0)
    }
    
    static var mock: FanDashboardData {
        FanDashboardData(
            user: DashboardUser.mock,
            fanArtists: FanArtist.mockArtists,
            aiTip: AITip.mockTip,
            recentActivity: [], // Empty for real user data
            totalMonthlyBudget: 500.0,
            totalMonthSpent: 200.0,
            upcomingEvents: UpcomingEvent.mockEvents,
            recentTransactions: DashboardTransaction.mockTransactions,
            insights: Insight.mockInsights,
            monthSummary: MonthSummary.mock
        )
    }
}

// Legacy FanUser for backward compatibility
struct FanUser {
    let id: UUID
    let name: String
    let profileImageURL: String?
    let memberSince: Date
    let totalSaved: Double
    
    static var mock: FanUser {
        FanUser(
            id: UUID(),
            name: "Fan",
            profileImageURL: nil,
            memberSince: Date().addingTimeInterval(-365*24*60*60),
            totalSaved: 1200.0
        )
    }
    
    // Convert to DashboardUser
    func toDashboardUser() -> DashboardUser {
        return DashboardUser(
            id: id,
            name: name,
            totalSaved: totalSaved,
            joinedDate: memberSince,
            profileImageURL: profileImageURL
        )
    }
}

struct DashboardArtist {
    let id: UUID
    let name: String
    let imageURL: String?
    let upcomingEvents: Int
    let budgetAllocated: Double
    let budgetSpent: Double
    
    static var mock: DashboardArtist {
        DashboardArtist(
            id: UUID(),
            name: "BTS",
            imageURL: nil as String?,
            upcomingEvents: 2,
            budgetAllocated: 300.0,
            budgetSpent: 150.0
        )
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let type: ActivityType
    let amount: Double?
    let fanCategory: FanCategory? // Added to support priority chart mapping
    
    enum ActivityType {
        case purchase, achievement, saving
    }
    
    static var mock: ActivityItem {
        ActivityItem(
            title: "Album Purchase",
            description: "Added new BTS album to collection",
            date: Date(),
            type: .purchase,
            amount: 25.0,
            fanCategory: .albums
        )
    }
}

// MARK: - Goal-related models removed
// Goal functionality has been removed from the app


// MARK: - Urgency Level
enum UrgencyLevel: String, CaseIterable, Codable {
    case low = "Low"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .piggySuccess
        case .high: return .piggyWarning
        case .critical: return .piggyError
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "clock"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Fan Category
enum FanCategory: String, CaseIterable, Codable, Hashable {
    case concerts = "Concerts & Shows"
    case albums = "Albums & Photocards"
    case merch = "Official Merch"
    case events = "Fan Events"
    case subscriptions = "Subscriptions & Apps"
    case other = "Other"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .concerts: return "🎤"
        case .albums: return "💿"
        case .merch: return "🛍️"
        case .events: return "📸"
        case .subscriptions: return "📱"
        case .other: return "✨"
        }
    }
    
    var emoji: String {
        switch self {
        case .concerts: return "🎤"
        case .albums: return "💿"
        case .merch: return "🛍️"
        case .events: return "📸"
        case .subscriptions: return "📱"
        case .other: return "✨"
        }
    }
    
    var color: Color {
        switch self {
        case .concerts: return .piggyPrimary
        case .albums: return .piggyAccent
        case .merch: return .piggySecondary
        case .events: return .piggyWarning
        case .subscriptions: return .piggySuccess
        case .other: return .piggyTextTertiary
        }
    }
    
    
    // MARK: - Priority Chart Category Mapping
    /// Maps FanCategory enum values to PiggyPriorityChart category IDs
    var priorityChartCategoryId: String {
        switch self {
        case .concerts:
            return "concerts"
        case .albums:
            return "albums"
        case .merch:
            return "merch"
        case .events:
            return "events"
        case .subscriptions:
            return "subscriptions"
        case .other:
            return "other"
        }
    }
    
    /// Creates FanCategory from string representation
    static func fromString(_ string: String) -> FanCategory {
        switch string.lowercased() {
        case "concerts", "concert", "shows":
            return .concerts
        case "albums", "album", "photocards":
            return .albums
        case "merch", "merchandise":
            return .merch
        case "events", "event", "fanmeet":
            return .events
        case "subscriptions", "subs", "apps":
            return .subscriptions
        default:
            return .other
        }
    }
}

// MARK: - Month Summary Model
struct MonthSummary: Codable {
    let month: String
    let budget: Double
    let spent: Double
    let saved: Double
    let remainingBudget: Double
    let spentPercentage: Double
    let isOverBudget: Bool
    
    var budgetStatus: BudgetStatus {
        if isOverBudget { return .overbudget }
        if spentPercentage > 0.8 { return .warning }
        if spentPercentage > 0.5 { return .moderate }
        return .healthy
    }
}

// MARK: - Transaction Model (Enhanced version of Purchase)
struct DashboardTransaction: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String?
    let amount: Double
    let type: TransactionType
    let category: TransactionCategory
    let date: Date
    let artistName: String?
    
    init(id: UUID = UUID(), title: String, subtitle: String? = nil, amount: Double, type: TransactionType, category: TransactionCategory, date: Date = Date(), artistName: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.artistName = artistName
    }
    
    var displayAmount: String {
        let prefix = type == .expense ? "-" : "+"
        return "\(prefix)$\(Int(abs(amount)))"
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

enum TransactionType: String, CaseIterable, Codable {
    case expense = "Expense"
    case income = "Income"
    case saving = "Saving"
}

enum TransactionCategory: String, CaseIterable, Codable {
    case concert = "Concert"
    case album = "Album"
    case merchandise = "Merchandise"
    case subscription = "Subscription"
    case food = "Food"
    case transport = "Transport"
    case saving = "Saving"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .concert: return "music.note"
        case .album: return "opticaldisc"
        case .merchandise: return "tshirt"
        case .subscription: return "star.circle"
        case .food: return "fork.knife"
        case .transport: return "car"
        case .saving: return "arrow.up.circle"
        case .other: return "circle"
        }
    }
    
    var color: Color {
        switch self {
        case .concert: return .piggyPrimary
        case .album: return .piggyAccent
        case .merchandise: return .piggySecondary
        case .subscription: return .piggyWarning
        case .food: return .piggySuccess
        case .transport: return .piggyWarning
        case .saving: return .piggyAccent
        case .other: return .piggyTextTertiary
        }
    }
}

// MARK: - Budget Status
enum BudgetStatus {
    case healthy, moderate, warning, overbudget
    
    var color: Color {
        switch self {
        case .healthy: return .piggySuccess
        case .moderate: return .piggyPrimary
        case .warning: return .piggyWarning
        case .overbudget: return .piggyError
        }
    }
    
    var message: String {
        switch self {
        case .healthy: return "Budget is in great shape"
        case .moderate: return "Budget is manageable"
        case .warning: return "Getting close to budget limit"
        case .overbudget: return "Over budget - time to reassess"
        }
    }
}

// MARK: - Insight Model
struct Insight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let actionTitle: String?
    let priority: InsightPriority
    let expiresAt: Date?
    
    init(id: UUID = UUID(), type: InsightType, title: String, message: String, actionTitle: String? = nil, priority: InsightPriority, expiresAt: Date? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.priority = priority
        self.expiresAt = expiresAt
    }
}

enum InsightType: String, CaseIterable, Codable {
    case concertAlert = "Concert Alert"
    case budgetWarning = "Budget Warning"
    case savingTip = "Saving Tip"
    case achievement = "Achievement"
    
    var icon: String {
        switch self {
        case .concertAlert: return "music.note"
        case .budgetWarning: return "exclamationmark.triangle"
        case .savingTip: return "lightbulb"
        case .achievement: return "star"
        }
    }
    
    var color: Color {
        switch self {
        case .concertAlert: return .piggyPrimary
        case .budgetWarning: return .piggyError
        case .savingTip: return .piggySuccess
        case .achievement: return .piggyWarning
        }
    }
}

enum InsightPriority: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .high: return .piggyError
        case .medium: return .piggyWarning
        case .low: return .piggyAccent
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .high: return 2
        case .medium: return 1
        case .low: return 0
        }
    }
}

// MARK: - Dashboard User Model (Enhanced version of User)
struct DashboardUser: Codable {
    let id: UUID
    let name: String
    let totalSaved: Double
    let monthlyBudget: Double
    let totalMonthlyBudget: Double
    let totalMonthSpent: Double
    let joinedDate: Date
    let profileImageURL: String?
    
    init(id: UUID = UUID(), name: String, totalSaved: Double = 0.0, monthlyBudget: Double = 300.0, totalMonthlyBudget: Double = 300.0, totalMonthSpent: Double = 0.0, joinedDate: Date = Date(), profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.totalSaved = totalSaved
        self.monthlyBudget = monthlyBudget
        self.totalMonthlyBudget = totalMonthlyBudget
        self.totalMonthSpent = totalMonthSpent
        self.joinedDate = joinedDate
        self.profileImageURL = profileImageURL
    }
    
    var formattedTotalSaved: String {
        return "$\(Int(totalSaved))"
    }
    
    var memberSince: Date? {
        return joinedDate
    }
}

// Note: FanDashboardData mock is now in FanExperienceModels.swift

extension DashboardUser {
    static let mock = DashboardUser(
        name: "K-pop Fan",
        totalSaved: 450.0,
        monthlyBudget: 300.0,
        totalMonthlyBudget: 300.0,
        totalMonthSpent: 145.0,
        joinedDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        profileImageURL: nil
    )
}

// Goal mock data removed - no longer using goal functionality

extension MonthSummary {
    static let mock = MonthSummary(
        month: DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1],
        budget: 300.0,
        spent: 145.0,
        saved: 50.0,
        remainingBudget: 155.0,
        spentPercentage: 0.48,
        isOverBudget: false
    )
}

extension DashboardTransaction {
    static let mockTransactions: [DashboardTransaction] = [
        DashboardTransaction(
            title: "Album Pre-order",
            subtitle: "IVE - I'VE MINE",
            amount: -25.0,
            type: .expense,
            category: .album,
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            artistName: "IVE"
        ),
        DashboardTransaction(
            title: "Monthly Savings",
            subtitle: "General savings",
            amount: 50.0,
            type: .saving,
            category: .saving,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            artistName: nil
        ),
        DashboardTransaction(
            title: "Starbucks",
            subtitle: "Coffee & snack",
            amount: -8.5,
            type: .expense,
            category: .food,
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            artistName: nil
        ),
        DashboardTransaction(
            title: "Monthly Savings",
            subtitle: "General savings",
            amount: 100.0,
            type: .saving,
            category: .saving,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            artistName: nil
        ),
        DashboardTransaction(
            title: "Concert Ticket",
            subtitle: "ITZY World Tour",
            amount: -120.0,
            type: .expense,
            category: .concert,
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            artistName: "ITZY"
        )
    ]
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: AchievementCategory
    let earnedAt: Date
    let xpPoints: Int
    let badge: String
    
    init(id: UUID = UUID(), title: String, description: String, category: AchievementCategory, earnedAt: Date = Date(), xpPoints: Int = 10, badge: String) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.earnedAt = earnedAt
        self.xpPoints = xpPoints
        self.badge = badge
    }
}

enum AchievementCategory: String, CaseIterable, Codable {
    case saving = "Saving"
    case spending = "Spending"
    case streak = "Streak"
    
    var color: Color {
        switch self {
        case .saving: return .piggySuccess
        case .spending: return .piggyPrimary
        case .streak: return .piggyWarning
        }
    }
}

extension Achievement {    
    static let mockAchievements: [Achievement] = [
        Achievement(
            title: "First Purchase!",
            description: "You made your first fan activity purchase",
            category: .spending,
            xpPoints: 50,
            badge: "🎯"
        ),
        Achievement(
            title: "Saving Streak",
            description: "7 days of consistent saving",
            category: .streak,
            xpPoints: 25,
            badge: "🔥"
        )
    ]
}

extension Insight {
    static let mockInsights: [Insight] = [
        Insight(
            type: .concertAlert,
            title: "🎤 BTS Concert Alert!",
            message: "Tickets for BTS World Tour go on sale tomorrow!",
            actionTitle: "Set Reminder",
            priority: .high,
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        ),
        Insight(
            type: .budgetWarning,
            title: "💰 Budget Check-in",
            message: "You're close to your monthly spending limit",
            actionTitle: "View Budget",
            priority: .medium,
            expiresAt: nil
        ),
        Insight(
            type: .savingTip,
            title: "✨ Smart Tip",
            message: "Skip one coffee this week to save $15 for your concert fund!",
            actionTitle: "Learn More",
            priority: .low,
            expiresAt: nil
        )
    ]
}
