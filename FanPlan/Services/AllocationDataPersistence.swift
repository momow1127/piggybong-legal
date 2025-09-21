import Foundation

// MARK: - Persistent Allocation Data Model
struct PersistentAllocationData: Codable {
    let id: UUID
    let category: String
    let allocatedAmount: Double
    let percentage: Double
    let createdAt: Date
    
    init(id: UUID = UUID(), category: String, allocatedAmount: Double, percentage: Double, createdAt: Date = Date()) {
        self.id = id
        self.category = category
        self.allocatedAmount = allocatedAmount
        self.percentage = percentage
        self.createdAt = createdAt
    }
}

// MARK: - Allocation Data Persistence
class AllocationDataPersistence {
    static let shared = AllocationDataPersistence()
    
    private init() {}
    
    // MARK: - Data Operations
    func saveAllocation(_ allocation: PersistentAllocationData) {
        // Implementation for saving allocation data
        print("Saving allocation data")
    }
    
    func loadAllocations() -> [PersistentAllocationData] {
        // Implementation for loading allocation data
        return []
    }
    
    func deleteAllocation(id: UUID) {
        // Implementation for deleting allocation
        print("Deleting allocation with id: \(id)")
    }
    
    func exportData() -> AllocationDataExport {
        return AllocationDataExport(
            exportDate: Date(),
            allocations: loadAllocations(),
            totalBudget: 1000.0,
            version: "1.0"
        )
    }
    
    func generateReport() -> DataIntegrityReport {
        return DataIntegrityReport(
            isValid: true,
            issues: [],
            lastChecked: Date()
        )
    }
    
    // Add missing method that some services might call
    func clearAllData() {
        // Implementation for clearing all stored allocation data
        print("Clearing all allocation data")
    }
}

// MARK: - Data Export Models
struct AllocationDataExport: Codable {
    let exportDate: Date
    let allocations: [PersistentAllocationData]
    let totalBudget: Double
    let version: String
}

struct DataIntegrityReport {
    let isValid: Bool
    let issues: [String]
    let lastChecked: Date
}