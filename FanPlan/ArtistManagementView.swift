import SwiftUI

// MARK: - Artist Management View (Add/Remove Artists Post-Onboarding)

struct ArtistManagementView: View {
    @StateObject private var dashboardService = FanDashboardService.shared
    @StateObject private var idolManagementService = IdolManagementService.shared
    private let onboardingService = OnboardingService.shared
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingRemoveAlert = false
    @State private var artistToRemove: FanArtist?
    @State private var allArtists: [Artist] = []
    @State private var selectedArtists: [Artist] = []
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            PiggyGradients.background.ignoresSafeArea()

            // Main content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Header spacer for close button
                    Color.piggyClear.frame(height: 44)

                    // Header with consistent left padding
                    headerSection
                        .padding(.horizontal, PiggySpacing.lg)
                        .padding(.bottom, PiggySpacing.md)

                    // Current Idols Section
                    if !idolManagementService.userIdols.isEmpty {
                        currentIdolsSection
                            .padding(.horizontal, PiggySpacing.lg)
                            .padding(.bottom, PiggySpacing.md)
                    }

                    // Artist Selection Grid with tighter padding
                    ArtistGridSelectionView(
                        allArtists: allArtists,
                        selectedArtists: $selectedArtists,
                        maxSelection: idolManagementService.subscriptionStatus.idolLimit,
                        hideSelectedArtists: true,
                        showSelectionOrder: false,
                        onSelectionChange: { artist, isSelected in
                            handleArtistSelection(artist: artist, isSelected: isSelected)
                        },
                        onMaxLimitReached: {
                            // Handle upgrade flow - could show paywall
                            print("Show upgrade prompt for more artists")
                        }
                    )
                }
                .padding(.bottom, PiggySpacing.xl)
            }

            // Floating close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(Color.piggyTextPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.piggyBlack.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
            .zIndex(10)
        }
        .alert("Remove Idol", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let artist = artistToRemove {
                    removeIdol(artist)
                }
            }
        } message: {
            if let artist = artistToRemove {
                Text("Are you sure you want to remove \(artist.name) from your idols? This won't delete your fan activity history.")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Add Artists")
                .font(PiggyFont.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.piggyTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Add your favorite K-pop artists")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, PiggySpacing.lg)
    }
    
    
    // MARK: - Current Idols Section

    @ViewBuilder
    private var currentIdolsSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            PiggySectionHeader(
                "Your Idols (\(idolManagementService.currentIdolCount))",
                subtitle: "Tap to remove"
            )

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: PiggySpacing.md) {
                ForEach(idolManagementService.userIdols, id: \.id) { idol in
                    IdolManagementCard(idol: idol) {
                        // Convert IdolModel to FanArtist for compatibility
                        let fanArtist = FanArtist(
                            id: UUID(uuidString: idol.id) ?? UUID(),
                            name: idol.name,
                            priorityRank: 1,
                            monthlyAllocation: 0,
                            monthSpent: 0,
                            totalSpent: 0,
                            remainingBudget: 0,
                            spentPercentage: 0,
                            imageURL: idol.profileImageURL.isEmpty ? nil : idol.profileImageURL,
                            timeline: [],
                            wishlistItems: [],
                            priorities: []
                        )
                        artistToRemove = fanArtist
                        showingRemoveAlert = true
                    }
                }
            }
        }
    }


    // MARK: - Data Loading and Management

    private func loadData() {
        globalLoading.show(LoadingMessage.artistSelection, simpleMode: false, priority: .normal)

        Task {
            idolManagementService.loadUserIdols()

            // Load artists from OnboardingService with error handling
            print("🎯 Loading artists for ArtistManagementView...")

            // Get all available artists (includes fallback if database is empty)
            let availableArtists = onboardingService.availableArtists

            if availableArtists.isEmpty {
                // If still empty, use fallback artists
                print("🔄 No available artists, using fallback...")
                let fallbackPopularArtists = onboardingService.getFallbackArtists()
                allArtists = fallbackPopularArtists.map { $0.artist }
                print("✅ Loaded \(allArtists.count) fallback artists")
            } else {
                allArtists = availableArtists
                print("✅ Loaded \(allArtists.count) available artists")
            }

            // Ensure we have some artists to show
            if allArtists.isEmpty {
                print("⚠️ No artists available, creating minimal fallback")
                // Create minimal fallback to prevent black screen
                allArtists = [
                    Artist(id: UUID(), name: "BTS", group: "BTS", imageURL: nil),
                    Artist(id: UUID(), name: "BLACKPINK", group: "BLACKPINK", imageURL: nil),
                    Artist(id: UUID(), name: "NewJeans", group: "NewJeans", imageURL: nil)
                ]
            }

            // Update selected artists to match current idols
            // Update selected artists to match current idols
            await MainActor.run {
                selectedArtists = idolManagementService.userIdols.compactMap { idol in
                    allArtists.first { $0.id.uuidString == idol.id || $0.name == idol.name }
                }
            }

            await MainActor.run {
                globalLoading.hide()
            }
        }
    }

    private func handleArtistSelection(artist: Artist, isSelected: Bool) {
        Task {
            do {
                if isSelected {
                    // Add artist to idols
                    let _ = try await idolManagementService.addIdol(
                        artistId: artist.id,
                        artistName: artist.name,
                        imageURL: artist.imageURL
                    )
                } else {
                    // Remove artist from idols
                    let _ = try await idolManagementService.deleteIdol(artistId: artist.id)
                }
            } catch {
                await MainActor.run {
                    // Provide more user-friendly error messages
                    if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                        errorMessage = "Unable to connect to server. Please check your internet connection and try again."
                    } else if error.localizedDescription.contains("limit") {
                        errorMessage = error.localizedDescription
                    } else {
                        errorMessage = "Unable to add artist. Please try again later."
                    }
                    showError = true
                    // Revert the selection change
                    if isSelected {
                        selectedArtists.removeAll { $0.id == artist.id }
                    } else {
                        selectedArtists.append(artist)
                    }
                }
            }
        }
    }

    private func removeIdol(_ artist: FanArtist) {
        Task {
            do {
                guard let artistId = UUID(uuidString: artist.id.uuidString) else { return }
                let _ = try await idolManagementService.deleteIdol(artistId: artistId)

                // Update selected artists
                await MainActor.run {
                    selectedArtists.removeAll { $0.id == artistId }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to remove idol: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Idol Management Card

struct IdolManagementCard: View {
    let idol: IdolModel
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            PiggyCard(style: .secondary, cornerRadius: .medium) {
                VStack(spacing: PiggySpacing.sm) {
                    // Artist Image/Initial
                    ZStack {
                        PiggyAvatarCircle(
                            text: idol.name,
                            size: .large,
                            style: .artistGradient,
                            showBorder: true,
                            borderColor: .piggyTextTertiary.opacity(0.3)
                        )

                        // Remove overlay
                        Circle()
                            .fill(Color.piggyBlack.opacity(0.6))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color.piggyError)
                            )
                    }

                    // Artist Name
                    Text(idol.name)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    // Remove instruction
                    Text("Tap to remove")
                        .font(PiggyFont.caption1)
                        .foregroundColor(Color.piggyError.opacity(0.8))
                }
                .padding(PiggySpacing.md)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ArtistManagementView()
        .environmentObject(GlobalLoadingManager.shared)
}
