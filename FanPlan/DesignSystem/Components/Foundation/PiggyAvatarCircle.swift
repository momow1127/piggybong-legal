import SwiftUI

struct PiggyAvatarCircle: View {
    enum Size {
        case small
        case medium
        case large
        case extraLarge
        case custom(CGFloat)
        
        var diameter: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 40
            case .large: return 64
            case .extraLarge: return 80
            case .custom(let size): return size
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 20
            case .extraLarge: return 24
            case .custom(let size): return size * 0.3
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .small, .medium: return .semibold
            case .large, .extraLarge: return .bold
            case .custom: return .semibold
            }
        }
    }
    
    enum Style {
        case gradient([Color])
        case solid(Color)
        case artistGradient
        case userGradient
        case systemGradient
        
        func colors(for text: String) -> [Color] {
            switch self {
            case .gradient(let colors):
                return colors
            case .solid(let color):
                return [color, color]
            case .artistGradient:
                return [Color.purple.opacity(0.8), Color.blue.opacity(0.6)]
            case .userGradient:
                return [Color.piggyPrimary.opacity(0.8), Color.piggySecondary.opacity(0.6)]
            case .systemGradient:
                // Generate consistent colors based on text hash
                let colors: [[Color]] = [
                    [.purple, .blue],
                    [.pink, .orange],
                    [.green, .teal],
                    [.orange, .red],
                    [.blue, .cyan],
                    [.indigo, .purple]
                ]
                let hash = abs(text.hashValue) % colors.count
                return colors[hash].map { $0.opacity(0.7) }
            }
        }
    }
    
    let text: String
    let size: Size
    let style: Style
    let showBorder: Bool
    let borderColor: Color
    let action: (() -> Void)?
    
    init(
        text: String,
        size: Size = .medium,
        style: Style = .systemGradient,
        showBorder: Bool = false,
        borderColor: Color = .white.opacity(0.3),
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.size = size
        self.style = style
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.action = action
    }
    
    private var displayText: String {
        let words = text.components(separatedBy: .whitespaces)
        if words.count > 1 {
            // Take first letter of first two words
            let firstTwoWords: [String] = Array(words.prefix(2))
            let firstChars: [Character] = firstTwoWords.compactMap { $0.first }
            let initials: [String] = firstChars.map(String.init)
            return initials.joined().uppercased()
        } else {
            // Take first 2-3 characters depending on size
            let charCount = size.diameter < 40 ? 2 : 3
            return String(text.prefix(charCount)).uppercased()
        }
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    avatarContent
                }
                .buttonStyle(PiggyAvatarButtonStyle())
            } else {
                avatarContent
            }
        }
    }
    
    private var avatarContent: some View {
        avatarCircle
    }
    
    private var avatarCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: style.colors(for: text),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size.diameter, height: size.diameter)
            .applyShadow(PiggyShadows.medium)
            .overlay(
                Text(displayText)
                    .font(.system(size: size.fontSize, weight: size.fontWeight))
                    .foregroundColor(.piggyTextPrimary)
            )
            .overlay(
                showBorder ?
                Circle()
                    .stroke(borderColor, lineWidth: 2)
                : nil
            )
    }
}

// MARK: - Custom Button Style for Avatar
struct PiggyAvatarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview("Avatar Sizes") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.xl) {
            HStack(spacing: PiggySpacing.lg) {
                PiggyAvatarCircle(text: "Small", size: .small)
                PiggyAvatarCircle(text: "Medium User", size: .medium)
                PiggyAvatarCircle(text: "Large Artist", size: .large)
                PiggyAvatarCircle(text: "Extra Large", size: .extraLarge)
            }
            
            HStack(spacing: PiggySpacing.lg) {
                PiggyAvatarCircle(text: "Custom", size: .custom(50))
                PiggyAvatarCircle(text: "Tiny", size: .custom(24))
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Avatar Styles") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.xl) {
            // System generated colors
            HStack(spacing: PiggySpacing.md) {
                PiggyAvatarCircle(text: "Alice", style: .systemGradient)
                PiggyAvatarCircle(text: "Bob", style: .systemGradient)
                PiggyAvatarCircle(text: "Charlie", style: .systemGradient)
                PiggyAvatarCircle(text: "Diana", style: .systemGradient)
            }
            
            // Predefined styles
            HStack(spacing: PiggySpacing.md) {
                PiggyAvatarCircle(text: "Artist", style: .artistGradient)
                PiggyAvatarCircle(text: "User", style: .userGradient)
                PiggyAvatarCircle(text: "Solid", style: .solid(.piggyPrimary))
            }
            
            // Custom gradient
            HStack(spacing: PiggySpacing.md) {
                PiggyAvatarCircle(
                    text: "Custom",
                    style: .gradient([.pink, .purple, .blue])
                )
                PiggyAvatarCircle(
                    text: "Warm",
                    style: .gradient([.orange, .red])
                )
            }
            
            // With borders
            HStack(spacing: PiggySpacing.md) {
                PiggyAvatarCircle(
                    text: "Border",
                    showBorder: true
                )
                PiggyAvatarCircle(
                    text: "Gold",
                    style: .artistGradient,
                    showBorder: true,
                    borderColor: .yellow
                )
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Interactive Avatars") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.xl) {
            Text("Tap the avatars!")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
            
            HStack(spacing: PiggySpacing.lg) {
                PiggyAvatarCircle(
                    text: "BTS",
                    size: .large,
                    style: .artistGradient,
                    showBorder: true,
                    borderColor: .purple.opacity(0.6)
                ) {
                    print("BTS avatar tapped")
                }
                
                PiggyAvatarCircle(
                    text: "BLACKPINK",
                    size: .large,
                    style: .gradient([.pink, .black]),
                    showBorder: true,
                    borderColor: .pink.opacity(0.6)
                ) {
                    print("BLACKPINK avatar tapped")
                }
                
                PiggyAvatarCircle(
                    text: "User Profile",
                    size: .large,
                    style: .userGradient,
                    showBorder: true
                ) {
                    print("User profile tapped")
                }
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Real World Usage") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            // Event feed style
            PiggyCard(style: .secondary) {
                HStack(spacing: PiggySpacing.sm) {
                    PiggyAvatarCircle(
                        text: "Concert Alert",
                        size: .small,
                        style: .artistGradient
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BTS World Tour")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("2 days ago")
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Profile header style
            HStack(spacing: PiggySpacing.md) {
                PiggyAvatarCircle(
                    text: "Fan Profile",
                    size: .large,
                    style: .userGradient,
                    showBorder: true,
                    borderColor: .piggyPrimary.opacity(0.4)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("K-Pop Fan")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextPrimary)
                    Text("Level 15 • 2.5k Points")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
                
                PiggyBadge(count: 12, style: .notification)
            }
            .piggyCardStyle(.elevated)
            
            // Artist carousel style
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PiggySpacing.sm) {
                    ForEach(["NewJeans", "IVE", "aespa", "ITZY"], id: \.self) { artist in
                        VStack(spacing: PiggySpacing.xs) {
                            PiggyAvatarCircle(
                                text: artist,
                                size: .medium,
                                style: .systemGradient
                            ) {
                                print("\(artist) selected")
                            }
                            
                            Text(artist)
                                .font(PiggyFont.caption)
                                .foregroundColor(.piggyTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, PiggySpacing.md)
            }
        }
        .padding(PiggySpacing.lg)
    }
}