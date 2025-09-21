import SwiftUI

struct QuickAddView: View {
    @StateObject private var quickAddData = QuickAddData()
    @StateObject private var dashboardService = FanDashboardService.shared
    @StateObject private var fanActivityManager = FanActivityManager.shared
    // SmartAllocationService removed - doesn't exist in current codebase
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAnimation = false
    @State private var showPriorityUpdate = false
    @State private var priorityUpdateMessage = ""
    @State private var showCategoryDropdown = false
    
    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PiggySpacing.xl) {
                        // Header
                        headerSection
                        
                        // Artist Selection
                        artistSelectionSection
                        
                        // Category Selection
                        categorySelectionSection
                        
                        // Amount Input
                        amountInputSection
                        
                        // Description Input
                        descriptionInputSection
                        
                        // Context & Special Options
                        contextSection
                        
                        // Submit Button
                        submitButton
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .overlay {
            if showSuccessAnimation {
                SuccessOverlay(priorityUpdateMessage: priorityUpdateMessage)
                    .animation(.spring(), value: showSuccessAnimation)
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            Text("Add a Fan Purchase")
                .font(PiggyFont.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Track your spending by artist and category")
                .font(PiggyFont.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, PiggySpacing.md)
    }
    
    @ViewBuilder
    private var artistSelectionSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            HStack {
                Text("Which artist? 💜")
                    .font(PiggyFont.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if quickAddData.selectedArtist != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if let dashboardData = dashboardService.dashboardData,
               !dashboardData.uiFanArtists.isEmpty {
                // Show user's artists first
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: PiggySpacing.md) {
                    ForEach(dashboardData.uiFanArtists) { fanArtist in
                        QuickAddArtistCard(
                            artist: Artist(id: fanArtist.id, name: fanArtist.name, group: fanArtist.name, imageURL: fanArtist.imageURL),
                            isSelected: quickAddData.selectedArtist?.id == fanArtist.id,
                            priorityBadge: fanArtist.priorityBadge
                        ) {
                            quickAddData.selectedArtist = Artist(id: fanArtist.id, name: fanArtist.name, group: fanArtist.name, imageURL: fanArtist.imageURL)
                        }
                    }
                }
                
                Button(action: {
                    // TODO: Show full artist selection
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add different artist")
                    }
                    .font(PiggyFont.body)
                    .foregroundColor(.piggySecondary)
                    .padding(.vertical, PiggySpacing.sm)
                }
            } else {
                // No artists yet - show popular artists
                Text("Select an artist to track spending")
                    .font(PiggyFont.body)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(PiggySpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
    }
    
    @ViewBuilder
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("What kind of purchase? \(quickAddData.category.emoji)")
                .font(PiggyFont.headline)
                .foregroundColor(.white)
            
            // Dropdown Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCategoryDropdown.toggle()
                }
            }) {
                HStack {
                    Text(quickAddData.category.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(quickAddData.category.displayName)
                            .font(PiggyFont.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(getCategoryDescription(quickAddData.category))
                            .font(PiggyFont.caption1)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(showCategoryDropdown ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showCategoryDropdown)
                }
                .padding(PiggySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .overlay(alignment: .bottom) {
                // Dropdown Options
                if showCategoryDropdown {
                    VStack(spacing: 0) {
                        ForEach(FanCategory.allCases, id: \.self) { category in
                            if category != quickAddData.category {
                                CategoryDropdownOption(
                                    category: category
                                ) {
                                    quickAddData.category = category
                                    quickAddData.updatePlaceholders()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showCategoryDropdown = false
                                    }
                                }
                                .zIndex(1000)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .offset(y: PiggySpacing.xs)
                    .animation(.easeInOut(duration: 0.2), value: showCategoryDropdown)
                    .zIndex(1000)
                }
            }
        }
        .zIndex(showCategoryDropdown ? 1000 : 1)
    }
    
    @ViewBuilder
    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("How much? 💰")
                .font(PiggyFont.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("$")
                    .font(PiggyFont.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("0.00", text: $quickAddData.amount)
                    .font(PiggyFont.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Quick amount buttons
            HStack(spacing: PiggySpacing.sm) {
                ForEach([10, 25, 50, 100], id: \.self) { amount in
                    Button(action: {
                        quickAddData.amount = String(amount)
                    }) {
                        Text("$\(amount)")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var descriptionInputSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("What did you buy? \(quickAddData.category.emoji)")
                .font(PiggyFont.headline)
                .foregroundColor(.white)
            
            TextField(quickAddData.contextualPlaceholder, text: $quickAddData.description, axis: .vertical)
                .font(PiggyFont.body)
                .foregroundColor(.white)
                .padding(PiggySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(Color.white.opacity(0.1))
                )
                .lineLimit(2...4)
        }
    }
    
    @ViewBuilder
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("Add context (optional)")
                .font(PiggyFont.headline)
                .foregroundColor(.white)
            
            TextField("e.g., SEVENTEEN comeback celebration! 🎉", text: $quickAddData.contextNote)
                .font(PiggyFont.body)
                .foregroundColor(.white)
                .padding(PiggySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(Color.white.opacity(0.1))
                )
            
            // Comeback toggle
            Button(action: {
                quickAddData.isComebackRelated.toggle()
            }) {
                HStack {
                    Image(systemName: quickAddData.isComebackRelated ? "checkmark.square.fill" : "square")
                        .foregroundColor(quickAddData.isComebackRelated ? .piggySecondary : .white.opacity(0.6))
                    
                    Text("This is comeback-related! 🎉")
                        .font(PiggyFont.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            
            // Category-specific fields
            if quickAddData.category == .concerts || quickAddData.category == .events {
                TextField("Venue or location (optional)", text: $quickAddData.venueLocation)
                    .font(PiggyFont.body)
                    .foregroundColor(.white)
                    .padding(PiggySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            if quickAddData.category == .albums {
                TextField("Album version (optional)", text: $quickAddData.albumVersion)
                    .font(PiggyFont.body)
                    .foregroundColor(.white)
                    .padding(PiggySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
    }
    
    @ViewBuilder
    private var submitButton: some View {
        Button(action: submitPurchase) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)

                Text("Add Purchase")
                    .font(PiggyFont.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                    .fill(quickAddData.isValid && !globalLoading.isVisible ?
                          PiggyGradients.primaryButton :
                          LinearGradient(
                              colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                              startPoint: .leading,
                              endPoint: .trailing
                          )
                    )
            )
        }
        .disabled(!quickAddData.isValid || globalLoading.isVisible)
        .padding(.bottom, PiggySpacing.xl)
    }
    
    private func submitPurchase() {
        guard !globalLoading.isVisible else { return }

        globalLoading.show(LoadingMessage.saving, simpleMode: false, priority: .normal)

        Task {
            let success = await dashboardService.addPurchase(quickAddData.purchase)

            await MainActor.run {
                globalLoading.hide()

                if success {
                    // Update priority tracking after smart decision
                    updatePriorityAfterPurchase()

                    // Auto-update category priorities based on activity
                    updateCategoryPrioritiesFromActivity()

                    showSuccessAnimation = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                } else {
                    // Handle error - could show alert
                    print("Failed to add purchase")
                }
            }
        }
    }
    
    private func updatePriorityAfterPurchase() {
        guard let artist = quickAddData.selectedArtist,
              let amount = Double(quickAddData.amount) else { return }
        
        // Update priority ranking based on spending behavior
        Task {
            // Use the FanDashboardService to update priority insights
            await FanDashboardService.shared.updatePriorityInsights(
                artistId: artist.id,
                category: quickAddData.category,
                amount: amount
            )
            
            await MainActor.run {
                priorityUpdateMessage = "Priority insights updated for \(artist.name)!"
            }
        }
    }
    
    private func updateCategoryPrioritiesFromActivity() {
        // Create a mock FanActivity from the purchase data for priority calculation
        guard let artist = quickAddData.selectedArtist,
              let amount = Double(quickAddData.amount) else { return }
        
        let activity = FanActivity(
            id: UUID(),
            artistName: artist.name,
            activityType: .purchase,
            title: quickAddData.description.isEmpty ? "\(artist.name) \(quickAddData.category.rawValue)" : quickAddData.description,
            description: quickAddData.description.isEmpty ? nil : quickAddData.description,
            amount: amount,
            createdAt: Date(),
            fanCategory: quickAddData.category
        )
        
        // Update category priorities based on this new activity
        fanActivityManager.didAddActivity(activity)
        
        print("🎯 Updated category priorities after adding: \(activity.title)")
    }
    
    private func getCategoryDescription(_ category: FanCategory) -> String {
        switch category {
        case .concerts: return "Tickets, outfits, lightsticks"
        case .albums: return "Physical & digital albums, PCs"
        case .merch: return "Clothing, accessories, goods"
        case .events: return "KCON, Hi-Touch, fanmeets"
        case .subscriptions: return "Apps, streaming, memberships"
        case .other: return "Other fan-related expenses"
        }
    }
}

// MARK: - Supporting Views

struct CategoryDropdownOption: View {
    let category: FanCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(category.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(PiggyFont.body)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Text(getCategoryDescription(category))
                        .font(PiggyFont.caption1)
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(PiggySpacing.md)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getCategoryDescription(_ category: FanCategory) -> String {
        switch category {
        case .concerts: return "Tickets, outfits, lightsticks"
        case .albums: return "Physical & digital albums, PCs"
        case .merch: return "Clothing, accessories, goods"
        case .events: return "KCON, Hi-Touch, fanmeets"
        case .subscriptions: return "Apps, streaming, memberships"
        case .other: return "Other fan-related expenses"
        }
    }
}

struct QuickAddArtistCard: View {
    let artist: Artist
    let isSelected: Bool
    let priorityBadge: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: PiggySpacing.sm) {
                artistImageView
                artistInfoView
            }
            .frame(maxWidth: .infinity)
            .padding(PiggySpacing.md)
            .background(cardBackground)
        }
    }
    
    private var artistImageView: some View {
        Circle()
            .fill(isSelected ? PiggyGradients.primaryButton : LinearGradient(
                colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(width: 60, height: 60)
            .overlay(artistImageContent)
            .overlay(selectionBorder)
    }
    
    private var artistImageContent: some View {
        Group {
            if let imageURL = artist.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    artistInitial
                }
                .clipShape(Circle())
            } else {
                artistInitial
            }
        }
    }
    
    private var artistInitial: some View {
        Text(String(artist.name.prefix(1)))
            .font(PiggyFont.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    
    private var selectionBorder: some View {
        Circle()
            .stroke(isSelected ? Color.piggySecondary : Color.clear, lineWidth: 3)
    }
    
    private var artistInfoView: some View {
        VStack(spacing: 2) {
            Text(artist.name)
                .font(PiggyFont.caption1)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let badge = priorityBadge {
                Text(badge)
                    .font(PiggyFont.caption2)
                    .foregroundColor(.piggySecondary)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
            .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                    .stroke(isSelected ? Color.piggySecondary : Color.clear, lineWidth: 2)
            )
    }
}


struct SuccessOverlay: View {
    let priorityUpdateMessage: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: PiggySpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Purchase Added!")
                    .font(PiggyFont.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !priorityUpdateMessage.isEmpty {
                    Text(priorityUpdateMessage)
                        .font(PiggyFont.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PiggySpacing.md)
                } else {
                    Text("Your spending has been tracked")
                        .font(PiggyFont.body)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(PiggySpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                    .fill(PiggyGradients.background)
                    .shadow(radius: 20)
            )
        }
    }
}

// MARK: - Quick Add Data Model

@MainActor
class QuickAddData: ObservableObject {
    @Published var selectedArtist: Artist?
    @Published var amount: String = ""
    @Published var category: FanCategory = .other
    @Published var description: String = ""
    @Published var contextNote: String = ""
    @Published var isComebackRelated: Bool = false
    @Published var venueLocation: String = ""
    @Published var albumVersion: String = ""
    @Published var contextualPlaceholder: String = "Enter description..."
    
    var purchase: QuickAddPurchase {
        return QuickAddPurchase(
            selectedArtist: selectedArtist,
            amount: amount,
            category: category,
            description: description,
            contextNote: contextNote,
            isComebackRelated: isComebackRelated,
            venueLocation: venueLocation,
            albumVersion: albumVersion
        )
    }
    
    var isValid: Bool {
        return selectedArtist != nil &&
               !amount.isEmpty &&
               Double(amount) != nil &&
               Double(amount)! > 0 &&
               !description.isEmpty
    }
    
    func updatePlaceholders() {
        guard let artist = selectedArtist else {
            contextualPlaceholder = "Enter description..."
            return
        }
        
        switch category {
        case .concerts:
            contextualPlaceholder = "\(artist.name) concert outfit, lightstick..."
        case .albums:
            contextualPlaceholder = "\(artist.name) latest album, special edition..."
        case .merch:
            contextualPlaceholder = "\(artist.name) hoodie, photobook..."
        // Removed - albums case covers photocards
        case .subscriptions:
            contextualPlaceholder = "\(artist.name) streaming subscription..."
        case .events:
            contextualPlaceholder = "\(artist.name) fanmeet outfit, banner..."
        case .other:
            contextualPlaceholder = "\(artist.name) related purchase..."
        }
    }
}

#Preview {
    QuickAddView()
        .environmentObject(RevenueCatManager.shared)
        .environmentObject(GlobalLoadingManager.shared)
}