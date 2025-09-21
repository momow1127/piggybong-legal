import SwiftUI

struct PiggyBadge: View {
    enum Style {
        case notification
        case count
        case status
        case accent
        
        var backgroundColor: Color {
            switch self {
            case .notification: return .red
            case .count: return .piggyPrimary
            case .status: return .green
            case .accent: return .piggySecondary
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .notification: return .white
            case .count: return .white
            case .status: return .white
            case .accent: return .white
            }
        }
        
        var font: Font {
            switch self {
            case .notification: return .system(size: 10, weight: .bold)
            case .count: return .system(size: 12, weight: .semibold)
            case .status: return .system(size: 11, weight: .medium)
            case .accent: return .system(size: 11, weight: .semibold)
            }
        }
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var minHeight: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 24
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    let text: String?
    let count: Int?
    let style: Style
    let size: Size
    let showZero: Bool
    
    init(
        text: String,
        style: Style = .accent,
        size: Size = .medium
    ) {
        self.text = text
        self.count = nil
        self.style = style
        self.size = size
        self.showZero = false
    }
    
    init(
        count: Int,
        style: Style = .count,
        size: Size = .medium,
        showZero: Bool = false
    ) {
        self.text = nil
        self.count = count
        self.style = style
        self.size = size
        self.showZero = showZero
    }
    
    private var displayText: String? {
        if let text = text {
            return text
        }
        
        if let count = count {
            if count == 0 && !showZero {
                return nil
            }
            
            if count > 99 {
                return "99+"
            }
            
            return String(count)
        }
        
        return nil
    }
    
    private var shouldShow: Bool {
        guard let displayText = displayText else { return false }
        return !displayText.isEmpty
    }
    
    var body: some View {
        Group {
            if shouldShow, let displayText = displayText {
                Text(displayText)
                    .font(style.font)
                    .foregroundColor(style.foregroundColor)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .frame(minHeight: size.minHeight)
                    .background(
                        Capsule()
                            .fill(style.backgroundColor)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.badgeBorder, lineWidth: 0.5)
                    )
            }
        }
    }
}

// MARK: - Dot Badge (for simple notification indicators)
struct PiggyDotBadge: View {
    let style: PiggyBadge.Style
    let size: CGFloat
    
    init(style: PiggyBadge.Style = .notification, size: CGFloat = 8) {
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(style.backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.badgeBorder, lineWidth: 1)
            )
    }
}

#Preview("Badge Text Styles") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            HStack(spacing: PiggySpacing.md) {
                PiggyBadge(text: "New", style: .notification)
                PiggyBadge(text: "Hot", style: .accent)
                PiggyBadge(text: "Live", style: .status)
            }
            
            HStack(spacing: PiggySpacing.md) {
                PiggyBadge(text: "Premium", style: .count, size: .large)
                PiggyBadge(text: "Beta", style: .notification, size: .small)
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Badge Count Styles") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            HStack(spacing: PiggySpacing.md) {
                PiggyBadge(count: 1, style: .notification)
                PiggyBadge(count: 12, style: .count)
                PiggyBadge(count: 123, style: .status)
                PiggyBadge(count: 0, showZero: true)
            }
            
            HStack(spacing: PiggySpacing.md) {
                PiggyBadge(count: 5, size: .small)
                PiggyBadge(count: 25, size: .medium)
                PiggyBadge(count: 250, size: .large)
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Dot Badges") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            HStack(spacing: PiggySpacing.md) {
                PiggyDotBadge(style: .notification)
                PiggyDotBadge(style: .count)
                PiggyDotBadge(style: .status)
                PiggyDotBadge(style: .accent)
            }
            
            HStack(spacing: PiggySpacing.md) {
                PiggyDotBadge(size: 6)
                PiggyDotBadge(size: 10)
                PiggyDotBadge(size: 14)
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Real Usage Examples") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            // Icon with badge overlay
            ZStack(alignment: .topTrailing) {
                PiggyIconButton("bell") {}
                PiggyBadge(count: 3, style: .notification, size: .small)
                    .offset(x: 8, y: -8)
            }
            
            // Tab bar item with badge
            HStack(spacing: PiggySpacing.xl) {
                VStack {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "house")
                            .font(.system(size: 24))
                            .foregroundColor(.piggyTextPrimary)
                        PiggyDotBadge(style: .notification, size: 6)
                            .offset(x: 6, y: -6)
                    }
                    Text("Home")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                VStack {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "message")
                            .font(.system(size: 24))
                            .foregroundColor(.piggyTextPrimary)
                        PiggyBadge(count: 12, style: .notification, size: .small)
                            .offset(x: 8, y: -8)
                    }
                    Text("Messages")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            // List item with status badge
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.piggyTextPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("User Name")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                    
                    HStack {
                        Text("Online")
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextSecondary)
                        
                        PiggyDotBadge(style: .status, size: 6)
                    }
                }
                
                Spacer()
                
                PiggyBadge(text: "Pro", style: .accent, size: .small)
            }
            .padding(PiggySpacing.md)
            .background(Color.badgeBackground)
            .cornerRadius(12)
        }
        .padding(PiggySpacing.lg)
    }
}