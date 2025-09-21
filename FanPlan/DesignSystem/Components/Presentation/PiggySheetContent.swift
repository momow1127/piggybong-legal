import SwiftUI

// MARK: - PiggySheetContent
/// A wrapper that applies Piggy design system styling to iOS native sheet presentations
/// Use this with .sheet() modifier to get native interactions with consistent styling
struct PiggySheetContent<Content: View>: View {
    let title: String
    let subtitle: String?
    let showCloseButton: Bool
    let closeAction: (() -> Void)?
    @ViewBuilder let content: () -> Content

    // For keyboard avoidance
    @FocusState private var isKeyboardFocused: Bool

    init(
        _ title: String,
        subtitle: String? = nil,
        showCloseButton: Bool = true,
        closeAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showCloseButton = showCloseButton
        self.closeAction = closeAction
        self.content = content
    }

    var body: some View {
        ZStack {
            // Background with gradient
            PiggyGradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator (iOS-style)
                dragIndicator

                // Header
                headerSection

                // Scrollable content
                ScrollView {
                    content()
                        .padding(.horizontal, PiggySpacing.lg)
                        .padding(.bottom, PiggySpacing.xl)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isKeyboardFocused = false
        }
    }

    // MARK: - Drag Indicator
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.dragHandle)
            .frame(width: 36, height: 6)
            .padding(.top, PiggySpacing.sm)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(title)
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                }
            }

            Spacer()

            if showCloseButton {
                PiggyIconButton(
                    "xmark",
                    size: .medium,
                    style: .tertiary,
                    action: {
                        piggyHapticFeedback(.light)
                        closeAction?()
                    }
                )
            }
        }
        .padding(.horizontal, PiggySpacing.lg)
        .padding(.vertical, PiggySpacing.md)
        .padding(.top, PiggySpacing.xs)
    }
}

// MARK: - Convenience Modifiers
extension View {
    /// Present content in an iOS native sheet with Piggy design system styling
    func piggySheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        detents: Set<PresentationDetent> = [.medium, .large],
        showDragIndicator: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            PiggySheetContent(
                title,
                subtitle: subtitle,
                showCloseButton: true,
                closeAction: {
                    isPresented.wrappedValue = false
                },
                content: content
            )
            .presentationDetents(detents)
            .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
            .presentationCornerRadius(24)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }

    /// Present content in a compact iOS native sheet (for alerts/confirmations)
    func piggyCompactSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            PiggySheetContent(
                title,
                subtitle: subtitle,
                showCloseButton: false,
                content: content
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
            .interactiveDismissDisabled() // Prevent swipe to dismiss for confirmations
        }
    }
}

// MARK: - Preview
#Preview("Piggy Sheet Content") {
    struct PreviewWrapper: View {
        @State private var showSheet = true
        @State private var showCompact = false

        var body: some View {
            ZStack {
                PiggyGradients.background

                VStack(spacing: PiggySpacing.lg) {
                    Button("Show Sheet") {
                        showSheet = true
                    }

                    Button("Show Compact") {
                        showCompact = true
                    }
                }
            }
            .piggySheet(
                isPresented: $showSheet,
                title: "Add Fan Activity",
                subtitle: "Track your K-pop spending"
            ) {
                VStack(spacing: PiggySpacing.lg) {
                    ForEach(0..<5) { index in
                        PiggyCard {
                            Text("Content item \(index + 1)")
                                .font(PiggyFont.body)
                                .foregroundColor(.piggyTextPrimary)
                                .padding()
                        }
                    }

                    PiggyButton(
                        title: "Save Activity",
                        action: { showSheet = false },
                        style: .primary,
                        size: .large
                    )
                }
            }
            .piggyCompactSheet(
                isPresented: $showCompact,
                title: "Delete Account?",
                subtitle: "This cannot be undone"
            ) {
                VStack(spacing: PiggySpacing.lg) {
                    Text("Are you sure?")
                        .font(PiggyFont.body)

                    HStack(spacing: PiggySpacing.md) {
                        PiggyButton(
                            title: "Cancel",
                            action: { showCompact = false },
                            style: .secondary
                        )

                        PiggyButton(
                            title: "Delete",
                            action: { showCompact = false },
                            style: .destructive
                        )
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}