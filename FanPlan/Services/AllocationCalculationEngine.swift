import Foundation

// MARK: - Allocation Calculation Engine
final class AllocationCalculationEngine: Sendable {
    static let shared = AllocationCalculationEngine()

    private init() {}
    
    // MARK: - Calculation Methods
    func calculateOptimalAllocation(budget: Double, priorities: [FanPriority]) -> AllocationResult {
        // Simple allocation logic
        let totalPriorities = priorities.count
        let allocationPerPriority = totalPriorities > 0 ? budget / Double(totalPriorities) : 0
        
        let allocations = priorities.map { priority in
            AllocationItem(
                priorityId: priority.id,
                allocatedAmount: allocationPerPriority,
                percentage: totalPriorities > 0 ? 100.0 / Double(totalPriorities) : 0
            )
        }
        
        return AllocationResult(
            totalBudget: budget,
            allocatedAmount: allocationPerPriority * Double(totalPriorities),
            remainingAmount: budget - (allocationPerPriority * Double(totalPriorities)),
            allocations: allocations,
            efficiency: 0.85
        )
    }
    
    func recalculateAfterChange() {
        // Implementation for recalculation
        print("Recalculating allocations after change")
    }
}

// MARK: - Allocation Models
struct AllocationResult {
    let totalBudget: Double
    let allocatedAmount: Double
    let remainingAmount: Double
    let allocations: [AllocationItem]
    let efficiency: Double
}

struct AllocationItem: Identifiable {
    let id = UUID()
    let priorityId: UUID
    let allocatedAmount: Double
    let percentage: Double
}