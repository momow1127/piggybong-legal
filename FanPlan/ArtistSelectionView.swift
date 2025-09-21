import SwiftUI


// Import required models and services
// These provide the types referenced in the view

// Import the required types that are defined elsewhere
// - Artist: from FanExperienceModels.swift
// - OnboardingData: from OnboardingModels.swift
// - PopularArtist: from ArtistModels.swift
// - ArtistSelectionMode: from OnboardingModels.swift
// - OnboardingService: from OnboardingService.swift

// MARK: - Array Extension for Duplicate Removal
extension Array {
    func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Artist Selection Card
struct ArtistSelectionCard: View {
    let popularArtist: PopularArtist
    let isSelected: Bool
    let canSelect: Bool
    let selectionOrder: Int? // Add selection order parameter
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            // Card with 3:2 aspect ratio for better visibility
            ZStack {
                // Card background - no inner purple background
                RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                    .fill(Color.white.opacity(0.1))
                    .aspectRatio(1.5, contentMode: .fit)  // 3:2 ratio for better visibility
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                            .stroke(
                                isSelected ? Color.piggyPrimary : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                // Artist name centered
                Text(popularArtist.artist.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)  // 2 lines max for shorter cards
                    .padding(.horizontal, 8)

                // Selection order badge
                if let order = selectionOrder {
                    VStack {
                        HStack {
                            Spacer()
                            orderBadge(order: order)
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(canSelect ? 1.0 : 0.6)  // Visual feedback when disabled
        }
        // Don't disable - let onTap handle rejection logic and show banner
        .buttonStyle(.plain)  // Use plain button style to avoid conflicts
        .animation(.easeInOut(duration: 0.1), value: isSelected) // Faster animation
        .animation(.easeInOut(duration: 0.05), value: isPressed) // Much faster press animation
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }

    private func orderBadge(order: Int) -> some View {
        let orderText: String = {
            switch order {
            case 1: return "1st"
            case 2: return "2nd"
            case 3: return "3rd"
            default: return "\(order)th"
            }
        }()

        return Text(orderText)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.piggyPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Selected Artist Chip
struct SelectedArtistChip: View {
    let artist: Artist
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(artist.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(PiggyGradients.primaryButton)
        )
    }
}

// MARK: - Artist Selection ViewModel
@MainActor
class ArtistSelectionViewModel: ObservableObject {
    @Published var popularArtists: [PopularArtist] = []
    @Published var trendingArtists: [PopularArtist] = []
    @Published var searchQuery: String = ""
    @Published var currentMode: ArtistSelectionMode = .popular
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Search Results
    @Published var sortedResults: [Artist] = []

    private let onboardingService = OnboardingService.shared
    private var searchTask: Task<Void, Never>?
    private var remoteSearchTask: Task<Void, Never>?

    // Reference to OnboardingData for cache updates
    weak var onboardingData: OnboardingData?

    // Performance optimization: Search cache
    private var searchCache: [String: [Artist]] = [:]
    private var normalizedStringCache: [String: String] = [:]

    var displayedArtists: [PopularArtist] {
        let baseArtists: [PopularArtist]
        switch currentMode {
        case .popular:
            baseArtists = popularArtists
        case .trending:
            baseArtists = trendingArtists
        case .search(_):
            // In search mode, show popular artists in grid (search results shown inline above)
            baseArtists = popularArtists
        case .mySelection:
            baseArtists = [] // This would show user's already selected artists in a different context
        }

        // No filtering needed - grid always shows base artists
        return baseArtists
    }

    func loadInitialData() async {
        // PHASE 1: INSTANT - Load embedded data immediately (no loading state)
        loadFallbackDataInstantly()

        // PHASE 2: BACKGROUND - Enhance with fresh data silently
        await loadFreshDataInBackground()
    }

    /// INSTANT LOADING: Load embedded artists immediately
    private func loadFallbackDataInstantly() {
        // Check if OnboardingService already has loaded artists
        let availableArtists = onboardingService.availableArtists

        if !availableArtists.isEmpty {
            // Use already loaded artists from OnboardingService (remove duplicates by name)
            let uniqueArtists = Array(Dictionary(grouping: availableArtists, by: { $0.name }).compactMapValues { $0.first }.values)
            let freshPopular = uniqueArtists.map { artist in
                PopularArtist(
                    artist: artist,
                    followerCount: 1000000, // Default follower count since we don't have this data
                    recentActivity: "Recently active" // Default activity text
                )
            }

            self.popularArtists = freshPopular
            self.trendingArtists = []

            // Update OnboardingData cache with fresh artists
            onboardingData?.updateArtistCache(with: availableArtists)

            print("⚡ INSTANT: Using \(freshPopular.count) already loaded artists from database")
            print("📋 Artist sample: \(freshPopular.prefix(3).map { $0.artist.name }.joined(separator: ", "))")
        } else {
            // Fall back to embedded artists while database loads
            let fallbackArtists = onboardingService.getFallbackArtists()

            self.popularArtists = fallbackArtists
            self.trendingArtists = []

            // Update OnboardingData cache with fallback artists
            let allArtists = fallbackArtists.map { $0.artist }
            onboardingData?.updateArtistCache(with: allArtists)

            print("⚡ INSTANT: Using \(fallbackArtists.count) embedded fallback artists (database still loading)")
        }
    }

    /// BACKGROUND ENHANCEMENT: Load fresh data and update silently
    private func loadFreshDataInBackground() async {
        print("🔄 BACKGROUND: Loading fresh artist data from OnboardingService...")

        // CRITICAL FIX: Capture main actor values before background processing
        let availableArtists = self.onboardingService.availableArtists

        // CRITICAL FIX: Move heavy data processing off main thread
        let processedData: ([PopularArtist], [Artist]) = await Task.detached(priority: .utility) {

            // All heavy operations on background thread - using captured value

            guard !availableArtists.isEmpty else {
                print("📦 BACKGROUND: No artists from database, keeping embedded data")
                return ([], [])
            }

            print("🔄 BACKGROUND: Found \(availableArtists.count) artists from database")

            // Heavy operations: Remove duplicates and create PopularArtist objects
            let uniqueArtists = Array(Dictionary(grouping: availableArtists, by: { $0.name }).compactMapValues { $0.first }.values)
            let freshPopular = uniqueArtists.map { artist in
                PopularArtist(
                    artist: artist,
                    followerCount: 1000000, // Default follower count
                    recentActivity: "Recently active" // Default activity text
                )
            }

            return (freshPopular, availableArtists)
        }.value

        // FIXED: Only UI updates on main thread
        guard !processedData.0.isEmpty else { return }

        await MainActor.run {
            self.popularArtists = processedData.0
            self.trendingArtists = [] // Keep trending empty for now
        }

        // Update cache (can happen off main thread)
        onboardingData?.updateArtistCache(with: processedData.1)

        print("🔄 BACKGROUND: Updated UI with \(processedData.0.count) real K-pop artists from database")
        print("📋 Real artist names: \(processedData.0.prefix(5).map { $0.artist.name }.joined(separator: ", "))...")
    }

    func refreshArtists() async {
        // For pull-to-refresh, do a background refresh without showing loading
        await loadFreshDataInBackground()
    }

    func setMode(_ mode: ArtistSelectionMode) {
        currentMode = mode

        if case .popular = mode, popularArtists.isEmpty {
            // Load instantly without showing loading state
            loadFallbackDataInstantly()
            Task { await loadFreshDataInBackground() }
        }
    }

    // MARK: - Optimized Search Implementation
    func performSearch(query: String) {
        // Cancel any existing search tasks
        searchTask?.cancel()
        remoteSearchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            // Clear search results and return to popular mode
            sortedResults = []
            if case .search(_) = currentMode {
                currentMode = .popular
            }
            return
        }

        // Set mode to search
        currentMode = .search(trimmedQuery)

        // OPTIMIZED: Use cached results if query is similar to prevent recalculation
        if let cached = getCachedSearchResults(for: trimmedQuery) {
            sortedResults = cached
            return
        }

        // CRITICAL FIX: All search operations moved to background with proper priority
        searchTask = Task(priority: .userInitiated) {
            // PHASE 1: Compute sorted results from local data on background thread
            await computeLocalSortedResultsAsync(query: trimmedQuery)

            // PHASE 2: Debounced remote search enhancement
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms debounce

            guard !Task.isCancelled else { return }

            // PERFORMANCE: Move remote search to separate lower-priority task
            let remoteTask = Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }

                do {
                    // Search remote K-pop artists from database (background thread)
                    let remoteArtists = try await self.onboardingService.searchArtists(query: trimmedQuery)

                    guard !Task.isCancelled else { return }

                    // Heavy sorting computation on background thread
                    let remoteSorted = await self.sortedCandidates(for: trimmedQuery, in: remoteArtists)

                    // FIXED: Only UI updates on main thread
                    await MainActor.run {
                        self.sortedResults = remoteSorted
                        self.cacheSearchResults(query: trimmedQuery, results: remoteSorted)
                        self.onboardingData?.updateArtistCache(with: remoteArtists)
                        print("📈 ENHANCED: Remote search provided \(remoteSorted.count) sorted results")
                    }
                } catch {
                    if !Task.isCancelled {
                        print("⚠️ REMOTE: Remote search failed, keeping local results: \(error.localizedDescription)")
                    }
                }
            }

            // Store remote task for cancellation
            self.remoteSearchTask = remoteTask
        }
    }

    // MARK: - Performance Optimization Methods
    private func getCachedSearchResults(for query: String) -> [Artist]? {
        return searchCache[query.lowercased()]
    }

    private func cacheSearchResults(query: String, results: [Artist]) {
        searchCache[query.lowercased()] = results

        // Limit cache size to prevent memory issues (reduced from 20 to 5)
        if searchCache.count > 5 {
            // Remove multiple old entries to keep cache small
            let keysToRemove = Array(searchCache.keys.prefix(searchCache.count - 3))
            for key in keysToRemove {
                searchCache.removeValue(forKey: key)
            }
        }
    }

    /// Compute sorted results asynchronously to avoid blocking main thread
    private func computeLocalSortedResultsAsync(query: String) async {
        // CRITICAL FIX: Move heavy computation off main thread with proper priority
        let results: [Artist] = await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return [] }

            // Perform all heavy operations on background thread
            return await self.computeLocalSortedResultsSync(query: query)
        }.value

