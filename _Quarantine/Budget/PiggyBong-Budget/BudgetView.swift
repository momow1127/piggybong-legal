import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var budgetService: BudgetService
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var databaseService: DatabaseService
    @State private var showingBudgetEditor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: PiggySpacing.sectionSpacing) {
                    if let budget = budgetService.currentBudget {
                        // Budget Overview
                        budgetOverviewSection(budget)
                        
                        // Spending by Category
                        categorySpendingSection
                        
                        // Artist Allocations
                        artistAllocationsSection
                        
                        // Monthly Trend (placeholder)
                        monthlyTrendSection
                    } else {
                        // Empty state
                        EmptyStateView(
                            icon: "chart.pie",
                            title: "No budget set",
                            message: "Set up your monthly budget to start tracking your K-pop spending!"
                        )
                    }
                }
                .padding(.horizontal, PiggySpacing.md)
                .padding(.top, PiggySpacing.sm)
            }
            .background(Color.piggyBackground.ignoresSafeArea())
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingBudgetEditor = true
                    }
                    .foregroundColor(.piggyPrimary)
                }
            }
            .sheet(isPresented: $showingBudgetEditor) {
                BudgetEditorView()
            }
        }
        .onAppear {
            loadBudgetData()
        }
    }
    
    private func budgetOverviewSection(_ budget: Budget) -> some View {
        VStack(spacing: PiggySpacing.lg) {
            // Main budget card
            VStack(spacing: PiggySpacing.md) {
                Text("\(budget.monthName) \(budget.year)")
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: min(budget.progress, 1.0))
                        .stroke(
                            budget.isOverBudget ? Color.budgetRed : Color.piggyPrimary,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(PiggyAnimation.slow, value: budget.progress)
                    
                    VStack(spacing: PiggySpacing.xs) {
                        Text("$\(budget.spent, specifier: "%.0f")")
                            .font(PiggyFont.title1)
                            .foregroundColor(.piggyTextPrimary)
                        
                        Text("of $\(budget.totalBudget, specifier: "%.0f")")
                            .font(PiggyFont.callout)
                            .foregroundColor(.piggyTextSecondary)
                        
                        Text("\(Int(budget.progress * 100))%")
                            .font(PiggyFont.caption1)
                            .foregroundColor(budget.isOverBudget ? .budgetRed : .piggyPrimary)
                    }
                }
                
                // Status indicators
                HStack(spacing: PiggySpacing.xl) {
                    VStack(spacing: PiggySpacing.xs) {
                        Text(budget.isOverBudget ? "Over Budget" : "Remaining")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)
                        
                        Text("$\(abs(budget.remaining), specifier: "%.2f")")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(budget.isOverBudget ? .budgetRed : .budgetGreen)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: PiggySpacing.xs) {
                        Text("Days Left")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)
                        
                        Text("\(daysLeftInMonth)")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                    }
                }
            }
            .padding(PiggySpacing.lg)
            .piggyCard()
        }
    }
    
    private var categorySpendingSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Spending by Category")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            let categorySpending = budgetService.getSpendingByCategory()
            
            if categorySpending.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No spending data",
                    message: "Add purchases to see spending breakdown"
                )
            } else {
                LazyVStack(spacing: PiggySpacing.sm) {
                    ForEach(categorySpending.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                        CategorySpendingRow(category: category, amount: amount, total: categorySpending.values.reduce(0, +))
                    }
                }
                .padding(PiggySpacing.md)
                .piggyCard()
            }
        }
    }
    
    private var artistAllocationsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            HStack {
                Text("Artist Spending")
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                Button("Manage") {
                    // TODO: Navigate to artist allocation management
                }
                .font(PiggyFont.callout)
                .foregroundColor(.piggyPrimary)
            }
            
            let topArtists = budgetService.getTopArtists(limit: 5)
            
            if topArtists.isEmpty {
                EmptyStateView(
                    icon: "music.note",
                    title: "No artist spending",
                    message: "Start adding purchases to see artist breakdown"
                )
            } else {
                LazyVStack(spacing: PiggySpacing.sm) {
                    ForEach(topArtists, id: \.0.id) { artist, amount in
                        ArtistSpendingDetailRow(artist: artist, amount: amount)
                    }
                }
                .padding(PiggySpacing.md)
                .piggyCard()
            }
        }
    }
    
    private var monthlyTrendSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Spending Trend")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            // Simple placeholder for monthly trend
            VStack(spacing: PiggySpacing.md) {
                Text("Coming Soon")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("Monthly spending trends and insights will be available soon!")
                    .font(PiggyFont.callout)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(PiggySpacing.lg)
            .frame(maxWidth: .infinity)
            .piggyCard()
        }
    }
    
    private var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        return calendar.dateComponents([.day], from: now, to: endOfMonth).day ?? 0
    }
    
    private func loadBudgetData() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            await budgetService.fetchCurrentBudget(for: user.id)
            if let budget = budgetService.currentBudget {
                await budgetService.fetchArtistAllocations(for: budget.id)
            }
        }
    }
}

