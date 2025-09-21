import SwiftUI

// MARK: - Reusable Artist Grid Selection View
struct ArtistGridSelectionView: View {
    // MARK: - Required Properties
    let allArtists: [Artist]
    @Binding var selectedArtists: [Artist]

    // MARK: - Optional Configuration
    var maxSelection: Int? = nil
    var hideSelectedArtists: Bool = false
    var showSelectionOrder: Bool = false
    var onSelectionChange: ((Artist, Bool) -> Void)? = nil
    var onMaxLimitReached: (() -> Void)? = nil // For paywall trigger

    // MARK: - Internal State
    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool

    // MARK: - Grid Configuration
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Computed Properties
    private var selectedArtistIDs: Set<UUID> {
        Set(selectedArtists.map { $0.id })
    }

    private var isAtMaxLimit: Bool {
        guard let maxSelection = maxSelection else { return false }
        return selectedArtists.count >= maxSelection
    }

    private var filteredArtists: [Artist] {
        var artists = allArtists

        // Apply search filter
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchQuery.lowercased()
            artists = artists.filter { artist in
                artist.name.lowercased().contains(query) ||
                (artist.group?.lowercased().contains(query) ?? false)
            }
        }

        // Apply hide selected filter (only when not searching)
        if hideSelectedArtists && searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            artists = artists.filter { !selectedArtistIDs.contains($0.id) }
        }

        return artists
    }

    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Search Bar
            searchBarSection

            // Artists Grid
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: PiggySpacing.md) {
                    ForEach(filteredArtists, id: \.id) { artist in
                        ReusableArtistCard(
                            artist: artist,
                            isSelected: selectedArtistIDs.contains(artist.id),
                            isDisabled: !selectedArtistIDs.contains(artist.id) && isAtMaxLimit,
                            selectionOrder: showSelectionOrder ? getSelectionOrder(for: artist) : nil,
                            onTap: { handleArtistTap(artist) }
                        )
                    }
                }
                .padding(.horizontal, PiggySpacing.md)
            }
        }
    }

    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        HStack(spacing: PiggySpacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.piggyTextSecondary)

                TextField("Search artists or groups...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.piggyTextPrimary)
                    .accentColor(.piggyPrimary)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .font(.system(size: 16, weight: .regular))
                    .autocorrectionDisabled()

                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.piggyTextSecondary)
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
        .padding(.horizontal, PiggySpacing.md)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }

    // MARK: - Helper Methods
    private func handleArtistTap(_ artist: Artist) {
        let isCurrentlySelected = selectedArtistIDs.contains(artist.id)

        if isCurrentlySelected {
            // Deselect artist
            selectedArtists.removeAll { $0.id == artist.id }
            onSelectionChange?(artist, false)
        } else {
            // Check max limit before selecting
            if let maxSelection = maxSelection, selectedArtists.count >= maxSelection {
                // Trigger paywall or limit reached callback
                onMaxLimitReached?()
                return
            }

            // Select artist
            selectedArtists.append(artist)
            onSelectionChange?(artist, true)
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func getSelectionOrder(for artist: Artist) -> Int? {
        guard let index = selectedArtists.firstIndex(where: { $0.id == artist.id }) else {
            return nil
        }
        return index + 1 // Convert to 1-based ordering
    }
}

// MARK: - Reusable Artist Card Component
struct ReusableArtistCard: View {
    let artist: Artist
    let isSelected: Bool
    let isDisabled: Bool
    let selectionOrder: Int?
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                    .fill(cardBackgroundColor)
                    .aspectRatio(1.5, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    )

                // Artist name
                Text(artist.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                // Selection order badge or status badge
                if let order = selectionOrder {
                    VStack {
                        HStack {
                            Spacer()
                            orderBadge(order: order)
                        }
                        Spacer()
                    }
                    .padding(6)
                } else if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            alreadyAddedBadge
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(cardOpacity)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.05), value: isPressed)
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

    // MARK: - Visual Properties
    private var cardBackgroundColor: Color {
        if isSelected {
            return Color.piggyPrimary.opacity(0.15)
        } else if isDisabled {
            return Color.white.opacity(0.05)
        } else {
            return Color.white.opacity(0.1)
        }
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.piggyPrimary
        } else if isDisabled {
            return Color.white.opacity(0.1)
        } else {
            return Color.white.opacity(0.3)
        }
    }

    private var strokeWidth: CGFloat {
        isSelected ? 2 : 1
    }

    private var textColor: Color {
        if isDisabled {
            return .piggyTextTertiary
        } else {
            return .piggyTextPrimary
        }
    }

    private var cardOpacity: Double {
        if isDisabled {
            return 0.5
        } else {
            return 1.0
        }
    }

    // MARK: - Badge Components
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

    private var alreadyAddedBadge: some View {
        Text("Added")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.piggyPrimary)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}