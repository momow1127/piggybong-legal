import SwiftUI

struct PurchasesView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddPurchase = false
    @State private var selectedCategory: PurchaseCategory?
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter section
                filterSection
                
                // Purchases list
                purchasesList
            }
            .background(Color.piggyBackground.ignoresSafeArea())
            .navigationTitle("Purchases")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPurchase = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.piggyPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddPurchase) {
                QuickAddPurchaseView()
            }
        }
    }
    
    private var filterSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PiggySpacing.sm) {
                    CategoryFilterChip(
                        category: nil,
                        isSelected: selectedCategory == nil,
                        title: "All"
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(PurchaseCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            title: category.displayName
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, PiggySpacing.md)
            }
        }
        .padding(.vertical, PiggySpacing.sm)
        .background(Color.piggySurface)
    }
    
    private var purchasesList: some View {
        Group {
            if filteredPurchases.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: selectedCategory == nil ? "No purchases yet" : "No \(selectedCategory?.displayName.lowercased() ?? "") purchases",
                    message: "Add your first K-pop purchase to get started!"
                )
                .padding(PiggySpacing.lg)
            } else {
                List {
                    ForEach(groupedPurchases.keys.sorted(by: >), id: \.self) { date in
                        Section(header: sectionHeader(for: date)) {
                            ForEach(groupedPurchases[date] ?? []) { purchase in
                                PurchaseListRow(purchase: purchase)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Delete", role: .destructive) {
                                            deletePurchase(purchase)
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.piggyBackground)
            }
        }
    }
    
    private var filteredPurchases: [Purchase] {
        let purchases = databaseService.purchases
        
        if let category = selectedCategory {
            return purchases.filter { $0.category == category }
        }
        
        return purchases
    }
    
    private var groupedPurchases: [Date: [Purchase]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredPurchases) { purchase in
            calendar.startOfDay(for: purchase.purchaseDate)
        }
    }
    
    private func sectionHeader(for date: Date) -> some View {
        Text(formatSectionDate(date))
            .font(PiggyFont.subheadline)
            .foregroundColor(.piggyTextSecondary)
            .textCase(nil)
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func deletePurchase(_ purchase: Purchase) {
        Task {
            await databaseService.deletePurchase(purchase)
        }
    }
}

struct CategoryFilterChip: View {
    let category: PurchaseCategory?
    let isSelected: Bool
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PiggySpacing.xs) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(PiggyFont.caption1)
            }
            .padding(.horizontal, PiggySpacing.md)
            .padding(.vertical, PiggySpacing.sm)
            .background(isSelected ? Color.piggyPrimary : Color.clear)
            .foregroundColor(isSelected ? .white : .piggyTextPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.piggyPrimary, lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}

struct PurchaseListRow: View {
    let purchase: Purchase
    @EnvironmentObject var databaseService: DatabaseService
    
    private var artist: Artist? {
        databaseService.artists.first { $0.id == purchase.artistId }
    }
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color.piggyPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: purchase.category.icon)
                    .font(.title3)
                    .foregroundColor(.piggyPrimary)
            }
            
            // Purchase details
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(purchase.description)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                HStack(spacing: PiggySpacing.sm) {
                    Text(artist?.displayName ?? "Unknown Artist")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                    
                    Text("•")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                    
                    Text(purchase.category.displayName)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                if let notes = purchase.notes, !notes.isEmpty {
                    Text(notes)
                        .font(PiggyFont.caption2)
                        .foregroundColor(.piggyTextSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Amount and date
            VStack(alignment: .trailing, spacing: PiggySpacing.xs) {
                Text("$\(purchase.amount, specifier: "%.2f")")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(formatPurchaseDate(purchase.purchaseDate))
                    .font(PiggyFont.caption2)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
        .padding(PiggySpacing.md)
        .background(Color.piggySurface)
        .cornerRadius(PiggyBorderRadius.md)
    }
    
    private func formatPurchaseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    PurchasesView()
        .environmentObject(DatabaseService())
        .environmentObject(AuthManager())
}