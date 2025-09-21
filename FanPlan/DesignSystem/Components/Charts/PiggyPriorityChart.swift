import SwiftUI

// MARK: - PiggyBong Priority Chart Component  
// Reusable priority visualization extracted from OnboardingInsightView

struct PiggyPriorityChart: View {
    
    // MARK: - Properties
    let categoryPriorities: [String: PriorityLevel]
    let showTitle: Bool
    let showPriorityList: Bool
    
    @State private var barAnimationProgress: CGFloat = 0
    
    // MARK: - Initializer
    init(
        categoryPriorities: [String: PriorityLevel] = [:],
        showTitle: Bool = true,
        showPriorityList: Bool = true
    ) {
        self.categoryPriorities = categoryPriorities
        self.showTitle = showTitle
        self.showPriorityList = showPriorityList
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.lg) {
            if showTitle {
                Text("Your Fan Priorities")
                    .font(PiggyFont.headline)
                    .foregroundColor(.piggyTextPrimary)
            }
            
            // Stacked Horizontal Bar
            stackedPriorityBar
            
            // Caption under bar
            Text("Here's how your fan plan is balanced 🎶")
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyTextSecondary)
                .padding(.bottom, PiggySpacing.xs)
            
            // Priority List
            if showPriorityList {
                VStack(spacing: PiggySpacing.md) {
                    ForEach(Array(getSortedCategories().enumerated()), id: \.0) { index, category in
                        HStack(spacing: PiggySpacing.sm) {
                            Text(category.iconName)
                                .font(.system(size: PiggyIcon.small))
                            
                            Text(category.title)
                                .font(PiggyFont.body)
                                .foregroundColor(.piggyTextPrimary)
                            
                            Spacer()
                            
                            Text(getPriorityLabel(for: category.id))
                                .font(PiggyFont.caption1)
                                .foregroundColor(.white)
                                .frame(width: 65)
                                .padding(.vertical, PiggySpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                                        .fill(getPriorityColor(for: category.id))
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.3)) {
                barAnimationProgress = 1.0
            }
        }
    }
    
    // MARK: - Stacked Bar Visualization
    private var stackedPriorityBar: some View {
        let segments = calculateBarSegments()
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 14)
                
                // Segments with spacing
                HStack(spacing: 2) {
                    ForEach(segments) { segment in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        segment.color.opacity(0.9),
                                        segment.color
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: safeFrameWidth(geometry: geometry, segment: segment), height: 14)
                            .animation(
                                .easeOut(duration: 0.4)
                                    .delay(segment.animationDelay),
                                value: barAnimationProgress
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            }
            .frame(height: 14)
        }
        .frame(height: 14)
        .accessibilityLabel(generateBarAccessibilityLabel())
    }
    
    // MARK: - Helper Functions

    private func safeFrameWidth(geometry: GeometryProxy, segment: PriorityBarSegment) -> CGFloat {
        let geometryWidth = NaNSafetyHelper.safeWidth(geometry.size.width)
        let segmentWidth = NaNSafetyHelper.safeCGFloat(segment.width)
        let animationProgress = NaNSafetyHelper.safeAnimationProgress(barAnimationProgress)

        // Use NaNSafetyHelper for safe calculations
        let rawCalculation = NaNSafetyHelper.safeDivision(
            geometryWidth * segmentWidth * animationProgress,
            1.0,
            fallback: 0
        ) - 2

        return NaNSafetyHelper.safeWidth(rawCalculation, maxWidth: geometryWidth)
    }

    private func getSortedCategories() -> [SpendingCategory] {
        let categories: [SpendingCategory] = [
            SpendingCategory(id: "concerts", title: "Concerts & Shows", subtitle: "Tickets, tours, fanmeets", hint: "$100–$400 per show", iconName: "🎤"),
            SpendingCategory(id: "albums", title: "Albums & Photocards", subtitle: "Physical albums, versions", hint: "$15–$30 per album", iconName: "💿"),
            SpendingCategory(id: "merch", title: "Official Merch", subtitle: "Lightsticks, apparel", hint: "$15–$80 per item", iconName: "🛍️"),
            SpendingCategory(id: "events", title: "Fan Events (KCON, Hi‑Touch)", subtitle: "KCON, fan sign/meet", hint: "$45–$1,700 per event", iconName: "👥"),
            SpendingCategory(id: "subs", title: "Subscriptions & Fan Apps", subtitle: "Streaming, Weverse/Bubble", hint: "$4–$20 per month", iconName: "📱")
        ]
        
        // Sort by priority from categoryPriorities or use default order
        return categories.sorted { first, second in
            let firstPriority = categoryPriorities[first.id] ?? .low
            let secondPriority = categoryPriorities[second.id] ?? .low
            
            let priorityOrder: [PriorityLevel] = [.high, .medium, .low]
            let firstIndex = priorityOrder.firstIndex(of: firstPriority) ?? 2
            let secondIndex = priorityOrder.firstIndex(of: secondPriority) ?? 2
            
            return firstIndex < secondIndex
        }
    }
    
