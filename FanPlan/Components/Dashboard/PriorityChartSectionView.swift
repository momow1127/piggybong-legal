import SwiftUI

// MARK: - Priority Chart Section View Component
struct PriorityChartSectionView: View {
    let data: FanDashboardData

    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header outside of card
            Text("Your Fan Priorities")
                .font(PiggyFont.sectionTitle)
                .foregroundColor(.piggyTextPrimary)

            // Single card for the priority content
            PiggyCard(style: .primary) {
                VStack(spacing: PiggySpacing.md) {
                    // Top priority highlight
                    topPriorityFocus

                    // Priority ranking list
                    priorityRankingList
                }
            }
        }
    }

    // MARK: - Top Priority Focus
    @ViewBuilder
    private var topPriorityFocus: some View {
        let topPriority = getTopPriorityCategory()

        HStack(spacing: PiggySpacing.sm) {
            Text("🎯")
                .font(.title2)

            VStack(spacing: PiggySpacing.xs) {
                Text("#1 FOCUS")
                    .font(PiggyFont.caption)
                    .foregroundColor(.piggyTextSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Text(topPriority.displayName)
                    .font(PiggyFont.headline)
                    .foregroundColor(.piggyTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Priority Ranking List
    @ViewBuilder
    private var priorityRankingList: some View {
        let sortedCategories = getSortedCategories()

        VStack(spacing: PiggySpacing.sm) {
            ForEach(0..<sortedCategories.count, id: \.self) { index in
                priorityRowView(for: sortedCategories[index], ranking: index + 1)
            }
        }
    }

    @ViewBuilder
    private func priorityRowView(for category: FanCategoryWithIcon, ranking: Int) -> some View {
        let isTopPriority = ranking == 1

        HStack(spacing: PiggySpacing.md) {
            // Tag-style badge
            priorityBadge(ranking: ranking, isTop: isTopPriority)

            // Icon
            Text(category.icon)
                .font(.system(size: 20))

            // Category name
            Text(category.displayName)
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

        }
    }

    @ViewBuilder
    private func priorityBadge(ranking: Int, isTop: Bool) -> some View {
        Group {
            if ranking == 1 {
                Image("trophy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.piggyBlack)
                    .frame(width: 16, height: 16)
            } else {
                Text("\(ranking)")
                    .font(PiggyFont.captionEmphasized)
                    .foregroundColor(.piggyTextPrimary)
            }
        }
        .frame(width: 28, height: 28)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                .fill(isTop ? Color.yellow.opacity(0.6) : Color.piggyTextSecondary.opacity(0.2))
        )
    }
    
    // MARK: - Helper Functions

    private func loadCategoryPriorities() -> [String: PriorityLevel] {
        guard let data = UserDefaults.standard.data(forKey: "onboarding_category_priorities"),
              let priorities = try? JSONDecoder().decode([String: PriorityLevel].self, from: data) else {
            // Return default priorities if onboarding not completed
            return [
                "concerts": .medium,
                "albums": .medium,
                "merch": .low,
                "events": .low,
                "subs": .low
            ]
        }
        return priorities
    }

    private func getSortedCategories() -> [FanCategoryWithIcon] {
        let categories: [FanCategory] = [
            .concerts,
            .albums,
            .merch,
            .events,
            .subscriptions
        ]

        let categoryPriorities = loadCategoryPriorities()

        // Sort by priority from categoryPriorities
        return categories.sorted { first, second in
            let firstPriority = categoryPriorities[getCategoryId(first)] ?? .low
            let secondPriority = categoryPriorities[getCategoryId(second)] ?? .low

            let priorityOrder: [PriorityLevel] = [.high, .medium, .low]
            let firstIndex = priorityOrder.firstIndex(of: firstPriority) ?? 2
            let secondIndex = priorityOrder.firstIndex(of: secondPriority) ?? 2

            return firstIndex < secondIndex
        }
    }

    private func getCategoryId(_ category: FanCategory) -> String {
        switch category {
        case .concerts: return "concerts"
        case .albums: return "albums"
        case .merch: return "merch"
        case .events: return "events"
        case .subscriptions: return "subs"
        case .other: return "other"
        }
    }

    private func getTopPriorityCategory() -> FanCategoryWithIcon {
        let categories = getSortedCategories()
        return categories.first ?? FanCategory.concerts
    }
}

// MARK: - Preview
struct PriorityChartSectionView_Previews: PreviewProvider {
    static var previews: some View {
        PriorityChartSectionView(data: FanDashboardData.mock)
            .padding()
            .background(PiggyGradients.background)
    }
}