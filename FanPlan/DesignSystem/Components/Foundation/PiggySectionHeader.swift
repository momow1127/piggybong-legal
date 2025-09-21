import SwiftUI

struct PiggySectionHeader: View {
    enum Style {
        case primary
        case secondary
        case accent
        
        var font: Font {
            switch self {
            case .primary: return PiggyFont.sectionTitle
            case .secondary: return PiggyFont.bodyEmphasized
            case .accent: return PiggyFont.caption.weight(.semibold)
            }
        }
        
        var color: Color {
            switch self {
            case .primary: return .piggyTextPrimary
            case .secondary: return .piggyTextPrimary
            case .accent: return .white.opacity(0.6)
            }
        }
    }
    
    enum ActionStyle {
        case text(String)
        case icon(String)
        case textWithIcon(String, String)
        
        var textContent: String? {
            switch self {
            case .text(let text): return text
            case .icon: return nil
            case .textWithIcon(let text, _): return text
            }
        }
        
        var iconName: String? {
            switch self {
            case .text: return nil
            case .icon(let icon): return icon
            case .textWithIcon(_, let icon): return icon
            }
        }
    }
    
    let title: String
    let subtitle: String?
    let style: Style
    let action: ActionStyle?
    let onAction: (() -> Void)?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        style: Style = .primary,
        action: ActionStyle? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.action = action
        self.onAction = onAction
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(title)
                    .font(style.font)
                    .foregroundColor(style.color)
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    HStack(spacing: PiggySpacing.xs) {
                        if let text = action.textContent {
                            Text(text)
                                .font(PiggyFont.bodyEmphasized)
                                .foregroundColor(.piggyPrimary)
                        }
                        
                        if let iconName = action.iconName {
                            Image(systemName: iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.piggyPrimary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(minHeight: 44)
    }
}

#Preview("Basic Header") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggySectionHeader("Recent Activities")
            
            PiggySectionHeader(
                "Your Artists",
                subtitle: "Manage your favorite K-pop artists"
            )
            
            PiggySectionHeader(
                "Events",
                style: .secondary,
                action: .text("View All"),
                onAction: {}
            )
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("With Actions") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggySectionHeader(
                "Smart Alerts",
                action: .icon("plus"),
                onAction: {}
            )
            
            PiggySectionHeader(
                "Fan Activities",
                subtitle: "Track your K-pop journey",
                action: .textWithIcon("Add", "plus.circle"),
                onAction: {}
            )
            
            PiggySectionHeader(
                "Settings",
                style: .accent,
                action: .text("Edit"),
                onAction: {}
            )
        }
        .padding(PiggySpacing.lg)
    }
}