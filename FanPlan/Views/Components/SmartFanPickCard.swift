import SwiftUI

struct SmartFanPickCard: View {
    let event: SmartFanPickEvent
    let insights: [String]
    let onReprioritize: () -> Void
    let onDismiss: () -> Void
    
    @State private var currentInsightIndex = 0
    @State private var showingCard = false
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        VStack(spacing: 0) {
            // Event Badge & Header
            eventHeader
            
            // Main Content
            cardContent
                .padding(PiggySpacing.md)
        }
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8)
        .overlay(
            // New indicator pulse
            event.isNew ? newIndicator : nil,
            alignment: .topTrailing
        )
        .scaleEffect(showingCard ? 1 : 0.95)
        .opacity(showingCard ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingCard = true
            }
            startInsightRotation()
        }
    }
    
    // MARK: - Event Header
    
    private var eventHeader: some View {
        HStack(spacing: 8) {
            // Event Badge
            HStack(spacing: 4) {
                Text(event.eventType.badgeEmoji)
                    .font(.system(size: 12))
                
                Text(event.eventType.badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(event.eventType.color.opacity(0.9))
            )
            
            Spacer()
            
            // Time remaining
            if !event.isExpired {
                Text(event.timeUntilExpiry)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(PiggySpacing.sm)
        .background(Color(.systemBackground).opacity(0.5))
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Artist & Event Title
            VStack(alignment: .leading, spacing: 4) {
                Text(event.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(event.eventTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            // Priority Recommendation
            HStack {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(event.recommendedPriority.color)
                
                Text(event.recommendedPriority.displayText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.recommendedPriority.color.opacity(0.1))
            )
            
            // AI Insight (with rotation)
            insightSection
            
            // CTA Button
            ctaButton
        }
    }
    
    // MARK: - Insight Section
    
    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text("Smart Tip")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // VIP indicator
                if subscriptionService.isVIP && insights.count > 1 {
                    Text("\(currentInsightIndex + 1)/\(insights.count)")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            
            // Rotating insight text
            if !insights.isEmpty {
                Text(insights[currentInsightIndex])
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .animation(.easeInOut, value: currentInsightIndex)
            }
            
            // Lock message for non-VIP
            if !subscriptionService.isVIP && insights.count > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("Unlock \(insights.count - 1) more insights with VIP")
                        .font(.caption2)
                }
                .foregroundColor(.purple.opacity(0.8))
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        Button(action: {
            HapticManager.medium()
            onReprioritize()
        }) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                
                Text("Reprioritize My Plan")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.piggyPrimary, Color.piggySecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Visual Elements
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        event.isNew ? 
                        LinearGradient(
                            colors: [event.eventType.color, event.eventType.color.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: event.isNew ? 2 : 1
                    )
            )
    }
    
    private var newIndicator: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .scaleEffect(showingCard ? 1 : 0)
            .animation(
                Animation.spring(response: 0.6, dampingFraction: 0.5)
                    .delay(0.3),
                value: showingCard
            )
            .offset(x: -8, y: 8)
    }
    
    // MARK: - Helper Functions
    
    private func startInsightRotation() {
        guard subscriptionService.isVIP && insights.count > 1 else { return }
        
        // Rotate insights every 5 seconds for VIP users
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsightIndex = (currentInsightIndex + 1) % insights.count
            }
        }
    }
}

// MARK: - Compact Version for Dashboard

struct SmartFanPickCompactCard: View {
    let event: SmartFanPickEvent
    let insight: String
    let onTap: () -> Void
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            onTap()
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Haptic Manager

// HapticManager is defined in Utils/HapticManager.swift