struct CategorySpendingRow: View {
    let category: PurchaseCategory
    let amount: Double
    let total: Double
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return amount / total
    }
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(.piggyPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                HStack {
                    Text(category.displayName)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Spacer()
                    
                    Text("$\(amount, specifier: "%.2f")")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                }
                
                ProgressView(value: percentage)
                    .progressViewStyle(PiggyProgressViewStyle(color: .piggyPrimary))
                
                Text("\(Int(percentage * 100))% of total")
                    .font(PiggyFont.caption2)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
    }
}

struct ArtistSpendingDetailRow: View {
    let artist: Artist
    let amount: Double
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            Circle()
                .fill(Color.piggyPrimary.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(artist.name.prefix(1)))
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyPrimary)
                )
            
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(artist.name)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                if let group = artist.group {
                    Text(group)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: PiggySpacing.xs) {
                Text("$\(amount, specifier: "%.2f")")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                // Find allocation if exists
                if let allocation = findAllocation(for: artist.id) {
                    Text("\(Int(allocation.progress * 100))% of budget")
                        .font(PiggyFont.caption2)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
        }
    }
    
    @EnvironmentObject var budgetService: BudgetService
    
    private func findAllocation(for artistId: UUID) -> ArtistBudgetAllocation? {
        budgetService.artistAllocations.first { $0.artistId == artistId }
    }
}

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var budgetService: BudgetService
    @EnvironmentObject var authManager: AuthManager
    @State private var monthlyBudget: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: PiggySpacing.lg) {
                // Header
                VStack(spacing: PiggySpacing.sm) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.piggyPrimary)
                    
                    Text("Edit Monthly Budget")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text("Set how much you want to spend on K-pop this month")
                        .font(PiggyFont.callout)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, PiggySpacing.lg)
                
                // Budget input
                VStack(spacing: PiggySpacing.md) {
                    HStack {
                        Text("$")
                            .font(PiggyFont.title2)
                            .foregroundColor(.piggyTextPrimary)
                        
                        TextField("0", text: $monthlyBudget)
                            .font(PiggyFont.budgetAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(PiggySpacing.md)
                    .background(Color.piggySurface)
                    .cornerRadius(PiggyBorderRadius.md)
                    
                    Text("Current budget: $\(budgetService.currentBudget?.totalBudget ?? 0, specifier: "%.2f")")
                        .font(PiggyFont.footnote)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, PiggySpacing.lg)
            .background(Color.piggyBackground.ignoresSafeArea())
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(monthlyBudget.isEmpty || Double(monthlyBudget) == nil)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                monthlyBudget = String(budgetService.currentBudget?.totalBudget ?? 0)
            }
        }
    }
    
    private func saveBudget() {
        guard let amount = Double(monthlyBudget),
              let user = authManager.currentUser else { return }
        
        Task {
            await budgetService.updateBudget(totalBudget: amount, for: user.id)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    BudgetView()
        .environmentObject(BudgetService())
        .environmentObject(AuthManager())
        .environmentObject(DatabaseService())
}