import SwiftUI

// MARK: - In-App Notification Banner
struct InAppNotificationBanner: View {
    let notification: ArtistNotification
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var offset: CGFloat = -100
    
    var body: some View {
        HStack(spacing: 12) {
            // Artist/Type Icon
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.icon)
                    .foregroundColor(notification.type.color)
                    .font(.system(size: 16, weight: .medium))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.artistName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notification.type.color.opacity(0.3), lineWidth: 1)
        )
        .offset(y: offset)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                offset = 0
            }
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismissBanner()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        dismissBanner()
                    }
                }
        )
    }
    
    private func dismissBanner() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            offset = -100
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - In-App Notification Manager
@MainActor
class InAppNotificationManager: ObservableObject {
    @Published var currentNotification: ArtistNotification?
    @Published var isShowingBanner = false
    
    private var notificationQueue: [ArtistNotification] = []
    
    static let shared = InAppNotificationManager()
    
    private init() {
        setupNotificationListeners()
    }
    
    private func setupNotificationListeners() {
        // Listen for new notifications
        NotificationCenter.default.addObserver(
            forName: .newArtistNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let artistNotification = notification.object as? ArtistNotification {
                Task { @MainActor in
                    self?.showNotification(artistNotification)
                }
            }
        }
    }
    
    func showNotification(_ notification: ArtistNotification) {
        // Add to queue if currently showing a notification
        if isShowingBanner {
            notificationQueue.append(notification)
            return
        }
        
        currentNotification = notification
        isShowingBanner = true
        
        // Mark as read after showing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ArtistNotificationService.shared.markNotificationAsRead(notification.id)
        }
    }
    
    func dismissCurrentNotification() {
        isShowingBanner = false
        currentNotification = nil
        
        // Show next notification in queue if any
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.notificationQueue.isEmpty {
                let nextNotification = self.notificationQueue.removeFirst()
                Task { @MainActor in
                    self.showNotification(nextNotification)
                }
            }
        }
    }
    
    func handleNotificationTap() {
        guard let notification = currentNotification else { return }
        
        // Navigate to relevant screen
        NotificationCenter.default.post(
            name: .navigateToArtist,
            object: notification.artistId
        )
        
        dismissCurrentNotification()
    }
}

// MARK: - Banner Overlay Modifier
struct InAppNotificationOverlay: ViewModifier {
    @ObservedObject private var notificationManager = InAppNotificationManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if notificationManager.isShowingBanner,
                   let notification = notificationManager.currentNotification {
                    InAppNotificationBanner(
                        notification: notification,
                        onTap: {
                            notificationManager.handleNotificationTap()
                        },
                        onDismiss: {
                            notificationManager.dismissCurrentNotification()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .zIndex(1000)
                }
            }
    }
}

extension View {
    func withInAppNotifications() -> some View {
        modifier(InAppNotificationOverlay())
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newArtistNotification = Notification.Name("newArtistNotification")
    static let navigateToArtist = Notification.Name("navigateToArtist")
    static let navigateToNotificationSettings = Notification.Name("navigateToNotificationSettings")
}

// MARK: - Notification Trigger Helper
extension ArtistNotificationService {
    func triggerInAppNotification(_ notification: ArtistNotification) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .newArtistNotification,
                object: notification
            )
        }
    }
}

#Preview {
    VStack {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .withInAppNotifications()
    .onAppear {
        // Simulate notification for preview
        let testNotification = ArtistNotification(
            id: UUID(),
            artistId: "blackpink",
            artistName: "BLACKPINK",
            updateId: "test",
            type: .comeback,
            title: "NEW ALBUM ANNOUNCED! 🎉",
            body: "BLACKPINK's highly anticipated 3rd studio album is coming this fall!",
            scheduledDate: Date(),
            isRead: false
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task { @MainActor in
                InAppNotificationManager.shared.showNotification(testNotification)
            }
        }
    }
}