import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Fan Wishlist View (Immediate Drag-and-Drop)
struct FanWishlistView: View {
    @State private var wishlistItems: [FanWishlistItem] = []
    @State private var selectedItemId: UUID? = nil
    @Environment(\.dismiss) var dismiss
    
    let onNext: ([FanCategory]) -> Void
    let onBack: () -> Void
    
    var body: some View {
        OnboardingContainer(
            buttonTitle: "Continue",
            canProceed: true,
            currentStep: .goalSetting,
            noTopPadding: true,
            onNext: {
                let categories = wishlistItems.map { $0.category }
                onNext(categories)
            }
        ) {
            VStack(spacing: PiggySpacing.lg) {
                // Small top spacing for better visual balance
                Spacer(minLength: PiggySpacing.sm)

                // Title and subtitle
                VStack(spacing: PiggySpacing.sm) {
                    Text("Build Your Fan Wishlist")
                        .font(PiggyFont.sectionTitle)
                        .foregroundColor(.piggyTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Drag and drop to prioritize your fan goals")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Main content - Fixed 5 cards with drag-and-drop
                VStack(spacing: PiggySpacing.md) {
                    ForEach(Array(wishlistItems.enumerated()), id: \.element.id) { index, item in
                        WishlistCard(
                            item: item,
                            index: index,
                            isSelected: selectedItemId == item.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedItemId = item.id
                                }
                            },
                            onDragEnded: { from, to in
                                moveItemFromTo(from: from, to: to)
                            }
                        )
                    }
                }
            }
        }
        .scrollDisabled(true)
        .onAppear {
            loadWishlistItems()
        }
    }

    // MARK: - Data Management
    private func loadWishlistItems() {
        wishlistItems = [
            FanWishlistItem(
                category: .albums,
                title: "Albums & Photocards",
                priceRange: "$15–$30 per album",
                icon: "💿"
            ),
            FanWishlistItem(
                category: .merch,
                title: "Official Merch",
                priceRange: "$15–$80 per item",
                icon: "🛍️"
            ),
            FanWishlistItem(
                category: .concerts,
                title: "Concerts & Shows",
                priceRange: "$100–$400 per show",
                icon: "🎤"
            ),
            FanWishlistItem(
                category: .events,
                title: "Fan Events",
                priceRange: "$45–$1,700 per event",
                icon: "👥"
            ),
            FanWishlistItem(
                category: .subscriptions,
                title: "Subscriptions & Fan Apps",
                priceRange: "$4–$20 per month",
                icon: "📱"
            )
        ]
    }
    
    private func moveItemFromTo(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < wishlistItems.count,
              destinationIndex >= 0, destinationIndex < wishlistItems.count else { return }
        
        // Haptic feedback for drag operation
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            let item = wishlistItems.remove(at: sourceIndex)
            wishlistItems.insert(item, at: destinationIndex)
        }
        
        // Optional: Light haptic after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let completionFeedback = UIImpactFeedbackGenerator(style: .light)
            completionFeedback.impactOccurred()
        }
    }
}

// MARK: - Wishlist Card
struct WishlistCard: View {
    let item: FanWishlistItem
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onDragEnded: (Int, Int) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isPressed = false
    
    var body: some View {
        cardContent
            .scaleEffect(isPressed || isDragging ? 0.95 : 1.0)
            .offset(dragOffset)
            .zIndex(isDragging ? 1 : 0)
            .simultaneousGesture(
                // Tap gesture for selection
                TapGesture()
                    .onEnded { _ in
                        if !isDragging {
                            onTap()
                        }
                    }
            )
            .simultaneousGesture(
                // Short press + drag for reordering
                LongPressGesture(minimumDuration: 0.2)
                    .sequenced(before: DragGesture())
                    .onChanged { value in
                        switch value {
                        case .first(true):
                            // Short press detected - ready to drag
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isPressed = true
                            }
                            // Light haptic feedback
                            let feedback = UIImpactFeedbackGenerator(style: .light)
                            feedback.impactOccurred()
                            
                        case .second(true, let dragValue):
                            // Now dragging
                            if let dragValue = dragValue {
                                isDragging = true
                                dragOffset = dragValue.translation
                            }
                            
                        default:
                            break
                        }
                    }
                    .onEnded { value in
                        switch value {
                        case .second(true, let dragValue):
                            if let dragValue = dragValue {
                                // Calculate target index based on drag distance using NaN safety
                                let cardHeight: CGFloat = 80
                                let dragDistance = NaNSafetyHelper.safeCGFloat(dragValue.translation.height)

                                // Safe division using helper
                                let rawOffset = NaNSafetyHelper.safeDivision(dragDistance, cardHeight, fallback: 0)
                                let targetOffset = Int(round(rawOffset))
                                let targetIndex = max(0, min(4, index + targetOffset))
                                
                                onDragEnded(index, targetIndex)
                                
                                // Medium haptic feedback for successful reorder
                                let feedback = UIImpactFeedbackGenerator(style: .medium)
                                feedback.impactOccurred()
                            }
                            
                        default:
                            break
                        }
                        
                        // Reset all states smoothly
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = .zero
                            isPressed = false
                            isDragging = false
                        }
                    }
            )
    }
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            // Icon
            Text(item.icon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(item.priceRange)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            // Custom drag handle - always visible
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .scaleEffect(1.2)
        }
        .padding(PiggySpacing.md)
        .background(cardBackground)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(isDragging ? 0.18 : 0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        strokeColor,
                        lineWidth: strokeWidth
                    )
            )
    }
    
    private var strokeColor: Color {
        if isDragging {
            return Color.piggyPrimary
        } else if isSelected {
            return Color.piggyPrimary
        } else {
            return Color.white.opacity(0.3)
        }
    }
    
    private var strokeWidth: CGFloat {
        (isDragging || isSelected) ? 2 : 1
    }
}

// MARK: - Fan Wishlist Item Model
struct FanWishlistItem: Identifiable {
    let id = UUID()
    let category: FanCategory
    let title: String
    let priceRange: String
    let icon: String
}


