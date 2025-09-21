import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @State private var isRequestingPermission = false
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Environment(\.dismiss) private var dismiss
    
    var onPermissionGranted: (() -> Void)?
    var onPermissionDenied: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header Section
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                
                Text("Stay Updated")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get notified about concerts, album releases, and exclusive K-pop updates")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Benefits Section
            VStack(spacing: 16) {
                NotificationBenefitRow(
                    icon: "music.note",
                    title: "Concert Alerts",
                    description: "Never miss your favorite group's tour announcements"
                )
                
                NotificationBenefitRow(
                    icon: "gift.fill",
                    title: "Exclusive Updates",
                    description: "Get early access to limited edition merchandise"
                )
                
                NotificationBenefitRow(
                    icon: "calendar.badge.plus",
                    title: "Event Reminders",
                    description: "Stay on top of comebacks and special events"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action Button
            VStack(spacing: 16) {
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enable Notifications")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isRequestingPermission)
                
                Button(action: {
                    // Skip notifications - proceed without permission
                    onPermissionDenied?()
                    dismiss()
                }) {
                    Text("Maybe Later")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.black, .purple.opacity(0.8), .pink.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .ignoresSafeArea()
        .onAppear {
            checkCurrentPermissionStatus()
        }
    }
    
    private func checkCurrentPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
                
                // If permission is already granted, automatically proceed
                if settings.authorizationStatus == .authorized {
                    onPermissionGranted?()
                    dismiss()
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        guard !isRequestingPermission else { return }
        
        isRequestingPermission = true
        
        let center = UNUserNotificationCenter.current()
        
        // Request authorization with all notification types
        center.requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                    // Still handle the response based on granted status
                }
                
                if granted {
                    // Permission granted
                    print("Notification permission granted")

                    // Register for remote notifications and connect to backend services
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }

                    // Update ArtistNotificationService state
                    Task {
                        await ArtistNotificationService.shared.checkNotificationStatus()

                        // Also request permission through PushNotificationService for proper Supabase integration
                        let _ = await PushNotificationService.shared.requestPushNotificationPermission()
                    }

                    self.onPermissionGranted?()
                    self.dismiss()
                } else {
                    // Permission denied
                    print("Notification permission denied")

                    // Update ArtistNotificationService state
                    Task {
                        await ArtistNotificationService.shared.checkNotificationStatus()
                    }

                    self.onPermissionDenied?()
                    self.dismiss()
                }
            }
        }
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionView(
            onPermissionGranted: {
                print("Permission granted")
            },
            onPermissionDenied: {
                print("Permission denied")
            }
        )
    }
}