        // FIXED: Only UI updates on main thread
        await MainActor.run {
            self.sortedResults = results
            self.cacheSearchResults(query: query, results: results)
        }
    }

    /// Compute sorted results from currently available local artists (synchronous, background thread)
    private func computeLocalSortedResultsSync(query: String) -> [Artist] {
        // Collect all available local artists
        var localArtists: [Artist] = []

        // Add artists from current mode
        localArtists.append(contentsOf: popularArtists.map { $0.artist })
        localArtists.append(contentsOf: trendingArtists.map { $0.artist })

        // Add fallback embedded artists
        let fallbackArtists = onboardingService.getFallbackArtists().map { $0.artist }
        localArtists.append(contentsOf: fallbackArtists)

        // Sort and dedupe using optimized helper method
        let results = sortedCandidatesOptimized(for: query, in: localArtists)

        print("⚡ LOCAL: Found \(results.count) sorted local results for '\(query)'")
        return results
    }

    /// Compute sorted results from currently available local artists (instant, main thread) - DEPRECATED
    private func computeLocalSortedResults(query: String) {
        // Collect all available local artists
        var localArtists: [Artist] = []

        // Add artists from current mode
        localArtists.append(contentsOf: popularArtists.map { $0.artist })
        localArtists.append(contentsOf: trendingArtists.map { $0.artist })

        // Add fallback embedded artists
        let fallbackArtists = onboardingService.getFallbackArtists().map { $0.artist }
        localArtists.append(contentsOf: fallbackArtists)

        // Sort and dedupe using helper method
        sortedResults = sortedCandidates(for: query, in: localArtists)

        print("⚡ LOCAL: Found \(sortedResults.count) sorted local results for '\(query)'")
    }

