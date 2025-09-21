import SwiftUI

// MARK: - Artists Section View Component
struct ArtistsSectionView: View {
    let data: FanDashboardData
    let subscriptionService: SubscriptionService
    @Binding var showArtistManagement: Bool
    @Binding var showPaywall: Bool
    @Binding var selectedArtist: FanArtist?
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header outside of card
            HStack {
                Text("Your Idols")
                    .font(PiggyFont.sectionTitle)
                    .foregroundColor(.piggyTextPrimary)

                Spacer()

                // Plan limitation display
                if !data.fanArtists.isEmpty {
                    Text("\(data.fanArtists.count) / \(subscriptionService.isVIP ? 6 : 3) idols")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                }
            }

            // Idol circles directly on background - no card wrapper
            YourIdolsResponsiveLayout(
                idols: displayedIdols(data: data),
                currentCount: data.fanArtists.count,
                planLimit: subscriptionService.isVIP ? 6 : 3,
                isVIP: subscriptionService.isVIP,
                onIdolTap: { idol in handleIdolTap(artist: idol, data: data) },
                onAddTap: {
                    print("🎯 Add Artist button tapped!")
                    showArtistManagement = true
                },
                onUpgradeTap: { showPaywall = true }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func displayedIdols(data: FanDashboardData) -> [FanArtist] {
        if data.fanArtists.isEmpty {
            // Return placeholder idol to avoid empty state
            return [createPlaceholderIdol()]
        }
        return data.fanArtists
    }
    
    private func createPlaceholderIdol() -> FanArtist {
        FanArtist(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: "Select First Idol",
            priorityRank: 1,
            monthlyAllocation: 0.0,
            monthSpent: 0.0,
            totalSpent: 0.0,
            remainingBudget: 0.0,
            spentPercentage: 0.0,
            imageURL: nil,
            timeline: [],
            wishlistItems: [],
            priorities: []
        )
    }
    
    private func isPlaceholderIdol(_ idol: FanArtist) -> Bool {
        return idol.id.uuidString == "00000000-0000-0000-0000-000000000000"
    }
    
    private func handleIdolTap(artist: FanArtist, data: FanDashboardData) {
        // Handle placeholder tap
        if isPlaceholderIdol(artist) {
            showArtistManagement = true
            return
        }
        
        // Single tap = view idol profile (safe and accessible)
        selectedArtist = artist
    }
}

// MARK: - Smart Breakpoints Responsive Layout (moved from main view)
struct YourIdolsResponsiveLayout: View {
    let idols: [FanArtist]
    let currentCount: Int
    let planLimit: Int
    let isVIP: Bool
    let onIdolTap: (FanArtist) -> Void
    let onAddTap: () -> Void
    let onUpgradeTap: () -> Void
    
    private var shouldScroll: Bool {
        // Smart Breakpoint Logic:
        // Each idol ≈ 60pt avatar + 20pt spacing = 80pt
        // Add button = 80pt
        // Edge padding = 32pt (16pt each side)
        let totalItems = idols.count + 1 // +1 for Add/Upgrade button
        let estimatedWidth = CGFloat(totalItems * 80) + 32
        return estimatedWidth > UIScreen.main.bounds.width
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if shouldScroll {
                    ScrollView(.horizontal, showsIndicators: false) {
                        idolsContent
                    }
                } else {
                    idolsContent
                }
            }
        }
        .frame(height: 100) // Fixed height for consistent layout
    }
    
    @ViewBuilder
    private var idolsContent: some View {
        HStack(spacing: PiggySpacing.lg) {
            // Display selected idols (guaranteed at least 1)
            ForEach(idols, id: \.id) { idol in
                IdolPillView(
                    idol: idol,
                    onTap: { onIdolTap(idol) }
                )
            }

            // Add idol button - plan-aware behavior
            AddIdolButton(
                currentCount: currentCount,
                planLimit: planLimit,
                isVIP: isVIP,
                onAddTap: onAddTap,
                onUpgradeTap: onUpgradeTap
            )
        }
    }
    
    @ViewBuilder
    private func IdolPillView(idol: FanArtist, onTap: @escaping () -> Void) -> some View {
        let isPlaceholder = idol.name == "Select First Idol" // Simple placeholder check
        
        VStack(spacing: PiggySpacing.md) {
            PiggyAvatarCircle(
                text: idol.name,
                size: .large,
                style: isPlaceholder ? .solid(.piggyTextTertiary.opacity(0.2)) : .artistGradient,
                showBorder: true,
                borderColor: isPlaceholder ? .piggyTextTertiary.opacity(0.3) : .piggyPrimary,
                action: onTap
            )
            .frame(width: 44, height: 44) // Minimum 44pt touch target
            .opacity(isPlaceholder ? 0.6 : 1.0)
            
            Text(isPlaceholder ? "Add First" : idol.name)
                .font(PiggyFont.caption1)
                .foregroundColor(isPlaceholder ? .piggyTextTertiary : .piggyTextPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 60) // Fixed width for consistent spacing
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
        
        VStack(spacing: PiggySpacing.md) {
            PiggyAvatarCircle(
                text: "+",
                size: .large,
                style: .solid(isAtLimit ? .piggyTextTertiary.opacity(0.2) : .piggyTextTertiary.opacity(0.3)),
                showBorder: true,
                borderColor: isAtLimit ? .piggyTextTertiary.opacity(0.2) : .piggyTextTertiary.opacity(0.5),
                action: {
                    if isAtLimit && !isVIP {
                        onUpgradeTap()
                    } else if !isAtLimit {
                        print("🔘 Add Idol button action triggered!")
                        onAddTap()
                    }
                }
            )
            .frame(width: 44, height: 44) // Minimum 44pt touch target
            .opacity(isAtLimit && isVIP ? 0.4 : 1.0)
            
            Text(isAtLimit && !isVIP ? "Upgrade" : "Add Idol")
                .font(.caption)
                .foregroundColor(isAtLimit ? .piggyTextTertiary : .piggyTextSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 60) // Fixed width for consistent spacing
    }
}

// MARK: - Preview
struct ArtistsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistsSectionView(
            data: FanDashboardData.mock,
            subscriptionService: SubscriptionService.shared,
            showArtistManagement: .constant(false),
            showPaywall: .constant(false),
            selectedArtist: .constant(nil)
        )
        .padding()
        .background(PiggyGradients.background)
    }
}