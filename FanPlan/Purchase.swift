import Foundation

enum PurchaseCategory: String, CaseIterable, Codable {
    case album = "album"
    case concert = "concert"
    case merchandise = "merchandise"
    case digital = "digital"
    case photocard = "photocard"
    case other = "other"
    
    var icon: String {
        switch self {
        case .album: return "music.note"
        case .concert: return "music.mic"
        case .merchandise: return "tshirt"
        case .digital: return "iphone"
        case .photocard: return "photo"
        case .other: return "bag"
        }
    }
    
    var displayName: String {
        switch self {
        case .album: return "Album"
        case .concert: return "Concert"
        case .merchandise: return "Merch"
        case .digital: return "Digital"
        case .photocard: return "Photocard"
        case .other: return "Other"
        }
    }
}

struct Purchase: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let amount: Double
    let category: PurchaseCategory
    let description: String
    let notes: String?
    let purchaseDate: Date
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        artistId: UUID,
        amount: Double,
        category: PurchaseCategory,
        description: String,
        notes: String? = nil,
        purchaseDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.artistId = artistId
        self.amount = amount
        self.category = category
        self.description = description
        self.notes = notes
        self.purchaseDate = purchaseDate
        self.createdAt = createdAt
    }
}