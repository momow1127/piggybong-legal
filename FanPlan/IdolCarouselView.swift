import SwiftUI

// MARK: - Idol Carousel View Component
struct IdolCarouselView: View {
    let selectedIdols: [FanArtist]
    let onSelectIdol: ((FanArtist) -> Void)?
    let onTapAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Idols")
                .font(PiggyFont.sectionTitle)
                .foregroundColor(.white)
            
            // Always use horizontal scroll - familiar pattern from music/fan apps
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // + Add Idol bubble always first (as requested)
                    AddIdolBubbleView(onTapAdd: onTapAdd)
                    
                    // Idol bubbles - horizontal scroll recommended for more than 3
                    ForEach(selectedIdols, id: \.id) { artist in
                        idolBubble(name: artist.name, artist: artist)
                    }
                }
                .padding(.horizontal, 16) // Proper padding to prevent cut-off
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func idolBubble(name: String, artist: FanArtist) -> some View {
        VStack(spacing: 8) {
            // Simple non-interactive circle - no selection indicators
            Button(action: {
                onSelectIdol?(artist)
            }) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(String(name.prefix(3)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
            
            // Name label below circle
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(width: 64) // Consistent width for all circles
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Empty state
        IdolCarouselView(
            selectedIdols: [],
            onSelectIdol: { artist in print("Selected: \(artist.name)") },
            onTapAdd: { print("Add idol tapped") }
        )
        
        // With idols
        IdolCarouselView(
            selectedIdols: FanArtist.mockArtists,
            onSelectIdol: { artist in print("Selected: \(artist.name)") },
            onTapAdd: { print("Add idol tapped") }
        )
    }
    .padding()
    .background(PiggyGradients.background)
}