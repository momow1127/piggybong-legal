import SwiftUI
import Foundation

// MARK: - RSS-Based Events Tab
struct EventsView: View {
    @StateObject private var eventService = EventService.shared
    @StateObject private var realTimeService = RealTimeEventService.shared
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var selectedCategory: EventCategory = .all
    @State private var showingCalculator = false
    @State private var selectedEventForCalculator: KPopEvent?
    
    
    var filteredEvents: [KPopEvent] {
        let events = eventService.events
        
        if selectedCategory == .all {
            return events
        }
        
        return events.filter { $0.category == selectedCategory }
    }
    
    var userSelectedArtists: [String] {
        // Get cached user-selected artists from onboarding
        if let data = UserDefaults.standard.data(forKey: "CachedSelectedArtists"),
           let artists = try? JSONDecoder().decode([String].self, from: data) {
            return artists
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                    PiggyGradients.background.ignoresSafeArea()

                    // Events list with proper state handling
                    if eventService.isLoading && eventService.events.isEmpty {
                        loadingView
                    } else if !eventService.events.isEmpty {
                        // We have content - show it regardless of any errors
                        eventsContentView
                    } else if let error = eventService.lastError {
                        // Only show error if we have NO content
                        errorStateView(message: error)
                    } else {
                        // Empty state (not an error)
                        emptyStateView
                    }
                }
                .navigationTitle("Events")
                .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCalculator) {
                if let event = selectedEventForCalculator {
                    PurchaseDecisionCalculatorView(
                        prefilledItem: event.calculatorPrefill
                    )
                }
            }
            .task {
                await initializeEventService()
            }
            .refreshable {
                await refreshEvents()
            }
        }
    }
    
    
    // MARK: - Events Scroll View
    // MARK: - Content Views

    private var eventsContentView: some View {
        ScrollView {
            LazyVStack(spacing: PiggySpacing.xl) {
                // Connection status if needed
                if realTimeService.connectionStatus != .connected && !eventService.isLoading {
                    connectionStatusSection
                }

                // Show warning banner if partial data
                if eventService.hasPartialData, let warning = eventService.warningMessage {
                    warningBannerSection(message: warning)
                }

                // Events list
                ForEach(filteredEvents) { event in
                    EventCard(
                        event: event,
                        userArtists: userSelectedArtists,
                        onReprioritize: {
                            selectedEventForCalculator = event
                            showingCalculator = true
                        }
                    )
                }

                // Bottom spacing for tab bar
                Spacer(minLength: PiggySpacing.xxl)
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
            .padding(.top, PiggySpacing.sm)
            .padding(.bottom, PiggySpacing.xl)
        }
        .refreshable {
            await refreshEvents()
        }
    }

    // MARK: - Header Section (matching home dashboard style)
    private var eventsHeaderSection: some View {
        HStack {
            Text("K-Pop Events")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

            if !eventService.events.isEmpty {
                Text("\(filteredEvents.count) events")
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
    }


    // MARK: - Connection Status Section
    private var connectionStatusSection: some View {
        PiggyCard(style: .secondary, cornerRadius: .medium) {
            VStack(spacing: PiggySpacing.sm) {
                Text("Connection Issue")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)

                Text("Couldn't load latest events")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)

                PiggyButton(
                    title: realTimeService.isRefreshing ? "Loading..." : "Reload Events",
                    action: {
                        HapticManager.light()
                        Task {
                            await eventService.fetchAllEventsAndNews()
                        }
                    },
                    style: .secondary,
                    size: .medium
                )
                .disabled(realTimeService.isRefreshing)
            }
        }
    }

    // MARK: - Warning Banner Section
    private func warningBannerSection(message: String) -> some View {
        PiggyCard(style: .secondary, cornerRadius: .medium) {
            HStack(spacing: PiggySpacing.md) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.piggyAccent)
                    .font(.system(size: PiggyIcon.medium))

                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text("Partial Data")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)

                    Text(message)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Button("Retry") {
                    Task {
                        await eventService.fetchAllEventsAndNews()
                    }
                }
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyAccent)
            }
        }
    }


    private func errorStateView(message: String) -> some View {
        ScrollView {
            VStack(spacing: PiggySpacing.xl) {
                // Error state content
                PiggyCard(style: .secondary, cornerRadius: .medium) {
                    VStack(spacing: PiggySpacing.lg) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: PiggyIcon.emptyState))
                            .foregroundColor(.red)

                        VStack(spacing: PiggySpacing.sm) {
                            Text("Connection Issue")
                                .font(PiggyFont.title3)
                                .foregroundColor(.piggyTextPrimary)
                                .multilineTextAlignment(.center)

                            Text(message)
                                .font(PiggyFont.body)
                                .foregroundColor(.piggyTextSecondary)
                                .multilineTextAlignment(.center)
                        }

                        PiggyButton(
                            title: "Try Again",
                            action: {
                                Task {
                                    await eventService.fetchAllEventsAndNews()
                                }
                            },
                            style: .primary,
                            size: .medium
                        )
                    }
                    .padding(PiggySpacing.xl)
                }

                // Bottom spacing for tab bar
                Spacer(minLength: PiggySpacing.xxl)
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
            .padding(.top, PiggySpacing.sm)
            .padding(.bottom, PiggySpacing.xl)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: PiggySpacing.xl) {
                // Header skeleton
                eventsHeaderSkeleton

                // Event cards skeleton
                ForEach(0..<5, id: \.self) { _ in
                    EventCardSkeleton()
                }

                // Bottom spacing for tab bar
                Spacer(minLength: PiggySpacing.xxl)
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
            .padding(.top, PiggySpacing.sm)
            .padding(.bottom, PiggySpacing.xl)
        }
    }

    // MARK: - Header Skeleton
    private var eventsHeaderSkeleton: some View {
        HStack {
            SkeletonRectangle(width: 120, height: 24, cornerRadius: 4)
            Spacer()
            SkeletonRectangle(width: 60, height: 16, cornerRadius: 2)
        }
    }

    
    // MARK: - Contextual Empty State View
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: PiggySpacing.xl) {
                // Empty state content
                PiggyCard(style: .secondary, cornerRadius: .medium) {
                    VStack(spacing: PiggySpacing.lg) {
                        Image(systemName: emptyStateIcon)
                            .font(.system(size: PiggyIcon.emptyState))
                            .foregroundColor(.piggyTextTertiary)

                        VStack(spacing: PiggySpacing.sm) {
                            Text(emptyStateTitle)
                                .font(PiggyFont.title3)
                                .foregroundColor(.piggyTextPrimary)
                                .multilineTextAlignment(.center)

                            Text(emptyStateMessage)
                                .font(PiggyFont.body)
                                .foregroundColor(.piggyTextSecondary)
                                .multilineTextAlignment(.center)
                        }

                        PiggyButton(
                            title: "Refresh Events",
                            action: {
                                Task {
                                    await refreshEvents()
                                }
                            },
                            style: .secondary,
                            size: .medium
                        )
                    }
                    .padding(PiggySpacing.xl)
                }

                // Bottom spacing for tab bar
                Spacer(minLength: PiggySpacing.xxl)
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
            .padding(.top, PiggySpacing.sm)
            .padding(.bottom, PiggySpacing.xl)
        }
    }

    // MARK: - Empty State Content by Category
    private var emptyStateIcon: String {
        switch selectedCategory {
        case .all: return "calendar.badge.exclamationmark"
        case .concertsShows, .concerts, .concert: return "music.mic"
        case .albumsPhotocards, .albums, .album: return "opticaldisc"
        case .officialMerch, .merch, .merchandise: return "tshirt"
        case .fanEvents, .events, .fanmeet: return "person.3"
        case .subscriptionsApps, .subscriptions: return "app.gift"
        case .livestream: return "video"
        case .collaboration: return "handshake"
        case .award: return "trophy"
        default: return "calendar.badge.exclamationmark"
        }
    }

    private var emptyStateTitle: String {
        switch selectedCategory {
        case .all: return "No events found"
        case .concertsShows, .concerts, .concert: return "No concert events"
        case .albumsPhotocards, .albums, .album: return "No album releases"
        case .officialMerch, .merch, .merchandise: return "No merch drops"
        case .fanEvents, .events, .fanmeet: return "No fan events"
        case .subscriptionsApps, .subscriptions: return "No app updates"
        case .livestream: return "No livestreams"
        case .collaboration: return "No collaborations"
        case .award: return "No awards news"
        default: return "Nothing here yet"
        }
    }

    private var emptyStateMessage: String {
        switch selectedCategory {
        case .all: return "No events available right now. Pull to refresh to check for new updates from your selected artists."
        case .concertsShows, .concerts, .concert: return "No upcoming concerts found for your selected artists. Check back later for tour announcements!"
        case .albumsPhotocards, .albums, .album: return "No new album releases from your artists right now. We'll show new music when it's available!"
        case .officialMerch, .merch, .merchandise: return "No merch releases found for your artists. Check back for exclusive drops!"
        case .fanEvents, .events, .fanmeet: return "No fan events found for your artists. Look out for KCON and fan meetups!"
        case .subscriptionsApps, .subscriptions: return "No subscription updates available right now."
        case .livestream: return "No livestreams happening. Check back for surprise lives from your artists!"
        case .collaboration: return "No collaboration news from your artists right now."
        case .award: return "No awards news for your artists right now."
        default: return "No events available. Pull to refresh or select your favorite artists in the profile tab."
        }
    }
    
    
    
    
    // MARK: - Event Handlers
    
    @MainActor
    private func initializeEventService() async {
        // Check API configuration
        let _ = await realTimeService.checkAPIConfiguration()
        
        // Sync user's artist subscriptions
        let userArtists = userSelectedArtists
        if !userArtists.isEmpty {
            let _ = await realTimeService.syncArtistSubscriptions(artists: userArtists)
        }
        
        // Load events with new improved error handling
        await eventService.fetchAllEventsAndNews()
    }
    
    @MainActor
    private func refreshEvents() async {
        // Use new fetch method with partial success handling
        print("🔄 EventsView: Refreshing with improved error handling...")
        await eventService.fetchAllEventsAndNews()
    }
}

