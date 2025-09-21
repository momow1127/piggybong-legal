import SwiftUI
import UserNotifications

// MARK: - Permission Request View
struct PermissionRequestView: View {
    @ObservedObject var onboardingData: OnboardingData
    @StateObject private var viewModel = PermissionViewModel()
    @EnvironmentObject private var notificationService: ArtistNotificationService
    @Environment(\.dismiss) private var dismiss
    @State private var showDetailedSettings = false
    @State private var detailedSettings = ArtistNotificationSettings()
    
    let onComplete: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            PiggyGradients.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    LazyVStack(spacing: PiggySpacing.xl) {
                        // Hero Section
                        heroSection
                        
                        // Permission Cards
                        permissionCardsSection
                        
                        // Privacy Note
                        privacyNoteSection
                        
                        Spacer(minLength: 120) // Bottom padding for button
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                }
            }
            
            // Bottom Action Button
            bottomActionButton
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.checkCurrentPermissions()
            detailedSettings = notificationService.notificationSettings
        }
        .onChange(of: detailedSettings) { _, _ in
            // Auto-save detailed settings
            notificationService.updateSettings(detailedSettings)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: PiggySpacing.sm) {
            // No back button - this is the final onboarding step
            
            VStack(spacing: PiggySpacing.xs) {
                Text("Stay in the Loop 🔔")
                    .font(PiggyFont.title1)
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Get notified about concert announcements, album drops, and more!")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PiggySpacing.md)
            }
        }
        .padding(.bottom, PiggySpacing.md)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Animated notification icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            Color.piggyPrimary.opacity(0.2 - Double(index) * 0.05),
                            lineWidth: 2
                        )
                        .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                        .scaleEffect(viewModel.isAnimating ? 1.2 + Double(index) * 0.1 : 1.0)
                        .opacity(viewModel.isAnimating ? 0.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(index) * 0.5)
                                .repeatForever(autoreverses: true),
                            value: viewModel.isAnimating
                        )
                }
                
                // Main notification bell
                ZStack {
                    Circle()
                        .fill(PiggyGradients.primaryButton)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(viewModel.isAnimating ? -15 : 15))
                        .animation(
                            .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: viewModel.isAnimating
                        )
                    
                    // Notification badge
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .scaleEffect(viewModel.isAnimating ? 1.2 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: viewModel.isAnimating
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                }
            }
            .onAppear {
                viewModel.isAnimating = true
            }
            
            VStack(spacing: PiggySpacing.xs) {
                Text("Never Miss a Beat!")
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Get personalized notifications for your favorite artists")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Permission Cards
    private var permissionCardsSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Main Notifications Card
            PermissionCard(
                title: "Push Notifications",
                description: "Get timely updates about concerts, albums, and events",
                iconName: "bell.fill",
                iconColor: .piggyPrimary,
                isEnabled: viewModel.notificationPermission == .authorized,
                isPending: viewModel.isRequestingPermission,
                showToggle: false
            ) {
                Task {
                    await viewModel.requestNotificationPermission()
                    onboardingData.preferences.notificationsEnabled = viewModel.notificationPermission == .authorized
                }
            }
            
            // Notification Type Preferences
            if viewModel.notificationPermission == .authorized {
                VStack(spacing: PiggySpacing.sm) {
                    HStack {
                        Text("Notification Preferences")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showDetailedSettings.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(showDetailedSettings ? "Less" : "More")
                                    .font(PiggyFont.caption1)
                                    .foregroundColor(.piggySecondary)
                                
                                Image(systemName: showDetailedSettings ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.piggySecondary)
                            }
                        }
                    }
                    
                    if showDetailedSettings {
                        detailedNotificationSettings
                    } else {
                        basicNotificationSettings
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.notificationPermission)
            }
        }
    }
    
    // MARK: - Privacy Note
    private var privacyNoteSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.piggySecondary)
                
                Text("Your Privacy Matters")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                PrivacyFeature(
                    iconName: "lock.fill",
                    title: "Secure Data",
                    description: "Your preferences are stored securely"
                )
                
                PrivacyFeature(
                    iconName: "hand.raised.fill",
                    title: "No Spam",
                    description: "Only relevant updates, no marketing"
                )
                
                PrivacyFeature(
                    iconName: "gear",
                    title: "Full Control",
                    description: "Change preferences anytime in settings"
                )
            }
        }
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(Color.piggySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                        .stroke(Color.piggySecondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, Color.piggyBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                
                VStack(spacing: PiggySpacing.sm) {
                    // Main action button
                    Button(action: onComplete) {
                        HStack(spacing: 8) {
                            Text(buttonTitle)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                .fill(PiggyGradients.primaryButton)
                        )
                        .shadow(
                            color: Color.piggyPrimary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    
                    // Skip button
                    Button("I'll set this up later") {
                        onComplete()
                    }
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    
                    // Debug button (remove in production)
                    Button("🔧 Debug: Test Permission") {
                        Task {
                            print("🔧 Debug button pressed")
                            await viewModel.requestNotificationPermission()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(Color.piggyBackground)
            }
        }
    }
    
    private var buttonTitle: String {
        switch viewModel.notificationPermission {
        case .authorized:
            return "Complete Setup"
        case .denied:
            return "Continue Anyway"
        case .notDetermined:
            return "Enable & Continue"
        case .provisional, .ephemeral:
            return "Complete Setup"
        @unknown default:
            return "Continue"
        }
    }
    
    // MARK: - Basic Notification Settings
    private var basicNotificationSettings: some View {
        VStack(spacing: PiggySpacing.xs) {
            NotificationTypeToggle(
                title: "Tour Announcements",
                description: "Get notified when artists announce concerts",
                iconName: "music.mic.circle.fill",
                isEnabled: detailedSettings.toursAndEvents
            ) {
                detailedSettings.toursAndEvents.toggle()
                onboardingData.preferences.tourAnnouncements = detailedSettings.toursAndEvents
            }
            
            NotificationTypeToggle(
                title: "Comeback Alerts",
                description: "New music releases and major announcements",
                iconName: "star.fill",
                isEnabled: detailedSettings.comebacksAndReleases
            ) {
                detailedSettings.comebacksAndReleases.toggle()
                onboardingData.preferences.comebackAlerts = detailedSettings.comebacksAndReleases
            }
            
            NotificationTypeToggle(
                title: "Merchandise Drops",
                description: "Don't miss limited edition merchandise",
                iconName: "bag.fill",
                isEnabled: detailedSettings.merchDrops
            ) {
                detailedSettings.merchDrops.toggle()
                onboardingData.preferences.merchDropAlerts = detailedSettings.merchDrops
            }
        }
    }
    
    // MARK: - Detailed Notification Settings
    private var detailedNotificationSettings: some View {
        VStack(spacing: PiggySpacing.md) {
            // All notification types
            VStack(spacing: PiggySpacing.xs) {
                DetailedNotificationToggle(
                    icon: "music.note.list",
                    title: "Comebacks & Releases",
                    subtitle: "New music, albums, singles, and MVs",
                    isOn: $detailedSettings.comebacksAndReleases,
                    color: .purple
                )
                
                DetailedNotificationToggle(
                    icon: "ticket.fill",
                    title: "Tours & Events",
                    subtitle: "Concerts, fan meets, and ticket sales",
                    isOn: $detailedSettings.toursAndEvents,
                    color: .pink
                )
                
                DetailedNotificationToggle(
                    icon: "bag.fill",
                    title: "Merch Drops",
                    subtitle: "Official merch and limited editions",
                    isOn: $detailedSettings.merchDrops,
                    color: .green
                )
                
            }
            
            // Smart settings section
            VStack(spacing: PiggySpacing.sm) {
                HStack {
                    Text("Smart Settings")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                    Spacer()
                }
                
                VStack(spacing: PiggySpacing.xs) {
                    SmartSettingToggle(
                        title: "Quiet Hours",
                        description: "Reduce notifications during sleep hours (10 PM - 8 AM)",
                        isOn: $detailedSettings.quietHoursEnabled
                    )
                }
            }
        }
    }
}


// MARK: - Notification Type Toggle
struct NotificationTypeToggle: View {
    let title: String
    let description: String
    let iconName: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                    .fill(Color.piggySecondary.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.piggySecondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.piggyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Toggle
            Toggle("", isOn: .constant(isEnabled))
                .labelsHidden()
                .onTapGesture {
                    onToggle()
                }
        }
        .padding(.horizontal, PiggySpacing.md)
        .padding(.vertical, PiggySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                .fill(isEnabled ? Color.piggySecondary.opacity(0.1) : Color.piggySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .stroke(
                            isEnabled ? Color.piggySecondary.opacity(0.3) : Color.piggyTextSecondary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Privacy Feature
struct PrivacyFeature: View {
    let iconName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: PiggySpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.piggySecondary)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.piggyTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.piggyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Detailed Notification Toggle
struct DetailedNotificationToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: PiggySpacing.sm) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                    .fill(color.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12, weight: .medium))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.piggyTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.piggyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, PiggySpacing.sm)
        .padding(.vertical, PiggySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                .fill(isOn ? color.opacity(0.1) : Color.piggySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                        .stroke(
                            isOn ? color.opacity(0.3) : Color.piggyTextSecondary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Smart Setting Toggle
struct SmartSettingToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: PiggySpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.piggyTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.piggyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, PiggySpacing.sm)
        .padding(.vertical, PiggySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                .fill(isOn ? Color.piggySecondary.opacity(0.1) : Color.piggySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                        .stroke(
                            isOn ? Color.piggySecondary.opacity(0.3) : Color.piggyTextSecondary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}


// MARK: - Preview
#Preview {
    NavigationView {
        PermissionRequestView(
            onboardingData: OnboardingData(),
            onComplete: {},
            onBack: {}
        )
    }
}
