import Foundation

// MARK: - Idol Management Models

/// Simplified model for idol management feature
struct IdolModel: Identifiable, Codable, Equatable {
    let id: String  // Artist UUID as string
    let name: String
    let profileImageURL: String
    
    static func == (lhs: IdolModel, rhs: IdolModel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Response Models for API

struct AddIdolResponse: Codable {
    let success: Bool
    let message: String
    let idol: IdolInfo?
    let currentCount: Int?
    let maxAllowed: Int?
    let isPro: Bool?
    
    struct IdolInfo: Codable {
        let id: String
        let artistId: String
        let artistName: String
        let priorityRank: Int
        let createdAt: String
    }
}

struct DeleteIdolResponse: Codable {
    let success: Bool
    let message: String
    let removedIdol: RemovedIdolInfo?
    let currentCount: Int?
    
    struct RemovedIdolInfo: Codable {
        let id: String
        let artistId: String
        let artistName: String
        let priorityRank: Int
    }
}

struct IdolLimitError: Codable {
    let success: Bool
    let message: String
    let currentCount: Int
    let maxAllowed: Int
    let isPro: Bool
}

// MARK: - Mock Data for Development

extension IdolModel {
    static let mockIdols: [IdolModel] = [
        IdolModel(id: "1", name: "BTS", profileImageURL: ""),
        IdolModel(id: "2", name: "BLACKPINK", profileImageURL: ""),
        IdolModel(id: "3", name: "NewJeans", profileImageURL: ""),
    ]
}

// MARK: - Conversion Extensions