    /// Score an artist based on query match quality
    private func scoreArtist(_ artist: Artist, query: String) -> Int {
        let normalizedQuery = normalizeString(query)
        let normalizedName = normalizeString(artist.name)
        let normalizedGroup = artist.group.map { normalizeString($0) }

        var score = 0

        // Name scoring
        if normalizedName.hasPrefix(normalizedQuery) {
            score += 100 // Prefix match
        } else if normalizedName.contains(" \(normalizedQuery)") || normalizedName.contains("-\(normalizedQuery)") {
            score += 50 // Word boundary match
        } else if normalizedName.localizedCaseInsensitiveContains(normalizedQuery) {
            score += 10 // Substring match
        }

        // Group name scoring (if available)
        if let group = normalizedGroup {
            if group.hasPrefix(normalizedQuery) {
                score += 120 // Group prefix match (slightly higher than name prefix)
            } else if group.contains(" \(normalizedQuery)") || group.contains("-\(normalizedQuery)") {
                score += 70 // Group word boundary match
            } else if group.localizedCaseInsensitiveContains(normalizedQuery) {
                score += 20 // Group substring match
            }
        }

        return score
    }

    /// Normalize string for consistent matching - WITH CACHING
    private func normalizeString(_ string: String) -> String {
        if let cached = normalizedStringCache[string] {
            return cached
        }

        let normalized = string.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        normalizedStringCache[string] = normalized

        // Limit cache size (reduced from 100 to 20)
        if normalizedStringCache.count > 20 {
            // Clear half the cache when limit reached
            let keysToRemove = Array(normalizedStringCache.keys.prefix(10))
            for key in keysToRemove {
                normalizedStringCache.removeValue(forKey: key)
            }
        }

        return normalized
    }

