import SwiftUI

// MARK: - Events Feed View Component
struct EventsFeedView: View {
    let upcomingEvents: [UpcomingEvent]
    let onEventCardTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            HStack {
                HStack(spacing: PiggySpacing.sm) {
                    Text("Events Feed")
                        .font(PiggyFont.sectionTitle)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button("See all") {
                    // TODO: Navigate to events tab
                }
                .font(PiggyFont.body)
                .foregroundColor(.piggyPrimary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PiggySpacing.md) {
                    ForEach(upcomingEvents, id: \.id) { event in
                        eventCard(
                            category: event.eventType.rawValue.uppercased(),
                            title: event.title,
                            artist: event.artistName,
                            timestamp: timeAgoString(from: event),
                            categoryColor: colorFor(eventType: event.eventType)
                        )
                    }
                }
                .padding(.horizontal, PiggySpacing.xs)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func eventCard(category: String, title: String, artist: String, timestamp: String, categoryColor: Color) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            // Category badge and thumbnail
            HStack {
                Text(category)
                    .font(PiggyFont.badge)
                    .foregroundColor(.white)
                    .padding(.horizontal, PiggySpacing.sm)
                    .padding(.vertical, PiggySpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.badge)
                            .fill(categoryColor)
                    )

                Spacer()

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.8), categoryColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(artist.prefix(1)))
                            .font(PiggyFont.captionEmphasized)
                            .foregroundColor(.white)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                Text(title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(artist) • \(timestamp)")
                    .font(PiggyFont.caption1)
                    .foregroundColor(.gray)
            }

            Spacer(minLength: PiggySpacing.sm)

            // Subtle hint that card is tappable
            HStack {
                Text("Tap to check priority")
                    .font(PiggyFont.caption2)
                    .foregroundColor(.piggyTextSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(PiggyFont.badge)
                    .foregroundColor(.piggyTextTertiary)
            }
        }
        .frame(width: 240, alignment: .leading)
        .padding(PiggySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            // Add haptic feedback for better UX
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onEventCardTapped()
        }
    }
    
    private func timeAgoString(from event: UpcomingEvent) -> String {
        if let daysUntil = event.daysUntil {
            if daysUntil == 0 { return "Today" }
            if daysUntil == 1 { return "Tomorrow" }
            if daysUntil < 0 { return "\(abs(daysUntil)) days ago" }
            return "In \(daysUntil) days"
        }
        return "Recently announced"
    }
    
    private func colorFor(eventType: EventType) -> Color {
        switch eventType {
        case .comeback: return .purple
        case .concert: return .red
        case .albumRelease: return .orange
        case .merchandise: return .pink
        case .fanmeet: return .blue
        }
    }
}

// MARK: - Preview
#Preview {
    EventsFeedView(
        upcomingEvents: UpcomingEvent.mockEvents,
        onEventCardTapped: {
            print("Event card tapped")
        }
    )
    .padding()
    .background(PiggyGradients.background)
}