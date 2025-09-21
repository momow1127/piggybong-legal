import SwiftUI

// MARK: - Fan Priority Planner Design Specifications
// Transforming PiggyBong onboarding from "budget tracker" to "decision-making tool"

// MARK: - 1. Enhanced Visual Language

struct PriorityPlannerGradients {
    // Empowerment-focused gradients (evolution from restrictive purple/pink)
    static let empowermentPrimary = LinearGradient(
        colors: [
            Color(hex: "#FF6B9D"),  // Confident pink
            Color(hex: "#C147E9"),  // Decisive purple  
            Color(hex: "#4E9AF1")   // Aspirational blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let decisionMaking = LinearGradient(
        colors: [
            Color(hex: "#FFE066"),  // Optimistic yellow
            Color(hex: "#FF9A56"),  // Energetic orange
            Color(hex: "#FF6B9D")   // Action pink
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let prioritySuccess = LinearGradient(
        colors: [
            Color(hex: "#00F5A0"),  // Achievement green
            Color(hex: "#00D9F5")   // Progress cyan
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Maintains K-pop aesthetic while feeling empowering
    static let background = LinearGradient(
        colors: [
            Color(hex: "#0D0015"),  // Deep space
            Color(hex: "#1A0033"),  // Dream purple
            Color(hex: "#0D0015")   // Returns to depth
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 2. Interactive Elements Enhancement

struct PriorityInteractionComponents {
    
    // Enhanced drag-and-drop with "choice confidence" feedback
    struct PriorityRankingCard: View {
        let item: PriorityItem
        let rank: Int
        @State private var isBeingDragged = false
        @State private var confidenceLevel: Double = 1.0
        
        var body: some View {
            HStack(spacing: 16) {
                // Confidence-based rank indicator
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(item.empowermentDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // "Choice Power" indicator
                VStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < rank ? Color.gray.opacity(0.3) : PriorityPlannerGradients.decisionMaking)
                            .frame(width: 20, height: 3)
                            .animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.1), value: rank)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isBeingDragged ? 
                                    AnyShapeStyle(PriorityPlannerGradients.decisionMaking) : 
                                    AnyShapeStyle(Color.white.opacity(0.1)),
                                lineWidth: isBeingDragged ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isBeingDragged ? .purple.opacity(0.3) : .clear,
                radius: isBeingDragged ? 12 : 0,
                y: isBeingDragged ? 8 : 0
            )
            .rotation3DEffect(
                .degrees(isBeingDragged ? 3 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
        }
    }
    
    // Enhanced budget slider with "capacity" framing
    struct PlanningCapacitySlider: View {
        @Binding var capacity: Double
        @State private var isDragging = false
        @State private var impactOccurred = false
        
        let milestones = [100, 250, 500, 750, 1000]
        
        var body: some View {
            VStack(spacing: 20) {
                // Capacity visualization
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    // Progress ring with gradient
                    Circle()
                        .trim(from: 0.0, to: capacity / 1000)
                        .stroke(PriorityPlannerGradients.empowermentPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: capacity)
                    
                    VStack(spacing: 4) {
                        Text("$\(Int(capacity))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .scaleEffect(isDragging ? 1.1 : 1.0)
                        
                        Text("monthly")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Enhanced slider
                VStack(spacing: 8) {
                    Slider(value: $capacity, in: 50...1000, step: 25) { editing in
                        withAnimation(.spring(response: 0.3)) {
                            isDragging = editing
                        }
                        
                        if editing && !impactOccurred {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            impactOccurred = true
                        } else if !editing {
                            impactOccurred = false
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                    .accentColor(.purple)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    
                    // Milestone indicators
                    HStack {
                        ForEach(milestones, id: \.self) { milestone in
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    capacity = Double(milestone)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(capacity >= Double(milestone) ? PriorityPlannerGradients.prioritySuccess : Color.white.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                    
                                    Text("$\(milestone)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(capacity >= Double(milestone) ? .white : .gray)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 3. Iconography & Visual Metaphors

struct PriorityPlannerIcons {
    
    // Choice & Decision-focused icons
    struct DecisionIcon: View {
        let isActive: Bool
        
        var body: some View {
            ZStack {
                // Base diamond shape representing "choice"
                Diamond()
                    .fill(isActive ? PriorityPlannerGradients.empowermentPrimary : Color.white.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                // Inner sparkle for "decision power"
                if isActive {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isActive ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
    }
    
    struct PriorityLevelIndicator: View {
        let level: Int // 1-3
        let maxLevel: Int = 3
        
        var body: some View {
            HStack(spacing: 2) {
                ForEach(0..<maxLevel, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            index < level ? 
                                AnyShapeStyle(PriorityPlannerGradients.empowermentPrimary) : 
                                AnyShapeStyle(Color.white.opacity(0.2))
                        )
                        .frame(width: 6, height: 12 + (CGFloat(index) * 2))
                        .animation(.spring(response: 0.3).delay(Double(index) * 0.1), value: level)
                }
            }
        }
    }
}

// MARK: - 4. Enhanced Copy Strategy

struct PriorityPlannerCopy {
    
    // Transform budget-restrictive language to empowering choice language
    static let transformedHeadlines = [
        // Budget Selection Screen
        ("Set Your Budget", "Design Your Dreams"),
        ("Monthly K-pop spending", "Monthly fan goal capacity"),
        ("Budget breakdown", "Priority roadmap"),
        
        // Artist Selection Screen  
        ("Choose up to 3 Idols", "Pick Your Priority Artists"),
        ("Get better recommendations", "Focus your fan energy"),
        ("Maximum selected", "Perfect focus achieved"),
        
        // Goal Setting Screen
        ("Set spending limits", "Design your journey"),
        ("Budget allocation", "Priority distribution"),
        ("Spending categories", "Dream categories"),
        
        // Progress/Completion
        ("Stay within budget", "Achieve your priorities"),
        ("Track spending", "Track progress"),
        ("Budget achieved", "Dreams unlocked")
    ]
    
    // Empowerment-focused microcopy
    static let empowermentMicrocopy = [
        "You're in control of your fan journey",
        "Every choice brings you closer to your goals",
        "Smart planning = more experiences",
        "Your priorities, your timeline",
        "Making it happen, step by step"
    ]
}

// MARK: - 5. Animation & Interaction Enhancements

struct PriorityPlannerAnimations {
    
    // "Choice confidence" animation
    static let choiceConfidence = Animation.interpolatingSpring(
        stiffness: 300,
        damping: 15
    )
    
    // "Priority lock-in" animation
    static let priorityLockIn = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6,
        blendDuration: 0.2
    )
    
    // "Dream visualization" animation
    static let dreamVisualization = Animation.easeInOut(duration: 0.8)
        .repeatCount(3, autoreverses: true)
    
    // Success celebration
    static let celebration = Animation.spring(response: 0.3, dampingFraction: 0.5)
}

// MARK: - 6. Supporting Shapes

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 7. Data Models for Enhanced Priority System

struct PriorityItem: Identifiable {
    let id = UUID()
    let title: String
    let budgetDescription: String      // Old restrictive copy
    let empowermentDescription: String // New empowering copy
    let category: PriorityCategory
    let suggestedAllocation: Double
}

enum PriorityCategory: String, CaseIterable {
    case concerts = "concerts"
    case albums = "albums"
    case merch = "merch"
    case events = "events"
    case subscriptions = "subs"
    
    var empowermentTitle: String {
        switch self {
        case .concerts: return "Live Experiences"
        case .albums: return "Music Collection"
        case .merch: return "Fan Expression"
        case .events: return "Community Events"
        case .subscriptions: return "Ongoing Access"
        }
    }
    
    var decisionIcon: String {
        switch self {
        case .concerts: return "music.note.house"
        case .albums: return "opticaldisc"
        case .merch: return "tshirt"
        case .events: return "person.3"
        case .subscriptions: return "app.badge"
        }
    }
    
    var empowermentColor: Color {
        switch self {
        case .concerts: return Color(hex: "#FF6B9D")
        case .albums: return Color(hex: "#4E9AF1")
        case .merch: return Color(hex: "#FFE066")
        case .events: return Color(hex: "#00F5A0")
        case .subscriptions: return Color(hex: "#C147E9")
        }
    }
}

// MARK: - 8. Implementation Strategy

/*
 PHASE 1: Immediate Messaging Updates (Current Sprint)
 - Update all headline copy to choice/decision language
 - Change button text from restrictive to empowering
 - Modify progress indicators to show "completion" vs "limits"
 
 PHASE 2: Visual Hierarchy Enhancement (Next Sprint)
 - Implement new gradient schemes
 - Add choice confidence animations
 - Enhanced drag-and-drop feedback
 - Priority level indicators
 
 PHASE 3: Interaction Revolution (Future Sprint)
 - Gamified priority selection
 - Dynamic visual feedback systems
 - Celebration animations for decisions
 - Advanced priority recommendation engine
 
 Key Metrics to Track:
 - Onboarding completion rates
 - Time spent on priority selection screen
 - User engagement with drag-and-drop interactions
 - Goal achievement rates post-onboarding
 - User retention after 7 days
*/

// MARK: - Usage Examples

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}