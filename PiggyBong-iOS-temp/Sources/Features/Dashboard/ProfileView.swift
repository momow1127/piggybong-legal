import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var budgetService: BudgetService
    @State private var showingSettings = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: PiggySpacing.sectionSpacing) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Stats Overview
                    statsOverviewSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Settings & Support
                    settingsSection
                }
                .padding(.horizontal, PiggySpacing.md)
                .padding(.top, PiggySpacing.sm)
            }
            .background(Color.piggyBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .foregroundColor(.piggyPrimary)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Avatar
            Circle()
                .fill(Color.piggyPrimary.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(authManager.currentUser?.name.prefix(1) ?? "U"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.piggyPrimary)
                )
            
            // User info
            VStack(spacing: PiggySpacing.xs) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(PiggyFont.callout)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            // Member since
            Text("PiggyBong member since \(memberSince)")
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyTextSecondary)
        }
        .padding(PiggySpacing.lg)
        .piggyCard()
    }
    
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Your Stats")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PiggySpacing.md), count: 2), spacing: PiggySpacing.md) {
                StatCard(
                    title: "Total Spent",
                    value: "$\(totalSpent, specifier: "%.0f")",
                    icon: "creditcard.fill",
                    color: .piggyPrimary
                )
                
                StatCard(
                    title: "Purchases",
                    value: "\(totalPurchases)",
                    icon: "bag.fill",
                    color: .piggySecondary
                )
                
                StatCard(
                    title: "Favorite Artist",
                    value: favoriteArtist,
                    icon: "star.fill",
                    color: .piggyAccent
                )
                
                StatCard(
                    title: "This Month",
                    value: "$\(monthlySpent, specifier: "%.0f")",
                    icon: "chart.line.uptrend.xyaxis",
                    color: budgetService.currentBudget?.isOverBudget == true ? .budgetRed : .budgetGreen
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Quick Actions")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            VStack(spacing: PiggySpacing.sm) {
                ProfileActionRow(
                    icon: "chart.pie.fill",
                    title: "Export Data",
                    subtitle: "Download your spending data",
                    action: { exportData() }
                )
                
                ProfileActionRow(
                    icon: "arrow.clockwise",
                    title: "Sync Data",
                    subtitle: "Update your purchase history",
                    action: { syncData() }
                )
                
                ProfileActionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage budget alerts",
                    action: { /* Navigate to notifications */ }
                )
            }
            .padding(PiggySpacing.md)
            .piggyCard()
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Settings & Support")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            VStack(spacing: PiggySpacing.sm) {
                ProfileActionRow(
                    icon: "gear",
                    title: "App Settings",
                    subtitle: "Preferences and configuration",
                    action: { showingSettings = true }
                )
                
                ProfileActionRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help with PiggyBong",
                    action: { /* Navigate to help */ }
                )
                
                ProfileActionRow(
                    icon: "heart.fill",
                    title: "Rate PiggyBong",
                    subtitle: "Leave us a review on the App Store",
                    action: { /* Navigate to App Store */ }
                )
                
                ProfileActionRow(
                    icon: "envelope.fill",
                    title: "Feedback",
                    subtitle: "Send us your thoughts",
                    action: { /* Open feedback */ }
                )
                
                Divider()
                    .padding(.vertical, PiggySpacing.xs)
                
                ProfileActionRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    action: { showingSignOutAlert = true },
                    textColor: .budgetRed
                )
            }
            .padding(PiggySpacing.md)
            .piggyCard()
        }
    }
    
    // MARK: - Computed Properties
    
    private var memberSince: String {
        guard let user = authManager.currentUser else { return "2024" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: user.createdAt)
    }
    
    private var totalSpent: Double {
        databaseService.purchases.reduce(0) { $0 + $1.amount }
    }
    
    private var totalPurchases: Int {
        databaseService.purchases.count
    }
    
    private var favoriteArtist: String {
        let topArtists = budgetService.getTopArtists(limit: 1)
        return topArtists.first?.0.name ?? "None yet"
    }
    
    private var monthlySpent: Double {
        budgetService.currentBudget?.spent ?? 0
    }
    
    // MARK: - Actions
    
    private func exportData() {
        // TODO: Implement data export
        print("Exporting data...")
    }
    
    private func syncData() {
        // TODO: Implement data sync
        print("Syncing data...")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: PiggySpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: PiggySpacing.xs) {
                Text(value)
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(title)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(PiggySpacing.md)
        .frame(maxWidth: .infinity)
        .piggyCard()
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    var textColor: Color = .piggyTextPrimary
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PiggySpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(textColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text(title)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(textColor)
                    
                    Text(subtitle)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.piggyTextSecondary)
            }
            .padding(.vertical, PiggySpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var budgetAlertsEnabled = true
    @State private var currency = "USD"
    @State private var darkMode = false
    
    private let currencies = ["USD", "EUR", "GBP", "JPY", "KRW"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Budget Alerts", isOn: $budgetAlertsEnabled)
                        .disabled(!notificationsEnabled)
                }
                
                Section("Preferences") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                Section("Data") {
                    Button("Clear Cache") {
                        // TODO: Implement cache clearing
                    }
                    
                    Button("Reset All Data", role: .destructive) {
                        // TODO: Implement data reset
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Privacy Policy") {
                        // TODO: Open privacy policy
                    }
                    
                    Button("Terms of Service") {
                        // TODO: Open terms
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(DatabaseService())
        .environmentObject(BudgetService())
}