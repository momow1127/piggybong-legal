import SwiftUI

// MARK: - Artist Management View
// A full-screen modal that reuses onboarding components for artist management
// Addresses UX issues: confusing messaging, prominent paywall, poor empty states

// MARK: - Artist Model
struct Artist: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let group: String
    let imageURL: String
    let category: ArtistCategory
    let isPopular: Bool
    let isTrending: Bool
    let fanFavorite: Bool
}

enum ArtistCategory: String, CaseIterable {
    case popular = "Popular"
    case trending = "Trending Now"
    case fanFavorites = "Fan Favorites"
    case girlGroups = "Girl Groups"
    case boyGroups = "Boy Groups"
    case soloArtists = "Solo Artists"
    case rookies = "Rising Stars"
}

// MARK: - User Tier Enum
enum UserTier {
    case free
    case premium

    var maxArtists: Int {
        switch self {
        case .free: return 3
        case .premium: return 6
        }
    }
}

// MARK: - Main Manage Artists View
struct ManageArtistsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedArtists: Set<Artist>
    @State private var availableArtists: [Artist] = []
    @State private var selectedCategory: ArtistCategory = .popular
    @State private var searchText: String = ""
    @State private var showingUpgradePrompt = false
    @State private var replacingArtist: Artist?
    @State private var isLoading = true
    @State private var showingReplaceOptions = false
    @State private var animateSelection = false

    let userTier: UserTier
    let onArtistsUpdated: (Set<Artist>) -> Void

    init(currentArtists: Set<Artist>, userTier: UserTier = .free, onArtistsUpdated: @escaping (Set<Artist>) -> Void) {
        _selectedArtists = State(initialValue: currentArtists)
        self.userTier = userTier
        self.onArtistsUpdated = onArtistsUpdated
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background using PiggyComponents
                PiggyGradients.primaryGradient
                    .ignoresSafeArea()

                if isLoading {
                    PiggyLoadingState(message: "Loading artists...", style: .spinner)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            currentArtistsSection
                            browseSection
                        }
                        .piggyPadding()
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Manage Artists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    PiggyButton("Done", style: .tertiary, size: .small) {
                        onArtistsUpdated(selectedArtists)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAvailableArtists()
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            UpgradePromptView(userTier: userTier)
        }
        .sheet(isPresented: $showingReplaceOptions) {
            if let artistToReplace = replacingArtist {
                ReplaceArtistView(
                    artistToReplace: artistToReplace,
                    availableArtists: availableArtists.filter { !selectedArtists.contains($0) },
                    onReplace: { newArtist in
                        selectedArtists.remove(artistToReplace)
                        selectedArtists.insert(newArtist)
                        replacingArtist = nil
                        showingReplaceOptions = false

                        // Animate the change
                        withAnimation(.spring()) {
                            animateSelection.toggle()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Current Artists Section
    private var currentArtistsSection: some View {
        PiggySection(
            "Your Artists",
            subtitle: progressText
        ) {
            if selectedArtists.isEmpty {
                // This should never happen as per requirements
                PiggyEmptyState(
                    icon: "music.note",
                    title: "No Artists Selected",
                    message: "Browse and select your favorite K-pop artists"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(selectedArtists).sorted(by: { $0.name < $1.name }), id: \.self) { artist in
                        SelectedArtistCard(
                            artist: artist,
                            canRemove: selectedArtists.count > 1,
                            onTap: {
                                handleArtistTap(artist)
                            },
                            onRemove: {
                                removeArtist(artist)
                            }
                        )
                        .scaleEffect(animateSelection ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3), value: animateSelection)
                    }
                }

                // Progress indicator with better styling
                HStack {
                    PiggyProgressIndicator(
                        current: selectedArtists.count,
                        total: userTier.maxArtists,
                        style: .dots
                    )

                    Spacer()

                    PiggyProgressIndicator(
                        current: selectedArtists.count,
                        total: userTier.maxArtists,
                        style: .text
                    )
                }
                .padding(.top, 12)
            }
        }
    }

    private var progressText: String {
        let remaining = userTier.maxArtists - selectedArtists.count
        if remaining > 0 {
            return "Add \(remaining) more artist\(remaining == 1 ? "" : "s")"
        } else {
            return "All slots filled"
        }
    }


    // MARK: - Browse Section
    private var browseSection: some View {
        PiggySection(
            "Discover Artists",
            subtitle: selectedArtists.count < userTier.maxArtists ? nil : "Upgrade for more slots",
            actionTitle: selectedArtists.count < userTier.maxArtists ? progressBadgeText : nil
        ) {
            VStack(spacing: 20) {
                // Category selector with improved styling
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ArtistCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .piggyPadding()
                }
                .padding(.horizontal, -16)

                // Enhanced search bar
                PiggyTextField(
                    "",
                    text: $searchText,
                    placeholder: "Search artists or groups..."
                )

                // Artist grid with improved layout
                artistGrid

                // Subtle upgrade hint when at limit
                if selectedArtists.count >= userTier.maxArtists && userTier == .free {
                    upgradeHint
                }
            }
        }
    }

    private var progressBadgeText: String {
        let remaining = userTier.maxArtists - selectedArtists.count
        return "Add \(remaining) more"
    }

    private var upgradeHint: some View {
        PiggyCard {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Want more artists?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Upgrade for 6 total slots")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                PiggyButton("Upgrade", style: .secondary, size: .small) {
                    showingUpgradePrompt = true
                }
            }
            .padding(16)
        }
    }

    // MARK: - Artist Grid
    private var artistGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredArtists, id: \.self) { artist in
                ArtistCard(
                    artist: artist,
                    isSelected: selectedArtists.contains(artist),
                    onTap: {
                        handleArtistSelection(artist)
                    }
                )
            }
        }
    }

    // MARK: - Computed Properties
    private var filteredArtists: [Artist] {
        let categoryFiltered = availableArtists.filter { artist in
            switch selectedCategory {
            case .popular:
                return artist.isPopular
            case .trending:
                return artist.isTrending
            case .fanFavorites:
                return artist.fanFavorite
            default:
                return artist.category == selectedCategory
            }
        }

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.group.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Actions
    private func handleArtistSelection(_ artist: Artist) {
        if selectedArtists.contains(artist) {
            // Deselect if already selected
            if selectedArtists.count > 1 {
                selectedArtists.remove(artist)
            }
        } else {
            // Add new artist
            if selectedArtists.count < userTier.maxArtists {
                selectedArtists.insert(artist)
            } else {
                // Show upgrade prompt for free users at limit
                if userTier == .free {
                    showingUpgradePrompt = true
                }
            }
        }
    }

    private func handleArtistTap(_ artist: Artist) {
        replacingArtist = artist
        showingReplaceOptions = true
    }

    private func removeArtist(_ artist: Artist) {
        if selectedArtists.count > 1 {
            selectedArtists.remove(artist)
        }
    }

    private func loadAvailableArtists() {
        // Simulate loading with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Mock data - replace with actual data loading
            availableArtists = [
                Artist(name: "IU", group: "Solo", imageURL: "", category: .popular, isPopular: true, isTrending: true, fanFavorite: true),
                Artist(name: "NewJeans", group: "NewJeans", imageURL: "", category: .trending, isPopular: true, isTrending: true, fanFavorite: false),
                Artist(name: "aespa", group: "aespa", imageURL: "", category: .popular, isPopular: true, isTrending: false, fanFavorite: true),
                Artist(name: "BLACKPINK", group: "BLACKPINK", imageURL: "", category: .popular, isPopular: true, isTrending: false, fanFavorite: true),
                Artist(name: "BTS", group: "BTS", imageURL: "", category: .popular, isPopular: true, isTrending: true, fanFavorite: true),
                Artist(name: "TWICE", group: "TWICE", imageURL: "", category: .fanFavorites, isPopular: true, isTrending: false, fanFavorite: true),
                Artist(name: "Stray Kids", group: "Stray Kids", imageURL: "", category: .trending, isPopular: true, isTrending: true, fanFavorite: false),
                Artist(name: "(G)I-DLE", group: "(G)I-DLE", imageURL: "", category: .girlGroups, isPopular: true, isTrending: true, fanFavorite: false),
                Artist(name: "ITZY", group: "ITZY", imageURL: "", category: .girlGroups, isPopular: true, isTrending: false, fanFavorite: true),
                Artist(name: "LE SSERAFIM", group: "LE SSERAFIM", imageURL: "", category: .rookies, isPopular: false, isTrending: true, fanFavorite: false)
            ]

            withAnimation(.easeOut) {
                isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

struct SelectedArtistCard: View {
    let artist: Artist
    let canRemove: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Artist image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Text(String(artist.name.prefix(2)).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )

                // Remove button
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Color.white, in: Circle())
                            .font(.system(size: 20))
                    }
                    .offset(x: 8, y: -8)
                }

                // Selected indicator
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .background(Color.white, in: Circle())
                            .font(.system(size: 16))
                    }
                }
                .padding(8)
            }

            VStack(spacing: 2) {
                Text(artist.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(artist.group)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Artist image placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Text(String(artist.name.prefix(2)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )

                // Selection indicator
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(Color.white, in: Circle())
                                .font(.system(size: 20))
                        }
                        Spacer()
                    }
                    .padding(12)
                }

                // Trending badge
                if artist.isTrending {
                    VStack {
                        HStack {
                            Text("🔥")
                                .font(.system(size: 16))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }

            VStack(spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(artist.group)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .onTapGesture {
            onTap()
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct CategoryButton: View {
    let category: ArtistCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(category.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))

            TextField("Search artists or groups...", text: $text)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))

            Text("No Artists Selected")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("Browse and select your favorite artists")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Replace Artist View
struct ReplaceArtistView: View {
    @Environment(\.dismiss) private var dismiss
    let artistToReplace: Artist
    let availableArtists: [Artist]
    let onReplace: (Artist) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.primaryGradient
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Current artist being replaced
                    PiggySection("Replacing") {
                        SelectedArtistCard(
                            artist: artistToReplace,
                            canRemove: false,
                            onTap: {},
                            onRemove: {}
                        )
                        .frame(width: 120)
                    }

                    // Available replacements
                    PiggySection("Choose Replacement") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(availableArtists, id: \.self) { artist in
                                ArtistCard(
                                    artist: artist,
                                    isSelected: false,
                                    onTap: {
                                        onReplace(artist)
                                    }
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .piggyPadding()
            }
            .navigationTitle("Replace Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct UpgradePromptView: View {
    @Environment(\.dismiss) private var dismiss
    let userTier: UserTier

    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.primaryGradient
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.3), radius: 10)

                        VStack(spacing: 8) {
                            Text("Want More Artists?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Upgrade to Premium and follow up to \(UserTier.premium.maxArtists) artists instead of \(userTier.maxArtists)")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                    }

                    // Benefits list
                    PiggyCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Follow up to 6 artists")
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Priority notifications")
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Advanced budget features")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .padding(20)
                    }

                    VStack(spacing: 16) {
                        PiggyButton("Upgrade to Premium", style: .primary, size: .large) {
                            // Handle upgrade
                            dismiss()
                        }

                        PiggyButton("Maybe Later", style: .tertiary, size: .medium) {
                            dismiss()
                        }
                    }
                    .piggyPadding()

                    Spacer()
                }
                .piggyPadding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - PiggyGradients (Placeholder)
struct PiggyGradients {
    static let background = LinearGradient(
        colors: [
            Color.purple.opacity(0.8),
            Color.pink.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Preview
struct ManageArtistsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageArtistsView(
            currentArtists: [
                Artist(name: "IU", group: "Solo", imageURL: "", category: .popular, isPopular: true, isTrending: true, fanFavorite: true),
                Artist(name: "NewJeans", group: "NewJeans", imageURL: "", category: .trending, isPopular: true, isTrending: true, fanFavorite: false)
            ],
            userTier: .free
        ) { artists in
            print("Updated artists: \(artists)")
        }
    }
}