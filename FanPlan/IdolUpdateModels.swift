import SwiftUI
import Foundation

// MARK: - Idol Update Data Models

struct IdolUpdate: Identifiable, Codable {
    let id: UUID
    let artistId: String
    let artistName: String
    let title: String
    let content: String
    let aiSummary: String?
    let originalContent: String
    let updateType: UpdateType
    let platform: Platform
    let timestamp: Date
    let imageURL: String?
    let videoURL: String?
    let externalURL: String?
    let sentiment: Sentiment
    let tags: [String]
    let engagementScore: Double
    let isBreakingNews: Bool
    let relatedArtists: [String]
    
    init(id: UUID = UUID(), artistId: String, artistName: String, title: String, content: String, aiSummary: String? = nil, originalContent: String, updateType: UpdateType, platform: Platform, timestamp: Date = Date(), imageURL: String? = nil, videoURL: String? = nil, externalURL: String? = nil, sentiment: Sentiment = .neutral, tags: [String] = [], engagementScore: Double = 0.0, isBreakingNews: Bool = false, relatedArtists: [String] = []) {
        self.id = id
        self.artistId = artistId
        self.artistName = artistName
        self.title = title
        self.content = content
        self.aiSummary = aiSummary
        self.originalContent = originalContent
        self.updateType = updateType
        self.platform = platform
        self.timestamp = timestamp
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.externalURL = externalURL
        self.sentiment = sentiment
        self.tags = tags
        self.engagementScore = engagementScore
        self.isBreakingNews = isBreakingNews
        self.relatedArtists = relatedArtists
    }
    
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var priorityScore: Double {
        var score = engagementScore
        if isBreakingNews { score += 50 }
        if updateType == .comeback || updateType == .concert { score += 30 }
        if sentiment == .positive { score += 10 }
        return score
    }
}

enum UpdateType: String, CaseIterable, Codable {
    case social = "Social Post"
    case news = "News"
    case comeback = "Comeback"
    case concert = "Concert"
    case album = "Album"
    case collaboration = "Collaboration"
    case interview = "Interview"
    case award = "Award"
    case variety = "Variety Show"
    case livestream = "Livestream"
    case merchandise = "Merchandise"
    case announcement = "Announcement"
    
    var icon: String {
        switch self {
        case .social: return "bubble.left.and.bubble.right"
        case .news: return "newspaper"
        case .comeback: return "star.circle"
        case .concert: return "music.note"
        case .album: return "opticaldisc"
        case .collaboration: return "person.2"
        case .interview: return "mic"
        case .award: return "trophy"
        case .variety: return "tv"
        case .livestream: return "dot.radiowaves.left.and.right"
        case .merchandise: return "tshirt"
        case .announcement: return "megaphone"
        }
    }
    
    var color: Color {
        switch self {
        case .social: return .blue
        case .news: return .orange
        case .comeback: return .purple
        case .concert: return .pink
        case .album: return .green
        case .collaboration: return .mint
        case .interview: return .yellow
        case .award: return .yellow
        case .variety: return .red
        case .livestream: return .indigo
        case .merchandise: return .brown
        case .announcement: return .gray
        }
    }
}

enum Platform: String, CaseIterable, Codable {
    case twitter = "Twitter"
    case instagram = "Instagram"
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case weibo = "Weibo"
    case vlive = "V LIVE"
    case universe = "Universe"
    case bubble = "Bubble"
    case soompi = "Soompi"
    case allkpop = "AllKPop"
    case spotify = "Spotify"
    case discord = "Discord"
    case reddit = "Reddit"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .twitter: return "bird"
        case .instagram: return "camera"
        case .youtube: return "play.rectangle"
        case .tiktok: return "music.note"
        case .weibo: return "globe.asia.australia"
        case .vlive: return "video"
        case .universe: return "star"
        case .bubble: return "bubble.left"
        case .soompi: return "newspaper"
        case .allkpop: return "doc.text"
        case .spotify: return "music.note.list"
        case .discord: return "message"
        case .reddit: return "bubble.left.and.bubble.right"
        case .other: return "link"
        }
    }
    
    var color: Color {
        switch self {
        case .twitter: return .blue
        case .instagram: return .pink
        case .youtube: return .red
        case .tiktok: return .black
        case .weibo: return .orange
        case .vlive: return .purple
        case .universe: return .indigo
        case .bubble: return .green
        case .soompi: return .orange
        case .allkpop: return .red
        case .spotify: return .green
        case .discord: return .indigo
        case .reddit: return .orange
        case .other: return .gray
        }
    }
}

enum Sentiment: String, CaseIterable, Codable {
    case positive = "Positive"
    case negative = "Negative"
    case neutral = "Neutral"
    case excited = "Excited"
    case concerned = "Concerned"
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😔"
        case .neutral: return "😐"
        case .excited: return "🤩"
        case .concerned: return "😰"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        case .excited: return .yellow
        case .concerned: return .orange
        }
    }
}

// MARK: - News Feed Configuration

struct NewsFeedConfiguration: Codable {
    var enabledPlatforms: [Platform]
    var updateTypes: [UpdateType]
    var refreshInterval: TimeInterval
    var maxItemsPerFeed: Int
    var enableAISummary: Bool
    var enableBreakingNews: Bool
    var enablePersonalization: Bool
    var sentimentFilter: [Sentiment]
    
