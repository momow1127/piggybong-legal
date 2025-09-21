import SwiftUI

struct PiggyModal<Content: View>: View {
    enum Style {
        case fullscreenModal    // FullScreenModal: complex flows (Paywall, Add Artist)
        case bottomSheetModal   // BottomSheetModal: contextual actions (Add Fan Activity)
        case alertModal         // AlertModal: destructive confirmations (Delete Account)
        case systemAlert        // SystemAlert: blocking errors (network, session expired)

        // Legacy support - use computed properties instead
        static var sheet: Style { .bottomSheetModal }
        static var fullscreen: Style { .fullscreenModal }
        static var alert: Style { .alertModal }
        static var bottomSheet: Style { .bottomSheetModal }

        var backgroundColor: Color {
            switch self {
            case .fullscreenModal, .bottomSheetModal:
                return Color.modalBackground
            case .alertModal:
                return Color.modalBackground
            case .systemAlert:
                return Color.clear // System alerts handle their own background
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .bottomSheetModal: return 20
            case .alertModal: return 16
            case .fullscreenModal: return 0
            case .systemAlert: return 0
            }
        }

        var description: String {
            switch self {
            case .fullscreenModal: return "Full screen modal for complex flows"
            case .bottomSheetModal: return "Bottom sheet for contextual actions"
            case .alertModal: return "Alert modal for destructive confirmations"
            case .systemAlert: return "Native iOS alert for blocking errors"
            }
        }
    }
    
    enum Size {
        case small      // ~30% height - for simple confirmations
        case medium     // ~50% height - for contextual actions
        case large      // ~75% height - for complex forms
        case adaptive   // Fits content - for variable content
        case compact    // Fixed small size for alert modals

        var maxHeight: CGFloat? {
            switch self {
            case .small: return UIScreen.main.bounds.height * 0.3
            case .medium: return UIScreen.main.bounds.height * 0.5
            case .large: return UIScreen.main.bounds.height * 0.75
            case .adaptive: return nil
            case .compact: return 300 // Fixed height for alert modals
            }
        }

        var recommendedWidth: CGFloat? {
            switch self {
            case .compact: return UIScreen.main.bounds.width * 0.85 // Narrower for alerts
            default: return nil // Use full width
            }
        }
    }
    
    // MARK: - Properties
    let title: String
    let subtitle: String?
    @Binding var isPresented: Bool
    let style: Style
    let size: Size
    let showCloseButton: Bool
    let isDismissible: Bool
    let content: () -> Content
    
    // MARK: - State
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    // MARK: - Initializer
    init(
        _ title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        style: Style = .sheet,
        size: Size = .medium,
        showCloseButton: Bool = true,
        isDismissible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isPresented = isPresented
        self.style = style
        self.size = size
        self.showCloseButton = showCloseButton
        self.isDismissible = isDismissible
        self.content = content
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background Overlay
            if isPresented {
                Color.modalOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        if isDismissible {
                            withAnimation(.spring()) {
                                dismiss()
                            }
                        }
                    }
                    .transition(.opacity)
            }
            
