import SwiftUI

// MARK: - Upcoming Events Section View Component
struct UpcomingEventsSectionView: View {
    let data: FanDashboardData
    let dashboardService: FanDashboardService
    let eventService: EventService
    @Binding var showEventList: Bool
    let tabSelection: TabSelection?
    @State private var selectedEvent: KPopEvent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header outside of card
            HStack {
                Text("Upcoming Events")
                    .font(PiggyFont.sectionTitle)
                    .foregroundColor(.piggyTextPrimary)

                Spacer()

                if !eventService.events.isEmpty {
                    Button("See All") {
                        // Switch to Events tab
                        if let tabSelection = tabSelection {
                            tabSelection.switchToEvents()
                        } else {
                            showEventList = true
                        }
                    }
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyAccent)
                }
            }

            if eventService.events.isEmpty {
                // Empty State - single card
                emptyStateView
            } else {
                // Show up to 3 events with DS styling - single card
                eventsListView
            }
        }
        .onAppear {
            Task {
                await eventService.loadEvents()
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        PiggyCard(style: .secondary) {
            VStack(spacing: PiggySpacing.md) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: PiggyIcon.emptyState))
                    .foregroundColor(.piggyTextSecondary)
                
                Text("No upcoming events")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Events List View
    
    private var eventsListView: some View {
        VStack(spacing: PiggySpacing.md) {
            ForEach(Array(eventService.events.prefix(3))) { event in
                Button(action: {
                    selectedEvent = event
                    HapticManager.medium()
                }) {
                    eventCardWithUrgency(event: event)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                PurchaseDecisionCalculatorView(
                    prefilledItem: event.calculatorPrefill
                )
                .navigationTitle("Priority Check")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            selectedEvent = nil
                        }
                        .foregroundColor(.piggyAccent)
                    }
                }
            }
        }
    }

    // MARK: - Event Card with Urgency Indicators

    @ViewBuilder
    private func eventCardWithUrgency(event: KPopEvent) -> some View {
        let urgency = getEventUrgency(event: event)

        PiggyCard(style: urgency.isUrgent ? .primary : .secondary) {
            HStack(spacing: PiggySpacing.md) {
                // Urgency indicator
                if urgency.isUrgent {
                    VStack(spacing: PiggySpacing.xs) {
                        Text(urgency.icon)
                            .font(.system(size: 16))

                        Text(urgency.label)
                            .font(PiggyFont.caption2)
                            .foregroundColor(.piggyTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    .frame(width: 44)
                }

                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    HStack(spacing: PiggySpacing.xs) {
                        Text(event.title)
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                            .lineLimit(1)

                        if urgency.isUrgent {
                            Text("•")
                                .font(PiggyFont.caption1)
                                .foregroundColor(urgency.color)

                            Text(urgency.timeLabel)
                                .font(PiggyFont.caption1)
                                .foregroundColor(urgency.color)
                                .fontWeight(.semibold)
                        }
                    }

                    if let summary = event.summary {
                        Text(summary)
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if !urgency.isUrgent {
                    Text(formatTimeAgo(event.publishedDate))
                        .font(PiggyFont.caption2)
                        .foregroundColor(.piggyTextTertiary)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Urgency Logic

    private func getEventUrgency(event: KPopEvent) -> EventUrgency {
        // Mock urgency logic - in real app this would be based on event.date
        let eventTitle = event.title.lowercased()

        // High urgency keywords for K-pop events
        if eventTitle.contains("pre-order") || eventTitle.contains("limited") {
            return EventUrgency(
                isUrgent: true,
                icon: "⚡",
                label: "urgent",
                timeLabel: "2 days left",
                color: .orange
            )
        } else if eventTitle.contains("ticket") || eventTitle.contains("sale") {
            return EventUrgency(
                isUrgent: true,
                icon: "🎫",
                label: "soon",
                timeLabel: "1 week",
                color: .yellow
            )
        } else if eventTitle.contains("comeback") || eventTitle.contains("release") {
            return EventUrgency(
                isUrgent: true,
                icon: "🔥",
                label: "hot",
                timeLabel: "trending",
                color: .red
            )
        }

        return EventUrgency(isUrgent: false, icon: "", label: "", timeLabel: "", color: .clear)
    }
}

// MARK: - Event Urgency Model

private struct EventUrgency {
    let isUrgent: Bool
    let icon: String
    let label: String
    let timeLabel: String
    let color: Color
}

// MARK: - Preview
struct UpcomingEventsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Preview with events
            UpcomingEventsSectionView(
                data: FanDashboardData.mock,
                dashboardService: FanDashboardService.shared,
                eventService: EventService.shared,
                showEventList: .constant(false),
                tabSelection: nil
            )

            // Preview with empty state
            UpcomingEventsSectionView(
                data: FanDashboardData.mock,
                dashboardService: FanDashboardService.shared,
                eventService: EventService.shared,
                showEventList: .constant(false),
                tabSelection: nil
            )
        }
        .padding()
        .background(PiggyGradients.background)
    }
}