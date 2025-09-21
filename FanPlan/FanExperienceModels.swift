import Foundation
import SwiftUI

// MARK: - Basic Artist Model
public struct Artist: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let group: String?
    public let imageURL: String?
    
    public init(id: UUID = UUID(), name: String, group: String? = nil, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.group = group
        self.imageURL = imageURL
    }
    
    // MARK: - Equatable/Hashable conformance by id only
    public static func == (lhs: Artist, rhs: Artist) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Convert to FanArtist with defaults
    func toFanArtist(priorityRank: Int = 1, monthlyAllocation: Double = 100.0) -> FanArtist {
        return FanArtist(
            id: self.id,
            name: self.name,
            priorityRank: priorityRank,
            monthlyAllocation: monthlyAllocation,
            monthSpent: 0.0,
            totalSpent: 0.0,
            remainingBudget: monthlyAllocation,
            spentPercentage: 0.0,
            imageURL: self.imageURL,
            timeline: [],
            wishlistItems: [],
            priorities: []
        )
    }
}

extension Artist {
    static let mockArtists: [Artist] = [
        Artist(name: "BTS", group: "Bangtan Boys"),
        Artist(name: "BLACKPINK", group: "BLACKPINK"),
        Artist(name: "NewJeans", group: "NewJeans"),
        Artist(name: "IVE", group: "IVE"),
        Artist(name: "TWICE", group: "TWICE"),
        Artist(name: "aespa", group: "aespa")
    ]
}

// MARK: - Fan Experience UI Models

struct FanArtist: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let priorityRank: Int
    let monthlyAllocation: Double
    let monthSpent: Double
    let totalSpent: Double
    let remainingBudget: Double
    let spentPercentage: Double
    let imageURL: String?
    
    let timeline: [ArtistTimelineItem]
    let wishlistItems: [WishlistItem]
    let priorities: [UserPriority]
    
    private var statusInternal: AppBudgetStatus {
        if spentPercentage >= 90 { return .overbudget }
        if spentPercentage >= 75 { return .warning }
        if spentPercentage >= 50 { return .moderate }
        return .healthy
    }
    
    var budgetStatus: BudgetStatus { 
        statusInternal.toUI() 
    }
    
    var priorityBadge: String {
        switch priorityRank {
        case 1: return "#1 Bias"
        case 2: return "#2 Bias"
        case 3: return "#3 Bias"
        default: return "Bias #\(priorityRank)"
        }
    }
    
    var allocationDescription: String {
        return "$\(Int(monthlyAllocation))/month"
    }
    
    func toArtist() -> Artist {
        return Artist(id: self.id, name: self.name, group: nil, imageURL: self.imageURL)
    }
}

enum AppBudgetStatus {
    case healthy, moderate, warning, overbudget
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .moderate: return .blue
        case .warning: return .orange
        case .overbudget: return .red
        }
    }
    
    var message: String {
        switch self {
        case .healthy: return "Looking good!"
        case .moderate: return "On track"
        case .warning: return "Watch spending"
        case .overbudget: return "Over budget"
        }
    }
    
    func toUI() -> BudgetStatus {
        switch self {
        case .healthy: return .healthy
        case .moderate: return .moderate
        case .warning: return .warning
        case .overbudget: return .overbudget
        }
    }
    
    static func fromUI(_ ui: BudgetStatus) -> AppBudgetStatus {
        switch ui {
        case .healthy: return .healthy
        case .moderate: return .moderate
        case .warning: return .warning
        case .overbudget: return .overbudget
        }
    }
}

// FanGoal struct removed - no longer using goal functionality

// MARK: - DB to UI Bridge
private extension DBGoalType {
    func asFanCategory() -> FanCategory {
        switch self {
        case .concertTickets: return .concerts
        case .albumCollection: return .albums
        case .merchHaul: return .merch
        case .fanmeetTickets: return .events
        case .photocardsComplete: return .albums
        case .digitalSubscriptions: return .subscriptions
        case .general: return .other
        }
    }
}

// UrgencyLevel is defined in PriorityModels.swift

struct FanPurchase: Identifiable, Codable {
    let id: UUID
    let artistId: UUID
    let artistName: String
    let amount: Double
    let category: FanCategory
    let description: String
    let contextNote: String?
    let isComebackRelated: Bool
    let venueLocation: String?
    let albumVersion: String?
    let purchaseDate: Date
    
    var displayTitle: String {
        if isComebackRelated {
            return "\(description) (Comeback!)"
        }
        return description
    }
    
    var contextualSubtitle: String {
        var parts: [String] = [artistName]
        
        if let context = contextNote {
            parts.append(context)
        } else {
            parts.append(category.displayName)
        }
        
        if let venue = venueLocation {
            parts.append("at \(venue)")
        }
        
        if let version = albumVersion {
            parts.append("(\(version) version)")
        }
        
        return parts.joined(separator: " • ")
    }
}

