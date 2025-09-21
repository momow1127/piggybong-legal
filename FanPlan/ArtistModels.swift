import Foundation
import SwiftUI
import UserNotifications

// MARK: - Artist Priority Extension for Notifications
enum ArtistPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case bias = "bias" // Ultimate bias - highest priority
    
    var displayName: String {
        switch self {
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        case .bias: return "Ultimate Bias"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .bias: return .pink
        }
    }
    
    var notificationImportance: UNNotificationInterruptionLevel {
        switch self {
        case .low: return .passive
        case .medium: return .active
        case .high: return .timeSensitive
        case .bias: return UNNotificationInterruptionLevel.timeSensitive // Use timeSensitive for compatibility
        }
    }
}

// MARK: - Artist Extension for Notifications
extension Artist {
    var priority: ArtistPriority {
        get {
            // Default medium priority for all artists
            return .medium
        }
    }
    
    // Convert to notification-friendly format
    func toNotificationArtist() -> Artist {
        return self
    }
}

// MARK: - Artist Update Model for Notifications
// NOTE: ArtistUpdate struct is defined in ArtistNotificationService.swift to avoid duplication

// MARK: - Mock Data Extensions
extension Artist {
    static let mockNotificationArtist = Artist(
        name: "BLACKPINK",
        group: "YG Entertainment",
        imageURL: "https://example.com/blackpink.jpg"
    )
    
    static let mockNotificationList: [Artist] = [
        Artist(name: "BLACKPINK", group: "YG Entertainment"),
        Artist(name: "BTS", group: "HYBE"),
        Artist(name: "TWICE", group: "JYP Entertainment"),
        Artist(name: "IU", group: "EDAM Entertainment"),
        Artist(name: "NewJeans", group: "ADOR")
    ]
}

extension ArtistUpdate {
    static let mockComebackUpdate = ArtistUpdate(
        id: "comeback_001",
        artistName: "BLACKPINK",
        type: .comeback,
        title: "BLACKPINK 3rd Full Album Coming Soon!",
        description: "After 2 years, BLACKPINK is preparing their highly anticipated 3rd studio album",
        timestamp: Date(),
        sourceURL: "https://blackpinkofficial.com/comeback",
        imageURL: "https://example.com/comeback.jpg",
        isBreaking: true
    )

    static let mockTourUpdate = ArtistUpdate(
        id: "tour_001",
        artistName: "BLACKPINK",
        type: .tour,
        title: "BLACKPINK WORLD TOUR 2024 ANNOUNCED",
        description: "Born Pink World Tour extended with new dates across Asia, Europe, and North America",
        timestamp: Date(),
        sourceURL: "https://blackpinkofficial.com/tour",
        imageURL: "https://example.com/tour.jpg",
        isBreaking: true
    )
}

// MARK: - Extension for IdolUpdate to ArtistUpdateType
extension IdolUpdate {
    func toArtistUpdateType() -> ArtistUpdateType {
        // Map existing update types to notification types
        if title.lowercased().contains("comeback") {
            return .comeback
        } else if title.lowercased().contains("tour") || title.lowercased().contains("concert") {
            return .tour
        } else if title.lowercased().contains("release") || title.lowercased().contains("album") {
            return .newRelease
        } else if title.lowercased().contains("tv") || title.lowercased().contains("show") {
            return .tvAppearance
        } else if title.lowercased().contains("merch") || title.lowercased().contains("merchandise") {
            return .merchDrops
        } else if title.lowercased().contains("award") || title.lowercased().contains("win") {
            return .award
        } else if title.lowercased().contains("collab") || title.lowercased().contains("featuring") {
            return .collaboration
        } else {
            return .socialMedia
        }
    }
}

// MARK: - PopularArtist Model
struct PopularArtist: Identifiable, Codable, Hashable {
    let id: UUID
    let artist: Artist
    let followerCount: Int
    let recentActivity: String?
    
    init(artist: Artist, followerCount: Int, recentActivity: String?) {
        self.id = UUID()
        self.artist = artist
        self.followerCount = followerCount
        self.recentActivity = recentActivity
    }
}

