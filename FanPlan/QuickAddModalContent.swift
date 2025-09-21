import SwiftUI

// MARK: - Quick Add Modal Content for PiggyModal
struct QuickAddModalContent: View {
    @StateObject private var formData = SimpleQuickAddData()
    @StateObject private var dashboardService = FanDashboardService.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager

    let onSave: (SavedFanActivity) -> Void
    let onCancel: () -> Void

    @State private var submitError: String?
    @FocusState private var isAmountFieldFocused: Bool
    @FocusState private var isNoteFieldFocused: Bool

    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Form Content
            quickAddFormSection

            // Action Buttons
            quickAddActionSection
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isAmountFieldFocused = false
            isNoteFieldFocused = false
        }
        .onAppear {
            loadUserArtists()
        }
    }

    // MARK: - Form Section
    private var quickAddFormSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Amount Input
            amountSection

            // Category Dropdown
            categorySection

            // Artist Dropdown
            artistSection

            // Note Input (Optional)
            noteSection

            // Submit Error
            if let error = submitError {
                Text(error)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Action Section
    private var quickAddActionSection: some View {
        VStack(spacing: PiggySpacing.md) {
            PiggyButton(
                title: "Save Activity",
                action: handleSave,
                style: .primary,
                size: .large,
                isLoading: globalLoading.isVisible,
                isDisabled: globalLoading.isVisible || !formData.isValid
            )

            PiggyButton(
                title: "Cancel",
                action: onCancel,
                style: .secondary,
                size: .large,
                isDisabled: globalLoading.isVisible
            )
        }
    }

    // MARK: - Form Sections

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Amount (USD)")
                .font(PiggyFont.captionEmphasized)
                .foregroundColor(.piggyTextSecondary)

            PiggyTextField(
                "0.00",
                text: $formData.amount,
                style: .primary,
                size: .medium,
                keyboardType: .decimalPad
            )
            .focused($isAmountFieldFocused)
        }
    }

    private var categorySection: some View {
        PiggyMenu(
            "Category",
            placeholder: "Select category",
            selection: $formData.selectedCategoryDisplayName,
            style: .dropdown,
            size: .medium
        ) {
            ForEach(FanCategory.allCases, id: \.rawValue) { category in
                PiggyMenuRow(
                    category.displayName,
                    isSelected: formData.selectedCategory == category,
                    style: .formMenu,
                    onTap: {
                        formData.selectedCategory = category
                        piggyHapticFeedback(.light)
                    }
                )
            }
        }
    }

    private var artistSection: some View {
        PiggyMenu(
            "Artist",
            placeholder: "Select artist",
            selection: $formData.selectedArtistDisplayName,
            style: .dropdown,
            size: .medium
        ) {
            ForEach(formData.availableArtists, id: \.id) { artist in
                PiggyMenuRow(
                    artist.name,
                    isSelected: formData.selectedArtist?.id == artist.id,
                    style: .formMenu,
                    onTap: {
                        formData.selectedArtist = artist
                        piggyHapticFeedback(.light)
                    }
                )
            }
        }
    }

    private var noteSection: some View {
        PiggyTextField(
            "Note (Optional)",
            text: $formData.note,
            style: .multiline,
            size: .medium,
            keyboardType: .default
        )
        .focused($isNoteFieldFocused)
    }

    // MARK: - Actions

    private func loadUserArtists() {
        // Provide fallback artists if dashboard data is not available
        if let dashboardData = dashboardService.dashboardData {
            formData.availableArtists = dashboardData.uiFanArtists
            print("✅ Loaded \(formData.availableArtists.count) artists")
        } else {
            // Create default artists to prevent crashes
            formData.availableArtists = [
                FanArtist(
                    id: UUID(),
                    name: "Default Artist",
                    priorityRank: 1,
                    monthlyAllocation: 50.0,
                    monthSpent: 0.0,
                    totalSpent: 0.0,
                    remainingBudget: 50.0,
                    spentPercentage: 0.0,
                    imageURL: nil,
                    timeline: [],
                    wishlistItems: [],
                    priorities: []
                )
            ]
            print("✅ Using fallback artist data")
        }
        print("📝 Available categories: \(FanCategory.allCases.map { $0.displayName })")
    }

    private func handleSave() {
        guard !globalLoading.isVisible else { return }

        submitError = nil
        globalLoading.show(LoadingMessage.saving, simpleMode: false, priority: .normal)

        Task {
            // Validate form data first
            guard !formData.amount.isEmpty, Double(formData.amount) != nil else {
                await MainActor.run {
                    globalLoading.hide()
                    submitError = "Please enter a valid amount"
                }
                return
            }

            // Call the proper saveFanActivity function with error handling
            let result = await dashboardService.saveFanActivity(
                amountMajor: Double(formData.amount) ?? 0.0,
                categoryId: formData.selectedCategory?.rawValue ?? "other",
                categoryTitle: formData.selectedCategory?.displayName ?? "Other",
                idolId: formData.selectedArtist?.id,
                note: formData.note.isEmpty ? nil : formData.note
            )

            await MainActor.run {
                globalLoading.hide()

                switch result {
                case .success(let insight):
                    // Create success model and call completion
                    let savedActivity = SavedFanActivity(
                        id: UUID(),
                        artistName: formData.selectedArtist?.name ?? "Default Artist",
                        activityType: .purchase,
                        title: "\(formData.selectedCategory?.displayName ?? "Other") Purchase",
                        description: formData.note.isEmpty ? nil : formData.note,
                        amount: Double(formData.amount) ?? 0.0,
                        createdAt: Date(),
                        fanCategory: formData.selectedCategory
                    )

                    print("✅ Activity saved successfully: \(insight)")
                    onSave(savedActivity)

                case .failure(let error):
                    submitError = "Failed to save activity: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Quick Add Modal Content") {
    ZStack {
        PiggyGradients.background

        VStack {
            QuickAddModalContent(
                onSave: { activity in
                    print("Saved: \(activity)")
                },
                onCancel: {
                    print("Cancelled")
                }
            )
            .padding()
        }
    }
    .environmentObject(RevenueCatManager.shared)
    .environmentObject(GlobalLoadingManager.shared)
}