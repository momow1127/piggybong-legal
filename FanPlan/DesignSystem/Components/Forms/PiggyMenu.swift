import SwiftUI

// MARK: - Dedicated Opaque Menu Background Color
extension Color {
    /// Opaque background specifically for dropdown menus - NO transparency
    static let piggyMenuBackground = Color(red: 0.18, green: 0.18, blue: 0.23) // Solid dark purple-gray
}

// MARK: - PiggyMenu Styling
struct PiggyMenuStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                    .fill(Color.piggyMenuBackground) // Solid background
            )
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                    .stroke(Color.piggyBorder.opacity(0.8), lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(0.25),
                radius: 16,
                x: 0, y: 8
            )
            .zIndex(1000)
    }
}

extension View {
    func piggyMenuStyle() -> some View {
        modifier(PiggyMenuStyle())
    }
}

struct PiggyMenu<Content: View, SelectionValue: Hashable>: View {
    enum Style {
        case dropdown
        case actionSheet  
        case segmented
        case picker
        
        var containerStyle: PiggyCard<AnyView>.Style {
            switch self {
            case .dropdown: return .secondary
            case .actionSheet: return .elevated
            case .segmented: return .subtle
            case .picker: return .primary
            }
        }
    }
    
    typealias Size = PiggyComponentSize
    
    let title: String
    let placeholder: String
    @Binding var selection: SelectionValue?
    let style: Style
    let size: Size
    let searchable: Bool
    let validation: PiggyTextField.ValidationState
    let content: () -> Content
    
    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var showingActionSheet = false
    @State private var isPressed = false
    
    init(
        _ title: String,
        placeholder: String = "Select an option",
        selection: Binding<SelectionValue?>,
        style: Style = .dropdown,
        size: Size = .medium,
        searchable: Bool = false,
        validation: PiggyTextField.ValidationState = .normal,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.placeholder = placeholder
        self._selection = selection
        self.style = style
        self.size = size
        self.searchable = searchable
        self.validation = validation
        self.content = content
    }
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        switch validation {
        case .error:
            return validation.borderColor
        case .success:
            return validation.borderColor
        case .normal:
            return Color.piggyCardBorder
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(PiggyFont.caption)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            switch style {
            case .dropdown:
                dropdownMenu
            case .actionSheet:
                actionSheetTrigger
            case .segmented:
                segmentedControl
            case .picker:
                pickerWheel
            }
            
            // Validation Error Message
            if let errorMessage = validation.message {
                Text(errorMessage)
                    .font(PiggyFont.caption)
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .onChange(of: selection) {
            // Dismiss menu when selection changes
            if isExpanded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded = false
                }
            }
        }
    }
    
    // MARK: - Dropdown Menu
    private var dropdownMenu: some View {
        // Trigger Button (stays in layout)
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
            piggyHapticFeedback(.light)
        }) {
            HStack {
                Text(selectionDisplayText)
                    .font(PiggyFont.body)
                    .foregroundColor(selection != nil ? .piggyTextPrimary : .piggyTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.piggyTextSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(.horizontal, PiggySpacing.md)
            .padding(.vertical, size.verticalPadding)
            .frame(height: size.height)
            .background(
                Color.piggyCardBackground
                    .overlay(
                        // Press state overlay
                        Color.white.opacity(isPressed ? 0.15 : 0)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: PiggyBorderRadius.input))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
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
        .overlay(
            // Dropdown Content (True Floating Overlay)
            Group {
                if isExpanded {
                    VStack(spacing: PiggySpacing.xs) {
                        if searchable {
                            PiggyTextField("Search...", text: $searchText, style: .search, size: size)
                                .padding(.horizontal, PiggySpacing.sm)
                                .padding(.top, PiggySpacing.sm)
                        }

                        ScrollView {
                            LazyVStack(spacing: 2) {
                                content()
                            }
                            .padding(.bottom, PiggySpacing.sm)
                        }
                        .frame(maxHeight: 200)
                    }
                    .piggyMenuStyle()
                    .offset(y: size.height + PiggySpacing.xs)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity
                    ))
                }
            },
            alignment: .topLeading
        )
    }
    
    // MARK: - Action Sheet Trigger
    private var actionSheetTrigger: some View {
        Button(action: {
            showingActionSheet = true
            piggyHapticFeedback(.light)
        }) {
            HStack {
                Text(selectionDisplayText)
                    .font(PiggyFont.body)
                    .foregroundColor(selection != nil ? .piggyTextPrimary : .piggyTextSecondary)
                
                Spacer()
                
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.piggyTextSecondary)
            }
            .padding(.horizontal, PiggySpacing.md)
            .padding(.vertical, PiggySpacing.sm)
            .background(Color.piggyCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                    .stroke(Color.piggyCardBorder, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: PiggyBorderRadius.input))
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog(title, isPresented: $showingActionSheet) {
            content()
        }
    }
    
    // MARK: - Segmented Control (Simplified)
    private var segmentedControl: some View {
        // Note: This is a simplified version. For full segmented control,
        // you'd need to extract options from content or pass them separately
        HStack {
            content()
        }
        .padding(PiggySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                .fill(Color.piggyInputBackground)
        )
    }
    
    // MARK: - Picker Wheel (iOS Native)
    private var pickerWheel: some View {
        // Note: This would require SelectionValue to conform to CaseIterable
        // or options to be passed separately for full implementation
        Menu(selectionDisplayText) {
            content()
        }
        .foregroundColor(.piggyTextPrimary)
        .padding(.horizontal, PiggySpacing.md)
        .padding(.vertical, PiggySpacing.sm)
        .background(Color.piggyMenuBackground)
        .overlay(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: PiggyBorderRadius.input))
    }
    
    private var selectionDisplayText: String {
        // This would need to be customized based on SelectionValue type
        return selection.map { "\($0)" } ?? placeholder
    }
}

