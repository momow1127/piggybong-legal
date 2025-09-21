import SwiftUI

struct IdolNewsFeedView: View {
    @StateObject private var updateService = IdolUpdateService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var selectedFilter: UpdateType?
    @State private var showingSettings = false
    @State private var showingArtistSearch = false
    @State private var searchText = ""
    @State private var showingSafari = false
    @State private var safariURL: URL?
    @State private var showPaywall = false
    
    var filteredUpdates: [IdolUpdate] {
        var updates = updateService.updates
        
        if let filter = selectedFilter {
            updates = updates.filter { $0.updateType == filter }
        }
        
        if !searchText.isEmpty {
            updates = updates.filter { update in
                update.artistName.localizedCaseInsensitiveContains(searchText) ||
                update.title.localizedCaseInsensitiveContains(searchText) ||
                update.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return updates
    }
    
    var displayUpdates: [IdolUpdate] {
        if subscriptionService.isVIP {
            return filteredUpdates
        } else {
            // Free users: 1 hero + 2-3 headlines (total 3)
            return Array(filteredUpdates.prefix(subscriptionService.getNewsLimit()))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background using our design system
                PiggyGradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Breaking News Banner
                    if !updateService.breakingNews.isEmpty {
                        breakingNewsBanner
                    }
                    
                    // Filter Section
                    filterSection
                    
                    // Main Feed
                    mainFeedContent
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    connectionStatusIndicator
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingArtistSearch = true }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.piggyTextPrimary)
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .foregroundColor(.piggyTextPrimary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search updates...")
            .refreshable {
                await updateService.refreshAllUpdates()
            }
            .sheet(isPresented: $showingSettings) {
                IdolUpdateSettingsView()
            }
            .sheet(isPresented: $showingArtistSearch) {
                ArtistSearchView()
            }
            .sheet(isPresented: $showPaywall) {
                SimplePaywallView(triggerContext: .generalUpgrade)
                    .environmentObject(revenueCatManager)
            }
            .onAppear {
                updateService.startRealtimeUpdates()
                subscriptionService.updateSubscriptionStatus(from: revenueCatManager)
            }
            .onDisappear {
                updateService.stopRealtimeUpdates()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text("Live Updates")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextPrimary)
                    
                    if let lastUpdate = updateService.lastUpdateTime {
                        Text("Last updated \(lastUpdate, style: .relative) ago")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: PiggySpacing.xs) {
                    if subscriptionService.isVIP {
                        Text("\(updateService.updates.count)")
                            .font(PiggyFont.title2)
                            .foregroundColor(.piggyTextPrimary)
                        
                        Text("Updates")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)
                    } else {
                        HStack(spacing: 4) {
                            Text("\(displayUpdates.count)")
                                .font(PiggyFont.title2)
                                .foregroundColor(.piggyTextPrimary)
                            
                            Text("/")
                                .font(PiggyFont.title3)
                                .foregroundColor(.piggyTextSecondary)
                            
                            Text("\(subscriptionService.getNewsLimit())")
                                .font(PiggyFont.title3)
                                .foregroundColor(.piggyTextSecondary)
                        }
                        
                        Text("Updates")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
            }
            
            // Following Artists
            if !updateService.followedArtists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PiggySpacing.xs) {
                        ForEach(updateService.followedArtists) { artist in
                            artistChip(artist)
                        }
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                }
            }
        }
        .padding(.horizontal, PiggySpacing.lg)
        .padding(.vertical, PiggySpacing.md)
    }
    
    private func artistChip(_ artist: ArtistProfile) -> some View {
        HStack(spacing: PiggySpacing.xs) {
            AsyncImage(url: URL(string: artist.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.piggyTextSecondary.opacity(0.2))
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            
            Text(artist.name)
                .font(PiggyFont.caption1)
                .fontWeight(.medium)
        }
        .padding(.horizontal, PiggySpacing.sm)
        .padding(.vertical, PiggySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(Color.piggySurface)
        )
        .foregroundColor(.piggyTextPrimary)
    }
    
    // MARK: - Breaking News Banner
    
    private var breakingNewsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PiggySpacing.sm) {
                ForEach(updateService.breakingNews.prefix(3)) { news in
                    breakingNewsCard(news)
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
        }
        .padding(.vertical, PiggySpacing.xs)
    }
    
    private func breakingNewsCard(_ news: IdolUpdate) -> some View {
        Button(action: {
            openUpdate(news)
        }) {
            HStack(spacing: PiggySpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("🚨")
                        .font(PiggyFont.title3)
                }
                
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text(news.artistName)
                        .font(PiggyFont.caption1)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(news.title)
                        .font(PiggyFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.piggyTextPrimary)
                        .lineLimit(2)
                    
                    Text(news.formattedTimestamp)
                        .font(PiggyFont.caption2)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
            }
            .padding(PiggySpacing.sm)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PiggySpacing.xs) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    action: { selectedFilter = nil }
                )
                
                ForEach(UpdateType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: selectedFilter == type,
                        action: { selectedFilter = type }
                    )
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
        }
        .padding(.vertical, PiggySpacing.xs)
    }
    
    // MARK: - Main Feed Content
    
    private var mainFeedContent: some View {
        Group {
            if updateService.isLoading && updateService.updates.isEmpty {
                loadingView
            } else if displayUpdates.isEmpty {
                emptyStateView
            } else {
                updatesList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: PiggySpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .piggyPrimary))
                .scaleEffect(1.5)
            
            Text("Loading idol updates...")
                .font(PiggyFont.headline)
                .foregroundColor(.piggyTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: PiggySpacing.lg) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.piggyTextSecondary.opacity(0.3))
            
            Text("No updates found")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)
            
            Text("Try following more artists or adjusting your filters")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
                .multilineTextAlignment(.center)
            
            PiggyButton(title: "Follow Artists", action: {
                showingArtistSearch = true
            }, style: .primary)
        }
        .padding(.horizontal, PiggySpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var updatesList: some View {
        ScrollView {
            LazyVStack(spacing: PiggySpacing.md) {
                ForEach(displayUpdates) { update in
                    IdolUpdateCard(update: update) {
                        openUpdate(update)
                    }
                }
                
                // VIP Upgrade Card for Free users
                if !subscriptionService.isVIP && filteredUpdates.count > subscriptionService.getNewsLimit() {
                    VIPUpgradeCard(feature: .fullNews) {
                        showPaywall = true
                    }
                    .padding(.top, PiggySpacing.lg)
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Connection Status
    
    private var connectionStatusIndicator: some View {
        HStack(spacing: PiggySpacing.xs) {
            Circle()
                .fill(updateService.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(updateService.isConnected ? "Live" : "Offline")
                .font(PiggyFont.caption1)
                .fontWeight(.medium)
                .foregroundColor(.piggyTextSecondary)
        }
        .padding(.horizontal, PiggySpacing.sm)
        .padding(.vertical, PiggySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                .fill(Color.piggySurface)
        )
    }
    
    // MARK: - Helper Methods
    
    private func openUpdate(_ update: IdolUpdate) {
        if let urlString = update.externalURL,
           let url = URL(string: urlString) {
            safariURL = url
            showingSafari = true
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PiggyFont.caption1)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .piggyTextPrimary)
                .padding(.horizontal, PiggySpacing.sm)
                .padding(.vertical, PiggySpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                        .fill(isSelected ? Color.piggyTextPrimary : Color.piggySurface)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Idol Update Card Component

struct IdolUpdateCard: View {
    let update: IdolUpdate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                // Header
                HStack(spacing: PiggySpacing.sm) {
                    // Artist Avatar
                    AsyncImage(url: URL(string: update.imageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.piggyTextSecondary.opacity(0.2))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(update.artistName)
                                .font(PiggyFont.headline)
                                .foregroundColor(.piggyTextPrimary)
                            
                            if update.isBreakingNews {
                                Text("BREAKING")
                                    .font(PiggyFont.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, PiggySpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(PiggyBorderRadius.xs)
                            }
                        }
                        
                        HStack(spacing: PiggySpacing.xs) {
                            Image(systemName: update.platform.icon)
                                .font(PiggyFont.caption1)
                                .foregroundColor(update.platform.color)
                            
                            Text(update.platform.rawValue)
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary)
                            
                            Text("•")
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary.opacity(0.5))
                            
                            Text(update.formattedTimestamp)
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: PiggySpacing.xs) {
                        Image(systemName: update.updateType.icon)
                            .font(PiggyFont.title3)
                            .foregroundColor(update.updateType.color)
                        
                        Text(update.sentiment.emoji)
                            .font(PiggyFont.caption1)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text(update.title)
                        .font(PiggyFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.piggyTextPrimary)
                        .lineLimit(2)
                    
                    if let aiSummary = update.aiSummary {
                        Text(aiSummary)
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                            .lineLimit(3)
                    } else {
                        Text(update.content)
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                            .lineLimit(3)
                    }
                }
                
                // Tags
                if !update.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PiggySpacing.xs) {
                            ForEach(update.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(PiggyFont.caption2)
                                    .foregroundColor(.piggyTextSecondary)
                                    .padding(.horizontal, PiggySpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                                            .fill(Color.piggySurface)
                                    )
                            }
                        }
                    }
                }
                
                // Engagement Score
                HStack {
                    Spacer()
                    
                    HStack(spacing: PiggySpacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.orange)
                        
                        Text("\(Int(update.engagementScore))")
                            .font(PiggyFont.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
            }
            .padding(PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                    .fill(Color.piggySurface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct IdolUpdateSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                VStack {
                    Text("Update Settings")
                        .font(PiggyFont.title1)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text("Coming soon...")
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.piggyTextPrimary)
                }
            }
        }
    }
}

struct ArtistSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                VStack {
                    Text("Artist Search")
                        .font(PiggyFont.title1)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text("Coming soon...")
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            .navigationTitle("Follow Artists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.piggyTextPrimary)
                }
            }
        }
    }
}

#Preview {
    IdolNewsFeedView()
}