// MARK: - Events Data Model
struct EventsData {
    let events: [KPopEvent]
    let filteredEvents: [KPopEvent]
    let selectedCategory: EventCategory
    let userArtists: [String]
    let hasEvents: Bool
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let category: EventCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: PiggySpacing.xs) {
                Text(category.displayName)
                    .font(PiggyFont.caption1)
                    .fontWeight(.medium)
            }
            .padding(.vertical, PiggySpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                    .fill(isSelected ? Color.piggyPrimary : Color.piggyCardBackground)
            )
            .foregroundColor(isSelected ? .piggyTextPrimary : .piggyTextSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                    .stroke(isSelected ? Color.clear : Color.piggyTextTertiary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(CategoryChipButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: KPopEvent
    let userArtists: [String]
    let onReprioritize: () -> Void

    private var isRelevantToUser: Bool {
        event.matchedArtists.contains { artist in
            userArtists.contains(artist)
        }
    }

    var body: some View {
        PiggyCard(
            style: isRelevantToUser ? .primary : .secondary,
            cornerRadius: .medium
        ) {
            VStack(alignment: .leading, spacing: PiggySpacing.md) {
                // Header with badges
                HStack(spacing: PiggySpacing.sm) {
                    // Breaking news badge
                    if event.isBreaking {
                        BreakingNewsBadge()
                    }

                    // Category badge
                    CategoryBadge(category: event.category)

                    Spacer()

                    // Time ago
                    Text(event.timeAgo)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextTertiary)
                }

                // Artist avatar + content
                HStack(alignment: .top, spacing: PiggySpacing.md) {
                    // Artist avatar (if matched)
                    if let firstArtist = event.matchedArtists.first {
                        PiggyAvatarCircle(
                            text: firstArtist,
                            size: .medium,
                            style: .artistGradient,
                            showBorder: true,
                            borderColor: isRelevantToUser ? .piggyPrimary : .piggyTextTertiary.opacity(0.3),
                            action: nil
                        )
                    }

                    // Content
                    VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                        // Title
                        Text(event.title)
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                            .lineLimit(2)

                        // Summary
                        if let summary = event.summary {
                            Text(summary)
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary)
                                .lineLimit(3)
                        }

                        // Matched artists tags
                        if !event.matchedArtists.isEmpty {
                            artistTagsView
                        }
                    }

                    Spacer()
                }

                // Action section for relevant users
                if isRelevantToUser {
                    HStack {
                        Text("Tap to check priority")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: PiggyIcon.small, weight: .medium))
                            .foregroundColor(.piggyTextTertiary)
                    }
                    .padding(.top, PiggySpacing.xs)
                }
            }
        }
        .onTapGesture {
            if isRelevantToUser {
                HapticManager.medium()
                onReprioritize()
            }
        }
    }

    // MARK: - Artist Tags View
    @ViewBuilder
    private var artistTagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PiggySpacing.xs) {
                ForEach(event.matchedArtists.prefix(3), id: \.self) { artist in
                    Text(artist)
                        .font(PiggyFont.caption2)
                        .padding(.horizontal, PiggySpacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.xs)
                                .fill(Color.piggyAccent.opacity(0.1))
                        )
                        .foregroundColor(.piggyAccent)
                }

                if event.matchedArtists.count > 3 {
                    Text("+\(event.matchedArtists.count - 3)")
                        .font(PiggyFont.caption2)
                        .foregroundColor(.piggyTextTertiary)
                }
            }
        }
    }
}

