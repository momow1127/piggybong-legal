import SwiftUI

// MARK: - Contextual Loading View
struct ContextualLoadingView: View {
    let isLoading: Bool
    let message: String
    let style: ContextualStyle
    let size: PiggyLoadingTokens.LoadingSize

    init(
        isLoading: Bool,
        message: String = "",
        style: ContextualStyle = .overlay,
        size: PiggyLoadingTokens.LoadingSize = .medium
    ) {
        self.isLoading = isLoading
        self.message = message
        self.style = style
        self.size = size
    }

    enum ContextualStyle {
        case overlay    // Semi-transparent over content
        case replace    // Replace content entirely
        case inline     // Alongside existing content
    }

    var body: some View {
        Group {
            if isLoading {
                switch style {
                case .overlay:
                    overlayContent
                case .replace:
                    replaceContent
                case .inline:
                    inlineContent
                }
            } else {
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: PiggyLoadingTokens.animationDuration), value: isLoading)
    }

    // MARK: - Style Variants

    private var overlayContent: some View {
        ZStack {
            // Semi-transparent background
            RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                .fill(PiggyLoadingTokens.contextualBackground)
                .allowsHitTesting(true)

            // Loading content
            loadingContent
        }
    }

    private var replaceContent: some View {
        VStack(spacing: PiggySpacing.md) {
            loadingContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private var inlineContent: some View {
        HStack(spacing: PiggySpacing.sm) {
            PiggyLoadingTokens.spinner(size: size)

            if !message.isEmpty {
                Text(message)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: PiggySpacing.md) {
            PiggyLoadingTokens.spinner(size: size)

            if !message.isEmpty {
                Text(message)
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(PiggySpacing.lg)
    }
}

// MARK: - Contextual Loading Modifier
extension View {
    func contextualLoading(
        isLoading: Bool,
        message: String = "",
        style: ContextualLoadingView.ContextualStyle = .overlay
    ) -> some View {
        ZStack {
            self

            if isLoading {
                ContextualLoadingView(
                    isLoading: isLoading,
                    message: message,
                    style: style
                )
            }
        }
    }
}

// MARK: - Preview
#Preview("Contextual Loading Styles") {
    VStack(spacing: PiggySpacing.xl) {
        // Overlay style
        PiggyCard(style: .primary) {
            VStack {
                Text("Content underneath")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextPrimary)
                Text("This gets overlaid")
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextSecondary)
            }
            .padding(PiggySpacing.lg)
        }
        .contextualLoading(
            isLoading: true,
            message: "Processing your request...",
            style: .overlay
        )

        // Replace style
        PiggyCard(style: .secondary) {
            ContextualLoadingView(
                isLoading: true,
                message: "Loading dashboard data...",
                style: .replace,
                size: .large
            )
            .frame(height: 100)
        }

        // Inline style
        HStack {
            Text("Saving changes")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

            ContextualLoadingView(
                isLoading: true,
                message: "Saving...",
                style: .inline,
                size: .small
            )
        }
        .padding(PiggySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                .fill(Color.piggyCardBackground)
        )
    }
    .padding()
    .background(PiggyGradients.background)
}