    /// Sort candidates by score and return deduplicated Artist array
    private func sortedCandidates(for query: String, in candidates: [Artist]) -> [Artist] {
        let normalizedQuery = normalizeString(query)

        // Score all candidates
        let scoredArtists = candidates.compactMap { artist -> (Artist, Int)? in
            let score = scoreArtist(artist, query: normalizedQuery)
            return score > 0 ? (artist, score) : nil
        }

        // Sort by score desc → name length asc → name asc
        let sortedArtists = scoredArtists.sorted { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 > rhs.1 // Higher score first
            }
            if lhs.0.name.count != rhs.0.name.count {
                return lhs.0.name.count < rhs.0.name.count // Shorter names first
            }
            return lhs.0.name.localizedCaseInsensitiveCompare(rhs.0.name) == .orderedAscending // Alphabetical
        }

        // Dedupe by ID while preserving order
        var uniqueArtists: [Artist] = []
        var seenIds: Set<UUID> = []

        for (artist, _) in sortedArtists {
            if !seenIds.contains(artist.id) {
                uniqueArtists.append(artist)
                seenIds.insert(artist.id)
            }
        }

        return uniqueArtists
    }

    /// OPTIMIZED: Sort candidates by score with performance improvements
    private func sortedCandidatesOptimized(for query: String, in candidates: [Artist]) -> [Artist] {
        let normalizedQuery = normalizeString(query)

        // Early return for empty query or candidates
        guard !normalizedQuery.isEmpty, !candidates.isEmpty else {
            return []
        }

        // Pre-filter candidates that have any chance of matching (performance optimization)
        let preFiltered = candidates.filter { artist in
            let normalizedName = normalizeString(artist.name)
            let normalizedGroup = artist.group.map { normalizeString($0) }

            return normalizedName.localizedCaseInsensitiveContains(normalizedQuery) ||
                   (normalizedGroup?.localizedCaseInsensitiveContains(normalizedQuery) ?? false)
        }

        // Score only pre-filtered candidates
        let scoredArtists: [(Artist, Int)] = preFiltered.compactMap { artist in
            let score = scoreArtist(artist, query: normalizedQuery)
            return score > 0 ? (artist, score) : nil
        }

        // Sort by score desc → name length asc → name asc (optimized comparisons)
        let sortedArtists = scoredArtists.sorted { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 > rhs.1 // Higher score first
            }
            let lhsCount = lhs.0.name.count
            let rhsCount = rhs.0.name.count
            if lhsCount != rhsCount {
                return lhsCount < rhsCount // Shorter names first
            }
            return lhs.0.name.localizedCaseInsensitiveCompare(rhs.0.name) == .orderedAscending // Alphabetical
        }

        // Fast deduplication using Set for O(1) lookup
        var uniqueArtists: [Artist] = []
        var seenIds = Set<UUID>()
        uniqueArtists.reserveCapacity(sortedArtists.count)

        for (artist, _) in sortedArtists {
            if seenIds.insert(artist.id).inserted {
                uniqueArtists.append(artist)
            }
        }

        return uniqueArtists
    }

    /// Gets realistic follower count based on artist name and popularity
    private func getRealisticFollowerCount(for artistName: String) -> Int {
        // Tier-based follower counts for realism
        let topTierArtists = ["BTS", "BLACKPINK", "TWICE", "SEVENTEEN"]
        let popularArtists = ["NewJeans", "aespa", "Stray Kids", "LE SSERAFIM", "IVE", "ENHYPEN", "ITZY", "TXT"]
        let risingArtists = ["BABYMONSTER", "ILLIT", "RIIZE", "NMIXX"]

        if topTierArtists.contains(artistName) {
            return Int.random(in: 15_000_000...45_000_000)
        } else if popularArtists.contains(artistName) {
            return Int.random(in: 8_000_000...20_000_000)
        } else if risingArtists.contains(artistName) {
            return Int.random(in: 3_000_000...10_000_000)
        } else {
            return Int.random(in: 500_000...5_000_000)
        }
    }

    /// Gets relevant recent activity for real K-pop artists
    private func getRecentActivityForArtist(_ artistName: String) -> String? {
        let activities = [
            "New album release",
            "World tour announcement",
            "Comeback stage performance",
            "Special collaboration",
            "Award show appearance",
            "Fan meeting event",
            "Music show win",
            "Billboard chart success",
            "Fashion brand partnership",
            "Variety show appearance"
        ]
        return activities.randomElement()
    }

    func clearSearch() {
        searchQuery = ""
        sortedResults = []
        currentMode = .popular
        searchTask?.cancel()
        remoteSearchTask?.cancel()
    }

    func showAllArtists() {
        // Keep the search query but switch to popular mode to show all artists
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMode = .popular
        }
        searchTask?.cancel()
    }

    func retryLastAction() async {
        // Retry background loading of real database artists without affecting current display
        await loadFreshDataInBackground()
    }

    /// Clean up memory when view disappears
    func cleanupMemory() {
        searchCache.removeAll()
        normalizedStringCache.removeAll()
        sortedResults.removeAll()
        searchTask?.cancel()
        remoteSearchTask?.cancel()
    }
}

