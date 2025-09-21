import SwiftUI

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var notificationService = ArtistNotificationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var permissionDeniedMessage = ""
    @State private var authStatus: NotificationAuthStatus = .notDetermined
    @State private var showToast = false
    
    private var areNotificationsEnabled: Bool {
        authStatus == .authorized || authStatus == .provisional
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                VStack(spacing: PiggySpacing.xl) {
                    // Permission Status Header
                    permissionStatusSection
                    
                    // Artist Updates Section
                    if areNotificationsEnabled {
                        artistUpdatesSection
                    } else {
                        disabledArtistUpdatesSection
                    }
                    
                    // Smart Settings Section
                    if areNotificationsEnabled {
                        smartSettingsSection
                    } else {
                        disabledSmartSettingsSection
                    }
                }
                // Profile tab spacing pattern
                .padding(.horizontal, PiggySpacing.md) // 16pt sides
                .padding(.top, PiggySpacing.sm) // Match profile page top padding
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, PiggySpacing.lg)) // safe bottom
                
                // Toast for disabled toggle feedback
                if showToast {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Turn on notifications above first.")
                                .font(PiggyFont.caption1)
                                .foregroundColor(.white)
                                .padding(PiggySpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                                        .fill(Color.black.opacity(0.8))
                                )
                            Spacer()
                        }
                        // Toast positioning: Above safe area bottom to avoid home indicator
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom + 20, 100))
                    }
                    .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.piggyTextPrimary)
                }
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                Task {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        await UIApplication.shared.open(settingsUrl)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(permissionDeniedMessage)
        }
        .onAppear {
            notificationService.checkNotificationStatus()
            Task {
                authStatus = await notificationService.getNotificationAuthStatus()
            }
        }
    }
    
    // MARK: - Permission Status Section
    private var permissionStatusSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("NOTIFICATION STATUS")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)
            
            PiggyCard(style: .secondary, padding: EdgeInsets()) {
                VStack(spacing: 0) {
                    // Status row with chip
                    HStack(spacing: PiggySpacing.md) {
                        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                            Text("Notifications")
                                .font(PiggyFont.body)
                                .foregroundColor(.piggyTextPrimary)
                            
                            Text("Never miss comebacks & updates")
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Status chip
                        Text(authStatus.displayText)
                            .font(PiggyFont.caption1)
                            .fontWeight(.medium)
                            .padding(.horizontal, PiggySpacing.sm)
                            .padding(.vertical, PiggySpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                                    .fill(authStatus == .authorized ? Color.piggyAccent.opacity(0.1) : Color.piggyTextTertiary.opacity(0.1))
                            )
                            .foregroundColor(authStatus == .authorized ? .piggyAccent : .piggyTextSecondary)
                    }
                    .padding(PiggySpacing.md)
                    .frame(minHeight: 52)
                    
                    // CTA row
                    if authStatus != .authorized {
                        Divider()
                            .background(Color.piggyCardBorderSubtle)
                            .padding(.leading, PiggySpacing.md)
                        
                        Button(action: {
                            handlePermissionAction()
                        }) {
                            HStack {
                                Text(authStatus.ctaText)
                                    .font(PiggyFont.body)
                                    .foregroundColor(.piggyTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.piggyTextSecondary)
                            }
                            .padding(PiggySpacing.md)
                            .frame(minHeight: 52)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Artist Updates Section
    private var artistUpdatesSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("ARTIST UPDATES")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)
            
            PiggyCard(style: .secondary, padding: EdgeInsets()) {
                VStack(spacing: 0) {
                    PiggyToggleRow(
                        "New Releases",
                        subtitle: "Albums & singles",
                        isOn: Binding(
                            get: { notificationService.notificationSettings.comebacksAndReleases },
                            set: { newValue in
                                var settings = notificationService.notificationSettings
                                settings.comebacksAndReleases = newValue
                                notificationService.updateSettings(settings)
                            }
                        ),
                        style: .inline
                    )
                    
                    Divider()
                        .background(Color.piggyCardBorderSubtle)
                        .padding(.leading, PiggySpacing.md)
                    
                    PiggyToggleRow(
                        "Tours & Events",
                        subtitle: "Concerts & tickets",
                        isOn: Binding(
                            get: { notificationService.notificationSettings.toursAndEvents },
                            set: { newValue in
                                var settings = notificationService.notificationSettings
                                settings.toursAndEvents = newValue
                                notificationService.updateSettings(settings)
                            }
                        ),
                        style: .inline
                    )
                    
                    Divider()
                        .background(Color.piggyCardBorderSubtle)
                        .padding(.leading, PiggySpacing.md)
                    
                    PiggyToggleRow(
                        "Merch Drops",
                        subtitle: "Official merchandise",
                        isOn: Binding(
                            get: { notificationService.notificationSettings.merchDrops },
                            set: { newValue in
                                var settings = notificationService.notificationSettings
                                settings.merchDrops = newValue
                                notificationService.updateSettings(settings)
                            }
                        ),
                        style: .inline
                    )
                }
            }
        }
    }
    
    // MARK: - Smart Settings Section
    private var smartSettingsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("SMART SETTINGS")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)
            
            PiggyCard(style: .secondary, padding: EdgeInsets()) {
                VStack(spacing: 0) {
                    PiggyToggleRow(
                        "Quiet Hours",
                        subtitle: "10pm - 8am pause",
                        isOn: Binding(
                            get: { notificationService.notificationSettings.quietHoursEnabled },
                            set: { newValue in
                                var settings = notificationService.notificationSettings
                                settings.quietHoursEnabled = newValue
                                notificationService.updateSettings(settings)
                            }
                        ),
                        style: .inline
                    )
                }
            }
        }
    }
    
    // MARK: - Disabled Sections (with toast feedback)
    private var disabledArtistUpdatesSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("ARTIST UPDATES")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)
            
            PiggyCard(style: .secondary, padding: EdgeInsets()) {
                VStack(spacing: 0) {
                    disabledToggleRow("New Releases", "Albums & singles")
                    Divider().background(Color.piggyCardBorderSubtle).padding(.leading, PiggySpacing.md)
                    disabledToggleRow("Tours & Events", "Concerts & tickets")
                    Divider().background(Color.piggyCardBorderSubtle).padding(.leading, PiggySpacing.md)
                    disabledToggleRow("Merch Drops", "Official merchandise")
                }
            }
        }
    }
    
    private var disabledSmartSettingsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("SMART SETTINGS")
                .font(PiggyFont.caption1)
                .fontWeight(.semibold)
                .foregroundColor(.piggyTextTertiary)
            
            PiggyCard(style: .secondary, padding: EdgeInsets()) {
                VStack(spacing: 0) {
                    disabledToggleRow("Top Artists Only", "Priority artists only")
                    Divider().background(Color.piggyCardBorderSubtle).padding(.leading, PiggySpacing.md)
                    disabledToggleRow("Quiet Hours", "10pm - 8am pause")
                }
            }
        }
    }
    
    private func disabledToggleRow(_ title: String, _ subtitle: String) -> some View {
        Button(action: {
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showToast = false
            }
        }) {
            HStack(spacing: PiggySpacing.md) {
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text(title)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                    Text(subtitle)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(false))
                    .disabled(true)
            }
            .padding(PiggySpacing.md)
            .frame(minHeight: 52)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Permission Actions
    private func handlePermissionAction() {
        Task {
            switch authStatus {
            case .notDetermined, .provisional:
                let granted = await notificationService.requestNotificationPermission()
                if !granted {
                    permissionDeniedMessage = "Please enable notifications in Settings to receive artist updates and comeback alerts."
                    showingPermissionAlert = true
                }
                authStatus = await notificationService.getNotificationAuthStatus()
            case .denied:
                // Open Settings
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(settingsUrl)
                }
            case .authorized:
                // Open Settings for management
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(settingsUrl)
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
