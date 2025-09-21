import SwiftUI

struct ActivitySavedView: View {
    let savedActivity: SavedFanActivity
    let insightMessage: String
    @Environment(\.dismiss) private var dismiss
    
    // Navigation callbacks
    let onAddAnother: () -> Void
    let onViewDashboard: () -> Void
    let onEditActivity: () -> Void
    
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            PiggyGradients.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: PiggySpacing.xl) {
                    // Header with celebration
                    VStack(spacing: PiggySpacing.lg) {
                        // Success Icon with Animation
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.budgetGreen.opacity(0.2), Color.budgetGreen.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .scaleEffect(showCelebration ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCelebration)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.budgetGreen)
                                .scaleEffect(showCelebration ? 1.0 : 0.3)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: showCelebration)
                        }
                        
                        VStack(spacing: PiggySpacing.sm) {
                            Text("🎉 Activity Saved!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.piggyTextPrimary)
                                .opacity(showCelebration ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.5).delay(0.3), value: showCelebration)
                            
                            Text(insightMessage)
                                .font(PiggyFont.subheadline)
                                .foregroundColor(.piggyTextSecondary)
                                .multilineTextAlignment(.center)
                                .opacity(showCelebration ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: showCelebration)
                        }
                    }
                    
                    // Activity Summary Card
                    activitySummaryCard
                        .opacity(showCelebration ? 1.0 : 0.0)
                        .offset(y: showCelebration ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: showCelebration)
                    
                    // Action Buttons
                    VStack(spacing: PiggySpacing.md) {
                        // Primary Actions
                        VStack(spacing: PiggySpacing.sm) {
                            PiggyButton(
                                title: "Add Another",
                                action: onAddAnother,
                                style: .primary,
                                size: .large
                            )
                            
                            PiggyButton(
                                title: "View Dashboard",
                                action: onViewDashboard,
                                style: .secondary,
                                size: .large
                            )
                        }
                        
                        // Secondary Action
                        Button(action: onEditActivity) {
                            HStack(spacing: PiggySpacing.xs) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                Text("Edit Activity")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.piggySecondary)
                        }
                        .padding(.top, PiggySpacing.xs)
                    }
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .offset(y: showCelebration ? 0 : 30)
                    .animation(.easeOut(duration: 0.7).delay(0.6), value: showCelebration)
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.vertical, PiggySpacing.xl)
            }
        }
        .onAppear {
            // Trigger celebration animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCelebration = true
                
                // Success haptic
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
    }
    
    // MARK: - Activity Summary Card
    private var activitySummaryCard: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.lg) {
            Text("Activity Summary")
                .font(PiggyFont.headline)
                .foregroundColor(.piggyTextPrimary)
            
            VStack(spacing: PiggySpacing.md) {
                // Category Row
                HStack {
                    Text(savedActivity.categoryIcon)
                        .font(.system(size: 18))
                    Text(savedActivity.categoryTitle)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextPrimary)
                    Spacer()
                }
                
                // Artist Row
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.piggySecondary)
                    Text(savedActivity.artistName ?? "Unknown Artist")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextPrimary)
                    Spacer()
                }
                
                // Amount Row
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.budgetGreen)
                    Text("$\(savedActivity.amount ?? 0.0, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.piggyTextPrimary)
                    Spacer()
                }
                
                // Note Row (if exists)
                if let note = savedActivity.description, !note.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16))
                            .foregroundColor(.piggyTextSecondary)
                        Text(note)
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
        }
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(Color.piggyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Models
// SavedFanActivity is now a typealias to FanActivity - see Typealiases.swift

// MARK: - Preview
#Preview {
    ActivitySavedView(
        savedActivity: FanActivity(
            id: UUID(),
            artistName: "NewJeans",
            activityType: .purchase,
            title: "Official Merch",
            description: "Limited edition hoodie from comeback collection",
            amount: 45.00,
            createdAt: Date(),
            fanCategory: .merch
        ),
        insightMessage: "Great! You're staying within budget for Merch this month.",
        onAddAnother: { print("Add Another") },
        onViewDashboard: { print("View Dashboard") },
        onEditActivity: { print("Edit Activity") }
    )
    .preferredColorScheme(.dark)
}