// MARK: - Artist Selection View
struct ArtistSelectionView: View {
    @ObservedObject var onboardingData: OnboardingData
    @StateObject private var viewModel = ArtistSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var showToast = false
    @State private var showPriorityInfo = false
    @State private var bannerTask: Task<Void, Never>?

    let onNext: () -> Void
    let onBack: () -> Void

    // Shared grid columns for both discovery and search results
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // Computed property for search state
    private var isSearchActive: Bool {
        !viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        OnboardingScaffold(
            title: "Continue",
            canProceed: canProceed,
            currentStep: .artistSelection,
            action: handleNextPressed
        ) {
            VStack(spacing: 0) {
                    // Title and subtitle
                    titleSection

                    // Content
                    ScrollView {
                        LazyVStack(spacing: PiggySpacing.md) {
                            // Search Bar
                            searchBarSection

                            // Search context indicator
                            searchContextView

                            // Search Results (inline, sorted)
                            searchResultsSection

                            // Contextual priority banner - only shows on 4th selection attempt
                            Group {
                                if showPriorityInfo && !isSearchActive {
                                    contextualPriorityBanner
                                        .padding(.vertical, PiggySpacing.sm)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                } else {
                                    // Placeholder to prevent layout jumps
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 0)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: showPriorityInfo)

                            // Artists Grid
                            artistsGridSection

                            // Bottom padding to ensure content isn't cut off
                            Spacer()
                                .frame(height: 50)
                        }
                        .padding(.horizontal, PiggySpacing.lg)
                    }
                    .refreshable {
                        await viewModel.refreshArtists()
                    }
                }

                // Toast overlay
                if showToast {
                    toastView
                }
        }
        .task {
            // Wire up OnboardingData reference for cache updates
            viewModel.onboardingData = onboardingData
            await viewModel.loadInitialData()
        }
        .onAppear {
            // Enforce artist limit when screen appears
            onboardingData.enforceArtistLimit()
        }
        .onDisappear {
            // Clean up banner state and timer when leaving view
            bannerTask?.cancel()
            showPriorityInfo = false
            // MEMORY: Clean up all caches to prevent memory pressure
            viewModel.cleanupMemory()
        }
        .alert("Database Connection", isPresented: .constant(viewModel.error != nil)) {
            Button("Retry") {
                Task {
                    await viewModel.retryLastAction()
                }
            }
            Button("Continue with Offline Data", role: .cancel) {
                viewModel.error = nil
                // Continue with embedded data
            }
        } message: {
            if let error = viewModel.error {
                Text("Unable to load latest K-pop artists from database. You can continue with offline data or retry the connection.\n\nError: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            Text("Set Your Priority Artists")
                .font(PiggyFont.sectionTitle)
                .foregroundColor(.piggyTextPrimary)
                .multilineTextAlignment(.center)

            Text("Get smart alerts when your artists compete")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
        .padding(.bottom, PiggySpacing.md)
    }

    private var contextualPriorityBanner: some View {
        PiggyCard(style: .elevated, cornerRadius: .medium) {
            HStack(spacing: PiggySpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.piggySecondary)

                HStack(spacing: PiggySpacing.xs) {
                    Text("Choose up to \(OnboardingConstants.maxArtistsSelection) artists.")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextPrimary)

                    Button("Upgrade to 6") {
                        // Route to upgrade flow
                        // TODO: Implement upgrade navigation
                    }
                    .font(PiggyFont.caption)
                    .foregroundColor(.piggyTextPrimary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBarSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: PiggySpacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.piggyTextSecondary)

                    TextField("Search artists or groups...", text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.piggyTextPrimary)
                        .accentColor(.piggyPrimary)
                        .overlay(
                            // Custom placeholder when text is empty
                            HStack {
                                if viewModel.searchQuery.isEmpty {
                                    Text("Search artists or groups...")
                                        .foregroundColor(.piggyTextPlaceholder)
                                        .allowsHitTesting(false)
                                }
                                Spacer()
                            }
                        )
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .font(.system(size: 16, weight: .regular))
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.searchQuery) { _, newValue in
                            viewModel.performSearch(query: newValue)

                            // Hide banner when search becomes active or is cleared
                            let trimmedQuery = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedQuery.isEmpty || (trimmedQuery.isEmpty && showPriorityInfo) {
                                bannerTask?.cancel()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPriorityInfo = false
                                }
                            }
                        }

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.piggyTextSecondary)
                        }
                    }
                }

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                        .stroke(isSearchFocused ? Color.piggyPrimary : Color.white.opacity(0.2), lineWidth: isSearchFocused ? 2 : 1)
                )
                .shadow(color: isSearchFocused ? Color.piggyPrimary.opacity(0.3) : Color.clear, radius: isSearchFocused ? 8 : 0)
        )
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
        .onTapGesture {
            isSearchFocused = true
        }
    }

    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        Group {
            if !viewModel.sortedResults.isEmpty {
                LazyVGrid(columns: gridColumns, spacing: PiggySpacing.md) {
                    ForEach(viewModel.sortedResults, id: \.id) { artist in
                        // TODO: Migrate ArtistSelectionCard to use plain Artist instead of PopularArtist
                        // This PopularArtist wrapper is a temporary shim for compatibility
                        ArtistSelectionCard(
                            popularArtist: PopularArtist(
                                artist: artist,
                                followerCount: 0, // Not displayed in search results
                                recentActivity: nil // Not displayed in search results
                            ),
                            isSelected: onboardingData.isArtistSelected(artist),
                            canSelect: canSelectMoreArtists || onboardingData.isArtistSelected(artist),
                            selectionOrder: onboardingData.getArtistSelectionOrder(artist)
                        ) {
                            // Just toggle selection - don't clear query or dismiss keyboard
                            toggleArtistSelection(artist)
                        }
                    }
                }
                .padding(.bottom, PiggySpacing.md)
            }
        }
    }

    // MARK: - Search Context View
    private var searchContextView: some View {
        Group {
            if !viewModel.searchQuery.isEmpty && viewModel.currentMode == .popular {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.piggySecondary)

                    Text("Showing all artists")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.piggyTextSecondary)

                    Spacer()

                    Button(action: { viewModel.performSearch(query: viewModel.searchQuery) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 11))
                            Text("Search")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.piggyPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.piggyPrimary.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Artists Grid
    private var artistsGridSection: some View {
        Group {
            if viewModel.displayedArtists.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: gridColumns, spacing: PiggySpacing.md) {
                    ForEach(viewModel.displayedArtists, id: \.artist.id) { popularArtist in
                        ArtistSelectionCard(
                            popularArtist: popularArtist,
                            isSelected: onboardingData.isArtistSelected(popularArtist.artist),
                            canSelect: canSelectMoreArtists || onboardingData.isArtistSelected(popularArtist.artist),
                            selectionOrder: onboardingData.getArtistSelectionOrder(popularArtist.artist)
                        ) {
                            toggleArtistSelection(popularArtist.artist)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: PiggySpacing.md) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(.piggyTextSecondary)

            Text("No artist found")
                .font(.headline)
                .foregroundColor(.white)

            Text("Try adjusting your search terms")
                .font(.subheadline)
                .foregroundColor(.piggyTextSecondary)
        }
        .padding(.vertical, PiggySpacing.xl)
    }

    private var canSelectMoreArtists: Bool {
        onboardingData.selectedArtistIDs.count < OnboardingConstants.maxArtistsSelection
    }

    private func toggleArtistSelection(_ artist: Artist) {
        let currentCount = onboardingData.selectedArtistIDs.count
        let isSelected = onboardingData.isArtistSelected(artist)

        // Check if this would be a 4th selection (rejection case)
        if !isSelected && currentCount >= OnboardingConstants.maxArtistsSelection {
            // Cancel any existing banner auto-dismiss timer
            bannerTask?.cancel()

            // Accessibility announcement (only if banner wasn't already showing)
            let shouldAnnounce = !showPriorityInfo

            // Show banner with reduced animation
            withAnimation(.easeInOut(duration: 0.15)) {
                showPriorityInfo = true
            }

            // Warning haptic feedback - moved to background
            Task {
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.warning)
            }

            // Post accessibility announcement if this is first rejection
            if shouldAnnounce {
                UIAccessibility.post(notification: .announcement, argument: "Choose up to 3 artists. Upgrade to 6.")
            }

            // Auto-dismiss after 3 seconds
            bannerTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showPriorityInfo = false
                    }
                }
            }

            return // Don't proceed with selection
        }

        // Successful selection or deselection - OPTIMIZED: immediate data update, minimal animation
        onboardingData.toggleArtist(artist)

        // Hide banner on deselection (no animation for performance)
        if isSelected {
            bannerTask?.cancel()
            showPriorityInfo = false
        }

        // Move expensive operations to background
        Task {
            // Analytics (non-blocking)
            OnboardingAnalytics.trackArtistSelected(artist, selectionMethod: viewModel.currentMode.title)

            // Haptic feedback (non-blocking)
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    // MARK: - Selection Summary


    // MARK: - Computed Properties
    private var canProceed: Bool {
        !onboardingData.selectedArtists.isEmpty
    }

    // MARK: - Toast View
    private var toastView: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.white)
                Text("Pick at least 1 artist for priority alerts")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.8)),
                removal: .opacity.combined(with: .move(edge: .bottom))
            ))
            .padding(.bottom, 140) // Space above OnboardingScaffold button
        }
    }

    // MARK: - Action Handlers
    private func handleNextPressed() {
        if canProceed {
            // Analytics tracking for selected real artists
            let selectedArtistNames = onboardingData.selectedArtists.map { $0.name }.joined(separator: ", ")
            print("🎵 User selected K-pop artists: \(selectedArtistNames)")
            print("📊 Artist selection mode: \(viewModel.currentMode.title)")

            // Proceed to next onboarding step
            onNext()
        } else {
            // Show toast and haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showToast = true
            }

            // Auto-hide toast after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showToast = false
                }
            }
        }
    }
}




// MARK: - Preview
#Preview {
    NavigationView {
        ArtistSelectionView(
            onboardingData: OnboardingData(),
            onNext: {},
            onBack: {}
        )
    }
}