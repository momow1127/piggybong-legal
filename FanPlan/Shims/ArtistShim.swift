import Foundation

// MARK: - Artist ↔ FanArtist Conversion Shims
// Keep both types and only convert at boundaries.
// Preserve existing UI architecture without changes.

extension Artist {
    /// Convert a lightweight Artist (used in onboarding) into a FanArtist (dashboard model).
    /// Supply defaults for fields FanArtist needs that Artist doesn't have.
    func asFanArtist(
        priorityRank: Int = 3,
        monthlyAllocation: Double = 100.0
    ) -> FanArtist {
        FanArtist(
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

extension FanArtist {
    /// Convert a FanArtist down to the lightweight Artist type
    func asArtist() -> Artist {
        Artist(
            id: self.id,
            name: self.name,
            group: nil, // FanArtist doesn't have group field
            imageURL: self.imageURL
        )
    }
    
    // MARK: - Placeholder Support
    static let placeholderID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    /// Placeholder idol to avoid empty state
    static let placeholder: FanArtist = FanArtist(
        id: placeholderID,
        name: "Select First Idol",
        priorityRank: 1,
        monthlyAllocation: 0.0,
        monthSpent: 0.0,
        totalSpent: 0.0,
        remainingBudget: 0.0,
        spentPercentage: 0.0,
        imageURL: nil,
        timeline: [],
        wishlistItems: [],
        priorities: []
    )
    
    /// Check if this is a placeholder idol
    var isPlaceholder: Bool {
        return self.id == Self.placeholderID
    }
}

// MARK: - Array Conversion Helpers
extension Array where Element == Artist {
    func asFanArtists(
        defaultPriority: Int = 3,
        defaultMonthlyAllocation: Double = 100.0
    ) -> [FanArtist] {
        map { $0.asFanArtist(priorityRank: defaultPriority, monthlyAllocation: defaultMonthlyAllocation) }
    }
}

extension Array where Element == FanArtist {
    func asArtists() -> [Artist] {
        map { $0.asArtist() }
    }
}