import SwiftUI

// MARK: - Profile Settings View (MVP)
struct ProfileSettingsView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @Environment(\.dismiss) private var dismiss
    @State private var username = "Fan User"
    @State private var showDeleteAccountModal = false

    var body: some View {
        NavigationView {
            ZStack {
                    PiggyGradients.background.ignoresSafeArea()

                    ScrollView {
                        LazyVStack(spacing: PiggySpacing.xl) {  // Use xl (32pt) for section spacing
                            // User profile info
                            userProfileSection

                            // Account Section
                            accountSection

                            // Privacy & Data Section
                            privacySection

                            // Support Section
                            supportSection

                            // Footer Section
                            footerSection

                            // Bottom spacing for tab bar
                            Spacer(minLength: PiggySpacing.xxl)
                        }
                        .padding(.horizontal, PiggySpacing.screenMargin)  // Add horizontal margins (20pt)
                        .padding(.top, PiggySpacing.sm)
                        .padding(.bottom, PiggySpacing.xl)
                    }
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserData()
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthed in
                if !isAuthed {
                    globalLoading.hide()
                }
            }
            .piggyCompactSheet(
                isPresented: $showDeleteAccountModal,
                title: "Delete Account",
                subtitle: "This action cannot be undone"
            ) {
                DeleteAccountModalContent(isPresented: $showDeleteAccountModal) {
                    Task {
                        await performAccountDeletion()
                    }
                }
            }
        }
    }

    // MARK: - Section Components

    // MARK: - User Profile Section (without title)
    private var userProfileSection: some View {
        // User profile info - no card wrapper, just content
        HStack(spacing: PiggySpacing.md) {
            PiggyAvatarCircle(
                text: username,
                size: .large,
                style: .userGradient,
                showBorder: true,
                borderColor: .piggyPrimary.opacity(0.3),
                action: nil
            )

            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(username)
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)

                Text("K-pop Fan")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header - match Notifications style
            Text("ACCOUNT")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)

            PiggyCard(
                style: .secondary,
                cornerRadius: .medium,
                padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            ) {
                VStack(spacing: PiggySpacing.sm) {
                    NavigationLink(destination: EditUsernameView(username: $username, onSave: { saveUsername(username) })) {
                        PiggyMenuRow(
                            "Edit Profile",
                            leadingIcon: "person.circle",
                            trailingIcon: "chevron.right",
                            style: .inline,
                            onTap: nil
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(Color.piggyCardBorder.opacity(0.3))
                        .padding(.horizontal, PiggySpacing.md)

                    NavigationLink(destination: NotificationSettingsView()) {
                        PiggyMenuRow(
                            "Notifications",
                            leadingIcon: "bell",
                            trailingIcon: "chevron.right",
                            style: .inline,
                            onTap: nil
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(Color.piggyCardBorder.opacity(0.3))
                        .padding(.horizontal, PiggySpacing.md)

                    Button {
                        showDeleteAccountModal = true
                    } label: {
                        PiggyMenuRow(
                            "Delete Account",
                            leadingIcon: "trash",
                            trailingIcon: "chevron.right",
                            style: .inline,
                            onTap: nil
                        )
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header - match Notifications style
            Text("PRIVACY & DATA")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)

            PiggyCard(
                style: .secondary,
                cornerRadius: .medium,
                padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            ) {
                VStack(spacing: PiggySpacing.sm) {
                    Button {
                        print("🔗 Terms of Service button tapped")
                        LegalDocumentService.shared.openTermsOfService {
                            print("⚠️ Terms of Service fallback triggered")
                        }
                    } label: {
                        PiggyMenuRow(
                            "Terms of Service",
                            leadingIcon: "doc.text",
                            trailingIcon: "arrow.up.right.square",
                            style: .inline
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(Color.piggyCardBorder.opacity(0.3))
                        .padding(.horizontal, PiggySpacing.md)

                    Button {
                        print("🔗 Privacy Policy button tapped")
                        LegalDocumentService.shared.openPrivacyPolicy {
                            print("⚠️ Privacy Policy fallback triggered")
                        }
                    } label: {
                        PiggyMenuRow(
                            "Privacy Policy",
                            leadingIcon: "shield",
                            trailingIcon: "arrow.up.right.square",
                            style: .inline
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header - match Notifications style
            Text("SUPPORT")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)

            PiggyCard(
                style: .secondary,
                cornerRadius: .medium,
                padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        openMailto()
                    } label: {
                        PiggyMenuRow(
                            "Contact Us",
                            leadingIcon: "envelope",
                            trailingIcon: "chevron.right",
                            style: .inline,
                            onTap: nil
                        )
                    }
                    .buttonStyle(.plain)

                    #if DEBUG
                    Divider()
                        .background(Color.piggyCardBorder.opacity(0.3))
                        .padding(.horizontal, PiggySpacing.md)

                    NavigationLink(destination: AppCheckTestView()) {
                        PiggyMenuRow(
                            "🔒 Test App Check",
                            leadingIcon: "checkmark.shield",
                            trailingIcon: "chevron.right",
                            style: .inline,
                            onTap: nil
                        )
                    }
                    .buttonStyle(.plain)
                    #endif
                }
            }
        }
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Log Out Button with breathing room
            PiggyButton(
                title: "Log Out",
                action: {
                    Task {
                        await performSignOut()
                    }
                },
                style: .destructive,
                size: .large
            )
            .padding(.horizontal, PiggySpacing.sm)  // Add 8pt breathing room
            .disabled(globalLoading.isVisible)
            .opacity(globalLoading.isVisible ? 0.6 : 1.0)

            // App Version
            appVersionFooter
        }
    }

    // MARK: - App Version Footer
    private var appVersionFooter: some View {
        HStack {
            Text("Version \(appVersion)")
                .font(PiggyFont.caption2)
                .foregroundColor(.piggyTextTertiary)

            Spacer()
        }
    }

    // MARK: - App Version Helper
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Computed Properties
    private var userInitials: String {
        let components = username.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }

    private var avatarColor: Color {
        // Generate consistent color based on username using Piggy colors
        let colors: [Color] = [.piggyPrimary, .piggySecondary, Color.pink, Color.purple, Color.orange, Color.green]
        let hash = username.hashValue
        return colors[abs(hash) % colors.count]
    }

    // MARK: - Helper Functions

    @MainActor
    private func performSignOut() async {
        print("🔓 Starting sign out process...")
        globalLoading.showLogout()

        await authService.signOut()
        print("✅ Sign out successful - UI should update automatically")
        // Keep hasCompletedOnboarding intact - users shouldn't see onboarding again
        // App will automatically redirect to login screen when isAuthenticated becomes false
        // GlobalLoading will be hidden by onChange(of: authService.isAuthenticated)
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openMailto() {
        guard let url = URL(string: "mailto:hello@piggybong.com") else {
            showEmailFallback()
            return
        }

        // Check if device can handle mailto URLs
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if !success {
                    DispatchQueue.main.async {
                        showEmailFallback()
                    }
                }
            }
        } else {
            showEmailFallback()
        }
    }

    private func showEmailFallback() {
        // Copy email to clipboard and show alert
        UIPasteboard.general.string = "hello@piggybong.com"

        // Show alert with copied email
        let alert = UIAlertController(
            title: "Email Copied",
            message: "No email app found. The email address 'hello@piggybong.com' has been copied to your clipboard.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func loadUserData() {
        // Load from authentication service first
        if let currentUser = authService.currentUser {
            username = generateUsernameFromAuth(currentUser.name, currentUser.email)
        } else if let savedUsername = UserDefaults.standard.string(forKey: "user_fandom_name") {
            username = savedUsername
        }
    }

    private func generateUsernameFromAuth(_ displayName: String, _ email: String) -> String {
        // First try to use display name if it's meaningful
        if !displayName.isEmpty && displayName != "User" && !displayName.contains("@") {
            return displayName
        }

        // Otherwise extract from email
        let emailPrefix = email.components(separatedBy: "@").first ?? "Fan"

        // Clean up common email patterns
        let cleanedName = emailPrefix
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: .decimalDigits.inverted)
            .joined()

        // Capitalize properly
        let finalName = cleanedName.isEmpty ? "Fan User" : cleanedName.capitalized

        return finalName.isEmpty ? "Fan User" : finalName
    }

    private func saveUsername(_ name: String) {
        let previousName = UserDefaults.standard.string(forKey: "user_fandom_name")
        UserDefaults.standard.set(name, forKey: "user_fandom_name")

        // Track fandom naming event
        AIInsightAnalyticsService.shared.logFandomNamed(
            fandomName: name,
            isFirstTime: previousName == nil
        )
    }

    // MARK: - Delete Account Action
    @MainActor
    private func performAccountDeletion() async {
        print("🗑️ Starting account deletion process...")

        // Close modal and show loading
        showDeleteAccountModal = false
        globalLoading.showAccountDeletion()

        do {
            // Call AuthenticationService to delete account
            try await authService.deleteAccount()

            // Clear all local data
            clearAllLocalData()

            print("✅ Account deletion successful")
            // The app will automatically redirect to login screen when isAuthenticated becomes false
            globalLoading.hide()

        } catch {
            print("❌ Account deletion failed: \(error)")
            globalLoading.hide()

            // Show error alert
            // Note: In production, you'd want to show a proper error modal
            print("⚠️ Please try again or contact support at hello@piggybong.com")
        }
    }

    private func clearAllLocalData() {
        // Clear onboarding status so they see onboarding if they sign up again
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Clear cached user data
        UserDefaults.standard.removeObject(forKey: "user_fandom_name")
        UserDefaults.standard.removeObject(forKey: "CachedSelectedArtists")
        UserDefaults.standard.removeObject(forKey: "unreadNotificationCount")

        // Clear any other app-specific cache
        UserDefaults.standard.synchronize()

        print("🧹 All local data cleared")
    }
}

#if DEBUG
struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
            .environmentObject(AuthenticationService.shared)
            .environmentObject(GlobalLoadingManager.shared)
    }
}
#endif
