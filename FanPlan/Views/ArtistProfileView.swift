import SwiftUI

struct ArtistProfileView: View {
    let artist: FanArtist
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @StateObject private var smartFanPickService = SmartFanPickService.shared
    @State private var showingRemoveConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessToast = false

    var body: some View {
        ZStack {
            // Background gradient matching home tab
            PiggyGradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing for navigation bar
                    Spacer()
                        .frame(height: PiggySpacing.sm)

                    VStack(spacing: PiggySpacing.xl) {
                        // 1. Artist Header
                        artistHeader
                            .padding(.horizontal, PiggySpacing.md)

                        // 2. Recent Smart Picks
                        recentSmartPicksSection

                        // 3. Remove Artist Button
                        removeArtistSection
                            .padding(.horizontal, PiggySpacing.md)
                    }
                    .padding(.bottom, PiggySpacing.xl)
                }
            }

            // Success Toast overlay
            if showSuccessToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Artist removed successfully!")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.white)
                            .padding(PiggySpacing.md)
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            .padding(.bottom, PiggySpacing.xl)
                        Spacer()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.large)
        .piggyModal(
            "Remove \(artist.name)?",
            subtitle: "This will remove \(artist.name) from your artists list. You can always add them back later.",
            isPresented: $showingRemoveConfirmation,
            style: .alert,
            size: .small,
            showCloseButton: false,
            isDismissible: true
        ) {
            VStack(spacing: PiggySpacing.lg) {
                HStack(spacing: PiggySpacing.md) {
                    PiggyButton(
                        title: "Cancel",
                        action: {
                            showingRemoveConfirmation = false
                        },
                        style: .secondary,
                        size: .medium
                    )

                    PiggyButton(
                        title: "Remove",
                        action: {
                            showingRemoveConfirmation = false
                            removeArtist()
                        },
                        style: .destructive,
                        size: .medium
                    )
                }
            }
            .padding(.top, PiggySpacing.sm)
        }
        .alert("Failed to Remove Artist", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Artist Header
    private var artistHeader: some View {
        VStack(spacing: PiggySpacing.md) {
            // Artist Avatar
            PiggyAvatarCircle(
                text: artist.name,
                size: .custom(120),
                style: .artistGradient,
                showBorder: false
            )

            // Artist Name
            Text(artist.name)
                .font(PiggyFont.largeTitle.weight(.bold))
                .foregroundColor(.piggyTextPrimary) // White text like home tab
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Fan spending insights")
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyTextSecondary)
        }
        .padding(.top, PiggySpacing.lg)
    }

    // MARK: - Recent Smart Picks Section
    private var recentSmartPicksSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section Header - matching home tab style
            Text("Recent Activity")
                .font(PiggyFont.sectionTitle)
                .foregroundColor(.piggyTextPrimary)
                .padding(.horizontal, PiggySpacing.md)

            // Show artist-specific events
            let artistEvents = smartFanPickService.getEventsForArtist(artist.name)

            if !artistEvents.isEmpty {
                VStack(spacing: PiggySpacing.sm) {
                    ForEach(artistEvents.prefix(3)) { event in
                        recentActivityRow(event: event)
                            .padding(.horizontal, PiggySpacing.md)
                    }
                }
            } else {
                // No events for this artist - using PiggyCard for consistency
                PiggyCard(style: .elevated, cornerRadius: .medium) {
                    VStack(spacing: PiggySpacing.md) {
                        Image(systemName: "calendar")
                            .font(.system(size: PiggyIcon.large))
                            .foregroundColor(.piggyTextSecondary)

                        Text("No recent activity")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)

                        Text("Start tracking activities with \(artist.name)")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(PiggySpacing.lg)
                }
                .padding(.horizontal, PiggySpacing.md)
            }
        }
    }

    private func recentActivityRow(event: SmartFanPickEvent) -> some View {
        PiggyCard(style: .secondary, cornerRadius: .medium) {
            HStack(spacing: PiggySpacing.sm) {
                // Event Category Icon
                Image(systemName: eventTypeIcon(for: event.eventType))
                    .font(.system(size: PiggyIcon.medium))
                    .foregroundColor(.piggyAccent)
                    .frame(width: 32, height: 32)

                // Event Details
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Text(event.eventTitle)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextPrimary)
                        .lineLimit(2)

                    Text(RelativeDateTimeFormatter().localizedString(for: event.eventDate ?? event.detectedAt, relativeTo: Date()))
                        .font(PiggyFont.caption2)
                        .foregroundColor(.piggyTextSecondary)
                }

                Spacer()

                // Priority indicator
                if event.recommendedPriority == .high {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(PiggySpacing.md)
        }
    }

    // MARK: - Remove Artist Section
    private var removeArtistSection: some View {
        Button(action: { showingRemoveConfirmation = true }) {
            PiggyCard(style: .secondary, cornerRadius: .large) {
                HStack {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: PiggyIcon.medium))
                        .foregroundColor(.red)

                    Text("Remove \(artist.name)")
                        .font(PiggyFont.body)
                        .foregroundColor(.red)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: PiggyIcon.small))
                        .foregroundColor(.piggyTextTertiary)
                }
                .padding(PiggySpacing.md)
            }
        }
    }

    // MARK: - Actions
    private func removeArtist() {
        Task {
            // Show loading state with GlobalLoadingManager
            globalLoading.show(for: .dataSync, simpleMode: true)

            // Use FanDashboardService to remove the artist
            let success = await FanDashboardService.shared.removeArtist(artist.id)

            globalLoading.hide()

            if success {
                // Show success toast briefly
                showSuccessToast = true

                // Auto-hide toast after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSuccessToast = false
                }

                // Navigate back after a short delay to show the toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // Navigation will happen automatically when artist is removed
                    // The parent view will handle navigation back
                }
            } else {
                // Show error alert
                errorMessage = "Failed to remove \(artist.name). Please try again."
                showErrorAlert = true
                print("❌ Failed to remove artist: \(artist.name)")
            }
        }
    }

    // MARK: - Helper Methods
    private func eventTypeIcon(for eventType: FanEventType) -> String {
        switch eventType {
        case .comeback:
            return "music.note"
        case .tour:
            return "location"
        case .album:
            return "opticaldisc"
        case .merch:
            return "bag"
        case .social:
            return "heart"
        case .fanmeet:
            return "person.2"
        }
    }
}

#Preview {
    ArtistProfileView(artist: FanArtist.mockArtists[0])
        .environmentObject(SubscriptionService.shared)
        .environmentObject(GlobalLoadingManager.shared)
}