// MARK: - Convenience Initializers for String Arrays
extension PiggyMenu where Content == ForEach<Array<String>, String, PiggyMenuRow>, SelectionValue == String {
    init(
        _ title: String,
        placeholder: String = "Select an option",
        selection: Binding<String?>,
        options: [String],
        style: Style = .dropdown,
        size: Size = .medium,
        searchable: Bool = false,
        validation: PiggyTextField.ValidationState = .normal
    ) {
        self.title = title
        self.placeholder = placeholder
        self._selection = selection
        self.style = style
        self.size = size
        self.searchable = searchable
        self.validation = validation
        self.content = {
            ForEach(options, id: \.self) { option in
                PiggyMenuRow(
                    option,
                    isSelected: selection.wrappedValue == option,
                    onTap: {
                        selection.wrappedValue = option
                        // Note: Menu dismissal is handled by the main PiggyMenu component
                        // when it detects selection change
                    }
                )
            }
        }
    }
}

#Preview("Menu Styles") {
    ZStack {
        PiggyGradients.background
        
        ScrollView {
            VStack(spacing: PiggySpacing.xl) {
                // Dropdown Menu
                PiggyMenu(
                    "Select Artist",
                    placeholder: "Choose your favorite",
                    selection: .constant(nil as String?),
                    options: ["BTS", "BLACKPINK", "NewJeans", "IVE", "aespa"],
                    style: .dropdown,
                    searchable: true
                )
                
                // Action Sheet Menu
                PiggyMenu(
                    "Priority Level",
                    selection: .constant("Medium" as String?),
                    options: ["High", "Medium", "Low"],
                    style: .actionSheet
                )
                
                // Custom content dropdown
                PiggyMenu(
                    "Artist Selection",
                    selection: .constant(nil as String?)
                ) {
                    PiggyMenuRow(
                        "BTS",
                        subtitle: "Korean Boy Band • 7 members",
                        leadingIcon: "person.3.fill",
                        onTap: { print("BTS selected") }
                    )
                    
                    PiggyMenuRow(
                        "BLACKPINK",
                        subtitle: "Korean Girl Group • 4 members",
                        leadingIcon: "person.3.fill",
                        isSelected: true,
                        onTap: { print("BLACKPINK selected") }
                    )
                    
                    PiggyMenuRow(
                        "NewJeans",
                        subtitle: "Korean Girl Group • 5 members",
                        leadingIcon: "person.3.fill",
                        onTap: { print("NewJeans selected") }
                    )
                }
            }
            .padding(PiggySpacing.lg)
        }
    }
}

#Preview("Interactive Form") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggySectionHeader("Add Fan Activity", style: .primary)
            
            PiggyCard(style: .secondary) {
                VStack(spacing: PiggySpacing.md) {
                    PiggyTextField(
                        "Activity Name",
                        text: .constant("Concert Ticket")
                    )
                    
                    PiggyMenu(
                        "Artist",
                        selection: .constant("BTS" as String?),
                        options: ["BTS", "BLACKPINK", "NewJeans", "IVE", "aespa", "ITZY", "Red Velvet"],
                        style: .dropdown,
                        searchable: true
                    )
                    
                    PiggyMenu(
                        "Priority",
                        selection: .constant("High" as String?),
                        options: ["High", "Medium", "Low"],
                        style: .actionSheet
                    )
                    
                    PiggyTextField(
                        "Amount",
                        text: .constant("150"),
                        style: .currency,
                        keyboardType: .decimalPad
                    )
                    
                    Button("Save Activity") {
                        print("Save activity")
                    }
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: PiggySpacing.buttonHeight)
                    .background(PiggyGradients.primaryButton)
                    .cornerRadius(PiggyBorderRadius.button)
                }
            }
        }
        .padding(PiggySpacing.lg)
    }
}
