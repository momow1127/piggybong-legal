import SwiftUI

// MARK: - Fan Priority Manager View Component
struct FanPriorityManagerView: View {
    // Service dependencies
    let smartFanPickService: SmartFanPickService
    let subscriptionService: SubscriptionService
    let dashboardService: FanDashboardService
    
    // Binding dependencies for state updates
    @Binding var selectedSmartPickEvent: SmartFanPickEvent?
    @Binding var showPriorityAdjustment: Bool
    @Binding var showPurchaseCalculator: Bool
    
    // State for user priorities from database
    @State private var userPriorities: [UserPriority] = []
    
    var body: some View {
        Group {
            if let currentEvent = smartFanPickService.getCurrentEvent() {
                // Show dynamic event-driven Smart Fan Pick
                SmartFanPickCompactCard(
                    event: currentEvent,
                    insight: smartFanPickService.getInsightsForEvent(
                        currentEvent,
                        userPriorities: userPriorities,
                        isVIP: subscriptionService.isVIP
                    ).first ?? "Stay focused on your priorities!",
                    onTap: {
                        selectedSmartPickEvent = currentEvent
                        showPriorityAdjustment = true
                        smartFanPickService.markAsViewed(currentEvent.id)
                        smartFanPickService.trackEventAction(currentEvent.id, action: "tapped")
                    }
                )
                .environmentObject(subscriptionService)
                .onAppear {
                    smartFanPickService.markAsViewed(currentEvent.id)
                }
                .task {
                    // Load real user priorities from database
                    userPriorities = await smartFanPickService.loadUserPrioritiesForInsights()
                }
            } else {
                // Show static fallback when no events
                staticSmartFanCard
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var staticSmartFanCard: some View {
        Button(action: { 
            // Small sparkle animation on tap
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showPurchaseCalculator = true 
        }) {
            HStack(spacing: 12) { // Reduced spacing to give more room for text
                // Left content - Fixed width to prevent truncation
                VStack(alignment: .leading, spacing: PiggySpacing.md) {
                    // Title - Changed to "Piggy Bong AI" with AI icon after
                    HStack(spacing: PiggySpacing.xs) {
                        Text("Piggy Bong AI")
                            .font(PiggyFont.sectionTitle)
                            .foregroundColor(.white)
                        
                        Image("AI")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                    .lineLimit(1)
                    
                    // Description - Fix truncation issue
                    Text("Get personalized tips to set better priorities for your idols")
                        .font(.system(size: 14)) // Slightly smaller font to fit better
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3) // Allow 3 lines if needed
                        .minimumScaleFactor(0.9) // Allow slight scaling to fit
                    
                    // Manual secondary button styling - exceptional case
                    HStack(spacing: PiggySpacing.sm) {
                        Image(systemName: subscriptionService.isVIP ? "sparkles" : "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.piggyPrimary)
                        
                        Text(subscriptionService.isVIP ? "Show Insight" : "Upgrade to VIP")
                            .font(PiggyFont.captionEmphasized) // 13pt semibold rounded
                            .foregroundColor(.piggyPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8) // Allow scaling if needed
                    }
                    .padding(.horizontal, PiggySpacing.inputPadding) // Use design system token: 14pt
                    .padding(.vertical, PiggySpacing.inputVertical) // Use design system token: 12pt
                    .background(.white)
                    .cornerRadius(PiggyBorderRadius.button) // Already using design system token
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                            .stroke(Color.piggyTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .frame(width: 180) // Fixed width to prevent truncation
                
                Spacer() // Push pig to the right
                
                // Right visual element - Smaller pig with proper clipping
                ZStack {
                    Image("piggy-lightstick-crown")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 160) // Much smaller to fit properly
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 1, y: 1)
                        .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
                        .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 0)
                }
                .frame(width: 120, alignment: .center) // Match the image width
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                    .fill(PiggyGradients.primaryButton)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: Color.piggyPrimary.opacity(0.4),
                radius: 20,
                x: 0,
                y: 10
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Functions
    
    private func getSmartAlertMessage() -> String {
        guard let dashboardData = dashboardService.dashboardData,
              let firstArtist = dashboardData.uiFanArtists.first,
              let nextEvent = dashboardData.uiUpcomingEvents.first else {
            return "Check upcoming events and see if they match your priorities"
        }
        
        return "\(firstArtist.name) \(nextEvent.eventType.displayName.lowercased()) announced! Check if it matches your priorities"
    }
}

// MARK: - Preview
#Preview {
    FanPriorityManagerView(
        smartFanPickService: SmartFanPickService.shared,
        subscriptionService: SubscriptionService.shared,
        dashboardService: FanDashboardService.shared,
        selectedSmartPickEvent: .constant(nil),
        showPriorityAdjustment: .constant(false),
        showPurchaseCalculator: .constant(false)
    )
    .padding()
    .background(PiggyGradients.background)
}
