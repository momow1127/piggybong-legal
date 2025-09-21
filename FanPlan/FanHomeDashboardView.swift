import SwiftUI

// MARK: - Helper Components

struct PiggyEmptyView: View {
    var icon: String = ""
    var title: String = ""
    var message: String = ""
    var actionTitle: String = ""
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: PiggyIcon.emptyState))
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Text(title)
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            
            if !message.isEmpty {
                Text(message)
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button(actionTitle, action: action)
                    .font(PiggyFont.button)
                    .foregroundColor(.piggyPrimary)
            }
        }
        .padding(PiggySpacing.xl)
    }
}

// rename this helper
struct FanDashboardLoadingPlaceholderView: View {
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .piggyTextPrimary))
            Text("Loading your fan dashboard...")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
        }
        .padding(PiggySpacing.xl)
    }
}

struct DashboardErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            Text("Something went wrong")
                .font(PiggyFont.title3)
                .foregroundColor(.piggyTextPrimary)
            Button("Retry", action: onRetry)
                .font(PiggyFont.button)
                .foregroundColor(.piggyPrimary)
        }
        .padding(PiggySpacing.xl)
    }
}

// MARK: - Fan Home Dashboard View
struct FanHomeDashboardView: View {
    @StateObject private var dashboardService = FanDashboardService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var eventService = EventService.shared
    @StateObject private var notificationService = RealTimeNotificationService.shared
    @StateObject private var performanceOptimizer = PerformanceOptimizer.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @EnvironmentObject private var tabSelection: TabSelection
    
    @State private var showQuickAdd = false
    @State private var showActivitySaved = false
    @State private var savedActivity: SavedFanActivity?
    @State private var showGoalProgress = false
    @State private var showPaywall = false
    // selectedGoal removed - goal functionality no longer supported
    @State private var showArtistManagement = false
    @State private var showPurchaseCalculator = false
    @State private var showVipUpgradePrompt = false
    @State private var selectedArtist: FanArtist?
    @State private var selectedSmartPickEvent: SmartFanPickEvent?
    @State private var showPriorityAdjustment: Bool = false
    @State private var showEventList: Bool = false
    @State private var unreadNotificationCount: Int = 0
    // @State private var showFanRecap = false // Removed - experimental feature
    @State private var contentState: ContentState<FanDashboardData> = .loading

    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.background.ignoresSafeArea()

