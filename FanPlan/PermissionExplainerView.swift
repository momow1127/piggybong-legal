import SwiftUI
import UserNotifications

// MARK: - Permission Explainer View
struct PermissionExplainerView: View {
    let onComplete: () -> Void
    @State private var isAnimating = false
    @State private var isRequestingPermission = false
    @State private var currentPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var buttonTitle = "Enable Notifications"
    @State private var debugInfo = ""
    
    var body: some View {
        ZStack {
            // Full-screen gradient background
            PiggyGradients.background.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top spacing similar to other onboarding screens
                Spacer()
                    .frame(height: 80)
                
                // Content
                VStack(spacing: PiggySpacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Animated Bell Feature
                    animatedBellFeature
                    
                    // Benefits Bullets
                    benefitsSection
                }
                .padding(.horizontal, PiggySpacing.lg)
                
                Spacer()
                
                // Button area
                VStack(spacing: 20) {
                    // Main button
                    PiggyButton(
                        title: isRequestingPermission ? "Requesting..." : buttonTitle,
                        action: {
                            print("🔔 Enable Notifications button tapped!")
                            // Add haptic feedback to confirm button press
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            requestNotificationPermission()
                        },
                        isLoading: isRequestingPermission,
                        isDisabled: isRequestingPermission
                    )
                    
                    // Maybe Later button with better spacing
                    Button("Maybe Later") {
                        print("🔔 Maybe Later button tapped!")
                        onComplete()
                    }
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .padding(.top, 4) // Additional top padding for visual separation
                    
                    // MARK: - Development Bypass Button
                    #if DEBUG
                    Button("🚀 DEV: SKIP NOTIFICATIONS") {
                        print("🚀 Development bypass: Skipping notifications")
                        onComplete()
                    }
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(6)
                    .padding(.top, 8)
                    #endif
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.bottom, PiggySpacing.xl)
            }
        }
        .onAppear {
            isAnimating = true
            checkCurrentPermissionStatus()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            Text("Never Miss a Comeback")
                .font(PiggyFont.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.piggyTextPrimary, Color.piggyPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Animated Bell Feature
    private var animatedBellFeature: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        Color.piggyPrimary.opacity(0.2 - Double(index) * 0.05),
                        lineWidth: 2
                    )
                    .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                    .scaleEffect(isAnimating ? 1.2 + Double(index) * 0.1 : 1.0)
                    .opacity(isAnimating ? 0.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 2.0 + Double(index) * 0.3)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Main notification bell
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.piggyPrimary, Color.piggySecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? -10 : 10))
                    .animation(
                        .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
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
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    Spacer()
                }
                .frame(width: 80, height: 80)
            }
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(spacing: PiggySpacing.md) {
            benefitRow(icon: "🎉", title: "Big Comebacks & Announcements")
            benefitRow(icon: "🛍️", title: "Get alerts for merch or special releases")
            benefitRow(icon: "🎫", title: "Presale & Event Reminders")
        }
    }
    
    private func benefitRow(icon: String, title: String) -> some View {
        HStack(spacing: PiggySpacing.sm) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(title)
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextPrimary)
            
            Spacer()
        }
        .padding(.horizontal, PiggySpacing.md)
        .padding(.vertical, PiggySpacing.sm)
    }
    
    
    
    // MARK: - Request Notification Permission
    private func requestNotificationPermission() {
        print("🔔 *** NOTIFICATION PERMISSION REQUEST STARTED ***")
        print("🔔 Button tapped - requesting notification permission")
        isRequestingPermission = true
        
        let center = UNUserNotificationCenter.current()
        
        // Simple, direct permission request
        center.getNotificationSettings { settings in
            print("🔍 Current permission status: \(settings.authorizationStatus.rawValue)")
            
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // Request permission - this should show iOS popup
                    print("📱 Requesting notification permission...")
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        print("📱 Permission result: granted=\(granted), error=\(String(describing: error))")
                        
                        DispatchQueue.main.async {
                            self.isRequestingPermission = false
                            if granted {
                                print("✅ Notifications enabled!")
                                UIApplication.shared.registerForRemoteNotifications()
                            } else {
                                print("⚠️ Notifications denied")
                            }
                            self.onComplete()
                        }
                    }
                    
                case .denied:
                    print("⚠️ Notifications previously denied - opening settings")
                    self.isRequestingPermission = false
                    self.openSettings()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.onComplete()
                    }
                    
                case .authorized, .provisional, .ephemeral:
                    print("✅ Notifications already enabled")
                    self.isRequestingPermission = false
                    self.onComplete()
                    
                @unknown default:
                    print("❓ Unknown notification status")
                    self.isRequestingPermission = false
                    self.onComplete()
                }
            }
        }
    }
    
    private func checkCurrentPermissionStatus() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            await MainActor.run {
                currentPermissionStatus = settings.authorizationStatus
                
                switch settings.authorizationStatus {
                case .notDetermined:
                    buttonTitle = "Enable Notifications"
                case .denied:
                    buttonTitle = "Open Settings"
                case .authorized, .provisional, .ephemeral:
                    buttonTitle = "Enable Notifications"
                @unknown default:
                    buttonTitle = "Enable Notifications"
                }
                
                print("🔍 Permission status on view load: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Preview
#Preview {
    PermissionExplainerView {
        print("Permission explainer completed")
    }
}