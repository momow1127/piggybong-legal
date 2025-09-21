import SwiftUI
import Foundation

struct BudgetScreen: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingAddBudget = false
    @State private var showingHistory = false
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var showingFilters = false
    @State private var animateCards = false
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Simple gradient background
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.6),
                    Color.blue.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header with navigation and timeframe selector
                    BudgetHeader(
                        selectedTimeframe: $selectedTimeframe,
                        showingFilters: $showingFilters,
                        showingHistory: $showingHistory,
                        animateCards: animateCards
                    )
                    
                    // Summary cards with balance and stats
                    BudgetSummaryCards(
                        viewModel: viewModel,
                        animateCards: animateCards
                    )
                    
                    // Quick actions for common tasks
                    BudgetActions(
                        showingAddBudget: $showingAddBudget,
                        animateCards: animateCards
                    )
                    
                    // Recent transactions list
                    BudgetTransactionsList(
                        viewModel: viewModel,
                        showingHistory: $showingHistory,
                        animateCards: animateCards
                    )
                    
                    // Budget goals progress
                    budgetGoalsSection
                    
                    // Insights and recommendations
                    insightsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateCards = true
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView()
        }
        .sheet(isPresented: $showingHistory) {
            BudgetHistoryView()
        }
        .sheet(isPresented: $showingFilters) {
            BudgetFiltersView()
        }
    }
    
    // MARK: - Budget Goals Section
    private var budgetGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Goals")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.budgetGoals, id: \.id) { goal in
                    BudgetGoalCard(goal: goal)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateCards)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.insights, id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: animateCards)
    }
}

// MARK: - Budget Goal Card
struct BudgetGoalCard: View {
    let goal: BudgetGoal
    
    private var progressPercentage: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return goal.currentAmount / goal.targetAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(goal.currentAmount))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("of $\(Int(goal.targetAmount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * min(progressPercentage, 1.0), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(progressPercentage * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let deadline = goal.deadline {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                    Text("\(max(daysRemaining, 0)) days left")
                        .font(.caption)
                        .foregroundColor(daysRemaining < 7 ? .red : .secondary)
                }
            }
        }
        .padding(16)
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

// MARK: - Insight Card
struct InsightCard: View {
    let insight: BudgetInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title3)
                .foregroundColor(insight.type.color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(insight.type.color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(insight.actionTitle) {
                HapticManager.light()
                // Handle action
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(insight.type.color)
            )
        }
        .padding(16)
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

// MARK: - Additional Views (Placeholder)
struct AddBudgetView: View {
    var body: some View {
        Text("Add Budget View")
    }
}

struct BudgetHistoryView: View {
    var body: some View {
        Text("Budget History View")
    }
}

struct BudgetFiltersView: View {
    var body: some View {
        Text("Budget Filters View")
    }
}


// MARK: - Preview
#Preview {
    BudgetScreen()
}