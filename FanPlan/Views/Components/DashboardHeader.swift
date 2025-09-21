import SwiftUI

struct DashboardHeader: View {
    let dashboardData: FanDashboardData
    let onQuickAdd: () -> Void
    let onProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Top navigation
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDay),")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(dashboardData.user.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Quick Add Button
                    Button(action: onQuickAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.piggyPrimary)
                            .background(Circle().fill(Color.white))
                    }
                    
                    // Profile Button
                    Button(action: onProfile) {
                        AsyncImage(url: URL(string: dashboardData.user.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 28))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            
            // Monthly Budget Overview
            BudgetOverviewCard(
                totalBudget: dashboardData.monthlyBudget,
                spent: dashboardData.spentThisMonth,
                remaining: dashboardData.monthlyBudget - dashboardData.spentThisMonth
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
}

struct BudgetOverviewCard: View {
    let totalBudget: Double
    let spent: Double
    let remaining: Double
    
    private var spentPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return min(spent / totalBudget, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monthly Budget")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(totalBudget.safeCurrencyString)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(LinearGradient(
                            colors: spentPercentage > 0.8 ? [.red, .orange] : [.piggyPrimary, .piggySecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * spentPercentage, height: 8)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 1.0), value: spentPercentage)
                }
            }
            .frame(height: 8)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Spent")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(spent.safeCurrencyString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(remaining.safeCurrencyString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(remaining < 0 ? .red : .white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DashboardHeader(
        dashboardData: FanDashboardData.mock,
        onQuickAdd: {},
        onProfile: {}
    )
    .background(PiggyGradients.background)
}