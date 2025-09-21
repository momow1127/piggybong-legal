import SwiftUI

// PurchaseRecommendation moved to AIModels.swift to consolidate models

// MARK: - Custom Dropdown Component
struct CustomDropdown: View {
    let title: String
    @Binding var selectedOption: String
    let options: [String]
    @Binding var isExpanded: Bool
    let onToggle: () -> Void  // To handle "only one open at a time" logic
    let isDisabled: Bool
    @Namespace private var dropdownNamespace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // Dropdown Field
                Button(action: {
                    if !isDisabled {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            onToggle()
                        }
                    }
                }) {
                    HStack {
                        Text(selectedOption.isEmpty ? "Select \(title.lowercased())" : selectedOption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.6))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.25), value: isExpanded)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Expanded Options List
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selectedOption = option
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if option == selectedOption {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    option == selectedOption ? 
                                    Color.white.opacity(0.1) : Color.clear
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if option != options.last {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
                    .padding(.top, 4)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
                }
            }
        }
        .zIndex(isExpanded ? 1000 : 1)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// PurchaseDecision enum moved to AIModels.swift to avoid duplication
// Using the consolidated enum from AIModels.swift

// MARK: - Purchase Decision Calculator / Fan Priority Manager
struct PurchaseDecisionCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var databaseService: DatabaseService
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @StateObject private var aiService = AIRecommendationService.shared
    
    // 🔄 TOGGLE: Switch between old and new UI
    @State private var useNewPriorityManager = true // Set to true for MVP
    
    // OLD: Should I Buy This states (preserved for future toggle)
    @State private var itemName = ""
    @State private var selectedArtist = ""
    @State private var selectedCategory = ""
    @State private var itemPrice = "0"
    @State private var isCategoryDropdownExpanded = false
    @State private var isArtistDropdownExpanded = false
    @State private var hasInitialData = false
    
    // NEW: Fan Priority Manager states
    @State private var fanInsight: String? = nil
    @State private var showingInsight = false
    @State private var isGeneratingInsight = false
    @State private var insightFeedback: InsightFeedback? = nil
    
    // Shared states
    @State private var isGeneratingRecommendation = false
    @State private var personalizedRecommendation: String? = nil
    @State private var showingResult = false
    @State private var recommendation: PurchaseRecommendation?
    @State private var showPaywall = false
    @State private var remainingChecks = 0
    @State private var currentLoadingStep = 0
    
    // Prefill support (legacy)
    let prefilledItem: PurchaseCalculatorPrefill?
    
    init(prefilledItem: PurchaseCalculatorPrefill? = nil) {
        self.prefilledItem = prefilledItem
    }
    
    // Categories matching the FanCategory enum displayName values for consistency
    private let availableCategories = [
        "Albums & Photocards",
        "Concerts & Shows", 
        "Official Merch",
        "Fan Events",
        "Subscriptions & Apps"
    ]
    
    // Available artists for dropdown
    private var availableArtists: [String] {
        if !databaseService.userArtists.isEmpty {
            return databaseService.userArtists.map(\.name) + ["General"]
        } else if let dashboardData = FanDashboardService.shared.dashboardData,
                  !dashboardData.uiFanArtists.isEmpty {
            return dashboardData.uiFanArtists.map(\.name) + ["General"]
        } else {
            return ["BTS", "BLACKPINK", "NewJeans", "aespa", "TWICE", "IVE", "LE SSERAFIM", "General"]
        }
    }
    
    var body: some View {
        if useNewPriorityManager {
            // NEW: Fan Priority Manager UI
            newFanPriorityManagerView
        } else {
            // OLD: Should I Buy This Modal (preserved for future toggle)
            oldShouldIBuyThisView
        }
    }
    
    // MARK: - NEW: Fan Priority Manager View
    private var newFanPriorityManagerView: some View {
        ZStack {
            // Background
            PiggyGradients.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                headerBar
                
                if showingInsight, let insight = fanInsight {
                    // Show the AI insight
                    insightDisplayView(insight)
                } else if isGeneratingInsight {
                    // Show progressive AI loading
                    ProgressiveAILoading(
                        steps: AILoadingStep.defaultSteps
                    ) {
                        // Loading complete - this will be handled by the async task
                    }
                } else {
                    // Initial state - show start button
                    initialStateView
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showPaywall) {
            SimplePaywallView(triggerContext: .vipTips)
                .environmentObject(revenueCatManager)
        }
        .onAppear {
            remainingChecks = MonthlyCheckTracker.getRemainingChecks()
            // Auto-start insight generation for seamless experience
            if fanInsight == nil && !isGeneratingInsight {
                generateFanInsight()
            }
        }
    }
    
    // MARK: - OLD: Should I Buy This View (Preserved)
    private var oldShouldIBuyThisView: some View {
        ZStack {
            // Background
            PiggyGradients.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Inline header with X button (always visible)
                inlineHeaderView
                    .padding(.horizontal, PiggySpacing.lg)
                
                // Full Scrollable Content
                ScrollView {
                    VStack(spacing: PiggySpacing.lg) {
                        // Lightbulb + description
                        headerSection
                        
                        // Input Form
                        inputFormSection
                        
                        // Button/Response Section - transforms in place
                        buttonToResponseSection
                        
                        // Single VIP Section (only show if result is visible)
                        if showingResult, let recommendation = recommendation {
                            singleVIPSection(recommendation)
                        }
                        
                        // Bottom spacer for sticky CTA
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(PiggySpacing.lg)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Close any open dropdowns when tapping outside
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCategoryDropdownExpanded = false
                        isArtistDropdownExpanded = false
                    }
                }
                
                // Sticky CTA at bottom (doesn't scroll)
                if !showingResult && !isGeneratingRecommendation {
                    stickyCTAButton
                }
            }
            
            // Loading Overlay (Option A - Full screen with dimmed background)
            if isGeneratingRecommendation {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showPaywall) {
            SimplePaywallView(triggerContext: .vipTips)
                .environmentObject(revenueCatManager)
        }
        .onAppear {
            remainingChecks = MonthlyCheckTracker.getRemainingChecks()
            
            // Set default category 
            if selectedCategory.isEmpty {
                selectedCategory = availableCategories.first ?? "Albums & Photocards"
            }
            
            // Apply prefill if available
            if let prefill = prefilledItem {
                itemName = prefill.itemName
                itemPrice = String(format: "%.0f", prefill.price)
                if let artistName = prefill.artistName {
                    selectedArtist = artistName
                }
            }
        }
    }
    
    // MARK: - NEW UI Components for Fan Priority Manager
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text("Your Fan Priority Insight")
                    .font(PiggyFont.title1)
                    .foregroundColor(.white)
                Text("Based on your preferences and recent activity")
                    .font(PiggyFont.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, PiggySpacing.lg)
        .padding(.top, PiggySpacing.md)
        .padding(.bottom, PiggySpacing.sm)
    }
    
    private var initialStateView: some View {
        VStack(spacing: PiggySpacing.lg) {
            Text("🎯")
                .font(.system(size: 80))
            
            Text("Getting your personalized fan insights...")
                .font(PiggyFont.headline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, PiggySpacing.xl)
        }
        .padding(.top, PiggySpacing.xxl)
    }
    
    private var loadingStepsView: some View {
        VStack(spacing: PiggySpacing.xl) {
            // Progress indicator
            VStack(spacing: PiggySpacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Analyzing your fan data...")
                    .font(PiggyFont.title2)
                    .foregroundColor(.white)
            }
            .padding(.top, PiggySpacing.xxl)
            
            // Loading steps
            VStack(spacing: PiggySpacing.lg) {
                ForEach(Array(loadingSteps.enumerated()), id: \.offset) { index, step in
                    LoadingStepRow(
                        step: step,
                        isActive: index == currentLoadingStep,
                        isCompleted: index < currentLoadingStep
                    )
                }
            }
            .padding(.horizontal, PiggySpacing.xl)
        }
    }
    
    private func insightDisplayView(_ insight: String) -> some View {
        ScrollView {
            VStack(spacing: PiggySpacing.lg) {
                // Main insight card
                VStack(spacing: PiggySpacing.lg) {
                    Text(insight)
                        .font(PiggyFont.body)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(PiggySpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.top, PiggySpacing.xl)
                
                // Feedback buttons
                HStack(spacing: PiggySpacing.md) {
                    Button(action: { submitFeedback(.positive) }) {
                        HStack(spacing: PiggySpacing.xs) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(PiggyFont.bodyEmphasized)
                            Text("Helpful")
                                .font(PiggyFont.body)
                        }
                        .foregroundColor(insightFeedback == .positive ? .white : .white.opacity(0.8))
                        .padding(.horizontal, PiggySpacing.lg)
                        .padding(.vertical, PiggySpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                .fill(insightFeedback == .positive ? Color.green : Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Button(action: { submitFeedback(.negative) }) {
                        HStack(spacing: PiggySpacing.xs) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(PiggyFont.bodyEmphasized)
                            Text("Not helpful")
                                .font(PiggyFont.body)
                        }
                        .foregroundColor(insightFeedback == .negative ? .white : .white.opacity(0.8))
                        .padding(.horizontal, PiggySpacing.lg)
                        .padding(.vertical, PiggySpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                .fill(insightFeedback == .negative ? Color.red : Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, PiggySpacing.lg)
                
                // Refresh button
                Button(action: refreshInsight) {
                    HStack(spacing: PiggySpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(PiggyFont.body)
                        Text("Get New Insight")
                            .font(PiggyFont.body)
                    }
                    .foregroundColor(.piggyPrimary)
                    .padding(.horizontal, PiggySpacing.lg)
                    .padding(.vertical, PiggySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                    .stroke(Color.piggyPrimary, lineWidth: 2)
                            )
                    )
                }
                .padding(.horizontal, PiggySpacing.lg)
                
                // Disclaimer
                Text("AI can make mistakes. Always double-check for accuracy.")
                    .font(PiggyFont.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PiggySpacing.xl)
                    .padding(.top, PiggySpacing.xs)
                
                Spacer()
                    .frame(height: PiggySpacing.xl)
            }
        }
    }
    
    // MARK: - Loading Steps Data
    private let loadingSteps = [
        "📊 Pulling your idol rankings...",
        "💳 Analyzing recent purchases...",
        "📅 Checking comeback schedules...",
        "🤖 Generating your fan insight..."
    ]
    
    // MARK: - Supporting Views
    private struct LoadingStepRow: View {
        let step: String
        let isActive: Bool
        let isCompleted: Bool
        
        var body: some View {
            HStack(spacing: PiggySpacing.sm) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isActive ? Color.piggyPrimary : Color.white.opacity(0.3)))
                        .frame(width: 24, height: 24)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if isActive {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    }
                }
                
                // Step text
                Text(step)
                    .font(isActive ? PiggyFont.bodyEmphasized : PiggyFont.body)
                    .foregroundColor(isActive ? .white : .white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, PiggySpacing.md)
            .padding(.vertical, PiggySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                    .fill(isActive ? Color.white.opacity(0.1) : Color.clear)
            )
        }
    }
    
    // MARK: - Inline Header View (scrolls with content)
    private var inlineHeaderView: some View {
        HStack {
            Spacer()
            
            // Dismiss Button (44pt touch target)
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    // MARK: - Sticky CTA Button
    private var stickyCTAButton: some View {
        VStack(spacing: 0) {
            // Subtle gradient overlay for separation
            LinearGradient(
                colors: [Color.clear, Color.piggyBackground.opacity(0.8), Color.piggyBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            // CTA Button
            Button(action: calculateRecommendation) {
                HStack {
                    Text("Get My Recommendation")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.white)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(PiggySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                        .fill(PiggyGradients.primaryButton)
                )
                .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, PiggySpacing.lg)
            .padding(.bottom, 20)
            
            // Safe area spacer
            Color.piggyBackground
                .frame(height: 0)
                .background(Color.piggyBackground)
        }
        .background(Color.piggyBackground)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("💡")
                .font(.system(size: 48))
            
            Text("Should I Buy This?")
                .font(PiggyFont.title1)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Get a smart recommendation for your K-pop purchase")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            // Semi-transparent background that dims everything
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Centered loading content
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Generating...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: isGeneratingRecommendation)
    }
    
    private var inputFormSection: some View {
        VStack(spacing: 20) {
            // Item Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Item name")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Album, concert ticket, merch...", text: $itemName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .disabled(isGeneratingRecommendation)
                    .opacity(isGeneratingRecommendation ? 0.6 : 1.0)
            }
            
            // Category Dropdown (Custom Component)
            CustomDropdown(
                title: "Category",
                selectedOption: $selectedCategory,
                options: availableCategories,
                isExpanded: $isCategoryDropdownExpanded,
                onToggle: {
                    // Close artist dropdown if open, then toggle category
                    if isArtistDropdownExpanded {
                        isArtistDropdownExpanded = false
                    }
                    isCategoryDropdownExpanded.toggle()
                },
                isDisabled: isGeneratingRecommendation
            )
            
            // Artist Selection (Custom Component)  
            CustomDropdown(
                title: "Idol",
                selectedOption: $selectedArtist,
                options: availableArtists,
                isExpanded: $isArtistDropdownExpanded,
                onToggle: {
                    // Close category dropdown if open, then toggle artist
                    if isCategoryDropdownExpanded {
                        isCategoryDropdownExpanded = false
                    }
                    isArtistDropdownExpanded.toggle()
                },
                isDisabled: isGeneratingRecommendation
            )
        }
        .padding(20)
    }
    
private var calculateButton: some View {
        Button(action: calculateRecommendation) {
            HStack {
                if isGeneratingRecommendation {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("Generating...")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.white)
                } else {
                    Text("Get My Recommendation")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.white)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                    .fill(PiggyGradients.primaryButton)
            )
            .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(itemName.isEmpty || isGeneratingRecommendation)
        .opacity((itemName.isEmpty || isGeneratingRecommendation) ? 0.5 : 1.0)
    }
    
    // MARK: - Button-to-Response Transformation Section
    private var buttonToResponseSection: some View {
        VStack(spacing: 0) {
            if isGeneratingRecommendation {
                // Show Loading in button's place
                loadingInPlaceSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.4), value: isGeneratingRecommendation)
                    
            } else if let recommendation = recommendation {
                // Show AI Response in button's place
                aiResponseSection(recommendation)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingResult)
            }
        }
    }
    
    // MARK: - Loading In Place Section
    private var loadingInPlaceSection: some View {
        VStack(spacing: 16) {
            // Animated sparkles
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkles")
                        .foregroundColor(.piggyPrimary)
                        .font(.system(size: 18))
                        .opacity(0.3)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                            value: isGeneratingRecommendation
                        )
                        .scaleEffect(isGeneratingRecommendation ? 1.2 : 0.8)
                }
            }
            
            Text("🤖 Analyzing your priorities...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Text("Getting personalized insight ✨")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.piggyPrimary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - AI Response Section  
    private func aiResponseSection(_ recommendation: PurchaseRecommendation) -> some View {
        VStack(spacing: 20) {
            // White Card Container
            VStack(spacing: 16) {
                // Decision Badge
                HStack(spacing: 12) {
                    Text(recommendation.emoji)
                        .font(.system(size: 28))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.decision.rawValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(recommendation.color)
                        
                        Text("For \(itemName)")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    Spacer()
                }
                
                // AI Reasoning
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(.piggyPrimary)
                            .font(.system(size: 16))
                        Text("AI Insight:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Text(recommendation.reasoning)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(nil)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Action Buttons Row
            HStack(spacing: 12) {
                // Regenerate Button
                Button(action: {
                    Task {
                        await regenerateRecommendation()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Regenerate")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.piggyPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.piggyPrimary, lineWidth: 1)
                            )
                    )
                }
                
                // Save Button
                Button(action: saveRecommendation) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Save")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(PiggyGradients.primaryButton)
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            recommendation.color.opacity(0.1),
                            recommendation.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(recommendation.color.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    private var loadingSection: some View {
        VStack(spacing: 20) {
            // Animated sparkles
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkles")
                        .foregroundColor(.piggyPrimary)
                        .font(.system(size: 20))
                        .opacity(0.3)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                            value: isGeneratingRecommendation
                        )
                        .scaleEffect(isGeneratingRecommendation ? 1.2 : 0.8)
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 8) {
                Text("🤖")
                    .font(.system(size: 32))
                
                Text("Analyzing your K-pop spending priorities...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("Getting personalized insight just for you ✨")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.piggyPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.easeInOut(duration: 0.3), value: isGeneratingRecommendation)
    }
    
    private func resultSection(_ recommendation: PurchaseRecommendation) -> some View {
        VStack(spacing: 20) {
            // Recommendation Badge
            HStack {
                Text(recommendation.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading) {
                    Text(recommendation.decision.rawValue)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(recommendation.color)
                    
                    Text("For \(itemName)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(recommendation.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(recommendation.color.opacity(0.3), lineWidth: 2)
                    )
            )
            
            // Reasoning
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Here's why:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(recommendation.reasoning)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Impact on Priorities
            priorityImpactSection(recommendation)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .slide))
        .animation(.easeInOut(duration: 0.5), value: showingResult)
    }
    
private func priorityImpactSection(_ recommendation: PurchaseRecommendation) -> some View {
        // Since price is removed, show priority alignment based on category weight
        let priorityCapacity = 100.0 // Percentage-based capacity
        let categoryWeight: Double = {
            switch recommendation.priorityLevel?.lowercased() {
            case "high": return 85.0 // High priority items use 85% of capacity
            case "medium": return 60.0 // Medium priority items use 60%
            case "low": return 35.0 // Low priority items use 35%
            default: return 60.0
            }
        }()
        let remaining = priorityCapacity - categoryWeight
        let _ = Int(remaining) // Silence unused variable warning
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.purple)
                Text("Impact on Your Priorities")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Before/After bars
            VStack(spacing: 12) {
                // Before
HStack {
                    Text("Priority alignment:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(priorityCapacity))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple.opacity(0.3))
                    .frame(height: 8)
                    .overlay(
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width)
                        }
                    )
                
                // After
HStack {
                    Text("Impact level:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(categoryWeight))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(recommendation.color)
                }
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .overlay(
                        GeometryReader { geometry in
RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geometry.size.width * CGFloat(categoryWeight / priorityCapacity)))
                        }
                    )
                
Text("This item aligns \(Int(categoryWeight))% with your top priorities")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // Removed detectCategoryFromItemName - using manual category selection
    
private func calculateRecommendation() {
        // Simple logic: VIP gets recommendations, free users see paywall
        if !subscriptionService.isVIP {
            showPaywall = true
            return
        }
        
        // Use selected category
        let itemCategory = selectedCategory
        
        // Priority mapping based on user's Fan Priority section
        let priorityLevels: [String: (priority: String, color: Color, weight: Int)] = [
            "Albums & Photocards": ("High", .red, 3),
            "Concerts & Shows": ("Medium", .orange, 2),
            "Official Merch": ("Medium", .orange, 2),
            "Digital Content & Streaming": ("Low", .blue, 1),
            "Fan Events & Meetings": ("Low", .blue, 1),
            "General": ("Medium", .orange, 2) // Default fallback
        ]
        
        let itemPriorityInfo = priorityLevels[itemCategory] ?? ("Medium", .orange, 2)
        let topPriority = itemPriorityInfo.priority
        
        // Generate spending streak context
        let recentSpendBehavior = generateSpendingStreakContext(for: itemCategory)
        
        // Start AI recommendation generation
        isGeneratingRecommendation = true
        personalizedRecommendation = nil
        
        Task {
            // Add minimum 2-second delay for premium AI experience
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Get AI-powered recommendation
            let aiRecommendation = await aiService.generatePersonalizedRecommendation(
                itemName: itemName,
                artist: selectedArtist,
                price: 0.0,
                topPriority: topPriority,
                recentSpendBehavior: recentSpendBehavior
            )
            
            await MainActor.run {
                personalizedRecommendation = aiRecommendation
                isGeneratingRecommendation = false
                
                // Create recommendation based on priority level
                let (decision, emoji, color) = determineDecisionFromPriority(topPriority)
                
                recommendation = PurchaseRecommendation(
                    decision: decision,
                    reasoning: aiRecommendation,
                    emoji: emoji,
                    color: color,
                    category: itemCategory,
                    priorityLevel: topPriority
                )
                
                // Add haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                showingResult = true
                
                // Log analytics
                VIPAnalytics.logDecisionSaved(outcome: decision.rawValue)
            }
        }
    }
    
    // Helper function to determine decision based on priority
    private func determineDecisionFromPriority(_ priority: String) -> (PurchaseDecision, String, Color) {
        switch priority.lowercased() {
        case "high":
            return (.buyNow, "✅", .green)
        case "medium":
            return (.saveForLater, "⏳", .orange)
        default: // low
            return (.skipThis, "🛑", .red)
        }
    }
    
    // MARK: - New Action Functions
    private func regenerateRecommendation() async {
        // Reset and regenerate with same inputs
        isGeneratingRecommendation = true
        personalizedRecommendation = nil
        
        // Use selected category
        let itemCategory = selectedCategory
        
        // Priority mapping based on user's Fan Priority section
        let priorityLevels: [String: (priority: String, color: Color, weight: Int)] = [
            "Albums & Photocards": ("High", .red, 3),
            "Concerts & Shows": ("Medium", .orange, 2),
            "Official Merch": ("Medium", .orange, 2),
            "Digital Content & Streaming": ("Low", .blue, 1),
            "Fan Events & Meetings": ("Low", .blue, 1),
            "General": ("Medium", .orange, 2) // Default fallback
        ]
        
        let itemPriorityInfo = priorityLevels[itemCategory] ?? ("Medium", .orange, 2)
        let topPriority = itemPriorityInfo.priority
        
        // Generate spending streak context
        let recentSpendBehavior = generateSpendingStreakContext(for: itemCategory)
        
        do {
            // Add minimum 2-second delay for premium AI experience
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Get AI-powered recommendation
            let aiRecommendation = await aiService.generatePersonalizedRecommendation(
                itemName: itemName,
                artist: selectedArtist,
                price: 0.0,
                topPriority: topPriority,
                recentSpendBehavior: recentSpendBehavior
            )
            
            await MainActor.run {
                personalizedRecommendation = aiRecommendation
                isGeneratingRecommendation = false
                
                // Create recommendation based on priority level
                let (decision, emoji, color) = determineDecisionFromPriority(topPriority)
                
                recommendation = PurchaseRecommendation(
                    decision: decision,
                    reasoning: aiRecommendation,
                    emoji: emoji,
                    color: color,
                    category: itemCategory,
                    priorityLevel: topPriority
                )
                
                // Add haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                // Log analytics
                VIPAnalytics.logDecisionSaved(outcome: decision.rawValue)
            }
        } catch {
            await MainActor.run {
                isGeneratingRecommendation = false
                print("⚠️ Error during regeneration: \(error)")
            }
        }
    }
    
    private func saveRecommendation() {
        guard let recommendation = recommendation else { return }
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Save to user's decision history
        VIPAnalytics.logDecisionSaved(outcome: recommendation.decision.rawValue)
        
        // Show confirmation
        let impact2 = UIImpactFeedbackGenerator(style: .medium)
        impact2.impactOccurred()
        
        // TODO: Implement actual saving to user's saved recommendations
        print("💾 Saved recommendation: \(recommendation.decision.rawValue) for \(itemName)")
    }
    
// MARK: - Single VIP Section (Simplified)
    @ViewBuilder
    private func singleVIPSection(_ recommendation: PurchaseRecommendation) -> some View {
        VStack(spacing: 12) {
            // Only show one VIP element - either limit warning OR tip
            if !subscriptionService.isVIP && remainingChecks <= 1 {
                // Show limit warning if close to limit
                MonthlyCheckLimitView(remainingChecks: remainingChecks, showPaywall: $showPaywall)
            } else if subscriptionService.isVIP {
                // Show VIP tip for subscribers
                VIPTipCard(
                    decision: recommendation.decision,
                    price: 0.0,
                    remainingBudget: 300.0
                )
            } else {
                // Show teaser for free users with checks remaining  
                VIPTipTeaser(showPaywall: $showPaywall)
            }
        }
    }
    
    private func generateSpendingStreakContext(for category: String) -> String {
        // Mock spending streak data - in real app this would come from user's activity history
        let mockSpendingCounts: [String: Int] = [
            "Albums & Photocards": 3,
            "Official Merch": 1,
            "Concerts & Shows": 0,
            "Digital Content & Streaming": 2,
            "Fan Events & Meetings": 0
        ]
        
        guard let count = mockSpendingCounts[category], count > 0 else {
            return ""
        }
        
        // Generate contextual nudges based on spending patterns
        switch count {
        case 1:
            return ""
        case 2:
            return "That's your 2nd \(category.lowercased()) item this month."
        case 3:
            return "That's \(category.lowercased()) #3 this month… your collection is thriving! Want to shift focus to your concert savings now?"
        default:
            return "You've been really active with \(category.lowercased()) lately 👀"
        }
    }
    
    // MARK: - NEW: Fan Priority Manager Logic
    
    private func generateFanInsight() {
        // Simple logic: VIP gets insights, free users see paywall
        if !subscriptionService.isVIP {
            showPaywall = true
            // Track paywall view with AI context
            AIInsightAnalyticsService.shared.logPaywallViewed(
                source: "ai_insight_request",
                variant: "purchase_decision",
                hasUsedAI: false
            )
            return
        }

        // Track AI insight generation start
        let startTime = Date()
        AIInsightAnalyticsService.shared.trackInsightGenerationStart(for: selectedArtist)

        isGeneratingInsight = true

        Task {
            // Gather dynamic user data
            let userData = gatherUserData()

            // Build Claude prompt
            let prompt = buildFanInsightPrompt(userData: userData)

            // Call Claude API
            let insight = await callClaudeForInsight(prompt: prompt)

            await MainActor.run {
                isGeneratingInsight = false
                fanInsight = insight
                showingInsight = true

                // Calculate generation time
                let generationTime = Int(Date().timeIntervalSince(startTime) * 1000) // in milliseconds

                // Track successful AI insight generation
                AIInsightAnalyticsService.shared.logAIInsightGenerated(
                    insightType: "purchase_decision",
                    artistId: nil,
                    artistName: selectedArtist,
                    generationTimeMs: generationTime,
                    fallbackUsed: insight.contains("Welcome to Your Fan Journey") // Check if fallback was used
                )

                // Add haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
        }
    }
    
    private func gatherUserData() -> UserFanData {
        // Using real user data from dashboard and database services
        
        let topIdols = databaseService.userArtists.prefix(3).map { $0.name }
        let fallbackIdols = ["NewJeans", "IVE", "ITZY"] // Fallback if no data
        
        // Get user name for personalization
        let userName = databaseService.currentUser?.name ?? "Fan"
        
        // Get real dashboard data for activities and priorities
        let dashboardData = FanDashboardService.shared.dashboardData
        
        // Extract real priorities from user data
        let realPriorities = extractUserPriorities()
        
        // Extract real recent activities
        let recentActivity = extractRecentActivity(from: dashboardData)
        
        // Extract real upcoming events
        let upcomingEvents = extractUpcomingEvents(from: dashboardData)
        
        return UserFanData(
            userName: userName,
            topIdols: topIdols.isEmpty ? fallbackIdols : Array(topIdols),
            priorities: realPriorities,
            recentActivity: recentActivity,
            upcomingEvents: upcomingEvents
        )
    }
    
    // MARK: - Real Data Extraction Helpers
    
    private func extractUserPriorities() -> [SimpleFanPriority] {
        // Try to get real priority data from UserDefaults or dashboard
        if let savedPriorities = UserDefaults.standard.data(forKey: "user_category_priorities"),
           let decodedPriorities = try? JSONDecoder().decode([String: String].self, from: savedPriorities) {
            
            return decodedPriorities.map { category, level in
                SimpleFanPriority(category: category, level: level)
            }.sorted { $0.category < $1.category }
        }
        
        // Fallback to default priorities
        return [
            SimpleFanPriority(category: "Concerts", level: "High"),
            SimpleFanPriority(category: "Albums", level: "Medium"),
            SimpleFanPriority(category: "Merch", level: "Low")
        ]
    }
    
    private func extractRecentActivity(from dashboardData: DashboardData?) -> String {
        guard let dashboardData = dashboardData,
              !dashboardData.recentActivity.isEmpty else {
            return "No recent fan activities recorded"
        }
        
        // Get last 3 activities and format them
        let recentActivities = dashboardData.recentActivity.prefix(3)
        let activityStrings = recentActivities.map { activity in
            let amount = (activity.amount ?? 0.0) > 0 ? " ($\(Int(activity.amount ?? 0.0)))" : ""
            return "\(activity.title)\(amount)"
        }
        
        return activityStrings.joined(separator: ", ")
    }
    
    private func extractUpcomingEvents(from dashboardData: DashboardData?) -> String {
        guard let dashboardData = dashboardData,
              !dashboardData.uiUpcomingEvents.isEmpty else {
            return "No upcoming events scheduled"
        }
        
        // Get next 2-3 upcoming events
        let upcomingEvents = dashboardData.uiUpcomingEvents.prefix(3)
        let eventStrings = upcomingEvents.map { event in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: event.date ?? Date())
            return "\(event.eventType.displayName) on \(dateString)"
        }
        
        return eventStrings.joined(separator: ", ")
    }
    
    private func buildFanInsightPrompt(userData: UserFanData) -> String {
        let idolText = userData.topIdols.enumerated().map { index, name in
            "\(name) (#\(index + 1))"
        }.joined(separator: ", ")
        
        let priorityText = userData.priorities.map { priority in
            "\(priority.category) (\(priority.level))"
        }.joined(separator: ", ")
        
        return """
        You are a warm, insightful K-pop fan advisor. Create a personalized insight using this EXACT format:

        "\(userData.userName), here's how your spending aligns with your fan priorities:

        **Where you're on track**
        [Emoji] [Achievement]: [Specific example of what they're doing well, referencing their actual activity and how it matches their priorities]

        **What to consider**
        [Emoji] [Opportunity]: [Specific guidance about upcoming events or adjustments, based on their top idols and priority settings]"

        User Data:
        - Top Idols: \(idolText)
        - Priorities: \(priorityText)
        - Recent Activity: \(userData.recentActivity)
        - Upcoming Events: \(userData.upcomingEvents)

        Use casual K-pop fan language. Keep each section to 1-2 sentences. Be specific about their data, not generic.
        """
    }
    
    private func callClaudeForInsight(prompt: String) async -> String {
        do {
            // Get user ID from auth service
            guard let userId = SupabaseService.shared.authService.currentUser?.id else {
                return generateFallbackInsight()
            }

            // Prepare payload for generate-fan-insights Edge Function
            let userData = gatherUserData()
            let requestBody: [String: Any] = [
                "user_id": userId,
                "artist_id": selectedArtist,
                "artist_name": selectedArtist,
                "event_history": userData.topIdols,
                "preferences": userData.priorities.map { "\($0.category) (\($0.level))" }
            ]

            // Call the updated Edge Function using URL request
            let response = try await callGenerateFanInsights(requestBody: requestBody)

            // Parse the AI response
            if let insights = response["insights"] as? [[String: Any]],
               let firstInsight = insights.first,
               let description = firstInsight["description"] as? String {
                return description
            }

            return generateFallbackInsight()
        } catch {
            print("❌ Failed to generate insight: \(error)")
            return generateFallbackInsight()
        }
    }
    
    private func generateFallbackInsight() -> String {
        return "✨ You've been doing great with your fan priorities! Based on your activity, consider focusing on upcoming comebacks from your top idols. Save up for those special moments that matter most to you! 💖"
    }

    private func callGenerateFanInsights(requestBody: [String: Any]) async throws -> [String: Any] {
        // Get Supabase configuration
        let baseURL = SupabaseService.shared.supabaseURL
        let anonKey = SupabaseService.shared.anonKey

        // Get user token for authentication
        guard let session = try? await SupabaseService.shared.client.auth.session else {
            throw EdgeFunctionError.missingParameter
        }
        let accessToken = session.accessToken

        // Build URL
        guard let url = URL(string: "\(baseURL)/functions/v1/generate-fan-insights") else {
            throw EdgeFunctionError.invalidURL
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        // Add body
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw EdgeFunctionError.serverError("HTTP error")
        }

        // Parse response
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EdgeFunctionError.decodingError
        }

        return jsonResponse
    }
    
    private func refreshInsight() {
        fanInsight = nil
        showingInsight = false
        insightFeedback = nil
        generateFanInsight()
    }
    
    private func submitFeedback(_ feedback: InsightFeedback) {
        insightFeedback = feedback

        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Log analytics - both old and new systems
        VIPAnalytics.logDecisionSaved(outcome: feedback == .positive ? "helpful" : "not_helpful")

        // Track AI insight feedback with Firebase Analytics
        let feedbackString = feedback == .positive ? "positive" : "negative"
        AIInsightAnalyticsService.shared.trackInsightFeedback(
            feedback: feedbackString,
            artistName: selectedArtist,
            insightType: "purchase_decision"
        )

        // Submit feedback to backend
        Task {
            do {
                let _ = try await EdgeFunctionService.shared.submitInsightFeedback(
                    artistId: selectedArtist,
                    feedback: feedbackString
                )
                print("✅ Feedback submitted successfully: \(feedback)")
            } catch {
                print("❌ Failed to submit feedback: \(error)")
                // Still show success to user since local feedback was recorded
            }
        }

        print("📊 Feedback submitted: \(feedback)")
    }
}

// MARK: - Supporting Data Models for Fan Priority Manager

enum InsightFeedback {
    case positive
    case negative
}

struct SimpleFanPriority {
    let category: String
    let level: String
}

struct UserFanData {
    let userName: String
    let topIdols: [String]
    let priorities: [SimpleFanPriority]
    let recentActivity: String
    let upcomingEvents: String
}



// MARK: - Recommendation Data Model
struct RecommendationData {
    let availableArtists: [String]
    let availableCategories: [String]
    let hasArtists: Bool
    let hasCategories: Bool
}

// MARK: - Supporting Models
// Models consolidated in AIModels.swift

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

#Preview {
    PurchaseDecisionCalculatorView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(SubscriptionService.shared)
        .environmentObject(RevenueCatManager.shared)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
}
