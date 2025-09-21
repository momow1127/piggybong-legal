import SwiftUI

// MARK: - Style Guide Implementation
// This file demonstrates how to apply consistent styling across the entire app

// MARK: - Example Views with Consistent Styling

// 1. Dashboard View Example
struct StyledDashboardView: View {
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header with gradient background
                headerSection
                
                // Search functionality
                searchSection
                
                // Stats cards
                statsSection
                
                // Recent activities
                recentActivitiesSection
            }
            .standardHorizontalPadding()
        }
        .gradientBackground()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Good morning!")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            
            Text("Ready to plan your K-pop journey?")
                .font(DesignSystem.Typography.displayMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
    
    private var searchSection: some View {
        CustomSearchBar(
            text: $searchText,
            placeholder: "Search events, artists, goals..."
        )
        .customShadow(DesignSystem.Shadows.soft)
    }
    
    private var statsSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            StatCard(
                title: "This Month",
                value: "$245",
                subtitle: "Budget used",
                icon: "creditcard"
            )
            
            StatCard(
                title: "Goals",
                value: "3",
                subtitle: "In progress",
                icon: "target"
            )
        }
    }
    
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Recent Activities")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                ActivityRow(
                    title: "Concert ticket saved",
                    subtitle: "BTS Permission to Dance",
                    amount: "+$50",
                    icon: "music.note"
                )
                
                ActivityRow(
                    title: "Album purchase",
                    subtitle: "TWICE Formula of Love",
                    amount: "-$25",
                    icon: "opticaldisc"
                )
            }
        }
    }
}

// 2. Settings/Profile View Example
struct StyledProfileView: View {
    @State private var notificationsEnabled = true
    @State private var monthlyBudget = 200.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    profileHeaderSection
                    
                    settingsSection
                    
                    preferencesSection
                    
                    aboutSection
                }
                .standardHorizontalPadding()
            }
            .gradientBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Profile image placeholder
            Circle()
                .fill(DesignSystem.Colors.primaryGradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("JK")
                        .font(DesignSystem.Typography.headlineLarge)
                        .foregroundColor(.white)
                )
            
            Text("K-pop Fan")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Member since March 2024")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Settings")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                SettingsRow(
                    title: "Notifications",
                    subtitle: "Get updates about your goals",
                    icon: "bell"
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(DesignSystem.Colors.primaryPink)
                }
                
                NavigationLink(destination: EmptyView()) {
                    SettingsRow(
                        title: "Privacy & Security",
                        subtitle: "Manage your data and privacy",
                        icon: "lock.shield",
                        showChevron: true
                    )
                }
                
                NavigationLink(destination: EmptyView()) {
                    SettingsRow(
                        title: "Help & Support",
                        subtitle: "Get help when you need it",
                        icon: "questionmark.circle",
                        showChevron: true
                    )
                }
            }
            .cardStyle()
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Preferences")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Monthly Budget: $\(Int(monthlyBudget))")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Slider(value: $monthlyBudget, in: 50...1000, step: 25)
                        .tint(DesignSystem.Colors.primaryPink)
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Button("Sign Out") {
                // Handle sign out
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Text("Version 1.0.0")
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.placeholderText)
        }
    }
}

// MARK: - Reusable Components

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryPink)
                
                Spacer()
            }
            
            Text(value)
                .font(DesignSystem.Typography.headlineLarge)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(title)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text(subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.placeholderText)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .customShadow(DesignSystem.Shadows.soft)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            Circle()
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Amount
            Text(amount)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(
                    amount.hasPrefix("+") ? DesignSystem.Colors.success : DesignSystem.Colors.primaryText
                )
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

struct SettingsRow<Accessory: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let showChevron: Bool
    let accessory: (() -> Accessory)?
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        showChevron: Bool = false,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.showChevron = showChevron
        self.accessory = accessory
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            Circle()
                .fill(DesignSystem.Colors.primaryGradient.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryPink)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Accessory
            if let accessory = accessory {
                accessory()
            }
            
            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.placeholderText)
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
}

// MARK: - Text Input Components

struct StyledTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(DesignSystem.Typography.bodyLarge)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Loading States

struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryPink))
                .scaleEffect(1.5)
            
            Text(message)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gradientBackground()
    }
}

// MARK: - Empty States

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.placeholderText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gradientBackground()
    }
}