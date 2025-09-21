import SwiftUI

// MARK: - Shared Layout Tokens
enum LayoutTokens {
    // MARK: - Spacing
    static let pageX: CGFloat = 20 // All horizontal page padding
    static let headerTop: CGFloat = 16 // Space from status bar bottom to first header element
    static let sectionTop: CGFloat = 24 // Space from previous block to section title
    static let cardGap: CGFloat = 12 // Space between stacked cards
    static let sectionHeaderBottom: CGFloat = 8 // Space below section headers
    static let avatarBlockBottom: CGFloat = 12 // Extra space after avatar block
    
    // MARK: - Sizes
    static let avatarSize: CGFloat = 64
    static let settingsIconSize: CGFloat = 14 // Further reduced to be less prominent
    static let logOutIconSize: CGFloat = 14 // Match settings icons
    static let chevronSize: CGFloat = 14
    
    // MARK: - Typography
    static let sectionHeaderFontSize: CGFloat = 13 // Reduced from 14
    static let sectionHeaderWeight: Font.Weight = .medium
    static let cardTextFontSize: CGFloat = 16
    static let cardTextWeight: Font.Weight = .regular
    static let versionFooterFontSize: CGFloat = 12
    
    // MARK: - Card Styling
    static let cardHeight: CGFloat = 44
    static let cardPadding: EdgeInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    static let cardCornerRadius: CGFloat = 12
}

// MARK: - Consistent Header View
struct AppHeaderView: View {
    let title: String
    let showAvatar: Bool
    let avatarImage: String?
    let userName: String?
    let subtitle: String?
    let applyHorizontalPadding: Bool
    
    init(
        title: String,
        showAvatar: Bool = false,
        avatarImage: String? = nil,
        userName: String? = nil,
        subtitle: String? = nil,
        applyHorizontalPadding: Bool = true
    ) {
        self.title = title
        self.showAvatar = showAvatar
        self.avatarImage = avatarImage
        self.userName = userName
        self.subtitle = subtitle
        self.applyHorizontalPadding = applyHorizontalPadding
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if showAvatar {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.piggyPrimary, Color.piggySecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: LayoutTokens.avatarSize, height: LayoutTokens.avatarSize)
                    .overlay(
                        Text(userName?.prefix(2).uppercased() ?? "FU")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(userName ?? "Fan User")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
            } else {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, applyHorizontalPadding ? PiggySpacing.lg : 0)
        .padding(.top, PiggySpacing.xl)
        .padding(.bottom, showAvatar ? PiggySpacing.md : 0)
    }
}