// MARK: - Breaking News Badge
struct BreakingNewsBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .fill(Color.red)
                        .scaleEffect(1.5)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
                )
            
            Text("BREAKING")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: EventCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Text(category.displayName)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(category.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(category.color.opacity(0.3), lineWidth: 1)
                )
        )
        .foregroundColor(category.color)
    }
}

// MARK: - Loading Skeleton Components
struct EventCardSkeleton: View {
    @State private var animatedGradient = false

    var body: some View {
        PiggyCard(style: .secondary, cornerRadius: .medium) {
            VStack(alignment: .leading, spacing: PiggySpacing.md) {
                // Header with badge skeletons
                HStack(spacing: PiggySpacing.sm) {
                    // Category badge skeleton
                    SkeletonRectangle(width: 60, height: 18, cornerRadius: 4)

                    Spacer()

                    // Time ago skeleton
                    SkeletonRectangle(width: 45, height: 12, cornerRadius: 2)
                }

                // Content section
                HStack(alignment: .top, spacing: PiggySpacing.md) {
                    // Avatar skeleton
                    SkeletonCircle(diameter: 40)

                    // Text content
                    VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                        // Title lines
                        SkeletonRectangle(width: nil, height: 16, cornerRadius: 2)
                        SkeletonRectangle(width: 180, height: 16, cornerRadius: 2)

                        // Summary lines
                        SkeletonRectangle(width: nil, height: 12, cornerRadius: 2)
                        SkeletonRectangle(width: 220, height: 12, cornerRadius: 2)
                        SkeletonRectangle(width: 160, height: 12, cornerRadius: 2)

                        // Artist tags
                        HStack(spacing: PiggySpacing.xs) {
                            SkeletonRectangle(width: 50, height: 20, cornerRadius: 4)
                            SkeletonRectangle(width: 40, height: 20, cornerRadius: 4)
                            SkeletonRectangle(width: 60, height: 20, cornerRadius: 4)
                        }
                    }

                    Spacer()
                }

                // Action section skeleton
                HStack {
                    SkeletonRectangle(width: 100, height: 14, cornerRadius: 2)
                    Spacer()
                    SkeletonRectangle(width: 16, height: 14, cornerRadius: 2)
                }
            }
        }
    }
}

struct SkeletonRectangle: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    @State private var animatedGradient = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.piggyTextTertiary.opacity(0.1),
                        Color.piggyTextTertiary.opacity(0.2),
                        Color.piggyTextTertiary.opacity(0.1)
                    ],
                    startPoint: animatedGradient ? .trailing : .leading,
                    endPoint: animatedGradient ? UnitPoint(x: 1.5, y: 0) : UnitPoint(x: -0.5, y: 0)
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animatedGradient = true
                }
            }
    }
}

struct SkeletonCircle: View {
    let diameter: CGFloat
    @State private var animatedGradient = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.piggyTextTertiary.opacity(0.1),
                        Color.piggyTextTertiary.opacity(0.2),
                        Color.piggyTextTertiary.opacity(0.1)
                    ],
                    startPoint: animatedGradient ? .trailing : .leading,
                    endPoint: animatedGradient ? UnitPoint(x: 1.5, y: 0) : UnitPoint(x: -0.5, y: 0)
                )
            )
            .frame(width: diameter, height: diameter)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animatedGradient = true
                }
            }
    }
}

// MARK: - Custom Button Styles
struct CategoryChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    EventsView()
        .environmentObject(RevenueCatManager.shared)
}