            // Modal Content
            if isPresented {
                if style == .systemAlert {
                    // System alerts are handled differently
                    EmptyView()
                } else {
                    modalContent
                        .transition(modalTransition)
                }
            }
        }
    }
    
    // MARK: - Modal Content
    private var modalContent: some View {
        Group {
            if style == .fullscreenModal {
                // Fullscreen Modal: Use full screen height with proper safe area handling
                fullscreenModalLayout
                    .ignoresSafeArea(.container, edges: .bottom) // Allow content to extend to bottom
                    .accessibilityAddTraits(.isModal)
            } else if style == .alertModal {
                // Alert Modal: Centered, compact design for destructive confirmations
                alertModalLayout
                    .accessibilityAddTraits(.isModal)
            } else {
                // Standard Modal Styles: Bottom sheet and others
                standardModalLayout
                    .accessibilityAddTraits(.isModal)
            }
        }
        .background(PiggyGradients.background)
        .clipShape(
            RoundedRectangle(cornerRadius: style.cornerRadius)
        )
        .overlay(
            style == .fullscreenModal ? nil :
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(Color.piggyCardBorder, lineWidth: 1)
        )
        .frame(maxWidth: size.recommendedWidth)
        .offset(y: dragOffset.height)
        .scaleEffect(isDragging ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .gesture(dragGesture)
    }
    
    // MARK: - Fullscreen Modal Layout
    private var fullscreenModalLayout: some View {
        fullscreenModalContent
    }
    
    private var fullscreenModalContent: some View {
        ZStack(alignment: .topLeading) {
            // Main content area - fills entire screen
            fullscreenScrollContent
                .allowsHitTesting(true)
            
            // Fixed header overlay with close button - ensure it's on top
            fullscreenHeaderOverlay
                .allowsHitTesting(true)
        }
    }
    
    private var fullscreenScrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top spacing for close button area (safe area)
                Spacer(minLength: PiggySpacing.xl + 44) // 44pt for close button + spacing
                
                // Modal content with proper padding
                content()
                    .padding(.horizontal, PiggySpacing.lg)
                    .padding(.bottom, PiggySpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Full screen expansion
    }
    
    private var fullscreenHeaderOverlay: some View {
        VStack(spacing: 0) {
            // Header with gradient background and close button
            fullscreenModalHeader
                .background(headerGradientBackground)
                .contentShape(Rectangle())
            
            // Transparent spacer to allow content scrolling below
            Spacer()
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .allowsHitTesting(true)
    }
    
    // Gradient background for header visibility
    private var headerGradientBackground: some View {
        PiggyGradients.background
            .opacity(0.9)
            .frame(height: 120)
            .allowsHitTesting(false)
    }
    
    // MARK: - Alert Modal Layout
    private var alertModalLayout: some View {
        VStack(spacing: 0) {
            // Compact header for alert modals
            alertModalHeader

            // Content with fixed constraints for alert modals
            VStack(spacing: PiggySpacing.lg) {
                content()
            }
            .padding(.horizontal, PiggySpacing.lg)
            .padding(.bottom, PiggySpacing.xl)
        }
        .frame(maxHeight: size.maxHeight)
    }

    // MARK: - Standard Modal Layout
    @ViewBuilder
    private var standardModalLayout: some View {
        VStack(spacing: 0) {
            // Drag Handle (for bottom sheets)
            if style == .bottomSheetModal {
                dragHandle
                    .padding(.top, PiggySpacing.sm)
            }

            // Header
            modalHeader

            // Content with height constraints for non-fullscreen modals
            ScrollView {
                content()
                    .padding(.horizontal, PiggySpacing.lg)
                    .padding(.bottom, PiggySpacing.xl)
            }
            .frame(maxHeight: size.maxHeight) // Only apply height constraint to non-fullscreen
        }
    }
    
    // MARK: - Fullscreen Modal Header
    private var fullscreenModalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(title)
                    .font(PiggyFont.largeTitle)
                    .foregroundColor(.piggyTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            Spacer()
            
            // Close Button - positioned outside ScrollView for consistent access
            if showCloseButton {
                PiggyIconButton(
                    "xmark",
                    size: .medium,
                    style: .tertiary,
                    action: {
                        withAnimation(.spring()) {
                            dismiss()
                        }
                    }
                )
                .accessibilityLabel("Close modal")
                .accessibilityHint("Double tap to dismiss this modal")
            }
        }
        .padding(.horizontal, PiggySpacing.lg)
        .padding(.vertical, PiggySpacing.md)
        .padding(.top, PiggySpacing.sm) // Additional top padding for safe area
    }
    
    // MARK: - Alert Modal Header
    private var alertModalHeader: some View {
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

            // Close Button for alerts (smaller, less prominent)
            if showCloseButton {
                PiggyIconButton(
                    "xmark",
                    size: .medium,
                    style: .tertiary,
                    action: {
                        withAnimation(.spring()) {
                            dismiss()
                        }
                    }
                )
            }
        }
        .padding(.horizontal, PiggySpacing.lg)
        .padding(.vertical, PiggySpacing.md)
    }

    // MARK: - Modal Header
    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(title)
                    .font(PiggyFont.largeTitle)
                    .foregroundColor(.piggyTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                }
            }

            Spacer()

            // Close Button
            if showCloseButton {
                PiggyIconButton(
                    "xmark",
                    size: .medium,
                    style: .tertiary,
                    action: {
                        withAnimation(.spring()) {
                            dismiss()
                        }
                    }
                )
            }
        }
        .padding(.horizontal, PiggySpacing.lg)
        .padding(.vertical, PiggySpacing.md)
    }
    
    // MARK: - Drag Handle
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.dragHandle)
            .frame(width: 36, height: 6)
    }
    
    // MARK: - Transitions
    private var modalTransition: AnyTransition {
        switch style {
        case .bottomSheetModal:
            return .move(edge: .bottom).combined(with: .opacity)
        case .fullscreenModal:
            return .move(edge: .trailing).combined(with: .opacity)
        case .alertModal:
            return .scale(scale: 0.9).combined(with: .opacity)
        case .systemAlert:
            return .opacity // System alerts handle their own transitions
        }
    }
    
    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only enable drag-to-dismiss for bottom sheet styles (not fullscreen or alert)
                if isDismissible && style == .bottomSheetModal {
                    isDragging = true
                    dragOffset = CGSize(width: 0, height: max(0, value.translation.height))
                }
            }
            .onEnded { value in
                isDragging = false

                // Only process drag dismissal for bottom sheet styles
                if isDismissible && style == .bottomSheetModal && value.translation.height > 100 {
                    // Dismiss if dragged down significantly
                    withAnimation(.spring()) {
                        dismiss()
                    }
                } else {
                    // Snap back
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    // MARK: - Helper Functions
    private func dismiss() {
        piggyHapticFeedback(.light)
        dragOffset = .zero
        isPresented = false
    }
}

// MARK: - Convenience Modifiers
extension View {
    func piggyModal<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        style: PiggyModal<Content>.Style = .bottomSheetModal,
        size: PiggyModal<Content>.Size = .medium,
        showCloseButton: Bool = true,
        isDismissible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self

            PiggyModal(
                title,
                subtitle: subtitle,
                isPresented: isPresented,
                style: style,
                size: size,
                showCloseButton: showCloseButton,
                isDismissible: isDismissible,
                content: content
            )
        }
    }

    // MARK: - Specific Modal Variants

    /// FullScreenModal: For complex flows like Paywall or Add Artist
    func fullscreenModal<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        showCloseButton: Bool = true,
        isDismissible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        piggyModal(
            title,
            subtitle: subtitle,
            isPresented: isPresented,
            style: .fullscreenModal,
            size: .adaptive,
            showCloseButton: showCloseButton,
            isDismissible: isDismissible,
            content: content
        )
    }

    /// BottomSheetModal: For contextual actions like Add Fan Activity
    func bottomSheetModal<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        size: PiggyModal<Content>.Size = .medium,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        piggyModal(
            title,
            subtitle: subtitle,
            isPresented: isPresented,
            style: .bottomSheetModal,
            size: size,
            showCloseButton: true,
            isDismissible: true,
            content: content
        )
    }

    /// AlertModal: For destructive confirmations like Delete Account
    func alertModal<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        isDismissible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        piggyModal(
            title,
            subtitle: subtitle,
            isPresented: isPresented,
            style: .alertModal,
            size: .compact,
            showCloseButton: false,
            isDismissible: isDismissible,
            content: content
        )
    }
}

// MARK: - Preview
#Preview("Modal Styles") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggyButton(
                title: "Show Sheet Modal",
                action: {},
                style: .primary,
                size: .large
            )
            
            PiggyButton(
                title: "Show Alert Modal", 
                action: {},
                style: .secondary,
                size: .large
            )
        }
        .padding(PiggySpacing.lg)
    }
    .piggyModal(
        "Add Fan Activity",
        subtitle: "Track your K-pop spending",
        isPresented: .constant(true),
        style: .sheet,
        size: .medium
    ) {
        VStack(spacing: PiggySpacing.lg) {
            PiggyTextField(
                "Activity Name",
                text: .constant("Concert Ticket"),
                style: .primary
            )
            
            PiggyMenu(
                "Artist",
                selection: .constant("BTS" as String?),
                options: ["BTS", "BLACKPINK", "NewJeans"],
                style: .dropdown
            )
            
            PiggyTextField(
                "Amount",
                text: .constant("150"),
                style: .currency
            )
            
            PiggyButton(
                title: "Save Activity",
                action: {},
                style: .primary,
                size: .large
            )
        }
    }
}
