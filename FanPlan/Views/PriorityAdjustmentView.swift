import SwiftUI

// Note: FanCategory is already available from DashboardModels.swift import

struct PriorityAdjustmentView: View {
    let event: SmartFanPickEvent?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var priorities: [PriorityItem] = []
    @State private var hasChanges = false
    
    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Event Context (if available)
                    if let event = event {
                        eventContextHeader(event)
                    }
                    
                    ScrollView {
                        VStack(spacing: PiggySpacing.lg) {
                            // Instructions
                            instructionCard
                            
                            // Priority List
                            priorityListSection
                            
                            // Save Button
                            saveButton
                        }
                        .padding(PiggySpacing.md)
                    }
                }
            }
            .navigationTitle("Adjust Priorities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadCurrentPriorities()
        }
    }
    
    // MARK: - Event Context Header
    
    private func eventContextHeader(_ event: SmartFanPickEvent) -> some View {
        VStack(spacing: 12) {
            // Event Badge
            HStack(spacing: 8) {
                Text(event.eventType.badgeEmoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.artistName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(event.eventTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            // Recommendation
            HStack {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundColor(event.recommendedPriority.color)
                
                Text(event.recommendedPriority.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .padding(PiggySpacing.md)
        .background(
            LinearGradient(
                colors: [event.eventType.color.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Instruction Card
    
    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("How Priority Works")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                priorityExplanation(level: "High", color: .red, description: "Your top focus - gets most attention")
                priorityExplanation(level: "Medium", color: .orange, description: "Important but flexible")
                priorityExplanation(level: "Low", color: .gray, description: "Nice to have when possible")
            }
        }
        .padding(PiggySpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func priorityExplanation(level: String, color: Color, description: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(level):")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Priority List Section
    
    private var priorityListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Priorities")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach($priorities) { $item in
                    PriorityRow(item: $item) {
                        hasChanges = true
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: savePriorities) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                
                Text("Save Priority Changes")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: hasChanges ? [Color.piggyPrimary, Color.piggySecondary] : [Color.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!hasChanges)
        .padding(.top, PiggySpacing.md)
    }
    
    // MARK: - Helper Functions
    
    private func loadCurrentPriorities() {
        // Load from user data using your original design categories
        priorities = [
            PriorityItem(id: UUID(), name: "Concerts & Shows", category: .concerts, priority: .high),
            PriorityItem(id: UUID(), name: "Albums & Photocards", category: .albums, priority: .medium),
            PriorityItem(id: UUID(), name: "Official Merch", category: .merch, priority: .low),
            PriorityItem(id: UUID(), name: "Fan Events (KCON, Hi-Touch)", category: .events, priority: .low),
            PriorityItem(id: UUID(), name: "Subscriptions & Fan Apps", category: .subscriptions, priority: .low)
        ]
    }
    
    private func savePriorities() {
        // Save priority changes
        // This would update the user's preferences
        HapticManager.medium()
        dismiss()
    }
}

// MARK: - Priority Item Model

struct PriorityItem: Identifiable {
    let id: UUID
    let name: String
    let category: FanCategory
    var priority: PriorityLevel
}

// PriorityLevel is defined in OnboardingModels.swift
extension PriorityLevel {
    var icon: String {
        switch self {
        case .high: return "flame.fill"
        case .medium: return "star.fill"
        case .low: return "circle.fill"
        }
    }
}

// MARK: - Priority Row Component

struct PriorityRow: View {
    @Binding var item: PriorityItem
    let onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Text(item.category.emoji)
                .font(.system(size: 16))
                .foregroundColor(item.priority.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(item.priority.color.opacity(0.1))
                )
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Priority Selector
            Menu {
                ForEach(PriorityLevel.allCases, id: \.self) { level in
                    Button(action: {
                        item.priority = level
                        onChange()
                    }) {
                        Label(
                            level.rawValue,
                            systemImage: level.icon
                        )
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: item.priority.icon)
                        .font(.caption)
                    
                    Text(item.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(item.priority.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.priority.color.opacity(0.1))
                )
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    PriorityAdjustmentView(
        event: SmartFanPickEvent.mockEvents.first
    )
    .environmentObject(SubscriptionService.shared)
}
