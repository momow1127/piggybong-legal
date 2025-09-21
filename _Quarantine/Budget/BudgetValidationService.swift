import Foundation
import SwiftUI

// MARK: - Budget Validation Service
/// Ensures all budget calculations are accurate and prevent negative amounts
class BudgetValidationService {
    static let shared = BudgetValidationService()
    
    private init() {}
    
    // MARK: - Financial Validation
    
    /// Validates that an amount is positive and reasonable
    func validateAmount(_ amount: Double, context: String = "amount") -> ValidationResult {
        if amount < 0 {
            return .invalid("\(context.capitalized) cannot be negative")
        }
        
        if amount > 1_000_000 {
            return .invalid("\(context.capitalized) exceeds maximum allowed ($1,000,000)")
        }
        
        if amount.isNaN || amount.isInfinite {
            return .invalid("\(context.capitalized) is not a valid number")
        }
        
        return .valid
    }
    
    /// Validates budget allocation doesn't exceed total budget
    func validateAllocation(_ allocation: Double, totalBudget: Double, spent: Double = 0) -> ValidationResult {
        let amountValidation = validateAmount(allocation, context: "allocation")
        if case .invalid(let message) = amountValidation {
            return .invalid(message)
        }
        
        let budgetValidation = validateAmount(totalBudget, context: "budget")
        if case .invalid(let message) = budgetValidation {
            return .invalid(message)
        }
        
        let spentValidation = validateAmount(spent, context: "spent amount")
        if case .invalid(let message) = spentValidation {
            return .invalid(message)
        }
        
        let availableBudget = totalBudget - spent
        if allocation > availableBudget {
            return .invalid("Allocation (\(allocation.safeCurrencyString)) exceeds available budget (\(availableBudget.safeCurrencyString))")
        }
        
        return .valid
    }
    
    /// Validates that total allocations don't exceed budget
    func validateTotalAllocations(_ allocations: [Double], totalBudget: Double, spent: Double = 0) -> ValidationResult {
        for (index, allocation) in allocations.enumerated() {
            let validation = validateAmount(allocation, context: "allocation #\(index + 1)")
            if case .invalid(let message) = validation {
                return .invalid(message)
            }
        }
        
        let totalAllocated = allocations.reduce(0, +)
        let availableBudget = totalBudget - spent
        
        if totalAllocated > availableBudget {
            return .invalid("Total allocations (\(totalAllocated.safeCurrencyString)) exceed available budget (\(availableBudget.safeCurrencyString))")
        }
        
        return .valid
    }
    
    /// Validates spending doesn't create negative balances
    func validateSpending(_ amount: Double, availableAmount: Double) -> ValidationResult {
        let amountValidation = validateAmount(amount, context: "spending amount")
        if case .invalid(let message) = amountValidation {
            return .invalid(message)
        }
        
        if amount > availableAmount {
            return .invalid("Spending (\(amount.safeCurrencyString)) exceeds available amount (\(availableAmount.safeCurrencyString))")
        }
        
        return .valid
    }
    
    /// Validates goal is achievable given current budget and timeline
    func validateGoal(targetAmount: Double, deadline: Date, monthlyBudget: Double, currentAmount: Double = 0) -> ValidationResult {
        let targetValidation = validateAmount(targetAmount, context: "target amount")
        if case .invalid(let message) = targetValidation {
            return .invalid(message)
        }
        
        let currentValidation = validateAmount(currentAmount, context: "current amount")
        if case .invalid(let message) = currentValidation {
            return .invalid(message)
        }
        
        let budgetValidation = validateAmount(monthlyBudget, context: "monthly budget")
        if case .invalid(let message) = budgetValidation {
            return .invalid(message)
        }
        
        if currentAmount >= targetAmount {
            return .valid // Goal already achieved
        }
        
        if deadline <= Date() {
            return .invalid("Goal deadline has already passed")
        }
        
        let remainingAmount = targetAmount - currentAmount
        let monthsRemaining = Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 0
        
        if monthsRemaining <= 0 {
            return .invalid("Not enough time remaining to achieve goal")
        }
        
        let requiredMonthlyAmount = remainingAmount / Double(monthsRemaining)
        
        if requiredMonthlyAmount > monthlyBudget {
            return .invalid("Goal requires \(requiredMonthlyAmount.safeCurrencyString) per month, but budget is only \(monthlyBudget.safeCurrencyString)")
        }
        
        return .valid
    }
    
    // MARK: - Safe Mathematical Operations
    
    /// Safely calculates percentage to avoid division by zero
    func safePercentage(amount: Double, total: Double) -> Double {
        guard total > 0 else { return 0 }
        return min((amount / total) * 100, 100) // Cap at 100%
    }
    