// MARK: - Mock Data Extensions

extension FanArtist {
    static let mockArtists: [FanArtist] = [
        FanArtist(
            id: UUID(),
            name: "BTS",
            priorityRank: 1,
            monthlyAllocation: 120.0,
            monthSpent: 65.0,
            totalSpent: 450.0,
            remainingBudget: 55.0,
            spentPercentage: 54.2,
            imageURL: nil,
            timeline: ArtistTimelineItem.mockTimelineForBTS,
            wishlistItems: WishlistItem.mockWishlistForBTS,
            priorities: UserPriority.mockPrioritiesForBTS
        ),
        FanArtist(
            id: UUID(),
            name: "NewJeans",
            priorityRank: 2,
            monthlyAllocation: 80.0,
            monthSpent: 40.0,
            totalSpent: 180.0,
            remainingBudget: 40.0,
            spentPercentage: 50.0,
            imageURL: nil,
            timeline: [],
            wishlistItems: [],
            priorities: []
        ),
        FanArtist(
            id: UUID(),
            name: "BLACKPINK",
            priorityRank: 3,
            monthlyAllocation: 100.0,
            monthSpent: 40.0,
            totalSpent: 300.0,
            remainingBudget: 60.0,
            spentPercentage: 40.0,
            imageURL: nil,
            timeline: [],
            wishlistItems: [],
            priorities: []
        )
    ]
}

// FanGoal mock data removed - no longer using goal functionality

extension AITip {
    static let mockTip = AITip(
        id: UUID(),
        message: "Consider setting aside $20 this week for your BTS concert fund!",
        tipType: .strategy,
        artistName: "BTS",
        isPremium: false,
        expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        createdAt: Date()
    )
}

extension FanActivity {
    var categoryIcon: String {
        return fanCategory?.icon ?? "🎵"
    }
    
    var categoryTitle: String {
        return fanCategory?.displayName ?? "Other"
    }
    
    static let mockActivities: [FanActivity] = [
        // Goal progress activity removed - goal functionality no longer supported
        FanActivity(
            id: UUID(),
            artistName: "IVE",
            activityType: .purchase,
            title: "Album Pre-order",
            description: "I'VE MINE - Special Edition",
            amount: 25.0,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            fanCategory: .albums
        ),
        FanActivity(
            id: UUID(),
            artistName: "NewJeans",
            activityType: .milestoneReached,
            title: "50% Goal Reached!",
            description: "Album Collection Fund",
            amount: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            fanCategory: .albums
        )
    ]
}

extension UpcomingEvent {
    static let mockEvents: [UpcomingEvent] = [
        UpcomingEvent(
            id: UUID(),
            artistName: "BTS",
            eventType: .concert,
            title: "BTS World Tour",
            date: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            daysUntil: 10,
            isRelatedToUserGoals: true
        ),
        UpcomingEvent(
            id: UUID(),
            artistName: "NewJeans",
            eventType: .albumRelease,
            title: "New Album Release",
            date: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
            daysUntil: 21,
            isRelatedToUserGoals: true
        ),
        UpcomingEvent(
            id: UUID(),
            artistName: "BLACKPINK",
            eventType: .merchandise,
            title: "Limited Edition Merch Drop",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            daysUntil: 5,
            isRelatedToUserGoals: false
        )
    ]
}

struct AITip: Identifiable, Codable {
    let id: UUID
    let message: String
    let tipType: TipType
    let artistName: String?
    let isPremium: Bool
    let expiresAt: Date?
    let createdAt: Date
    
    var displayMessage: String {
        if isPremium {
            return "✨ \(message)"
        }
        return message
    }
    
    var typeIcon: String {
        switch tipType {
        case .cheer: return "heart.fill"
        case .strategy: return "brain.head.profile"
        case .comebackAlert: return "bell.fill"
        case .budgetWarning: return "exclamationmark.triangle.fill"
        }
    }
    
