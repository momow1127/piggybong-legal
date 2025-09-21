import SwiftUI

// MARK: - Piggy Banner
struct PiggyBanner: View {
    let icon: String
    let title: String
    let message: String
    let type: BannerType
    let primaryAction: BannerAction?
    let secondaryAction: BannerAction?
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var offset: CGFloat = -100

    enum BannerType {
        case info
        case warning
        case success
        case error

        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .success: return .green
            case .error: return .red
            }
        }

        var backgroundColor: Color {
            return color.opacity(0.1)
        }
    }

    struct BannerAction {
        let title: String
        let action: () -> Void
    }

    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(type.color)
                    .font(.system(size: 16, weight: .medium))
            }

            // Content
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.primary)

                Text(message)
                    .font(PiggyFont.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action Buttons
            if let primaryAction = primaryAction {
                Button(action: primaryAction.action) {
                    Text(primaryAction.title)
                        .font(PiggyFont.captionEmphasized)
                        .foregroundColor(type.color)
                        .padding(.horizontal, PiggySpacing.sm)
                        .padding(.vertical, PiggySpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                .fill(type.color.opacity(0.1))
                        )
                }
            }

            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(PiggySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .offset(y: offset)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                offset = 0
            }

            // Auto-dismiss after 5 seconds if no primary action
            if primaryAction == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismissBanner()
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        dismissBanner()
                    }
                }
        )
    }

    private func dismissBanner() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            offset = -100
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Piggy Banner Manager
@MainActor
class PiggyBannerManager: ObservableObject {
    @Published var currentBanner: BannerData?
    @Published var isShowingBanner = false

    private var bannerQueue: [BannerData] = []

    static let shared = PiggyBannerManager()

    private init() {}

    struct BannerData {
        let id = UUID()
        let icon: String
        let title: String
        let message: String
        let type: PiggyBanner.BannerType
        let primaryAction: PiggyBanner.BannerAction?
        let secondaryAction: PiggyBanner.BannerAction?
    }

    func showBanner(
        icon: String,
        title: String,
        message: String,
        type: PiggyBanner.BannerType = .info,
        primaryAction: PiggyBanner.BannerAction? = nil,
        secondaryAction: PiggyBanner.BannerAction? = nil
    ) {
        let banner = BannerData(
            icon: icon,
            title: title,
            message: message,
            type: type,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )

        // Add to queue if currently showing a banner
        if isShowingBanner {
            bannerQueue.append(banner)
            return
        }

        currentBanner = banner
        isShowingBanner = true
    }

    func dismissCurrentBanner() {
        isShowingBanner = false
        currentBanner = nil

        // Show next banner in queue if any
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.bannerQueue.isEmpty {
                let nextBanner = self.bannerQueue.removeFirst()
                self.showBanner(
                    icon: nextBanner.icon,
                    title: nextBanner.title,
                    message: nextBanner.message,
                    type: nextBanner.type,
                    primaryAction: nextBanner.primaryAction,
                    secondaryAction: nextBanner.secondaryAction
                )
            }
        }
    }

    // MARK: - Convenience Methods
    func showPriorityMismatch(
        activity: String,
        priority: String,
        onUpdatePriority: @escaping () -> Void
    ) {
        showBanner(
            icon: "exclamationmark.triangle.fill",
            title: "Priority Mismatch",
            message: "You marked \(activity) as \(priority) priority, but just added \(activity) activity.",
            type: .warning,
            primaryAction: PiggyBanner.BannerAction(
                title: "Update Priority",
                action: onUpdatePriority
            )
        )
    }

    func showBudgetWarning(
        amount: Double,
        remaining: Double,
        onViewBudget: @escaping () -> Void
    ) {
        showBanner(
            icon: "dollarsign.circle.fill",
            title: "Budget Alert",
            message: "This $\(Int(amount)) purchase will exceed your remaining budget of $\(Int(remaining)).",
            type: .warning,
            primaryAction: PiggyBanner.BannerAction(
                title: "View Budget",
                action: onViewBudget
            )
        )
    }

    func showSuccess(
        title: String,
        message: String
    ) {
        showBanner(
            icon: "checkmark.circle.fill",
            title: title,
            message: message,
            type: .success
        )
    }

    // MARK: - Artist Update Methods
    func handleArtistUpdate(for artistName: String, updateType: String) {
        // Choose appropriate emoji based on updateType
        let emoji: String
        switch updateType.lowercased() {
        case let type where type.contains("album"):
            emoji = "🎉"
        case let type where type.contains("concert"):
            emoji = "🎤"
        case let type where type.contains("merch"):
            emoji = "🛍️"
        default:
            emoji = "✨"
        }

        let message = "\(artistName) just announced a new \(updateType.lowercased())! \(emoji)"

        showArtistUpdate(artistName: artistName, message: message)
    }

    func showArtistUpdate(
        artistName: String,
        message: String
    ) {
        showBanner(
            icon: "music.note",
            title: "Artist Update",
            message: message,
            type: .info
        )
    }
}

// MARK: - Banner Overlay Modifier
struct PiggyBannerOverlay: ViewModifier {
    @ObservedObject private var bannerManager = PiggyBannerManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if bannerManager.isShowingBanner,
                   let banner = bannerManager.currentBanner {
                    PiggyBanner(
                        icon: banner.icon,
                        title: banner.title,
                        message: banner.message,
                        type: banner.type,
                        primaryAction: banner.primaryAction,
                        secondaryAction: banner.secondaryAction,
                        onDismiss: {
                            bannerManager.dismissCurrentBanner()
                        }
                    )
                    .padding(.horizontal, PiggySpacing.lg)
                    .padding(.top, PiggySpacing.sm)
                    .zIndex(1000)
                }
            }
    }
}

extension View {
    func withPiggyBanner() -> some View {
        modifier(PiggyBannerOverlay())
    }
}

#Preview {
    VStack(spacing: PiggySpacing.lg) {
        Text("Main Content")
            .font(PiggyFont.title)

        Button("Show Priority Mismatch") {
            PiggyBannerManager.shared.showPriorityMismatch(
                activity: "concerts",
                priority: "Low",
                onUpdatePriority: {
                    print("Update priority tapped")
                }
            )
        }

        Button("Show Budget Warning") {
            PiggyBannerManager.shared.showBudgetWarning(
                amount: 150,
                remaining: 100,
                onViewBudget: {
                    print("View budget tapped")
                }
            )
        }

        Button("Show Success") {
            PiggyBannerManager.shared.showSuccess(
                title: "Purchase Added!",
                message: "Your K-pop purchase has been successfully tracked."
            )
        }

        Button("Show Artist Update") {
            PiggyBannerManager.shared.handleArtistUpdate(
                for: "BLACKPINK",
                updateType: "New Album"
            )
        }

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .withPiggyBanner()
}