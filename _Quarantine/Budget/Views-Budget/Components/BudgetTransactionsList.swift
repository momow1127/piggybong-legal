import SwiftUI

// MARK: - Budget Transactions List Component
struct BudgetTransactionsList: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Binding var showingHistory: Bool
    let animateCards: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See All") {
                    showingHistory = true
                    HapticManager.light()
                }
                .font(.subheadline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.recentTransactions, id: \.id) { transaction in
                    TransactionRow(transaction: transaction)
                        .onTapGesture {
                            HapticManager.light()
                            // Handle transaction tap
                        }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: animateCards)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.category.icon)
                    .font(.headline)
                    .foregroundColor(transaction.category.color)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(transaction.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and date
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .expense ? "-" : "+")$\(formatCurrency(transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
                
                Text(transaction.date.formatted(.dateTime.month().day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}