    var typeColor: Color {
        switch tipType {
        case .cheer: return .pink
        case .strategy: return .blue
        case .comebackAlert: return .purple
        case .budgetWarning: return .orange
        }
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

enum TipType: String, CaseIterable, Codable {
    case cheer = "cheer"
    case strategy = "strategy"
    case comebackAlert = "comeback_alert"
    case budgetWarning = "budget_warning"
    
    var displayName: String {
        switch self {
        case .cheer: return "Daily Cheer"
        case .strategy: return "Smart Strategy"
        case .comebackAlert: return "Comeback Alert"
        case .budgetWarning: return "Budget Warning"
        }
    }
}

struct FanActivity: Identifiable, Codable {
    let id: UUID
    let artistName: String?
    let activityType: ActivityType
    let title: String
    let description: String?
    let amount: Double?
    let createdAt: Date
    let fanCategory: FanCategory? // Added to support priority chart mapping
    
    var displayTitle: String {
        return title
    }
    
    var displaySubtitle: String {
        var parts: [String] = []
        
        if let artistName = artistName {
            parts.append(artistName)
        }
        
        if let description = description {
            parts.append(description)
        }
        
        if parts.isEmpty {
            parts.append(activityType.displayName)
        }
        
        return parts.joined(separator: " • ")
    }
    
    var amountDisplay: String? {
        guard let amount = amount else { return nil }
        return "+$\(String(format: "%.2f", amount))"
    }
    
    var icon: String {
        switch activityType {
        case .purchase: return "bag.fill"
        case .artistAdded: return "person.badge.plus"
        case .milestoneReached: return "party.popper.fill"
        }
    }
    
    var iconColor: Color {
        switch activityType {
        case .purchase: return .blue
        case .artistAdded: return .purple
        case .milestoneReached: return .yellow
        }
    }
}

enum ActivityType: String, CaseIterable, Codable {
    case purchase = "purchase"
    case artistAdded = "artist_added"
    case milestoneReached = "milestone_reached"
    
    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .artistAdded: return "Artist Added"
        case .milestoneReached: return "Milestone Reached"
        }
    }
}


struct UpcomingEvent: Identifiable, Codable {
    let id: UUID
    let artistName: String
    let eventType: EventType
    let title: String
    let date: Date?
    let daysUntil: Int?
    let isRelatedToUserGoals: Bool
    
    var typeIcon: String {
        switch eventType {
        case .comeback: return "music.note.list"
        case .concert: return "mic.fill"
        case .fanmeet: return "person.3.fill"
        case .albumRelease: return "opticaldisc.fill"
        case .merchandise: return "bag.fill"
        }
    }
    
    var typeColor: Color {
        switch eventType {
        case .comeback: return .purple
        case .concert: return .red
        case .fanmeet: return .pink
        case .albumRelease: return .blue
        case .merchandise: return .orange
        }
    }
    
    var urgencyText: String? {
        guard let days = daysUntil else { return nil }
        if days == 0 { return "TODAY" }
        if days == 1 { return "TOMORROW" }
        if days <= 7 { return "\(days) DAYS" }
        return nil
    }
}

enum EventType: String, CaseIterable, Codable {
    case comeback = "comeback"
    case concert = "concert"
    case fanmeet = "fanmeet"
    case albumRelease = "album_release"
    case merchandise = "merchandise"
    
    var displayName: String {
        switch self {
        case .comeback: return "Comeback"
        case .concert: return "Concert"
        case .fanmeet: return "Fanmeet"
        case .albumRelease: return "Album Release"
        case .merchandise: return "Merchandise"
        }
    }
}

// MARK: - Quick Add Models

struct QuickAddPurchase {
    var selectedArtist: Artist?
    var amount: String = ""
    var category: FanCategory = .other
    var description: String = ""
    var contextNote: String = ""
    var isComebackRelated: Bool = false
    var venueLocation: String = ""
    var albumVersion: String = ""
    
    var isValid: Bool {
        return selectedArtist != nil && 
               !amount.isEmpty && 
               Double(amount) != nil &&
               Double(amount)! > 0 &&
               !description.isEmpty
    }
    
    var contextualPlaceholder: String {
        guard let artist = selectedArtist else { return "Enter description..." }
        
        switch category {
        case .concerts:
            return "\(artist.name) concert outfit, lightstick..."
        case .albums:
            return "\(artist.name) latest album, special edition..."
        case .merch:
            return "\(artist.name) hoodie, photobook..."
        // Removed - photocards now part of albums
        case .subscriptions:
            return "\(artist.name) streaming subscription..."
        case .events:
            return "\(artist.name) fanmeet outfit, banner..."
        case .other:
            return "\(artist.name) related purchase..."
        }
    }
}

// GoalProgressAdd struct removed - no longer using goal functionality

// MARK: - Artist Profile Models

struct WishlistItem: Identifiable, Codable, Hashable {
    let id: UUID
    let artistId: UUID
    let category: FanCategory
    let title: String
    let price: Double?
    let priority: WishlistPriority
    let addedAt: Date
    let imageURL: String?
    let notes: String?
    
    var priorityDisplay: String {
        switch priority {
        case .high: return "Must Have"
        case .medium: return "Want"
        case .low: return "Maybe"
        }
    }
    
    var priceDisplay: String {
        guard let price = price else { return "Price TBD" }
        return "$\(String(format: "%.2f", price))"
    }
}

enum WishlistPriority: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