                switch contentState {
                case .idle, .loading:
                    FanDashboardLoadingPlaceholderView()
                case .empty(let message):
                    PiggyEmptyView(
                        icon: "chart.bar",
                        title: "No data yet",
                        message: message ?? "Start by adding some fan activities",
                        actionTitle: "Get Started"
                    )
                case .offline:
                    DashboardErrorView(onRetry: { Task { await loadDashboardAsync() } })
                case .error(_):
                    DashboardErrorView(onRetry: { Task { await loadDashboardAsync() } })
                case .loaded(let data):
                    // Loaded state - Original comprehensive dashboard with crash fixes
                    ScrollView {
                        LazyVStack(spacing: PiggySpacing.xl) { // 32pt section spacing using design token
                            // a) Greeting Section with Notifications
                            GreetingRowView(
                                hasUnreadNotifications: unreadNotificationCount > 0
                            )

                            // b) DashboardArtistsSection (Your Idols)
                            ArtistsSectionView(
                                data: data,
                                subscriptionService: subscriptionService,
                                showArtistManagement: $showArtistManagement,
                                showPaywall: $showPaywall,
                                selectedArtist: $selectedArtist
                            )

                            // c) Priority Chart (from onboarding, updates with real-time activity)
                            PriorityChartSectionView(data: data)

                            // d) FanPriorityManagerView (VIP-gated)
                            PriorityManagerSectionView(
                                data: data,
                                subscriptionService: subscriptionService,
                                dashboardService: dashboardService,
                                selectedSmartPickEvent: $selectedSmartPickEvent,
                                showPriorityAdjustment: $showPriorityAdjustment,
                                showPurchaseCalculator: $showPurchaseCalculator,
                                showPaywall: $showPaywall
                            )

                            // e) Fan Activity Section (conditional)
                            FanActivitySectionView(
                                data: data,
                                dashboardService: dashboardService,
                                showQuickAdd: $showQuickAdd
                            )

                            // f) Upcoming Events preview
                            UpcomingEventsSectionView(
                                data: data,
                                dashboardService: dashboardService,
                                eventService: eventService,
                                showEventList: $showEventList,
                                tabSelection: tabSelection
                            )

                            // Bottom spacing for tab bar
                            Spacer(minLength: PiggySpacing.xxl)
                        }
                        .padding(.horizontal, PiggySpacing.screenMargin) // Add horizontal margins
                        .padding(.top, PiggySpacing.sm)
                        .padding(.bottom, PiggySpacing.xl)
                    }
                    .refreshable {
                        await loadDashboardAsync()
                    }
                }
            }
            .navigationBarHidden(true)
            // Goal progress sheet removed - goal functionality no longer supported
            .fullScreenCover(isPresented: $showArtistManagement) {
                ArtistManagementView()
                    .environmentObject(globalLoading)
                    .onAppear {
                        print("✅ ArtistManagementView appeared!")
                    }
            }
            .fullScreenCover(isPresented: $showPurchaseCalculator) {
                PurchaseDecisionCalculatorView()
                    .environmentObject(subscriptionService)
                    .environmentObject(revenueCatManager)
            }
            .sheet(isPresented: $showVipUpgradePrompt) {
                VipUpgradePromptView()
                    .environmentObject(revenueCatManager)
            }
            .sheet(isPresented: $showActivitySaved) {
                if let savedActivity = savedActivity {
                    ActivitySavedView(
                        savedActivity: savedActivity,
                        insightMessage: generateFanInsight(for: savedActivity),
                        onAddAnother: {
                            showActivitySaved = false
                            showQuickAdd = true
                        },
                        onViewDashboard: {
                            showActivitySaved = false
                            // Dashboard is already visible
                        },
                        onEditActivity: {
                            showActivitySaved = false
                            // Could implement edit functionality here
                        }
                    )
                }
            }
            .navigationDestination(item: $selectedArtist) { artist in
                ArtistProfileView(artist: artist)
                    .environmentObject(subscriptionService)
                    .environmentObject(GlobalLoadingManager.shared)
            }
            // .sheet(isPresented: $showFanRecap) {
            //     FanRecapView() // Removed - experimental feature
            // }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallModalContent(triggerContext: .advancedGoals)
                .environmentObject(revenueCatManager)
        }
        .piggySheet(
            isPresented: $showQuickAdd,
            title: "Add Fan Activity",
            subtitle: "Track your K-pop spending",
            detents: [.large]
        ) {
            QuickAddModalContent(
                onSave: { activity in
                    savedActivity = activity
                    showQuickAdd = false
                    showActivitySaved = true

                    // Refresh dashboard data to show new activity
                    Task {
                        await loadDashboardAsync()
                    }
                },
                onCancel: {
                    showQuickAdd = false
                }
            )
            .environmentObject(revenueCatManager)
            .environmentObject(globalLoading)
        }
        .monitorPerformance(name: "FanHomeDashboard")
        .onAppear {
            // Track dashboard load performance - but don't block UI
            PerformanceService.shared.trackScreenLoad("FanHomeDashboard", loadTime: 1.0)
        }
        .withHeavyWork(
            operation: "dashboard_load",
            work: {
                // Heavy operations moved to background thread
                await loadDashboardAsync()
                await loadNotificationCountAsync()
                return "Dashboard loaded"
            },
            onComplete: { _ in
                print("✅ Dashboard loading completed successfully")
            },
            onError: { error in
                print("❌ Dashboard loading failed: \(error)")
            }
        )
    }

    // MARK: - Section Methods
    
    
    @ViewBuilder
    private func dashboardQuickStatsSection(data: FanDashboardData) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Quick Stats")
                .font(PiggyFont.sectionTitle)
                .foregroundColor(.piggyTextPrimary)
            
            HStack(spacing: PiggySpacing.md) {
                // Artists stat (should work)
                quickStatCard(
                    title: "Artists",
                    value: "\(data.fanArtists.count)",
                    icon: "music.note",
                    color: .piggyAccent
                )
                
                // Goals stat - DS Empty State if missing
                quickStatCard(
                    title: "Goals",
                    value: "—",
                    icon: "target",
                    color: .piggySecondary
                )
                
                // Purchases stat - DS Empty State if missing
                quickStatCard(
                    title: "Purchases",
                    value: "—",
                    icon: "bag.fill",
                    color: .piggyPrimary
                )
            }
        }
    }
    
    @ViewBuilder
    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        PiggyCard(style: .secondary, cornerRadius: .medium) {
            VStack(spacing: PiggySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: PiggyIcon.large, weight: .medium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(title)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
    }
    
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        HStack(spacing: PiggySpacing.md) {
            // Quick Add Button
            Button(action: { showQuickAdd = true }) {
                PiggyCard(style: .secondary, cornerRadius: .large) {
                    HStack(spacing: PiggySpacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: PiggyIcon.large))
                            .foregroundColor(.piggyAccent)
                        
                        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                            Text("Add New Priority")
                                .font(PiggyFont.bodyEmphasized)
                                .foregroundColor(.piggyTextPrimary)

                            Text("What matters to you now?")
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: PiggyIcon.small, weight: .medium))
                            .foregroundColor(.piggyTextSecondary)
                    }
                        }
            }
            
            // Fan Recap Button - Removed experimental feature
            // Button(action: { showFanRecap = true }) {
            //     PiggyCard(style: .primary, cornerRadius: .large) {
            //         HStack(spacing: PiggySpacing.md) {
            //             Image(systemName: "chart.bar.fill")
            //         }
            //     }
            // }
        }
    }
    
    
    
    
    
    
    
    
    // MARK: - Data Loading Helpers
    
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func IdolPillView(idol: FanArtist, onTap: @escaping () -> Void) -> some View {
        let isPlaceholder = isPlaceholderIdol(idol)
        
        VStack(spacing: PiggySpacing.sm) {
            PiggyAvatarCircle(
                text: idol.name,
                size: .large,
                style: isPlaceholder ? .solid(.piggyTextTertiary.opacity(0.2)) : .artistGradient,
                showBorder: true,
                borderColor: isPlaceholder ? .piggyTextTertiary.opacity(0.3) : .piggyPrimary,
                action: onTap
            )
            .opacity(isPlaceholder ? 0.6 : 1.0)
            
            Text(isPlaceholder ? "Add First Idol" : idol.name)
                .font(PiggyFont.caption1)
                .foregroundColor(isPlaceholder ? .piggyTextTertiary : .piggyTextPrimary)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private func AddIdolButton(
        currentCount: Int,
        planLimit: Int,
        isVIP: Bool,
        onAddTap: @escaping () -> Void,
        onUpgradeTap: @escaping () -> Void
    ) -> some View {
        let isAtLimit = currentCount >= planLimit
        
        VStack(spacing: PiggySpacing.xs) {
            Button(action: {
                if isAtLimit && !isVIP {
                    // Free plan at limit - show paywall
                    onUpgradeTap()
                } else if !isAtLimit {
                    // Under limit - allow adding
                    onAddTap()
                }
                // VIP at limit - do nothing (disabled)
            }) {
                ZStack {
                    Circle()
                        .fill(isAtLimit ? Color.piggyTextTertiary.opacity(0.2) : Color.piggyTextTertiary.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(isAtLimit ? Color.piggyTextTertiary.opacity(0.2) : Color.piggyTextTertiary.opacity(0.5), lineWidth: 1)
                        )

                    Image("plus")
                        .renderingMode(.template)
                        .foregroundColor(isAtLimit ? Color.piggyTextTertiary : Color.piggyTextSecondary)
                        .font(.system(size: 24, weight: .medium))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isAtLimit && isVIP ? 0.4 : 1.0) // Disabled appearance for VIP at limit

            Text(isAtLimit && !isVIP ? "Upgrade" : "Add Idol")
                .font(PiggyFont.caption1)
                .foregroundColor(isAtLimit ? Color.piggyTextTertiary : Color.piggyTextSecondary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Private Methods
    
    
    @MainActor
    /// Optimized dashboard loading - UI updates on main thread, heavy work on background
    private func loadDashboardAsync() async {
        // Show loading state on main thread
        await MainActor.run {
            contentState = .loading
        }

        // Heavy data loading happens on background thread automatically
        await dashboardService.loadDashboardData()

        // UI updates back on main thread
        await MainActor.run {
            // Check if we got data or if there was an error
            if let data = dashboardService.dashboardData {
                contentState = .loaded(data)
            } else if dashboardService.error != nil {
                // If there's an error (like no auth), show empty state
                print("⚠️ Dashboard loading error, showing empty state for guest user")
                contentState = .empty(message: "Welcome! Start by adding your favorite artists")
            } else {
                // Default to empty state instead of loading forever
                contentState = .empty(message: "Start by adding some fan activities")
            }
        }
    }
    
    /// Optimized notification loading - background work with main thread UI updates
    private func loadNotificationCountAsync() async {
        // Load unread notification count from UserDefaults
        await MainActor.run {
            unreadNotificationCount = UserDefaults.standard.integer(forKey: "unreadNotificationCount")
        }
    }

    @MainActor
    private func loadNotificationCount() async {
        // Load unread notification count from notification service
        // For now, we'll use a placeholder count that could come from UserDefaults or a service
        unreadNotificationCount = UserDefaults.standard.integer(forKey: "unreadNotificationCount")
        
        // You could also integrate with the notification service:
        // unreadNotificationCount = await notificationService.getUnreadCount()
    }
    
    // MARK: - Helper Methods
    
    private func isPlaceholderIdol(_ idol: FanArtist) -> Bool {
        return idol.id.uuidString == "00000000-0000-0000-0000-000000000000"
    }
    
    private func generateFanInsight(for activity: SavedFanActivity) -> String {
        guard let dashboardData = dashboardService.dashboardData else {
            return "Ready to start your fan journey? ✨"
        }
        
        let activities = dashboardData.recentActivity
        return generateFanInsight(from: activities)
    }
    
    private func generateFanInsight(from activities: [FanActivity]) -> String {
        let recentActivities = activities.filter {
            Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 999 < 30
        }

        guard !recentActivities.isEmpty else {
            return "Ready to start your fan journey? ✨"
        }

        // Era Detection (Artist Dominance)
        let artistCounts = Dictionary(grouping: recentActivities, by: { $0.artistName ?? "Unknown" })
            .mapValues { $0.count }

        if let (dominantArtist, count) = artistCounts.max(by: { $0.value < $1.value }),
           count >= 3 && Double(count) / Double(recentActivities.count) >= 0.6 {
            let eraMessages = [
                "All eyes on \(dominantArtist) this month 👀",
                "Deep in your \(dominantArtist) era 💜",
                "\(dominantArtist) has your full attention lately ✨"
            ]
            return eraMessages.randomElement() ?? ""
        }

        // Category Pattern Detection
        let categoryGroups = Dictionary(grouping: recentActivities, by: { $0.activityType })
        
        if let merchActivities = categoryGroups[.purchase],
           merchActivities.count >= 3 {
            let merchMessages = [
                "Someone's been busy collecting! 🛍️",
                "Your merch game is strong this month ✨",
                "Building that collection one purchase at a time 💫"
            ]
            return merchMessages.randomElement() ?? ""
        }

        // Balance Nudge (gentle encouragement)
        if artistCounts.count == 1 {
            let balanceMessages = [
                "Maybe explore some new artists? 🌟",
                "Your dedication is inspiring! Ever thought about branching out? ✨",
                "Single-artist focus = true fan energy 💜"
            ]
            return balanceMessages.randomElement() ?? ""
        }

        // Activity Frequency Insights
        if recentActivities.count >= 5 {
            return "You've been super active lately! 🔥"
        } else if recentActivities.count >= 3 {
            return "Loving this consistent fan energy! ⚡"
        } else if recentActivities.count == 2 {
            return "Great momentum building! Keep it up! 🚀"
        } else {
            return "Every fan activity counts! ✨"
        }
    }
}

// MARK: - Greeting Modifier

extension GreetingRowView {
    func greetingColorModifier() -> some View {
        self.foregroundColor(.piggyTextPrimary)
    }
}

// MARK: - Preview
struct FanHomeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        FanHomeDashboardView()
            .environmentObject(RevenueCatManager())
    }
}
