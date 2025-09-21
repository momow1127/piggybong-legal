import SwiftUI
import Charts

// MARK: - Reusable Components
// Note: PiggyButton and PiggyCard have been moved to DesignSystem/Components/
// This file now contains specialized feature-specific components

// MARK: - Feature Card Component

struct PiggyFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    var isSelected: Bool = false
    var action: (() -> Void)? = nil
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: PiggySpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                // Content
                VStack(spacing: PiggySpacing.xs) {
                    Text(title)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            PiggyCard(style: isSelected ? .outlined : .elevated) {
                Color.clear
            }
        )
        .scaleEffect({
            if isPressed {
                return 0.95
            } else if isSelected {
                return 1.05
            } else {
                return 1.0
            }
        }())
        .opacity(isPressed ? 0.9 : 1.0)
        .animation(PiggyAnimations.springBouncy, value: isSelected)
        .animation(PiggyAnimations.fast, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Dropdown Component

struct PiggyDropdown<T: Hashable & CustomStringConvertible>: View {
    let title: String
    let options: [T]
    @Binding var selectedOption: T?
    var placeholder: String = "Select an option"
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            Text(title)
                .font(PiggyFont.callout)
                .foregroundColor(.piggyTextSecondary)
            
            VStack(spacing: 0) {
                // Selected option display
                Button(action: { 
                    withAnimation(PiggyAnimations.standard) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(selectedOption?.description ?? placeholder)
                            .font(PiggyFont.body)
                            .foregroundColor(selectedOption != nil ? .piggyTextPrimary : .piggyTextSecondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.piggyTextSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(PiggyAnimations.standard, value: isExpanded)
                    }
                    .padding(.horizontal, PiggySpacing.md)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.piggyCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                                    .stroke(Color.piggyTextSecondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Options list
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(Array(options.enumerated()), id: \.element) { index, option in
                            Button(action: {
                                selectedOption = option
                                withAnimation(PiggyAnimations.standard) {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(option.description)
                                        .font(PiggyFont.body)
                                        .foregroundColor(.piggyTextPrimary)
                                    
                                    Spacer()
                                    
                                    if selectedOption == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.piggyAccent)
                                    }
                                }
                                .padding(.horizontal, PiggySpacing.md)
                                .padding(.vertical, 12)
                                .background(
                                    Color.piggyCardBackground.opacity(0.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < options.count - 1 {
                                Divider()
                                    .background(Color.piggyTextSecondary.opacity(0.2))
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                            .fill(Color.piggyCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                                    .stroke(Color.piggyTextSecondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .offset(y: -1) // Overlap border
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
        }
    }
}

// MARK: - Data Visualization Components

struct PiggyProgressBar: View {
    let value: Double // 0.0 to 1.0
    let label: String
    var color: Color = .piggyAccent
    var showPercentage: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
            HStack {
                Text(label)
                    .font(PiggyFont.callout)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                if showPercentage {
                    Text("\(Int(value * 100))%")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.piggyTextSecondary.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 8)
                        .animation(PiggyAnimations.standard, value: value)
                }
            }
            .frame(height: 8)
        }
    }
}

struct PiggyDonutChart: View {
    let data: [(String, Double, Color)]
    let total: Double
    @State private var animationProgress: Double = 0
    
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.piggyTextSecondary.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Data segments
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    let startAngle = startAngleFor(index: index)
                    let endAngle = endAngleFor(index: index)
                    
                    Circle()
                        .trim(from: startAngle / 360, to: endAngle / 360 * animationProgress)
                        .stroke(item.2, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                }
                
                // Center content
                VStack(spacing: PiggySpacing.xs) {
                    Text("$\(Int(total))")
                        .font(PiggyFont.title3)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text("Total")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: PiggySpacing.sm) {
                        Circle()
                            .fill(item.2)
                            .frame(width: 12, height: 12)
                        
                        Text(item.0)
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextPrimary)
                        
                        Spacer()
                        
                        Text("$\(Int(item.1))")
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(PiggyAnimations.standard.delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func startAngleFor(index: Int) -> Double {
        let previousValues = data.prefix(index).reduce(0) { $0 + $1.1 }
        return (previousValues / total) * 360
    }
    
    private func endAngleFor(index: Int) -> Double {
        let upToCurrentValues = data.prefix(index + 1).reduce(0) { $0 + $1.1 }
        return (upToCurrentValues / total) * 360
    }
}

struct PiggyBarChart: View {
    let data: [(String, Double)]
    let maxValue: Double
    var barColor: Color = .piggyAccent
    @State private var animationProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            HStack(alignment: .bottom, spacing: PiggySpacing.sm) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: PiggySpacing.xs) {
                        // Value label
                        Text("$\(Int(item.1))")
                            .font(PiggyFont.caption2)
                            .foregroundColor(.piggyTextSecondary)
                            .opacity(animationProgress)
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(width: 24, height: CGFloat(item.1 / maxValue) * CGFloat(100) * CGFloat(animationProgress))
                            .animation(PiggyAnimations.standard, value: animationProgress)
                        
                        // Category label
                        Text(item.0)
                            .font(PiggyFont.caption2)
                            .foregroundColor(.piggyTextSecondary)
                            .rotationEffect(.degrees(-45))
                            .frame(width: 40)
                    }
                }
            }
            .frame(height: 140)
        }
        .onAppear {
            withAnimation(PiggyAnimations.standard.delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Quick Stats Card

struct PiggyStatsCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let trend: StatsTrend?
    var accentColor: Color = .piggyAccent
    
    enum StatsTrend {
        case up(String)
        case down(String)
        case neutral(String)
        
        var color: Color {
            switch self {
            case .up: return .budgetGreen
            case .down: return .budgetRed
            case .neutral: return .piggyTextSecondary
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down" 
            case .neutral: return "minus"
            }
        }
        
        var text: String {
            switch self {
            case .up(let text), .down(let text), .neutral(let text):
                return text
            }
        }
    }
    
    var body: some View {
        PiggyCard(style: .elevated) {
            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(accentColor)
                    
                    Spacer()
                    
                    if let trend = trend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(trend.text)
                                .font(PiggyFont.caption2)
                        }
                        .foregroundColor(trend.color)
                    }
                }
                
                Text(value)
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(title)
                    .font(PiggyFont.callout)
                    .foregroundColor(.piggyTextSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextTertiary)
                }
            }
        }
    }
}

// MARK: - Preview Examples

#Preview("Button Styles") {
    VStack(spacing: PiggySpacing.md) {
        PiggyButton("Primary Button", action: {})
        PiggyButton(title: "Secondary Button", action: {}, style: .secondary)
        PiggyButton(title: "Tertiary Button", action: {}, style: .tertiary)
        PiggyButton(title: "Loading...", action: {}, isLoading: true)
        PiggyButton(title: "With Icon", action: {}, icon: "star.fill")
    }
    .padding()
    .background(Color.piggyBackground)
}

#Preview("Cards & Components") {
    ScrollView {
        VStack(spacing: PiggySpacing.lg) {
            PiggyFeatureCard(
                icon: "star.fill",
                title: "Feature Title",
                description: "This is a description of the feature",
                accentColor: .piggyAccent
            )
            
            PiggyStatsCard(
                icon: "dollarsign.circle.fill",
                title: "Monthly Budget",
                value: "$300",
                subtitle: "Remaining this month",
                trend: .up("12%")
            )
            
            PiggyProgressBar(
                value: 0.65,
                label: "Concert Savings",
                color: .piggyAccent
            )
        }
        .padding()
    }
    .background(Color.piggyBackground)
}