    private func calculateBarSegments() -> [PriorityBarSegment] {
        let weights: [PriorityLevel: CGFloat] = [
            .high: 40,
            .medium: 25,
            .low: 10
        ]
        
        // Count priorities
        var priorityCounts: [PriorityLevel: Int] = [:]
        for (_, priority) in categoryPriorities {
            priorityCounts[priority, default: 0] += 1
        }
        
        // Handle empty case
        if priorityCounts.isEmpty {
            return [PriorityBarSegment(
                id: "placeholder",
                width: 1.0,
                color: .gray.opacity(0.3),
                priority: .low,
                animationDelay: 0
            )]
        }
        
        // Calculate total weighted sum
        let totalWeight = priorityCounts.reduce(0) { sum, pair in
            sum + (CGFloat(pair.value) * (weights[pair.key] ?? 0))
        }

        // Prevent division by zero
        guard totalWeight > 0 else {
            return [PriorityBarSegment(
                id: "zero-weight",
                width: 1.0,
                color: .gray.opacity(0.3),
                priority: .low,
                animationDelay: 0
            )]
        }
        
        // Create segments
        var segments: [PriorityBarSegment] = []
        var animationDelay: Double = 0
        
        // Order: High → Medium → Low
        let priorityOrder: [PriorityLevel] = [.high, .medium, .low]
        
        for priority in priorityOrder {
            guard let count = priorityCounts[priority], count > 0 else { continue }
            
            let weight = weights[priority] ?? 0
            let rawWidth = (CGFloat(count) * weight) / totalWeight

            // Ensure width is finite and valid
            guard rawWidth.isFinite && rawWidth >= 0 else { continue }
            let width = min(rawWidth, 1.0) // Cap at 100%
            
            segments.append(PriorityBarSegment(
                id: priority.rawValue,
                width: width,
                color: getColorForPriority(priority),
                priority: priority,
                animationDelay: animationDelay
            ))
            
            animationDelay += 0.12
        }
        
        return segments
    }
    
    private func getColorForPriority(_ priority: PriorityLevel) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    private func getPriorityLabel(for categoryId: String) -> String {
        let priority = categoryPriorities[categoryId] ?? .low
        switch priority {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    private func getPriorityColor(for categoryId: String) -> Color {
        let priority = categoryPriorities[categoryId] ?? .low
        return getColorForPriority(priority)
    }
    
    private func generateBarAccessibilityLabel() -> String {
        var counts: [PriorityLevel: Int] = [:]
        for (_, priority) in categoryPriorities {
            counts[priority, default: 0] += 1
        }
        
        var parts: [String] = []
        if let high = counts[.high], high > 0 {
            parts.append("High \(high) items")
        }
        if let medium = counts[.medium], medium > 0 {
            parts.append("Medium \(medium) items")
        }
        if let low = counts[.low], low > 0 {
            parts.append("Low \(low) items")
        }
        
        if parts.isEmpty {
            return "No priorities set"
        }
        
        return "Priority mix: " + parts.joined(separator: ", ")
    }
}

// MARK: - Supporting Models
struct PriorityBarSegment: Identifiable {
    let id: String
    let width: CGFloat
    let color: Color
    let priority: PriorityLevel
    let animationDelay: Double
}

// SpendingCategory model for priority chart
struct SpendingCategory: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let hint: String
    let iconName: String
}

// MARK: - Preview
#Preview("Priority Chart") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.xl) {
            // Configured chart
            PiggyCard(style: .primary) {
                PiggyPriorityChart(
                    categoryPriorities: [
                        "concerts": .high,
                        "albums": .high,
                        "merch": .medium,
                        "events": .medium,
                        "subs": .low
                    ]
                )
                .padding(PiggySpacing.lg)
            }
            
            // Empty state chart
            PiggyCard(style: .secondary) {
                PiggyPriorityChart(categoryPriorities: [:])
                    .padding(PiggySpacing.lg)
            }
        }
        .padding(PiggySpacing.lg)
    }
}