import SwiftUI

// MARK: - Original Priority Design Implementation
struct OriginalPriorityView: View {
    @State private var priorities: [OriginalPriorityItem] = []
    @State private var isReordering = false
    @Environment(\.dismiss) var dismiss
    
    let onNext: ([FanCategory]) -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Original background gradient from design specs
            PriorityPlannerGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Instructions card
                        instructionsCard
                        
                        // Priority list with original design
                        priorityListSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                // Continue button
                continueButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOriginalPriorities()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Set Priorities")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Instructions Card
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.yellow)
                
                Text("Rank Your Fan Priorities")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Drag to reorder based on what matters most to you. This helps us personalize your experience.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(nil)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Priority List Section
    private var priorityListSection: some View {
        VStack(spacing: 12) {
            ForEach(priorities.indices, id: \.self) { index in
                PriorityRankingCard(
                    item: priorities[index],
                    rank: index + 1,
                    isReordering: isReordering
                )
            }
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                let categories = priorities.map { $0.category }
                onNext(categories)
            }) {
                HStack {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(PriorityPlannerGradients.empowermentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(
            Rectangle()
                .fill(PriorityPlannerGradients.background)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Data Loading
    private func loadOriginalPriorities() {
        priorities = [
            OriginalPriorityItem(
                title: "Concerts & Shows",
                empowermentDescription: "Live experiences and unforgettable moments",
                category: .concerts
            ),
            OriginalPriorityItem(
                title: "Albums & Photocards",
                empowermentDescription: "Music collection and trading treasures",
                category: .albums
            ),
            OriginalPriorityItem(
                title: "Official Merch",
                empowermentDescription: "Express your fandom with style",
                category: .merch
            ),
            OriginalPriorityItem(
                title: "Fan Events (KCON, Hi-Touch)",
                empowermentDescription: "Connect with artists and community",
                category: .events
            ),
            OriginalPriorityItem(
                title: "Subscriptions & Fan Apps",
                empowermentDescription: "Stay connected and access exclusive content",
                category: .subscriptions
            )
        ]
    }
}

// MARK: - Priority Ranking Card (Original Design)
struct PriorityRankingCard: View {
    let item: OriginalPriorityItem
    let rank: Int
    let isReordering: Bool
    @State private var isBeingDragged = false
    @State private var confidenceLevel: Double = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            rankIndicator
            itemContent
            Spacer()
            choicePowerIndicator
        }
        .padding(16)
        .background(cardBackground)
        .shadow(
            color: isBeingDragged ? .purple.opacity(0.3) : .clear,
            radius: isBeingDragged ? 12 : 0,
            y: isBeingDragged ? 8 : 0
        )
    }
    
    private var rankIndicator: some View {
        ZStack {
            Circle()
                .fill(PriorityPlannerGradients.empowermentPrimary)
                .frame(width: 40, height: 40)
                .shadow(color: .purple.opacity(0.4), radius: confidenceLevel * 8)
            
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .scaleEffect(isBeingDragged ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isBeingDragged)
    }
    
    private var itemContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(item.empowermentDescription)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
    
    private var choicePowerIndicator: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < rank ? Color.gray.opacity(0.3) : Color.orange)
                    .frame(width: 20, height: 3)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Original Design Gradients
struct PriorityPlannerGradients {
    // Empowerment-focused gradients (evolution from restrictive purple/pink)
    static let empowermentPrimary = LinearGradient(
        colors: [
            Color.pink,        // Confident pink
            Color.purple,      // Decisive purple
            Color.blue         // Aspirational blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let decisionMaking = LinearGradient(
        colors: [
            Color.yellow,      // Optimistic yellow
            Color.orange,      // Energetic orange
            Color.pink         // Action pink
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Maintains K-pop aesthetic while feeling empowering
    static let background = LinearGradient(
        colors: [
            Color.black,       // Deep space
            Color.purple.opacity(0.3),  // Dream purple
            Color.black        // Returns to depth
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Priority Item Model (Original)
struct OriginalPriorityItem: Identifiable {
    let id = UUID()
    let title: String
    let empowermentDescription: String
    let category: FanCategory
}