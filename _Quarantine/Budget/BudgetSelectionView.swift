import SwiftUI

// MARK: - Fan Wallet Setup View
struct BudgetSelectionView: View {
    @ObservedObject var onboardingData: OnboardingData
    @Binding var monthlyBudget: Double
    let onComplete: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        OnboardingContainer(
            title: "",
            showBackButton: true,
            buttonTitle: "Set My Fan Wallet",
            canProceed: monthlyBudget >= 50,
            currentStep: nil,
            onBack: onBack,
            onNext: onComplete
        ) {
            BudgetSelectionContent(
                onboardingData: onboardingData,
                monthlyBudget: $monthlyBudget
            )
        }
    }
}

// MARK: - Fan Wallet Content
struct BudgetSelectionContent: View {
    @ObservedObject var onboardingData: OnboardingData
    @Binding var monthlyBudget: Double
    
    private let walletOptions: [Double] = [100, 200, 300, 500, 750, 1000]
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.lg) {
            headerSection
            walletSliderSection
            quickSelectSection
            if !onboardingData.selectedSpendingCategories.isEmpty {
                BudgetAllocationPreview(
                    monthlyBudget: monthlyBudget,
                    selectedCategories: onboardingData.selectedSpendingCategories
                )
            }
        }
        .padding(.horizontal, PiggySpacing.lg)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Set Up Your Fan Wallet")
                .font(PiggyFont.title1)
                .foregroundColor(.piggyTextPrimary)
            
            Text("Set your monthly K-Pop budget for smarter spending decisions.")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var walletSliderSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Current budget display
            VStack(spacing: PiggySpacing.xs) {
                Text("K-Pop Fund")
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
                
                Text("$\(Int(monthlyBudget))")
                    .font(PiggyFont.budgetAmount)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, PiggySpacing.cardPadding)
            .padding(.vertical, PiggySpacing.cardVertical)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                            .stroke(Color.piggyCardBorder, lineWidth: 1)
                    )
            )
            
            // Custom slider
            VStack(spacing: PiggySpacing.sm) {
                CustomSlider(
                    value: $monthlyBudget,
                    range: 50...2000,
                    step: 25
                )
                
                HStack {
                    Text("$50")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                    Spacer()
                    Text("$2000+")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
        }
    }
    
    private var quickSelectSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Quick Select")
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(.piggyTextPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: PiggySpacing.sm) {
                ForEach(walletOptions, id: \.self) { option in
                    WalletOptionButton(
                        amount: option,
                        isSelected: monthlyBudget == option,
                        onSelect: { monthlyBudget = option }
                    )
                }
            }
        }
    }
}

// MARK: - Custom Slider
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        Slider(value: $value, in: range, step: step)
            .accentColor(.piggyPrimary)
    }
}

// MARK: - Wallet Option Button
struct WalletOptionButton: View {
    let amount: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text("$\(Int(amount))")
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(isSelected ? .white : .piggyTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(isSelected ? .primaryButton() : .secondaryButton())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Budget Selection Breakdown View  
struct BudgetSelectionBreakdownView: View {
    let monthlyBudget: Double
    let selectedCategories: Set<String>
    
    // Map spending category IDs to display data
    private let categoryMapping: [String: (name: String, color: Color, emoji: String)] = [
        "albums": ("Albums & Photocards", Color.pink, "💿"),
        "merch": ("Official Merch", Color.blue, "🛍️"),
        "concerts": ("Concerts & Shows", Color.purple, "🎤"),
        "events": ("Fan Events", Color.green, "👥"),
        "subs": ("Subscriptions & Apps", Color.orange, "📱")
    ]
    
    // Generate realistic breakdown based on selected categories
    private var breakdownItems: [(String, Double, Color, String)] {
        let categories = Array(selectedCategories)
        guard !categories.isEmpty else { return [] }
        
        // Smart percentage distribution based on number of categories
        let percentages: [Double]
        switch categories.count {
        case 1:
            percentages = [1.0]
        case 2:
            percentages = [0.60, 0.40]
        case 3:
            percentages = [0.50, 0.30, 0.20]
        case 4:
            percentages = [0.40, 0.30, 0.20, 0.10]
        case 5:
            percentages = [0.35, 0.25, 0.20, 0.15, 0.05]
        default:
            let evenSplit = 1.0 / Double(categories.count)
            percentages = Array(repeating: evenSplit, count: categories.count)
        }
        
        return categories.enumerated().compactMap { index, categoryId in
            guard let categoryData = categoryMapping[categoryId],
                  index < percentages.count else { return nil }
            return (categoryData.name, percentages[index], categoryData.color, categoryData.emoji)
        }
    }
    
    var body: some View {
        PiggyCard(style: .primary) {
            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                Text("Your Wishlist Allocation")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                if breakdownItems.isEmpty {
                    Text("Select wishlist priorities to see allocation")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                        .italic()
                } else {
                    ForEach(Array(breakdownItems.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: PiggySpacing.sm) {
                            Text(item.3)
                                .font(.system(size: 14))
                            
                            Text(item.0)
                                .font(PiggyFont.caption1)
                                .foregroundColor(.piggyTextSecondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(Int(monthlyBudget * item.1))")
                                    .font(PiggyFont.caption1)
                                    .fontWeight(.medium)
                                    .foregroundColor(.piggyTextPrimary)
                                Text("\(Int(item.1 * 100))%")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.piggyTextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Budget Allocation Preview (Alias for backward compatibility)
typealias BudgetAllocationPreview = BudgetSelectionBreakdownView

#Preview {
    BudgetSelectionView(
        onboardingData: OnboardingData(),
        monthlyBudget: .constant(300),
        onComplete: {},
        onBack: {}
    )
}