    static let `default` = NewsFeedConfiguration(
        enabledPlatforms: [.twitter, .instagram, .youtube, .soompi, .allkpop],
        updateTypes: UpdateType.allCases,
        refreshInterval: 300, // 5 minutes
        maxItemsPerFeed: 50,
        enableAISummary: true,
        enableBreakingNews: true,
        enablePersonalization: true,
        sentimentFilter: [.positive, .neutral, .excited]
    )
}

// MARK: - Artist Profile for Updates

struct ArtistProfile: Identifiable, Codable {
    let id: String
    let name: String
    let koreanName: String?
    let group: String?
    let agency: String?
    let debutDate: Date?
    let socialHandles: SocialHandles
    let tags: [String]
    let imageURL: String?
    let isFollowing: Bool
    let notificationSettings: NotificationSettings
    
    struct SocialHandles: Codable {
        let twitter: String?
        let instagram: String?
        let youtube: String?
        let tiktok: String?
        let weibo: String?
        let vlive: String?
        let universe: String?
        let bubble: String?
    }
    
    struct NotificationSettings: Codable {
        let enablePushNotifications: Bool
        let breakingNewsOnly: Bool
        let quietHours: QuietHours?
        let updateTypes: [UpdateType]
        
        struct QuietHours: Codable {
            let startTime: Date
            let endTime: Date
            let timezone: String
        }
    }
}

// MARK: - Real-time Update Event

struct UpdateEvent: Codable {
    let eventId: UUID
    let artistId: String
    let updateId: UUID
    let eventType: EventType
    let timestamp: Date
    let metadata: [String: String]
    
    enum EventType: String, Codable {
        case newUpdate = "new_update"
        case updateModified = "update_modified"
        case breakingNews = "breaking_news"
        case artistLive = "artist_live"
        case collaborationAnnounced = "collaboration_announced"
        case comebackConfirmed = "comeback_confirmed"
    }
}

// MARK: - Mock Data Extensions

extension IdolUpdate {
    static let mockUpdates: [IdolUpdate] = [
        IdolUpdate(
            artistId: "bts",
            artistName: "BTS",
            title: "Jungkook shares new workout routine",
            content: "Just dropped my latest workout routine! 💪 Always staying healthy for ARMY 💜",
            aiSummary: "Jungkook shared his workout routine with fans, emphasizing the importance of staying healthy.",
            originalContent: "방금 새로운 운동 루틴을 공유했어요! 💪 항상 아미를 위해 건강하게 지내고 있어요 💜",
            updateType: .social,
            platform: .instagram,
            timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(),
            imageURL: nil,
            sentiment: .positive,
            tags: ["fitness", "health", "workout"],
            engagementScore: 95.5,
            isBreakingNews: false
        ),
        IdolUpdate(
            artistId: "newjeans",
            artistName: "NewJeans",
            title: "NewJeans announces comeback date",
            content: "🚨 BREAKING: NewJeans confirms comeback for March 2024 with new album 'Spring Dreams'",
            aiSummary: "NewJeans officially announced their comeback scheduled for March 2024 with a new album titled 'Spring Dreams'.",
            originalContent: "🚨 속보: 뉴진스가 2024년 3월에 새 앨범 'Spring Dreams'로 컴백을 확정했습니다",
            updateType: .comeback,
            platform: .soompi,
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            imageURL: nil,
            sentiment: .excited,
            tags: ["comeback", "album", "2024"],
            engagementScore: 98.7,
            isBreakingNews: true
        ),
        IdolUpdate(
            artistId: "blackpink",
            artistName: "BLACKPINK",
            title: "Lisa spotted at Paris Fashion Week",
            content: "Lisa turning heads at Paris Fashion Week with her stunning Celine outfit ✨",
            aiSummary: "Lisa attended Paris Fashion Week wearing a Celine outfit that received widespread attention.",
            originalContent: "리사가 파리 패션위크에서 셀린느 의상으로 시선을 사로잡았습니다 ✨",
            updateType: .news,
            platform: .allkpop,
            timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
            imageURL: nil,
            sentiment: .positive,
            tags: ["fashion", "paris", "celine"],
            engagementScore: 87.3,
            isBreakingNews: false
        )
    ]
}

extension ArtistProfile {
    static let mockProfiles: [ArtistProfile] = [
        ArtistProfile(
            id: "bts",
            name: "BTS",
            koreanName: "방탄소년단",
            group: "BTS",
            agency: "HYBE Corporation",
            debutDate: Calendar.current.date(from: DateComponents(year: 2013, month: 6, day: 13)),
            socialHandles: ArtistProfile.SocialHandles(
                twitter: "@BTS_twt",
                instagram: "@bts.bighitofficial",
                youtube: "BANGTANTV",
                tiktok: "@bts_official_bighit",
                weibo: "BTS_official",
                vlive: "BTS",
                universe: "BTS",
                bubble: "BTS"
            ),
            tags: ["K-pop", "Hip Hop", "Pop", "R&B"],
            imageURL: nil,
            isFollowing: true,
            notificationSettings: ArtistProfile.NotificationSettings(
                enablePushNotifications: true,
                breakingNewsOnly: false,
                quietHours: nil,
                updateTypes: [.social, .news, .comeback, .concert, .album]
            )
        )
    ]
}