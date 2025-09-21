import SwiftUI

struct OnboardingInsightView: View {
    @ObservedObject var onboardingData: OnboardingData
    @Binding var showDashboard: Bool
    let onNext: (() -> Void)? // Callback to navigate to permission explainer
    @State private var isAnalyzing = false
    @State private var showResults = false
    @State private var animateProgress = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        OnboardingScaffold(
            title: showResults ? "Start My Fan Journey" : "",
            canProceed: showResults,
            showSkip: false,
            showButton: showResults,
            currentStep: nil,
            action: completeOnboarding
        ) {
            // Let OnboardingScaffold handle all spacing
            VStack(spacing: PiggySpacing.xl) {
                    if !showResults {
                        analysisView
                    } else {
                        resultsContent
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, PiggySpacing.lg)
        }
        .onAppear {
            startAnalysis()
        }
    }
    
    // MARK: - Analysis View
    private var analysisView: some View {
        VStack(spacing: PiggySpacing.xl) {
            // Loading Animation - centered without extra spacers
            VStack(spacing: PiggySpacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.piggyTextSecondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: animateProgress ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [Color.piggyPrimary, Color.piggySecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(PiggyAnimations.standard.delay(0.5), value: animateProgress)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.piggyPrimary)
                        .scaleEffect(isAnalyzing ? 1.1 : 1.0)
                        .animation(PiggyAnimations.springBouncy.repeatForever(autoreverses: true), value: isAnalyzing)
                }
                
                VStack(spacing: PiggySpacing.md) {
                    Text("Analyzing Your Profile 🧠")
                        .font(PiggyFont.title1)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text("Analyzing your priorities and preferences...")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Analysis Steps
            VStack(alignment: .leading, spacing: PiggySpacing.md) {
                AnalysisStep(text: "Processing your music taste", isComplete: true)
                AnalysisStep(text: "Analyzing your priorities", isComplete: animateProgress)
                AnalysisStep(text: "Setting up smart recommendations", isComplete: false)
                AnalysisStep(text: "Preparing your fan assistant", isComplete: false)
            }
            .padding(.horizontal, PiggySpacing.lg)
        }
    }
    
    // MARK: - Results Content (without button)
    private var resultsContent: some View {
        VStack(spacing: PiggySpacing.xl) {
            // Header
            VStack(spacing: PiggySpacing.md) {
                let topPriority = getTopPriorityCategory()
                VStack(spacing: PiggySpacing.xs) {
                    Text("#1 FOCUS")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(topPriority.displayName)
                        .font(PiggyFont.title1)
                        .foregroundColor(.piggyTextPrimary)
                        .multilineTextAlignment(.center)
                }

                Text("We'll filter everything else to keep you focused on what matters most.")
                    .font(PiggyFont.subheadline)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Results Summary
            VStack(spacing: PiggySpacing.lg) {
                // Priority Ranking Card with Stacked Bar
                priorityRankingCard
            }
        }
    }
    
    // MARK: - Component Views
    private var priorityListView: some View {
        let sortedCategories = getSortedCategories()

        return VStack(spacing: PiggySpacing.md) {
            ForEach(0..<sortedCategories.count, id: \.self) { index in
                priorityRowView(for: sortedCategories[index])
            }
        }
    }

    private func priorityRowView(for category: FanCategoryWithIcon) -> some View {
        priorityRowContent(for: category)
    }

    private func priorityRowContent(for category: FanCategoryWithIcon) -> some View {
        let categoryId = getCategoryId(category)
        let ranking = getPriorityRanking(for: categoryId)
        let isTopPriority = ranking == 1

        return HStack(spacing: PiggySpacing.md) {
            // Tag-style badge
            priorityBadge(ranking: ranking, isTop: isTopPriority)

            // Icon with proper size token
            Text(category.icon)
                .font(.system(size: 20))

            // Category name with emphasized body font
            Text(category.displayName)
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

        }
        .contentShape(Rectangle())
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


    private var priorityRankingCard: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.lg) {
            // Priority List
            priorityListView
        }
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(Color.piggyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    
    // New Simple Insight Card
    private var insightCard: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            let topPriority = getTopPriorityCategory()
            Text("We'll help you keep your spending aligned with your top priority: \(topPriority.icon) \(topPriority.displayName)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.piggyPrimary.opacity(0.15),
                            Color.piggySecondary.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                        .stroke(
                            Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Helper Functions
    private func startAnalysis() {
        isAnalyzing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateProgress = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(PiggyAnimations.springBouncy) {
                showResults = true
                isAnalyzing = false
            }
        }
    }
    
    private func getSortedCategories() -> [FanCategoryWithIcon] {
        // Use FanCategory enum values that match the onboarding categories
        let categories: [FanCategory] = [
            .concerts,
            .albums, 
            .merch,
            .events,
            .subscriptions
        ]
        
        // Sort by priority from categoryPriorities or use default order
        return categories.sorted { first, second in
            let firstPriority = onboardingData.categoryPriorities[getCategoryId(first)] ?? .low
            let secondPriority = onboardingData.categoryPriorities[getCategoryId(second)] ?? .low
            
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

    private func getPriorityRanking(for categoryId: String) -> Int {
        let sortedCategories = getSortedCategories()
        guard let index = sortedCategories.firstIndex(where: { getCategoryId($0) == categoryId }) else {
            return sortedCategories.count // Default to last if not found
        }
        return index + 1 // Convert 0-based index to 1-based ranking
    }
    
    
    private func getColorForPriority(_ priority: PriorityLevel) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    
    private func getTopPriorityCategory() -> FanCategoryWithIcon {
        let categories = getSortedCategories()
        return categories.first ?? FanCategory.concerts
    }
    
    
    private func getTopArtistName() -> String {
        return onboardingData.selectedArtists.first?.name ?? "your favorite artist"
    }
    
    private func generateSmartTip() -> String {
        let tips = [
            "Your priorities will guide every purchase decision so you never have to wonder if you should buy something again.",
            "High priority items get green lights, medium priority gets careful consideration, and low priority gets save for later recommendations.",
            "Never miss your number one priority releases while you are spending money on lower priority items that can wait.",
            "Smart timing recommendations help you save money for upcoming high-priority drops from your favorite artists.",
            "Get personalized alerts when your favorite artists announce new releases so you can plan your spending accordingly."
        ]
        return tips.randomElement() ?? tips[0]
    }
    
    private func completeOnboarding() {
        // Save onboarding selections to UserDefaults for dashboard use
        saveOnboardingData()
        
        // Set onboarding as completed - this will trigger app routing change
        hasCompletedOnboarding = true
        
        // Check if we should show notification explainer first
        if let onNext = onNext {
            // Navigate to permission explainer
            onNext()
        } else {
            // Fallback to direct dashboard (for legacy usage)
            showDashboard = true
        }
    }
    
    private func saveOnboardingData() {
        // Save selected artists
        if let artistsData = try? JSONEncoder().encode(onboardingData.selectedArtists) {
            UserDefaults.standard.set(artistsData, forKey: "onboarding_selected_artists")
            print("✅ Saved \(onboardingData.selectedArtists.count) selected artists to UserDefaults")
        }
        
        // Save selected goals
        if let goalsData = try? JSONEncoder().encode(onboardingData.selectedGoals) {
            UserDefaults.standard.set(goalsData, forKey: "onboarding_selected_goals")
            print("✅ Saved \(onboardingData.selectedGoals.count) selected goals to UserDefaults")
        }
        
        // Save user name
        UserDefaults.standard.set(onboardingData.name, forKey: "userName")
        
        // Save custom goal amounts
        if let customAmountsData = try? JSONEncoder().encode(onboardingData.customGoalAmounts) {
            UserDefaults.standard.set(customAmountsData, forKey: "onboarding_custom_goal_amounts")
            print("✅ Saved custom goal amounts to UserDefaults")
        }
        
        // Save category priorities for dashboard priority chart (fallback)
        if let categoryPriorityData = try? JSONEncoder().encode(onboardingData.categoryPriorities) {
            UserDefaults.standard.set(categoryPriorityData, forKey: "onboarding_category_priorities")
            print("✅ Saved category priorities to UserDefaults as fallback")
        }
        
        // Save priorities to database if user is authenticated
        Task {
            await savePrioritiesToDatabase()
        }
    }
    
    /// Saves user priorities to Supabase database
    private func savePrioritiesToDatabase() async {
        guard let authUser = try? await SupabaseService.shared.getCurrentUser() else {
            print("⚠️ No authenticated user, skipping database priority save")
            return
        }
        
        print("💾 Saving priorities to database for user: \(authUser.id)")
        
        await DatabaseService.shared.saveOnboardingPriorities(
            userId: authUser.id,
            categoryPriorities: onboardingData.categoryPriorities
        )
    }
}

// MARK: - Analysis Step Component
struct AnalysisStep: View {
    let text: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: PiggySpacing.sm) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? .budgetGreen : .white.opacity(0.3))
                .font(.system(size: 16))
            
            Text(text)
                .font(PiggyFont.subheadline)
                .foregroundColor(isComplete ? .piggyTextPrimary : .piggyTextSecondary)
            
            Spacer()
        }
        .animation(PiggyAnimations.fast, value: isComplete)
    }
}


#Preview {
    ZStack {
        Color.piggyBackground
        OnboardingInsightView(
            onboardingData: {
                let data = OnboardingData()
                data.name = "Test User"
                // Update artist cache and select by ID
                let testArtists = [
                    Artist(name: "NewJeans"),
                    Artist(name: "Stray Kids")
                ]
                data.updateArtistCache(with: testArtists)
                data.selectedArtistIDs = testArtists.map { $0.id }
                data.categoryPriorities = [
                    "concerts": .high,
                    "albums": .high,
                    "merch": .medium,
                    "events": .medium,
                    "subs": .low
                ]
                return data
            }(),
            showDashboard: .constant(false),
            onNext: nil
        )
    }
}

// SpendingCategory definition moved to PiggyPriorityChart.swift to avoid duplication
