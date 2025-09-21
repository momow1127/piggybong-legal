import SwiftUI

// MARK: - Add Idol Bubble Component
struct AddIdolBubbleView: View {
    let onTapAdd: () -> Void
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Interactive add button - matching idol circle size exactly
            Button(action: onTapAdd) {
                ZStack {
                    Circle()
                        .stroke(
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .foregroundColor(.piggyTextSecondary.opacity(0.4))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "plus")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            .buttonStyle(.plain)
            
            // Label below circle to match idol layout  
            Text(revenueCatManager.isSubscriptionActive || revenueCatManager.hasValidPromoCode ? "Add Idol" : "Upgrade")
                .font(PiggyFont.caption)
                .foregroundColor(.piggyTextSecondary)
                .lineLimit(1)
        }
        .frame(width: 64) // Consistent width matching idol circles
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 16) {
        AddIdolBubbleView(onTapAdd: { print("Add idol tapped") })
        
        // Example idol bubble for comparison
        VStack(spacing: 8) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.piggyPrimary.opacity(0.6), Color.piggyAccent.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Text("BTS")
                        .font(PiggyFont.captionEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                )
            
            Text("BTS")
                .font(PiggyFont.caption)
                .foregroundColor(.piggyTextSecondary)
                .lineLimit(1)
        }
        .frame(width: 64)
    }
    .padding()
    .background(PiggyGradients.background)
}