    /// Safely calculates ratio to avoid division by zero
    func safeRatio(numerator: Double, denominator: Double) -> Double {
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }
    
    /// Safely subtracts amounts ensuring non-negative result
    func safeSubtraction(_ minuend: Double, _ subtrahend: Double) -> Double {
        return max(0, minuend - subtrahend)
    }
    
    /// Safely adds amounts with overflow protection
    func safeAddition(_ amounts: [Double]) -> Double {
        let total = amounts.reduce(0) { result, amount in
            guard !amount.isNaN && !amount.isInfinite else { return result }
            let newTotal = result + amount
            return newTotal > 1_000_000 ? 1_000_000 : newTotal
        }
        return total
    }
    
    // MARK: - Budget Calculation Helpers
    
    /// Calculates remaining budget safely
    func calculateRemainingBudget(totalBudget: Double, spent: Double) -> Double {
        return safeSubtraction(totalBudget, spent)
    }
    
    /// Calculates spending percentage safely
    func calculateSpendingPercentage(spent: Double, budget: Double) -> Double {
        return safePercentage(amount: spent, total: budget)
    }
    
    /// Calculates goal progress percentage safely
    func calculateGoalProgress(currentAmount: Double, targetAmount: Double) -> Double {
        return safePercentage(amount: currentAmount, total: targetAmount)
    }
    
    /// Calculates months to goal completion
    func calculateMonthsToGoal(remainingAmount: Double, monthlyContribution: Double) -> Double {
        guard monthlyContribution > 0 else { return Double.infinity }
        return remainingAmount / monthlyContribution
    }
    
    // MARK: - Real-Time Budget Health Check
    
    func assessBudgetHealth(totalBudget: Double, spent: Double, allocations: [Double]) -> BudgetHealthStatus {
        let totalAllocated = safeAddition(allocations)
        let remaining = calculateRemainingBudget(totalBudget: totalBudget, spent: spent)
        let spentPercentage = calculateSpendingPercentage(spent: spent, budget: totalBudget)
        let allocationPercentage = safePercentage(amount: totalAllocated, total: totalBudget)
        
        // Check for critical issues
        if spent > totalBudget {
            return BudgetHealthStatus(
                level: .critical,
                message: "Budget exceeded by \((spent - totalBudget).safeCurrencyString)",
                recommendations: ["Review and cut spending immediately", "Consider increasing budget or reducing allocations"]
            )
        }
        
        if totalAllocated > totalBudget {
            return BudgetHealthStatus(
                level: .critical,
                message: "Total allocations exceed budget by \((totalAllocated - totalBudget).safeCurrencyString)",
                recommendations: ["Reduce allocations", "Increase budget", "Prioritize essential goals only"]
            )
        }
        
        // Check for warning conditions
        if spentPercentage > 90 {
            return BudgetHealthStatus(
                level: .warning,
                message: "\(Int(spentPercentage))% of budget used",
                recommendations: ["Monitor spending closely", "Avoid non-essential purchases"]
            )
        }
        
        if allocationPercentage > 95 {
            return BudgetHealthStatus(
                level: .warning,
                message: "\(Int(allocationPercentage))% of budget allocated",
                recommendations: ["Leave some budget unallocated for flexibility", "Review allocation priorities"]
            )
        }
        
        // Check for moderate concerns
        if spentPercentage > 70 {
            return BudgetHealthStatus(
                level: .moderate,
                message: "\(Int(spentPercentage))% of budget used",
                recommendations: ["Track spending more carefully", "Consider if remaining allocations are realistic"]
            )
        }
        
        // Budget is healthy
        return BudgetHealthStatus(
            level: .healthy,
            message: "Budget is on track (\(remaining.safeCurrencyString) remaining)",
            recommendations: ["Continue current spending pattern", "Consider if you can save more toward goals"]
        )
    }
    
}

// MARK: - Supporting Types

enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

struct BudgetHealthStatus {
    let level: HealthLevel
    let message: String
    let recommendations: [String]
    
    enum HealthLevel: String, CaseIterable {
        case healthy = "Healthy"
        case moderate = "Moderate"
        case warning = "Warning"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .healthy: return .green
            case .moderate: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var systemImage: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .moderate: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Extensions for Financial Safety

extension Double {
    /// Safely formats currency avoiding crashes from invalid numbers
    var safeCurrencyString: String {
        guard !isNaN && !isInfinite else { return "$0.00" }
        return String(format: "$%.2f", self)
    }
    
    /// Rounds to 2 decimal places for financial calculations
    var rounded2: Double {
        return (self * 100).rounded() / 100
    }
    
    /// Ensures the value is non-negative
    var nonNegative: Double {
        return max(0, self)
    }
}