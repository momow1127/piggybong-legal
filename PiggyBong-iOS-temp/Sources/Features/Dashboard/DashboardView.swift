import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var budgetService: BudgetService
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            PurchasesView()
                .tabItem {
                    Image(systemName: "bag.fill")
                    Text("Purchases")
                }
                .tag(1)
            
            BudgetView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Budget")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.piggyPrimary)
        .onAppear {
            loadDashboardData()
        }
    }
    
    private func loadDashboardData() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            await budgetService.fetchCurrentBudget(for: user.id)
            await databaseService.fetchPurchases(for: user.id)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var budgetService: BudgetService
    @EnvironmentObject var databaseService: DatabaseService
    @State private var showingQuickAdd = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: PiggySpacing.sectionSpacing) {
                    // Header
                    headerSection
                    
                    // Budget Overview
                    if let budget = budgetService.currentBudget {
                        BudgetOverviewCard(budget: budget)
                    }
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Purchases
                    recentPurchasesSection
                    
                    // Artist Spending
                    artistSpendingSection
                }
                .padding(.horizontal, PiggySpacing.md)
                .padding(.top, PiggySpacing.sm)
            }
            .background(Color.piggyBackground.ignoresSafeArea())
            .navigationTitle("PiggyBong")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddPurchaseView()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text("Hello, \(authManager.currentUser?.name ?? "K-pop Fan")!")
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("Let's track your K-pop spending")
                    .font(PiggyFont.callout)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            // Piggy avatar placeholder
            Circle()
                .fill(Color.piggyPrimary.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "star.fill")
                        .foregroundColor(.piggyPrimary)
                )
        }
        .padding(.vertical, PiggySpacing.sm)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Quick Actions")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            HStack(spacing: PiggySpacing.md) {
                QuickActionButton(
                    title: "Add Purchase",
                    icon: "plus.circle.fill",
                    color: .piggyPrimary
                ) {
                    showingQuickAdd = true
                }
                
                QuickActionButton(
                    title: "View Budget",
                    icon: "chart.pie.fill",
                    color: .piggySecondary
                ) {
                    // Navigate to budget tab
                }
            }
        }
    }
    
    private var recentPurchasesSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            HStack {
                Text("Recent Purchases")
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to purchases tab
                }
                .font(PiggyFont.callout)
                .foregroundColor(.piggyPrimary)
            }
            
            if databaseService.purchases.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: "No purchases yet",
                    message: "Add your first K-pop purchase to get started!"
                )
            } else {
                LazyVStack(spacing: PiggySpacing.sm) {
                    ForEach(Array(databaseService.purchases.prefix(3))) { purchase in
                        PurchaseRowView(purchase: purchase)
                    }
                }
            }
        }
    }
    
    private var artistSpendingSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Top Artists This Month")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            let topArtists = budgetService.getTopArtists(limit: 3)
            
            if topArtists.isEmpty {
                EmptyStateView(
                    icon: "music.note",
                    title: "No artist spending yet",
                    message: "Start adding purchases to see your favorite artists!"
                )
            } else {
                LazyVStack(spacing: PiggySpacing.sm) {
                    ForEach(topArtists, id: \.0.id) { artist, amount in
                        ArtistSpendingRowView(artist: artist, amount: amount)
                    }
                }
            }
        }
    }
}

struct BudgetOverviewCard: View {
    let budget: Budget
    
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text("\(budget.monthName) Budget")
                        .font(PiggyFont.subheadline)
                        .foregroundColor(.piggyTextSecondary)
                    
                    Text("$\(budget.spent, specifier: "%.2f") / $\(budget.totalBudget, specifier: "%.2f")")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: PiggySpacing.xs) {
                    Text(budget.isOverBudget ? "Over Budget" : "Remaining")
                        .font(PiggyFont.caption1)
                        .foregroundColor(budget.isOverBudget ? .budgetRed : .piggyTextSecondary)
                    
                    Text("$\(abs(budget.remaining), specifier: "%.2f")")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(budget.isOverBudget ? .budgetRed : .budgetGreen)
                }
            }
            
            // Progress bar
            ProgressView(value: budget.progress)
                .progressViewStyle(PiggyProgressViewStyle(
                    color: budget.isOverBudget ? .budgetRed : .piggyPrimary
                ))
        }
        .padding(PiggySpacing.cardPadding)
        .piggyCard()
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: PiggySpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.piggySurface)
            .cornerRadius(PiggyBorderRadius.md)
        }
    }
}

struct PurchaseRowView: View {
    let purchase: Purchase
    @EnvironmentObject var databaseService: DatabaseService
    
    private var artist: Artist? {
        databaseService.artists.first { $0.id == purchase.artistId }
    }
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            Image(systemName: purchase.category.icon)
                .font(.title3)
                .foregroundColor(.piggyPrimary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(purchase.description)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(artist?.displayName ?? "Unknown Artist")
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            Text("$\(purchase.amount, specifier: "%.2f")")
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(.piggyTextPrimary)
        }
        .padding(PiggySpacing.md)
        .background(Color.piggySurface)
        .cornerRadius(PiggyBorderRadius.md)
    }
}

struct ArtistSpendingRowView: View {
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
                Text(artist.displayName)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("\(artist.group ?? "Solo Artist")")
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            Text("$\(amount, specifier: "%.2f")")
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(.piggyTextPrimary)
        }
        .padding(PiggySpacing.md)
        .background(Color.piggySurface)
        .cornerRadius(PiggyBorderRadius.md)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.piggyTextSecondary)
            
            VStack(spacing: PiggySpacing.xs) {
                Text(title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(message)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(PiggySpacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.piggySurface)
        .cornerRadius(PiggyBorderRadius.md)
    }
}

struct PiggyProgressViewStyle: ProgressViewStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 8)
                .overlay(
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0))
                        Spacer(minLength: 0)
                    }
                )
        }
        .frame(height: 8)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .environmentObject(BudgetService())
        .environmentObject(DatabaseService())
}