struct ArtistTimelineItem: Identifiable, Codable, Hashable {
    let id: UUID
    let artistId: UUID
    let type: TimelineItemType
    let title: String
    let description: String?
    let date: Date
    let imageURL: String?
    let isUpcoming: Bool
    let relatedAmount: Double?
    
    var timeDisplay: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()
        
        if isUpcoming {
            let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if days == 0 { return "Today" }
            if days == 1 { return "Tomorrow" }
            if days <= 7 { return "\(days) days" }
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        } else {
            if calendar.isDate(date, inSameDayAs: now) { return "Today" }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), 
               calendar.isDate(date, inSameDayAs: yesterday) { return "Yesterday" }
            
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days <= 7 { return "\(days) days ago" }
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

enum TimelineItemType: String, CaseIterable, Codable, Hashable {
    case comeback = "comeback"
    case concert = "concert"
    case purchase = "purchase"
    case milestone = "milestone"
    case albumRelease = "album_release"
    case merchandise = "merchandise"
    case fanmeet = "fanmeet"
    
    var icon: String {
        switch self {
        case .comeback: return "music.note.list"
        case .concert: return "mic.fill"
        case .purchase: return "bag.fill"
        case .milestone: return "star.fill"
        case .albumRelease: return "opticaldisc.fill"
        case .merchandise: return "tshirt.fill"
        case .fanmeet: return "person.3.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .comeback: return .purple
        case .concert: return .red
        case .purchase: return .blue
        case .milestone: return .yellow
        case .albumRelease: return .green
        case .merchandise: return .orange
        case .fanmeet: return .pink
        }
    }
}

struct UserPriority: Identifiable, Codable, Hashable {
    let id: UUID
    let artistId: UUID
    let category: FanCategory
    let priority: Int
    let monthlyAllocation: Double
    let spent: Double
    
    var progressPercentage: Double {
        guard monthlyAllocation > 0 else { return 0 }
        return min((spent / monthlyAllocation) * 100, 100)
    }
    
    var remaining: Double {
        return max(monthlyAllocation - spent, 0)
    }
    
    private var statusInternal: AppBudgetStatus {
        if progressPercentage >= 90 { return .overbudget }
        if progressPercentage >= 75 { return .warning }
        if progressPercentage >= 50 { return .moderate }
        return .healthy
    }
    
    var status: BudgetStatus { 
        statusInternal.toUI() 
    }
}

// MARK: - Mock Data Extensions for Artist Profile

extension ArtistTimelineItem {
    static let mockTimelineForBTS: [ArtistTimelineItem] = [
        ArtistTimelineItem(
            id: UUID(),
            artistId: UUID(),
            type: .comeback,
            title: "New Album Announcement",
            description: "BTS announces their highly anticipated new album",
            date: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            imageURL: nil,
            isUpcoming: true,
            relatedAmount: nil
        ),
        ArtistTimelineItem(
            id: UUID(),
            artistId: UUID(),
            type: .purchase,
            title: "Concert Tickets",
            description: "World Tour tickets purchased",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            imageURL: nil,
            isUpcoming: false,
            relatedAmount: 250.0
        ),
        ArtistTimelineItem(
            id: UUID(),
            artistId: UUID(),
            type: .milestone,
            title: "$400 Goal Reached!",
            description: "Concert fund milestone achieved",
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            imageURL: nil,
            isUpcoming: false,
            relatedAmount: 400.0
        )
    ]
}

extension WishlistItem {
    static let mockWishlistForBTS: [WishlistItem] = [
        WishlistItem(
            id: UUID(),
            artistId: UUID(),
            category: .merch,
            title: "Official BTS Hoodie",
            price: 65.0,
            priority: .high,
            addedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            imageURL: nil,
            notes: "Limited edition design"
        ),
        WishlistItem(
            id: UUID(),
            artistId: UUID(),
            category: .albums,
            title: "BE Album Special Edition",
            price: 35.0,
            priority: .medium,
            addedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            imageURL: nil,
            notes: "Missing from collection"
        ),
        WishlistItem(
            id: UUID(),
            artistId: UUID(),
            category: .albums,
            title: "Jungkook PC Set",
            price: nil,
            priority: .low,
            addedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            imageURL: nil,
            notes: "If I find a good deal"
        )
    ]
}

extension UserPriority {
    static let mockPrioritiesForBTS: [UserPriority] = [
        UserPriority(
            id: UUID(),
            artistId: UUID(),
            category: .concerts,
            priority: 1,
            monthlyAllocation: 50.0,
            spent: 25.0
        ),
        UserPriority(
            id: UUID(),
            artistId: UUID(),
            category: .albums,
            priority: 2,
            monthlyAllocation: 40.0,
            spent: 20.0
        ),
        UserPriority(
            id: UUID(),
            artistId: UUID(),
            category: .merch,
            priority: 3,
            monthlyAllocation: 30.0,
            spent: 20.0
        )
    ]
}