import SwiftUI

struct PiggyMenuRow: View {
    enum Style {
        case standard       // Standalone row with background
        case inline         // Plain row for use inside cards
        case formMenu       // For dropdown-style alignment in form
        
        var backgroundColor: Color {
            switch self {
            case .standard: return Color.piggyCardBackground
            case .inline: return Color.clear
            case .formMenu: return Color.piggyCardBackground
            }
        }
        
        var hasBackgroundStyling: Bool {
            switch self {
            case .standard: return true
            case .inline: return false
            case .formMenu: return true
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .formMenu:
                return EdgeInsets(
                    top: PiggySpacing.md,
                    leading: 0, // align text flush left
                    bottom: PiggySpacing.md,
                    trailing: PiggySpacing.md
                )
            default:
                return EdgeInsets(
                    top: PiggySpacing.md,
                    leading: PiggySpacing.md,
                    bottom: PiggySpacing.md,
                    trailing: PiggySpacing.md
                )
            }
        }
    }
    
    let title: String
    let subtitle: String?
    let leadingIcon: String?
    let trailingIcon: String?
    let isSelected: Bool
    let style: Style
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        isSelected: Bool = false,
        style: Style = .standard,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.isSelected = isSelected
        self.style = style
        self.onTap = onTap
    }
    
    var body: some View {
        let content = HStack(spacing: PiggySpacing.sm) {
            // Leading Icon or Selection Indicator
            if let leadingIcon = leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .piggyPrimary : .piggyTextSecondary)
                    .frame(width: 24)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24)
                    .padding(.leading, PiggySpacing.sm)
            } else {
                Spacer()
                    .frame(width: 24)
            }
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PiggyFont.body)
                    .foregroundColor(isSelected ? .piggyTextPrimary : .piggyTextPrimary)
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Trailing Icon
            if let trailingIcon = trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.piggyTextTertiary)
            }
        }
        .padding(style.padding)
        .frame(minHeight: 52)
        .background(
            Group {
                if style.hasBackgroundStyling && isSelected {
                    Color.white.opacity(0.1)
                } else if isPressed {
                    Color.white.opacity(0.15) // Press state background
                } else {
                    style.backgroundColor
                }
            }
        )
        .overlay(
            style.hasBackgroundStyling && isSelected ? 
            RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            : nil
        )
        .clipShape(RoundedRectangle(cornerRadius: style.hasBackgroundStyling ? PiggyBorderRadius.input : 0))
        
        // Conditional button wrapping
        if let onTap = onTap {
            Button(action: {
                piggyHapticFeedback(.selection)
                onTap()
            }) {
                content
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
        } else {
            content
        }
    }
}

#Preview("Menu Row Variations") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.xs) {
            PiggyMenuRow("Simple Item")
            
            PiggyMenuRow(
                "Selected Item",
                isSelected: true
            )
            
            PiggyMenuRow(
                "With Subtitle",
                subtitle: "Additional information about this item"
            )
            
            PiggyMenuRow(
                "With Icons",
                subtitle: "Artist from Seoul, South Korea",
                leadingIcon: "music.note",
                trailingIcon: "chevron.right"
            )
            
            PiggyMenuRow(
                "BTS",
                subtitle: "Korean Boy Band • 7 members",
                leadingIcon: "person.3.fill",
                isSelected: true
            )
        }
        .padding(PiggySpacing.md)
    }
}
