import SwiftUI
import Foundation

// MARK: - Fan Priority Data Models

struct FanPriority: Identifiable, Codable {
    let id: UUID
    let type: PriorityType
    let artistId: String
    let artistName: String
    let estimatedCost: Double
    let priorityRank: Int // 1 = highest
    let isFlexible: Bool // Can wait if needed
    let alertOnOpportunity: Bool
    let dateAdded: Date
    var status: PriorityStatus
    var notes: String
    var targetDate: Date?
    var alternativeOptions: [AlternativeOption]
    
    init(id: UUID = UUID(), type: PriorityType, artistId: String, artistName: String, estimatedCost: Double, priorityRank: Int, isFlexible: Bool = false, alertOnOpportunity: Bool = true, dateAdded: Date = Date(), status: PriorityStatus = .watching, notes: String = "", targetDate: Date? = nil, alternativeOptions: [AlternativeOption] = []) {
        self.id = id
        self.type = type
        self.artistId = artistId
        self.artistName = artistName
        self.estimatedCost = estimatedCost
        self.priorityRank = priorityRank
        self.isFlexible = isFlexible
        self.alertOnOpportunity = alertOnOpportunity
        self.dateAdded = dateAdded
        self.status = status
        self.notes = notes
        self.targetDate = targetDate
        self.alternativeOptions = alternativeOptions
    }
}

enum PriorityType: String, Codable, CaseIterable {
    case concert = "Concert"
    case albumCollection = "Album Collection"
    case merchandise = "Merchandise"
    case koreaTrip = "Korea Trip"
    case fanMeeting = "Fan Meeting"
    case onlineContent = "Online Content"
    case limitedEdition = "Limited Edition"
    case membership = "Membership"
    
    var icon: String {
        switch self {
        case .concert: return "music.note"
        case .albumCollection: return "opticaldisc"
        case .merchandise: return "tshirt"
        case .koreaTrip: return "airplane"
        case .fanMeeting: return "person.2"
        case .onlineContent: return "play.rectangle"
        case .limitedEdition: return "star.circle"
        case .membership: return "crown"
        }
    }
    
    var color: Color {
        switch self {
        case .concert: return .purple
        case .albumCollection: return .blue
        case .merchandise: return .green
        case .koreaTrip: return .orange
        case .fanMeeting: return .pink
        case .onlineContent: return .red
        case .limitedEdition: return .yellow
        case .membership: return .indigo
        }
    }
}

enum PriorityStatus: String, Codable, CaseIterable {
    case watching = "Watching"
    case available = "Available Now"
    case upcoming = "Coming Soon"
    case completed = "Got It!"
    case missed = "Missed"
    case considering = "Considering"
    
    var color: Color {
        switch self {
        case .watching: return .blue
        case .available: return .green
        case .upcoming: return .orange
        case .completed: return .purple
        case .missed: return .red
        case .considering: return .yellow
        }
    }
    
    var systemImage: String {
        switch self {
        case .watching: return "eye"
        case .available: return "checkmark.circle"
        case .upcoming: return "clock"
        case .completed: return "heart.fill"
        case .missed: return "xmark.circle"
        case .considering: return "questionmark.circle"
        }
    }
}

// MARK: - Alternative Options

struct AlternativeOption: Identifiable, Codable {
    let id: UUID
    let title: String
    let cost: Double
    let pros: [String]
    let cons: [String]
    let availability: String
    
    init(id: UUID = UUID(), title: String, cost: Double, pros: [String] = [], cons: [String] = [], availability: String = "Unknown") {
        self.id = id
        self.title = title
        self.cost = cost
        self.pros = pros
        self.cons = cons
        self.availability = availability
    }
}

// MARK: - Budget Allocation Models

struct BudgetAllocation: Identifiable, Codable {
    let id: UUID
    let month: Date
    let totalBudget: Double
    var allocations: [PriorityAllocation]
    var flexibilityBuffer: Double
    var emergencyFund: Double
    
    init(id: UUID = UUID(), month: Date, totalBudget: Double, allocations: [PriorityAllocation] = [], flexibilityBuffer: Double = 0, emergencyFund: Double = 0) {
        self.id = id
        self.month = month
        self.totalBudget = totalBudget
        self.allocations = allocations
        self.flexibilityBuffer = flexibilityBuffer
        self.emergencyFund = emergencyFund
    }
    
    var totalAllocated: Double {
        allocations.reduce(0) { $0 + $1.amount } + flexibilityBuffer + emergencyFund
    }
    
    var remainingBudget: Double {
        totalBudget - totalAllocated
    }
}

struct PriorityAllocation: Identifiable, Codable {
    let id: UUID
    let priorityId: UUID
    let amount: Double
    let reasoning: String
    let isRecommended: Bool
    
    init(id: UUID = UUID(), priorityId: UUID, amount: Double, reasoning: String = "", isRecommended: Bool = false) {
        self.id = id
        self.priorityId = priorityId
        self.amount = amount
        self.reasoning = reasoning
        self.isRecommended = isRecommended
    }
}

// MARK: - Opportunity Models

struct FanOpportunity: Identifiable, Codable {
    let id: UUID
    let title: String
    let artistName: String
    let type: PriorityType
    let originalPrice: Double
    let currentPrice: Double?
    let availableUntil: Date?
    let urgencyLevel: PriorityUrgencyLevel
    let description: String
    let pros: [String]
    let cons: [String]
    let source: String
    let matchedPriorities: [UUID] // Priority IDs this opportunity matches
    
