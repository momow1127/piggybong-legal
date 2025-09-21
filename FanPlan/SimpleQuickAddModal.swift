import SwiftUI

// MARK: - Simplified Quick Add Modal using basic SwiftUI
struct SimpleQuickAddModal: View {
    @StateObject private var formData = SimpleQuickAddData()
    @StateObject private var dashboardService = FanDashboardService.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager

    let onSave: (SavedFanActivity) -> Void
    let onCancel: () -> Void

    @State private var submitError: String?
    @State private var isSaving = false
    @FocusState private var isAmountFieldFocused: Bool
    @FocusState private var isNoteFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            PiggyGradients.background
                .ignoresSafeArea()

            // Modal Content wrapped in ScrollView for proper sizing
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: PiggySpacing.lg) {
                        // Header Section (consistent with other modals)
                        quickAddHeaderSection

                        // Form Content
                        quickAddFormSection

                        // Action Buttons
                        quickAddActionSection

                        // Extra padding at bottom to ensure nothing is cut off
                        Color.clear
                            .frame(height: geometry.safeAreaInsets.bottom + PiggySpacing.xl)
                    }
                    .padding(.top, PiggySpacing.sm)
                    .padding(.horizontal, PiggySpacing.md)
                    .padding(.bottom, PiggySpacing.md)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea(.keyboard) // Allow keyboard to push content up
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isAmountFieldFocused = false
            isNoteFieldFocused = false
        }
        .onAppear {
            loadUserArtists()
        }
    }

    // MARK: - Header Section (consistent with tab headers)
    private var quickAddHeaderSection: some View {
        HStack {
            Text("Add Fan Activity")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

            PiggyIconButton(
                "xmark",
                size: .medium,
                style: .tertiary,
                action: onCancel
            )
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
                isLoading: isSaving,
                isDisabled: isSaving
            )

            PiggyButton(
                title: "Cancel",
                action: onCancel,
                style: .secondary,
                size: .large,
                isDisabled: isSaving
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
        guard !isSaving else { return }

        submitError = nil
        isSaving = true

        Task {
            // Validate form data first
            guard !formData.amount.isEmpty, Double(formData.amount) != nil else {
                await MainActor.run {
                    isSaving = false
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
                isSaving = false

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

// MARK: - Form Data Model
class SimpleQuickAddData: ObservableObject {
    @Published var amount: String = ""
    @Published var note: String = ""
    @Published var availableArtists: [FanArtist] = []
    
    @Published var selectedCategory: FanCategory? {
        didSet {
            selectedCategoryDisplayName = selectedCategory?.displayName
        }
    }
    @Published var selectedCategoryDisplayName: String?
    
    @Published var selectedArtist: FanArtist? {
        didSet {
            selectedArtistDisplayName = selectedArtist?.name
        }
    }
    @Published var selectedArtistDisplayName: String?
    
    // Legacy computed properties for backward compatibility
    var selectedCategoryId: String? {
        return selectedCategory?.rawValue
    }
    
    var selectedArtistId: String? {
        return selectedArtist?.id.uuidString
    }
    
    var amountValidation: PiggyTextField.ValidationState {
        if amount.isEmpty {
            return .normal
        }
        
        guard let value = Double(amount), value > 0 else {
            return .error("Please enter a valid amount")
        }
        
        return .normal
    }
    
    var isValid: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        guard selectedCategory != nil else { return false }
        guard selectedArtist != nil else { return false }
        return true
    }
    
    var purchase: QuickAddPurchase {
        let artist = selectedArtist.map { fanArtist in
            Artist(id: fanArtist.id, name: fanArtist.name, imageURL: fanArtist.imageURL)
        }
        return QuickAddPurchase(
            selectedArtist: artist,
            amount: amount,
            category: selectedCategory ?? .other,
            description: note.isEmpty ? "Fan activity purchase" : note,
            contextNote: "",
            isComebackRelated: false,
            venueLocation: "",
            albumVersion: ""
        )
    }
}

// MARK: - Preview
#Preview("Simple Quick Add Modal") {
    ZStack {
        PiggyGradients.background
        
        SimpleQuickAddModal(
            onSave: { activity in
                print("Saved: \(activity)")
            },
            onCancel: {
                print("Cancelled")
            }
        )
    }
    .environmentObject(RevenueCatManager.shared)
    .environmentObject(GlobalLoadingManager.shared)
}
