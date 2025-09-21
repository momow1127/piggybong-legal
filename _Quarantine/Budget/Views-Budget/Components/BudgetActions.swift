import SwiftUI

// MARK: - Budget Actions Component
struct BudgetActions: View {
    @Binding var showingAddBudget: Bool
    let animateCards: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActionCard(
                        title: "Add Expense",
                        icon: "plus.circle.fill",
                        color: .purple,
                        action: { showingAddBudget = true }
                    )
                    
                    ActionCard(
                        title: "Set Goal",
                        icon: "target",
                        color: .blue,
                        action: { /* Handle set goal */ }
                    )
                    
                    ActionCard(
                        title: "Transfer",
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: .green,
                        action: { /* Handle transfer */ }
                    )
                    
                    ActionCard(
                        title: "Analytics",
                        icon: "chart.bar.fill",
                        color: .orange,
                        action: { /* Handle analytics */ }
                    )
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateCards)
    }
}

// MARK: - Action Card
struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticManager.medium()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color)
                            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