    init(id: UUID = UUID(), title: String, artistName: String, type: PriorityType, originalPrice: Double, currentPrice: Double? = nil, availableUntil: Date? = nil, urgencyLevel: PriorityUrgencyLevel = .low, description: String = "", pros: [String] = [], cons: [String] = [], source: String = "", matchedPriorities: [UUID] = []) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.type = type
        self.originalPrice = originalPrice
        self.currentPrice = currentPrice
        self.availableUntil = availableUntil
        self.urgencyLevel = urgencyLevel
        self.description = description
        self.pros = pros
        self.cons = cons
        self.source = source
        self.matchedPriorities = matchedPriorities
    }
    
    var savings: Double {
        guard let currentPrice = currentPrice else { return 0 }
        return originalPrice - currentPrice
    }
    
    var savingsPercentage: Double {
        guard originalPrice > 0 else { return 0 }
        return (savings / originalPrice) * 100
    }
    
    var effectivePrice: Double {
        return currentPrice ?? originalPrice
    }
}

enum PriorityUrgencyLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "tortoise"
        case .medium: return "clock"
        case .high: return "timer"
        case .critical: return "flame"
        }
    }
    
    func toUI() -> UrgencyLevel {
        switch self {
        case .low: return .low
        case .medium, .high: return .high
        case .critical: return .critical
        }
    }
}

// MARK: - Trade-off Analysis

struct TradeOffAnalysis: Identifiable, Codable {
    let id: UUID
    let scenario: String
    let currentAllocation: BudgetAllocation
    let proposedAllocation: BudgetAllocation
    let tradeOffs: [TradeOff]
    let recommendation: String
    let confidenceScore: Double // 0-100
    
    init(id: UUID = UUID(), scenario: String, currentAllocation: BudgetAllocation, proposedAllocation: BudgetAllocation, tradeOffs: [TradeOff] = [], recommendation: String = "", confidenceScore: Double = 0) {
        self.id = id
        self.scenario = scenario
        self.currentAllocation = currentAllocation
        self.proposedAllocation = proposedAllocation
        self.tradeOffs = tradeOffs
        self.recommendation = recommendation
        self.confidenceScore = confidenceScore
    }
}

struct TradeOff: Identifiable, Codable {
    let id: UUID
    let description: String
    let impact: ImpactLevel
    let affectedPriorities: [UUID]
    let mitigation: String?
    
    init(id: UUID = UUID(), description: String, impact: ImpactLevel, affectedPriorities: [UUID] = [], mitigation: String? = nil) {
        self.id = id
        self.description = description
        self.impact = impact
        self.affectedPriorities = affectedPriorities
        self.mitigation = mitigation
    }
}

enum ImpactLevel: String, Codable, CaseIterable {
    case minimal = "Minimal"
    case moderate = "Moderate"
    case significant = "Significant"
    case major = "Major"
    
    var color: Color {
        switch self {
        case .minimal: return .green
        case .moderate: return .yellow
        case .significant: return .orange
        case .major: return .red
        }
    }
}

// MARK: - Mock Data

extension FanPriority {
    static let mockPriorities: [FanPriority] = [
        FanPriority(
            type: .concert,
            artistId: "bts",
            artistName: "BTS",
            estimatedCost: 450.0,
            priorityRank: 1,
            isFlexible: false,
            alertOnOpportunity: true,
            status: .watching,
            notes: "World tour tickets - prefer floor seats",
            targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            alternativeOptions: [
                AlternativeOption(
                    title: "General Admission",
                    cost: 150.0,
                    pros: ["More affordable", "Still great experience"],
                    cons: ["Further from stage", "Standing only"],
                    availability: "Usually available"
                )
            ]
        ),
        FanPriority(
            type: .albumCollection,
            artistId: "newjeans",
            artistName: "NewJeans",
            estimatedCost: 200.0,
            priorityRank: 2,
            isFlexible: true,
            alertOnOpportunity: true,
            status: .upcoming,
            notes: "Complete discography collection",
            alternativeOptions: [
                AlternativeOption(
                    title: "Digital Only",
                    cost: 50.0,
                    pros: ["Much cheaper", "Instant access"],
                    cons: ["No physical collection", "No photobooks"],
                    availability: "Always available"
                )
            ]
        ),
        FanPriority(
            type: .koreaTrip,
            artistId: "multiple",
            artistName: "Multiple Artists",
            estimatedCost: 2500.0,
            priorityRank: 3,
            isFlexible: true,
            alertOnOpportunity: true,
            status: .considering,
            notes: "Visit K-pop locations and attend music shows",
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
    ]
}

extension FanOpportunity {
    static let mockOpportunities: [FanOpportunity] = [
        FanOpportunity(
            title: "BTS Concert Resale Tickets",
            artistName: "BTS",
            type: .concert,
            originalPrice: 450.0,
            currentPrice: 380.0,
            availableUntil: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            urgencyLevel: .high,
            description: "Verified resale tickets for upcoming concert",
            pros: ["Below market price", "Good seats", "Verified seller"],
            cons: ["Still expensive", "Limited time"],
            source: "StubHub",
            matchedPriorities: [FanPriority.mockPriorities[0].id]
        ),
        FanOpportunity(
            title: "NewJeans Album Bundle Sale",
            artistName: "NewJeans",
            type: .albumCollection,
            originalPrice: 200.0,
            currentPrice: 120.0,
            availableUntil: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()),
            urgencyLevel: .medium,
            description: "Limited time bundle of all albums with extras",
            pros: ["40% off", "Includes exclusive items", "Complete collection"],
            cons: ["Still a large purchase", "Limited quantities"],
            source: "Official Store",
            matchedPriorities: [FanPriority.mockPriorities[1].id]
        )
    ]
}