import SwiftUI

// MARK: - Usage Example for ManageArtistsView
// This file demonstrates how to integrate the improved ManageArtistsView into your app

struct ProfileView: View {
    @State private var selectedArtists: Set<Artist> = []
    @State private var showingManageArtists = false
    @State private var userTier: UserTier = .free

    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.primaryGradient
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // User's current artists display
                    currentArtistsSection

                    // Manage button
                    PiggyButton("Manage Artists", style: .secondary, size: .large) {
                        showingManageArtists = true
                    }

                    Spacer()
                }
                .piggyPadding()
            }
            .navigationTitle("Profile")
        }
        .fullScreenCover(isPresented: $showingManageArtists) {
            ManageArtistsView(
                currentArtists: selectedArtists,
                userTier: userTier
            ) { updatedArtists in
                selectedArtists = updatedArtists
            }
        }
        .onAppear {
            loadUserData()
        }
    }

    private var currentArtistsSection: some View {
        PiggySection("Your Artists") {
            if selectedArtists.isEmpty {
                PiggyEmptyState(
                    icon: "music.note",
                    title: "No Artists Yet",
                    message: "Add your favorite K-pop artists to get personalized recommendations",
                    actionTitle: "Add Artists"
                ) {
                    showingManageArtists = true
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(selectedArtists).sorted(by: { $0.name < $1.name }), id: \.self) { artist in
                        ArtistMiniCard(artist: artist)
                    }
                }
            }
        }
    }

    private func loadUserData() {
        // Simulate loading user's selected artists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedArtists = [
                Artist(name: "IU", group: "Solo", imageURL: "", category: .popular, isPopular: true, isTrending: true, fanFavorite: true),
                Artist(name: "NewJeans", group: "NewJeans", imageURL: "", category: .trending, isPopular: true, isTrending: true, fanFavorite: false)
            ]
        }
    }
}

// MARK: - Mini card for displaying artists in profile
struct ArtistMiniCard: View {
    let artist: Artist

    var body: some View {
        VStack(spacing: 8) {
            // Artist image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Text(String(artist.name.prefix(2)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(artist.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Dashboard Integration Example
struct DashboardView: View {
    @State private var selectedArtists: Set<Artist> = []
    @State private var showingManageArtists = false

    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.primaryGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome section
                        welcomeSection

                        // Artist section with quick access
                        artistSection

                        // Other dashboard content...
                    }
                    .piggyPadding()
                }
            }
            .navigationTitle("Dashboard")
        }
        .fullScreenCover(isPresented: $showingManageArtists) {
            ManageArtistsView(
                currentArtists: selectedArtists,
                userTier: .free
            ) { updatedArtists in
                selectedArtists = updatedArtists
            }
        }
    }

    private var welcomeSection: some View {
        PiggyCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Good morning!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Stay updated with your favorite artists")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }

    private var artistSection: some View {
        PiggySection(
            "Your Artists",
            actionTitle: "Manage",
            action: {
                showingManageArtists = true
            }
        ) {
            if selectedArtists.isEmpty {
                PiggyButton("Add Your First Artist", style: .secondary) {
                    showingManageArtists = true
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedArtists), id: \.self) { artist in
                            ArtistMiniCard(artist: artist)
                                .frame(width: 80)
                        }
                    }
                    .piggyPadding()
                }
                .padding(.horizontal, -16)
            }
        }
    }
}

// MARK: - Onboarding Integration Example
struct OnboardingArtistSelectionView: View {
    @State private var selectedArtists: Set<Artist> = []
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ZStack {
            PiggyGradients.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Onboarding header
                VStack(spacing: 16) {
                    Text("Choose Your Artists")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Select up to 3 K-pop artists you want to follow. You can always change this later.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .piggyPadding()
                }

                // Reuse the ManageArtistsView components
                ManageArtistsView(
                    currentArtists: selectedArtists,
                    userTier: .free
                ) { updatedArtists in
                    selectedArtists = updatedArtists

                    // Complete onboarding if minimum requirements met
                    if selectedArtists.count >= 1 {
                        isOnboardingComplete = true
                    }
                }
            }
        }
    }
}

// MARK: - Settings Integration Example
struct SettingsView: View {
    @State private var selectedArtists: Set<Artist> = []
    @State private var showingManageArtists = false
    @State private var userTier: UserTier = .free

    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.primaryGradient
                    .ignoresSafeArea()

                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Artists")
                                    .foregroundColor(.white)
                                Text("\(selectedArtists.count) of \(userTier.maxArtists) selected")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingManageArtists = true
                        }

                        HStack {
                            Text("Subscription")
                                .foregroundColor(.white)

                            Spacer()

                            PiggyBadge(
                                text: userTier == .free ? "Free" : "Premium",
                                style: userTier == .free ? .info : .success,
                                size: .small
                            )
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
                .piggyPadding()
            }
            .navigationTitle("Settings")
        }
        .fullScreenCover(isPresented: $showingManageArtists) {
            ManageArtistsView(
                currentArtists: selectedArtists,
                userTier: userTier
            ) { updatedArtists in
                selectedArtists = updatedArtists
            }
        }
    }
}

// MARK: - Preview
struct ManageArtistsUsageExample_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .previewDisplayName("Profile Integration")

            DashboardView()
                .previewDisplayName("Dashboard Integration")

            OnboardingArtistSelectionView(isOnboardingComplete: .constant(false))
                .previewDisplayName("Onboarding Integration")

            SettingsView()
                .previewDisplayName("Settings Integration")
        }
    }
}