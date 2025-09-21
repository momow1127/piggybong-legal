import SwiftUI

// MARK: - Adaptive Dashboard Loading View
struct AdaptiveDashboardLoading: View {
    let expectedSections: [DashboardSection]
    let fallbackTimeout: TimeInterval

    @State private var showFallback = false

    init(
        expectedSections: [DashboardSection] = DashboardSection.defaultSections,
        fallbackTimeout: TimeInterval = 3.0
    ) {
        self.expectedSections = expectedSections
        self.fallbackTimeout = fallbackTimeout
    }

    var body: some View {
        Group {
            if showFallback {
                // Fallback to simple loading state
                LoadingStateView(
                    isEmpty: false,
                    hasError: false,
                    message: "Loading your fan dashboard..."
                )
            } else {
                // Show skeleton loading for expected structure
                PredictiveSkeletonLoading(sections: expectedSections)
            }
        }
        .onAppear {
            // Start fallback timer
            DispatchQueue.main.asyncAfter(deadline: .now() + fallbackTimeout) {
                withAnimation(.easeInOut(duration: PiggyLoadingTokens.animationDuration)) {
                    showFallback = true
                }
            }
        }
    }
}

// MARK: - Dashboard Section Model
struct DashboardSection: Identifiable, Equatable {
    let id = UUID()
    let type: SectionType
    let title: String
    let hasSubtitle: Bool
    let itemCount: Int

    enum SectionType {
        case header
        case stats
        case chart
        case list
        case grid
        case carousel

        var height: CGFloat {
            switch self {
            case .header: return 80
            case .stats: return 100
            case .chart: return 200
            case .list: return 60
            case .grid: return 120
            case .carousel: return 150
            }
        }
    }

    static let defaultSections: [DashboardSection] = [
        DashboardSection(type: .header, title: "Welcome Back", hasSubtitle: true, itemCount: 1),
        DashboardSection(type: .stats, title: "Quick Stats", hasSubtitle: false, itemCount: 3),
        DashboardSection(type: .chart, title: "Monthly Spending", hasSubtitle: true, itemCount: 1),
        DashboardSection(type: .carousel, title: "Your Artists", hasSubtitle: false, itemCount: 5),
        DashboardSection(type: .list, title: "Recent Activities", hasSubtitle: false, itemCount: 4)
    ]
}

// MARK: - Predictive Skeleton Loading
private struct PredictiveSkeletonLoading: View {
    let sections: [DashboardSection]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: PiggySpacing.xl) {
                ForEach(sections) { section in
                    sectionSkeleton(for: section)
                }

                // Bottom spacing for tab bar
                Spacer(minLength: PiggySpacing.xxl)
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
            .padding(.top, PiggySpacing.sm)
            .padding(.bottom, PiggySpacing.xl)
        }
    }

    @ViewBuilder
    private func sectionSkeleton(for section: DashboardSection) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            // Section header
            if !section.title.isEmpty {
                sectionHeaderSkeleton(hasSubtitle: section.hasSubtitle)
            }

            // Section content based on type
            switch section.type {
            case .header:
                headerSectionSkeleton()
            case .stats:
                statsSectionSkeleton(count: section.itemCount)
            case .chart:
                chartSectionSkeleton()
            case .list:
                listSectionSkeleton(count: section.itemCount)
            case .grid:
                gridSectionSkeleton(count: section.itemCount)
            case .carousel:
                carouselSectionSkeleton(count: section.itemCount)
            }
        }
    }

    // MARK: - Section Skeletons

    private func sectionHeaderSkeleton(hasSubtitle: Bool) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
            PiggyLoadingTokens.skeletonRectangle(width: 150, height: 20)

            if hasSubtitle {
                PiggyLoadingTokens.skeletonRectangle(width: 200, height: 16)
            }
        }
    }

    private func headerSectionSkeleton() -> some View {
        HStack(spacing: PiggySpacing.md) {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                PiggyLoadingTokens.skeletonRectangle(width: 180, height: 24)
                PiggyLoadingTokens.skeletonRectangle(width: 220, height: 16)
            }

            Spacer()

            PiggyLoadingTokens.skeletonCircle(diameter: 50)
        }
    }

    private func statsSectionSkeleton(count: Int) -> some View {
        HStack(spacing: PiggySpacing.md) {
            ForEach(0..<count, id: \.self) { _ in
                VStack(spacing: PiggySpacing.sm) {
                    PiggyLoadingTokens.skeletonCircle(diameter: 32)
                    PiggyLoadingTokens.skeletonRectangle(width: 40, height: 18)
                    PiggyLoadingTokens.skeletonRectangle(width: 60, height: 14)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(Color.piggyCardBackground.opacity(0.3))
                )
            }
        }
    }

    private func chartSectionSkeleton() -> some View {
        VStack(spacing: PiggySpacing.md) {
            // Chart placeholder
            RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                .fill(PiggyLoadingTokens.skeletonColor)
                .frame(height: 160)
                .overlay(
                    VStack(spacing: PiggySpacing.sm) {
                        PiggyLoadingTokens.skeletonRectangle(width: 100, height: 16)

                        // Simple chart-like skeleton
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(0..<7, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(PiggyLoadingTokens.skeletonHighlight)
                                    .frame(width: 12, height: CGFloat.random(in: 20...60))
                            }
                        }
                    }
                )
        }
    }

    private func listSectionSkeleton(count: Int) -> some View {
        VStack(spacing: PiggySpacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                HStack(spacing: PiggySpacing.md) {
                    PiggyLoadingTokens.skeletonCircle(diameter: 40)

                    VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                        PiggyLoadingTokens.skeletonRectangle(width: 120, height: 16)
                        PiggyLoadingTokens.skeletonRectangle(width: 80, height: 14)
                    }

                    Spacer()

                    PiggyLoadingTokens.skeletonRectangle(width: 60, height: 16)
                }
                .padding(PiggySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(Color.piggyCardBackground.opacity(0.2))
                )
            }
        }
    }

    private func gridSectionSkeleton(count: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: PiggySpacing.md) {
            ForEach(0..<count, id: \.self) { _ in
                VStack(spacing: PiggySpacing.sm) {
                    PiggyLoadingTokens.skeletonRectangle(width: nil, height: 80)
                    PiggyLoadingTokens.skeletonRectangle(width: 100, height: 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(Color.piggyCardBackground.opacity(0.2))
                )
            }
        }
    }

    private func carouselSectionSkeleton(count: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PiggySpacing.md) {
                ForEach(0..<count, id: \.self) { _ in
                    VStack(spacing: PiggySpacing.sm) {
                        PiggyLoadingTokens.skeletonCircle(diameter: 60)
                        PiggyLoadingTokens.skeletonRectangle(width: 80, height: 14)
                    }
                    .padding(PiggySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.piggyCardBackground.opacity(0.2))
                    )
                }
            }
            .padding(.horizontal, PiggySpacing.screenMargin)
        }
    }
}

// MARK: - Preview
#Preview("Adaptive Dashboard Loading") {
    ZStack {
        PiggyGradients.background
            .ignoresSafeArea()

        AdaptiveDashboardLoading(
            expectedSections: DashboardSection.defaultSections,
            fallbackTimeout: 2.0
        )
    }
}