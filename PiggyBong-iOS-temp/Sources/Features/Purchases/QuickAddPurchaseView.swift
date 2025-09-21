import SwiftUI

struct QuickAddPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var budgetService: BudgetService
    
    @State private var selectedArtist: Artist?
    @State private var selectedCategory: PurchaseCategory = .album
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var notes: String = ""
    @State private var purchaseDate = Date()
    @State private var showingCustomAmount = false
    @State private var showingArtistPicker = false
    
    // Quick preset amounts for different categories
    private let presetAmounts: [PurchaseCategory: [Double]] = [
        .album: [15.99, 25.99, 35.99, 45.99],
        .concert: [75.00, 150.00, 250.00, 400.00],
        .merchandise: [20.00, 35.00, 50.00, 75.00],
        .digital: [1.99, 9.99, 19.99, 29.99],
        .photocard: [5.00, 10.00, 15.00, 25.00],
        .other: [10.00, 25.00, 50.00, 100.00]
    ]
    
    private var currentPresets: [Double] {
        presetAmounts[selectedCategory] ?? []
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PiggySpacing.lg) {
                    // Header
                    headerSection
                    
                    // Artist Selection
                    artistSelectionSection
                    
                    // Category Selection
                    categorySelectionSection
                    
                    // Amount Selection
                    amountSelectionSection
                    
                    // Description
                    descriptionSection
                    
                    // Notes (Optional)
                    notesSection
                    
                    // Date
                    dateSection
                    
                    Spacer(minLength: PiggySpacing.xl)
                }
                .padding(.horizontal, PiggySpacing.lg)
            }
            .background(Color.piggyBackground.ignoresSafeArea())
            .navigationTitle("Add Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPurchase()
                    }
                    .disabled(!canAddPurchase)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingArtistPicker) {
                ArtistPickerView(selectedArtist: $selectedArtist)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            Image(systemName: "bag.fill.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.piggyPrimary)
            
            Text("Quick Add Purchase")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)
        }
        .padding(.top, PiggySpacing.md)
    }
    
    private var artistSelectionSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Artist")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
            
            Button(action: { showingArtistPicker = true }) {
                HStack {
                    if let artist = selectedArtist {
                        Circle()
                            .fill(Color.piggyPrimary.opacity(0.1))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(String(artist.name.prefix(1)))
                                    .font(PiggyFont.caption1)
                                    .foregroundColor(.piggyPrimary)
                            )
                        
                        Text(artist.displayName)
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextPrimary)
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.piggyPrimary)
                        
                        Text("Select Artist")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                .padding(PiggySpacing.md)
                .background(Color.piggySurface)
                .cornerRadius(PiggyBorderRadius.md)
            }
        }
    }
    
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Category")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PiggySpacing.sm), count: 3), spacing: PiggySpacing.sm) {
                ForEach(PurchaseCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        // Clear amount when category changes
                        if !showingCustomAmount {
                            amount = ""
                        }
                    }
                }
            }
        }
    }
    
    private var amountSelectionSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Amount")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
            
            if showingCustomAmount {
                HStack {
                    Text("$")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextPrimary)
                    
                    TextField("0.00", text: $amount)
                        .font(PiggyFont.body)
                        .keyboardType(.decimalPad)
                }
                .padding(PiggySpacing.md)
                .background(Color.piggySurface)
                .cornerRadius(PiggyBorderRadius.md)
                
                Button("Use Presets") {
                    showingCustomAmount = false
                    amount = ""
                }
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyPrimary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PiggySpacing.sm), count: 2), spacing: PiggySpacing.sm) {
                    ForEach(currentPresets, id: \.self) { preset in
                        AmountButton(
                            amount: preset,
                            isSelected: amount == String(preset)
                        ) {
                            amount = String(preset)
                        }
                    }
                }
                
                Button("Custom Amount") {
                    showingCustomAmount = true
                    amount = ""
                }
                .font(PiggyFont.caption1)
                .foregroundColor(.piggyPrimary)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Description")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
            
            TextField("What did you buy?", text: $description)
                .textFieldStyle(PiggyTextFieldStyle())
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Notes (Optional)")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
            
            TextField("Any additional details...", text: $notes, axis: .vertical)
                .textFieldStyle(PiggyTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text("Purchase Date")
                .font(PiggyFont.subheadline)
                .foregroundColor(.piggyTextSecondary)
            
            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
    }
    
    private var canAddPurchase: Bool {
        selectedArtist != nil &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        !description.isEmpty
    }
    
    private func addPurchase() {
        guard let artist = selectedArtist,
              let amountValue = Double(amount),
              let user = authManager.currentUser else { return }
        
        let purchase = Purchase(
            userId: user.id,
            artistId: artist.id,
            amount: amountValue,
            category: selectedCategory,
            description: description,
            notes: notes.isEmpty ? nil : notes,
            purchaseDate: purchaseDate
        )
        
        Task {
            await databaseService.addPurchase(purchase)
            await budgetService.addPurchaseToBudget(purchase)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct CategoryButton: View {
    let category: PurchaseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: PiggySpacing.xs) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .piggyPrimary)
                
                Text(category.displayName)
                    .font(PiggyFont.caption2)
                    .foregroundColor(isSelected ? .white : .piggyTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? Color.piggyPrimary : Color.piggySurface)
            .cornerRadius(PiggyBorderRadius.md)
        }
    }
}

struct AmountButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("$\(amount, specifier: "%.2f")")
                .font(PiggyFont.bodyEmphasized)
                .foregroundColor(isSelected ? .white : .piggyTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.piggyPrimary : Color.piggySurface)
                .cornerRadius(PiggyBorderRadius.md)
        }
    }
}

struct ArtistPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @Binding var selectedArtist: Artist?
    @State private var searchText = ""
    
    private var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return databaseService.artists
        } else {
            return databaseService.artists.filter { artist in
                artist.name.localizedCaseInsensitiveContains(searchText) ||
                (artist.group?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search artists...")
                
                List(filteredArtists) { artist in
                    Button(action: {
                        selectedArtist = artist
                        dismiss()
                    }) {
                        HStack(spacing: PiggySpacing.md) {
                            Circle()
                                .fill(Color.piggyPrimary.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(artist.name.prefix(1)))
                                        .font(PiggyFont.bodyEmphasized)
                                        .foregroundColor(.piggyPrimary)
                                )
                            
                            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                                Text(artist.name)
                                    .font(PiggyFont.bodyEmphasized)
                                    .foregroundColor(.piggyTextPrimary)
                                
                                if let group = artist.group {
                                    Text(group)
                                        .font(PiggyFont.caption1)
                                        .foregroundColor(.piggyTextSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedArtist?.id == artist.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.piggyPrimary)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.piggyTextSecondary)
            
            TextField(placeholder, text: $text)
                .font(PiggyFont.body)
        }
        .padding(PiggySpacing.md)
        .background(Color.piggySurface)
        .cornerRadius(PiggyBorderRadius.md)
        .padding(.horizontal, PiggySpacing.md)
    }
}

#Preview {
    QuickAddPurchaseView()
        .environmentObject(DatabaseService())
        .environmentObject(AuthManager())
        .environmentObject(BudgetService())
}