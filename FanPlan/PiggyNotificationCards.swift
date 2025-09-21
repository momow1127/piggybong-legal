import SwiftUI

// MARK: - Fan-Focused Notification Card Component

struct PiggyNotificationCard: View {
    let type: NotificationType
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    var timestamp: Date? = nil
    var isNew: Bool = false
    
    enum NotificationType {
        case aiTip
        case comeback
        case savings
        case concert
        case merch
        case budget
        case achievement
        
        var icon: String {
            switch self {
            case .aiTip: return "sparkles"
            case .comeback: return "star.fill"
            case .savings: return "dollarsign.circle.fill"
            case .concert: return "ticket.fill"
            case .merch: return "bag.fill"
            case .budget: return "chart.pie.fill"
            case .achievement: return "trophy.fill"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .aiTip: return .piggyAccent // Gold
            case .comeback: return Color(red: 1.0, green: 0.42, blue: 0.28) // Warm orange
            case .savings: return .budgetGreen
            case .concert: return .piggyPrimary
            case .merch: return .piggySecondary
            case .budget: return .piggyAccent
            case .achievement: return .piggyAccent
            }
        }
        
        var priority: Priority {
            switch self {
            case .comeback, .concert: return .high
            case .aiTip, .savings, .achievement: return .medium
            case .budget, .merch: return .low
            }
        }
    }
    
    enum Priority {
        case high, medium, low
        
        var titleWeight: Font.Weight {
            switch self {
            case .high: return .bold
            case .medium, .low: return .regular
            }
        }
    }
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            // Icon with accent color
            ZStack {
                Circle()
                    .fill(type.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(type.accentColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(PiggyFont.bodyEmphasized)
                        .fontWeight(type.priority.titleWeight)
                        .foregroundColor(.piggyTextPrimary)
                        .lineLimit(1)
                    
                    if isNew {
                        Circle()
                            .fill(type.accentColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    if let timestamp = timestamp {
                        Text(timeAgoString(from: timestamp))
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextTertiary)
                    }
                }
                
                Text(subtitle)
                    .font(PiggyFont.callout)
                    .foregroundColor(.piggyTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(PiggySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(Color.piggyCardBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval/60))m" }
        if interval < 86400 { return "\(Int(interval/3600))h" }
        return "\(Int(interval/86400))d"
    }
}

// MARK: - Copy Guidelines Constants

enum PiggyCopyGuidelines {
    // Character limits
    static let headlineMax = 50  // ~10 words
    static let subtitleMax = 100 // ~20 words  
    static let actionLabelMax = 20 // ~3 words
    
    // Fan-friendly action verbs
    static let actionVerbs = [
        "Save now",
        "See details", 
        "Start saving",
        "Check it out",
        "Learn more",
        "Get tickets",
        "Join now"
    ]
    
    // Positive reinforcement phrases
    static let encouragements = [
        "You're doing great!",
        "Almost there!",
        "Nice progress!",
        "Keep going!",
        "Smart choice!",
        "Great timing!"
    ]
}

// MARK: - Preview

#Preview("Notification Cards") {
    ScrollView {
        VStack(spacing: PiggySpacing.md) {
            PiggyNotificationCard(
                type: .comeback,
                title: "SEVENTEEN comeback!",
                subtitle: "New album drops Dec 15 - you've got $80 saved",
                action: {},
                timestamp: Date(),
                isNew: true
            )

            PiggyNotificationCard(
                type: .aiTip,
                title: "Smart fan tip",
                subtitle: "Join a GO for 30% off shipping on albums",
                action: {},
                timestamp: Date().addingTimeInterval(-3600)
            )

            PiggyNotificationCard(
                type: .savings,
                title: "Goal reached!",
                subtitle: "Your concert fund hit $500!",
                action: {},
                timestamp: Date().addingTimeInterval(-7200)
            )
        }
        .padding()
    }
    .background(Color.piggyBackground)
}
