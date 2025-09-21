import SwiftUI

// MARK: - Budget Summary Cards Component
struct BudgetSummaryCards: View {
    @ObservedObject var viewModel: BudgetViewModel
    let animateCards: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Main balance card
            BalanceCard(
                title: "This Month's Budget",
                amount: viewModel.monthlyBudget,
                spent: viewModel.monthlySpent,
                icon: "dollarsign.circle.fill"
            )
            
            // Secondary cards
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Saved",
                    amount: viewModel.totalSaved,
                    color: .green,
                    icon: "arrow.down.circle.fill",
                    trend: viewModel.savingsTrend
                )
                
                SummaryCard(
                    title: "Goals",
                    amount: viewModel.goalProgress,
                    color: .blue,
                    icon: "target",
                    isPercentage: true,
                    trend: viewModel.goalsTrend
                )
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCards)
    }
}

// MARK: - Balance Card
struct BalanceCard: View {
    let title: String
    let amount: Double
    let spent: Double
    let icon: String
    
    private var remainingBudget: Double {
        amount - spent
    }
    
    private var budgetProgress: Double {
        spent / amount
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit Budget", action: { /* Handle edit */ })
                    Button("View Details", action: { /* Handle details */ })
                    Button("Set Alert", action: { /* Handle alert */ })
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.ultraThinMaterial))
                }
            }
            
            // Amount display
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(remainingBudget))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: remainingBudget >= 0 ? [.green, .green] : [.red, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                }
                
                HStack {
                    Text("Remaining of $\(formatCurrency(amount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(budgetProgress * 100))% used")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(budgetProgress > 0.9 ? .red : .secondary)
                }
            }
            
            // Progress bar with glow effect
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: budgetProgress > 0.9 ? [.red, .orange] : 
                                           budgetProgress > 0.7 ? [.orange, .yellow] : [.green, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(budgetProgress, 1.0), height: 8)
                            .shadow(
                                color: budgetProgress > 0.9 ? .red.opacity(0.5) : .green.opacity(0.3),
                                radius: 4,
                                x: 0,
                                y: 0
                            )
                    }
                }
                .frame(height: 8)
                
                // Spending breakdown
                HStack {
                    SpendingBreakdownItem(label: "Spent", amount: spent, color: .red)
                    Spacer()
                    SpendingBreakdownItem(label: "Remaining", amount: remainingBudget, color: .green)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    let trend: Double?
    let isPercentage: Bool
    
    init(title: String, amount: Double, color: Color, icon: String, isPercentage: Bool = false, trend: Double? = nil) {
        self.title = title
        self.amount = amount
        self.color = color
        self.icon = icon
        self.isPercentage = isPercentage
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    TrendIndicator(value: trend, color: color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isPercentage ? "\(Int(amount))%" : "$\(formatCurrency(amount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Views
struct SpendingBreakdownItem: View {
    let label: String
    let amount: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("$\(formatCurrency(amount))")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct TrendIndicator: View {
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
                .foregroundColor(value >= 0 ? .green : .red)
            
            Text("\(abs(value), specifier: "%.1f")%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(value >= 0 ? .green : .red)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill((value >= 0 ? Color.green : Color.red).opacity(0.1))
        )
    }
}

