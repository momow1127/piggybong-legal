import SwiftUI

// MARK: - Notification List View
struct NotificationListView: View {
    @StateObject private var notificationService = ArtistNotificationService.shared
    @StateObject private var realTimeService = RealTimeNotificationService.shared
    @State private var notifications: [ArtistNotification] = []
    @State private var isLoading = true
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingNotificationSettings = false

    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case comeback = "Comeback"
        case concerts = "Concerts"
        case merch = "Merch"
        case tips = "Tips"

        func matches(_ notification: ArtistNotification) -> Bool {
            switch self {
            case .all:
                return true
            case .comeback:
                return [.comeback, .comebacksAndReleases].contains(notification.type)
            case .concerts:
                return [.tour, .toursAndEvents].contains(notification.type)
            case .merch:
                return [.merchDrops, .merchandise].contains(notification.type)
            case .tips:
                return [.newRelease, .tvAppearance, .socialMedia, .award, .collaboration].contains(notification.type)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with unread count
                    headerSection

                    // Filter tabs (only show if we have notifications)
                    if !isLoading && !notifications.isEmpty {
                        filterTabsSection
                    }

                    if isLoading {
                        loadingSection
                    } else if filteredNotifications.isEmpty {
                        emptyStateSection
                    } else {
                        notificationsList
                    }
                }
                .padding(.horizontal, PiggySpacing.md)
                .padding(.top, PiggySpacing.sm)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, PiggySpacing.lg))
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbar {
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Mark All Read") {
                    markAllAsRead()
                }
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyAccent)
                .disabled(notifications.allSatisfy { $0.isRead })
            }
        }
        .onAppear {
            loadNotifications()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationView {
                NotificationSettingsView()
            }
        }
    }

    // MARK: - Computed Properties
    private var filteredNotifications: [ArtistNotification] {
        notifications.filter { selectedFilter.matches($0) }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications")
                    .font(PiggyFont.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                let unreadCount = notifications.filter { !$0.isRead }.count
                if unreadCount > 0 {
                    Text("\(unreadCount) new update\(unreadCount == 1 ? "" : "s")")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            Spacer()
            
            // Test notification buttons (for first 2 artists)
            if !realTimeService.userSelectedArtists.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(realTimeService.userSelectedArtists.prefix(2)), id: \.id) { artist in
                        Button(action: {
                            Task {
                                await realTimeService.testNotificationForArtist(artist)
                                // Refresh list after test notification
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    loadNotifications()
                                }
                            }
                        }) {
                            Text("Test \(artist.name)")
                                .font(PiggyFont.caption2)
                                .foregroundColor(.piggyAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.piggyAccent.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
        .padding(.bottom, PiggySpacing.lg)
    }

    // MARK: - Filter Tabs Section
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PiggySpacing.sm) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(PiggyFont.caption1)
                            .fontWeight(.medium)
                            .padding(.horizontal, PiggySpacing.md)
                            .padding(.vertical, PiggySpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                                    .fill(selectedFilter == filter ? Color.piggyAccent : Color.piggyCardBackground)
                            )
                            .foregroundColor(selectedFilter == filter ? .black : .piggyTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PiggySpacing.md)
        }
        .padding(.bottom, PiggySpacing.md)
    }

    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: PiggySpacing.lg) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .piggyAccent))
                .scaleEffect(1.2)
            
            Text("Loading your updates...")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: PiggySpacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(PiggyGradients.primaryButton.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.slash")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.piggyAccent)
            }
            
            VStack(spacing: PiggySpacing.sm) {
                Text("No notifications yet")
                    .font(PiggyFont.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("We'll notify you about comebacks, events, and updates from your favorite artists.")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PiggySpacing.lg)
            }
            
            Button(action: {
                showingNotificationSettings = true
            }) {
                Text("Notification Settings")
                    .font(PiggyFont.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, PiggySpacing.lg)
                    .padding(.vertical, PiggySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                            .fill(PiggyGradients.primaryButton)
                    )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: PiggySpacing.md) {
                ForEach(filteredNotifications, id: \.id) { notification in
                    notificationCard(for: notification)
                }
            }
            .padding(.bottom, PiggySpacing.xl)
        }
        .refreshable {
            loadNotifications()
        }
    }
    
    // MARK: - Notification Card
    private func notificationCard(for notification: ArtistNotification) -> some View {
        PiggyNotificationCard(
            type: piggyNotificationType(from: notification.type),
            title: notification.title,
            subtitle: notification.body,
            action: {
                handleNotificationTap(notification)
            },
            timestamp: notification.scheduledDate,
            isNew: !notification.isRead
        )
    }
    
    // MARK: - Helper Methods
    private func piggyNotificationType(from artistType: ArtistUpdateType) -> PiggyNotificationCard.NotificationType {
        switch artistType {
        case .comeback, .comebacksAndReleases:
            return .comeback
        case .tour, .toursAndEvents:
            return .concert
        case .merchDrops, .merchandise:
            return .merch
        case .newRelease, .tvAppearance, .socialMedia, .award, .collaboration:
            return .aiTip
        }
    }
    
    
    private func handleNotificationTap(_ notification: ArtistNotification) {
        markAsRead(notification)

        // Navigate based on notification type
        NotificationCenter.default.post(
            name: .navigateToArtist,
            object: notification.artistId
        )
    }
    
    private func markAsRead(_ notification: ArtistNotification) {
        if !notification.isRead {
            ArtistNotificationService.shared.markNotificationAsRead(notification.id)
            
            // Update local copy
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
        }
    }
    
    private func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        for notification in unreadNotifications {
            ArtistNotificationService.shared.markNotificationAsRead(notification.id)
        }
        
        // Update local copies
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }
    
    private func loadNotifications() {
        isLoading = true

        // Fetch real notifications from Supabase with timeout fallback
        Task {
            // Try to fetch real notifications with a timeout
            let fetchTask = Task {
                await notificationService.fetchRealNotifications()
            }

            // Wait for either completion or timeout
            do {
                _ = try await withTimeout(seconds: 8) {
                    await fetchTask.value
                }

                await MainActor.run {
                    self.notifications = notificationService.recentNotifications

                    // If no real notifications, show sample notifications for better UX
                    if self.notifications.isEmpty {
                        print("📱 No real notifications found, showing sample notifications")
                        self.notifications = generateSampleNotifications()
                    }

                    self.isLoading = false
                    print("✅ Loaded \(self.notifications.count) notifications in UI")
                }
            } catch {
                // Timeout or error occurred, show sample notifications
                print("⚠️ Notification loading failed/timeout: \(error.localizedDescription)")
                await MainActor.run {
                    self.notifications = generateSampleNotifications()
                    self.isLoading = false
                    print("📱 Showing sample notifications due to loading failure")
                }
            }
        }
    }

    // Helper function for timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }

    private struct TimeoutError: Error {
        var localizedDescription: String = "Operation timed out"
    }
    
    // MARK: - Sample Notifications (for development)
    private func generateSampleNotifications() -> [ArtistNotification] {
        let sampleArtists = realTimeService.userSelectedArtists
        guard !sampleArtists.isEmpty else { return [] }
        
        var notifications: [ArtistNotification] = []
        
        // Recent comeback notification
        if let firstArtist = sampleArtists.first {
            notifications.append(ArtistNotification(
                id: UUID(),
                artistId: firstArtist.id.uuidString,
                artistName: firstArtist.name,
                updateId: "comeback_\(firstArtist.id)",
                type: .comeback,
                title: "\(firstArtist.name) COMEBACK! 🎉",
                body: "New album drops this Friday - you've got $150 saved for it!",
                scheduledDate: Date().addingTimeInterval(-3600), // 1 hour ago
                isRead: false
            ))
        }
        
        // Tour announcement
        if sampleArtists.count > 1 {
            let secondArtist = sampleArtists[1]
            notifications.append(ArtistNotification(
                id: UUID(),
                artistId: secondArtist.id.uuidString,
                artistName: secondArtist.name,
                updateId: "tour_\(secondArtist.id)",
                type: .toursAndEvents,
                title: "\(secondArtist.name) World Tour Announced",
                body: "Pre-sale tickets available tomorrow at 10am!",
                scheduledDate: Date().addingTimeInterval(-7200), // 2 hours ago
                isRead: true
            ))
        }
        
        // AI Tip
        notifications.append(ArtistNotification(
            id: UUID(),
            artistId: "ai_tip",
            artistName: "PiggyBot",
            updateId: "tip_savings",
            type: .newRelease,
            title: "Smart fan tip 💡",
            body: "Join a group order for 30% off shipping on albums!",
            scheduledDate: Date().addingTimeInterval(-14400), // 4 hours ago
            isRead: true
        ))
        
        return notifications.sorted { $0.scheduledDate > $1.scheduledDate }
    }
}

#Preview {
    NavigationView {
        NotificationListView()
    }
}