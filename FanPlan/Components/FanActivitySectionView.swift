import SwiftUI

// MARK: - Fan Activity Section View Component
struct FanActivitySectionView: View {
    let data: FanDashboardData
    let dashboardService: FanDashboardService
    @Binding var showQuickAdd: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header outside of card
            Text("Fan Activity")
                .font(PiggyFont.sectionTitle)
                .foregroundColor(.piggyTextPrimary)

            if data.recentActivity.isEmpty {
                // Empty State - single card
                emptyActivityCard
            } else {
                VStack(spacing: PiggySpacing.lg) {
                    // Activity List (3 latest entries) - single card
                    activityListCard(activities: data.recentActivity)

                    // See All Button (if more than 3 activities)
                    if data.recentActivity.count > 3 {
                        PiggyButton(
                            title: "See All",
                            action: { print("See All tapped") },
                            style: .secondary,
                            size: .medium
                        )
                        .padding(.horizontal, PiggySpacing.sm)  // Add 8pt breathing room
                    }

                    // AI Insight Section - already has its own card
                    if let insightMessage = dashboardService.insightMessage, !data.recentActivity.isEmpty {
                        PiggyCard(style: .primary) {
                            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                                Text("🧠 Fan Insight")
                                    .font(PiggyFont.headline)
                                    .foregroundColor(.piggyTextPrimary)

                                Text(insightMessage)
                                    .font(PiggyFont.body)
                                    .foregroundColor(.piggyTextSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State Card
    private var emptyActivityCard: some View {
        PiggyCard(style: .secondary) {
            VStack(spacing: PiggySpacing.md) {  // Reduced from lg (24pt) to md (16pt)
                VStack(spacing: PiggySpacing.xs) {
                    Text("Track Your Fan Purchases")
                        .font(PiggyFont.headline)
                        .foregroundColor(.piggyTextPrimary)

                    Text("Record your K-pop spending and build your fan priorities")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.center)
                }

                PiggyButton(
                    title: "Add Fan Activity",
                    action: { showQuickAdd = true },
                    style: .primary,
                    size: .medium
                )
                .padding(.horizontal, PiggySpacing.sm)  // Add 8pt breathing room
            }
        }
    }
    
    // MARK: - Activity List Card
    private func activityListCard(activities: [FanActivity]) -> some View {
        PiggyCard(style: .secondary) {
            VStack(spacing: 0) {
                // Activity List (3 latest entries)
                VStack(spacing: PiggySpacing.xs) {
                    let recentActivities: [SavedFanActivity] = Array(activities.prefix(3))
                    let enumeratedActivities: [(Int, SavedFanActivity)] = Array(recentActivities.enumerated())

                    ForEach(enumeratedActivities, id: \.1.id) { index, activity in
                        activityListItem(activity: activity, isLast: index == min(activities.count, 3) - 1)
                    }
                }
                
                // Add More Button
                Divider()
                    .foregroundColor(.piggyCardBorder)
                
                PiggyButton(
                    title: "Add Fan Activity",
                    action: { showQuickAdd = true },
                    style: .secondary,
                    size: .medium
                )
                .padding(.horizontal, PiggySpacing.sm)  // Add 8pt breathing room
            }
        }
    }
    
    // MARK: - Individual Activity List Item
    private func activityListItem(activity: FanActivity, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                // Emoji/Icon (based on fanCategory)
                Text(getCategoryEmoji(activity: activity))
                    .font(.system(size: 16))
                
                // Category Name
                Text(getCategoryName(activity: activity))
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                // Amount
                if let amount = activity.amount {
                    Text("$\(Int(amount))")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                }
                
                // Relative Date
                Text("• \(activity.createdAt.relativeString)")
                    .font(PiggyFont.caption)
                    .foregroundColor(.piggyTextSecondary)
            }
            .padding(.vertical, PiggySpacing.sm)
            
            if !isLast {
                Divider()
                    .foregroundColor(.piggyCardBorder.opacity(0.3))
            }
        }
    }
    
    // MARK: - Helper Methods for Activity Display
    private func getCategoryEmoji(activity: FanActivity) -> String {
        if let fanCategory = activity.fanCategory {
            return fanCategory.emoji
        }
        
        // Fallback based on title for activities without fanCategory
        let title = activity.title.lowercased()
        if title.contains("concert") || title.contains("show") || title.contains("ticket") {
            return "🎤"
        } else if title.contains("album") {
            return "💿"
        } else if title.contains("photocard") {
            return "📸"
        } else if title.contains("merch") {
            return "🛍️"
        } else if title.contains("digital") || title.contains("streaming") {
            return "📱"
        } else if title.contains("event") || title.contains("fanmeet") {
            return "👥"
        }
        return "📱" // Default
    }
    
    private func getCategoryName(activity: FanActivity) -> String {
        if let fanCategory = activity.fanCategory {
            return fanCategory.rawValue
        }
        
        // Fallback display based on activity type/title
        let title = activity.title.lowercased()
        if title.contains("concert") || title.contains("show") || title.contains("ticket") {
            return "Concert Prep"
        } else if title.contains("album") {
            return "Album Hunting"
        } else if title.contains("photocard") {
            return "Photocard Collecting"
        } else if title.contains("merch") {
            return "Merch Haul"
        } else if title.contains("digital") || title.contains("streaming") {
            return "Digital Content"
        } else if title.contains("event") || title.contains("fanmeet") {
            return "Fanmeet Prep"
        }
        return "Other"
    }
}

// MARK: - Preview
struct FanActivitySectionView_Previews: PreviewProvider {
    static var previews: some View {
        FanActivitySectionView(
            data: FanDashboardData.mock,
            dashboardService: FanDashboardService.shared,
            showQuickAdd: .constant(false)
        )
        .padding()
        .background(PiggyGradients.background)
    }
}