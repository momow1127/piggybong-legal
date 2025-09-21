import SwiftUI

struct PiggyTextField: View {
    enum Style {
        case primary
        case search  
        case currency
        case multiline
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color.piggyCardBackground
            case .search: return Color.piggyCardBackground
            case .currency: return Color.piggyCardBackground
            case .multiline: return Color.piggyCardBackground
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return .piggyBorder
            case .search: return .piggyBorder
            case .currency: return .piggyBorder
            case .multiline: return .piggyBorder
            }
        }
        
        var focusBorderColor: Color {
            switch self {
            case .primary: return .piggyPrimary
            case .search: return .piggySecondary
            case .currency: return .piggyPrimary
            case .multiline: return .piggyPrimary
            }
        }
        
        var leadingIcon: String? {
            switch self {
            case .search: return "magnifyingglass"
            case .currency: return "dollarsign.circle"
            default: return nil
            }
        }
    }
    
    typealias Size = PiggyComponentSize
    
    enum ValidationState {
        case normal
        case error(String)
        case success
        
        var borderColor: Color {
            switch self {
            case .normal: return .clear
            case .error: return .red
            case .success: return .green
            }
        }
        
        var message: String? {
            switch self {
            case .normal, .success: return nil
            case .error(let message): return message
            }
        }
    }
    
    let label: String
    @Binding var text: String
    let style: Style
    let size: Size
    let validation: ValidationState
    let leadingIcon: String?
    let trailingIcon: String?
    let onTrailingIconTap: (() -> Void)?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        _ label: String,
        text: Binding<String>,
        style: Style = .primary,
        size: Size = .medium,
        validation: ValidationState = .normal,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        onTrailingIconTap: (() -> Void)? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        onCommit: (() -> Void)? = nil
    ) {
        self.label = label
        self._text = text
        self.style = style
        self.size = size
        self.validation = validation
        self.leadingIcon = leadingIcon ?? style.leadingIcon
        self.trailingIcon = trailingIcon
        self.onTrailingIconTap = onTrailingIconTap
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.onCommit = onCommit
    }
    
    private var effectiveBorderColor: Color {
        if case .error = validation {
            return validation.borderColor
        } else if case .success = validation {
            return validation.borderColor
        } else if isFocused {
            return style.focusBorderColor
        } else {
            return style.borderColor
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
            if style == .multiline {
                multilineField
            } else {
                singleLineField
            }
            
            if let errorMessage = validation.message {
                Text(errorMessage)
                    .font(PiggyFont.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
    
    private var singleLineField: some View {
        HStack(spacing: PiggySpacing.sm) {
            // Leading Icon
            if let leadingIcon = leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.piggyTextSecondary)
            }
            
            // Text Input with custom placeholder handling
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(label)
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextTertiary)
                        .allowsHitTesting(false)
                }
                
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                            .textInputFieldStyle()
                    } else {
                        TextField("", text: $text)
                            .textInputFieldStyle()
                            .keyboardType(keyboardType)
                    }
                }
            }
            .focused($isFocused)
            .onSubmit {
                onCommit?()
            }
            
            // Trailing Icon
            if let trailingIcon = trailingIcon {
                Button(action: {
                    piggyHapticFeedback(.light)
                    onTrailingIconTap?()
                }) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.piggyTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, PiggySpacing.md)
        .padding(.vertical, size.verticalPadding)
        .frame(height: size.height)
        .background(style.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                .stroke(effectiveBorderColor, lineWidth: isFocused ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: PiggyBorderRadius.input))
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: validation.message)
    }
    
    private var multilineField: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
            Text(label)
                .font(PiggyFont.caption)
                .foregroundColor(.piggyTextSecondary)
            
            TextEditor(text: $text)
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextPrimary)
                .scrollContentBackground(.hidden)
                .padding(PiggySpacing.sm)
                .frame(minHeight: 80)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                        .stroke(effectiveBorderColor, lineWidth: isFocused ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: PiggyBorderRadius.input))
                .focused($isFocused)
        }
    }
}

// MARK: - Text Field Style Extension
extension View {
    func textInputFieldStyle() -> some View {
        self
            .font(PiggyFont.body)
            .foregroundColor(.piggyTextPrimary)
            .textFieldStyle(PlainTextFieldStyle())
            .accentColor(.piggyPrimary) // Cursor color
    }
}

// MARK: - Validation Helpers
extension PiggyTextField {
    static func validateRequired(_ text: String, fieldName: String = "Field") -> ValidationState {
        text.isEmpty ? .error("\(fieldName) is required") : .normal
    }
    
    static func validateEmail(_ email: String) -> ValidationState {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) ? .success : .error("Enter a valid email address")
    }
    
    static func validateCurrency(_ text: String, min: Double = 0, max: Double = 999999) -> ValidationState {
        guard let value = Double(text.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) else {
            return .error("Enter a valid amount")
        }
        
        if value < min {
            return .error("Amount must be at least $\(String(format: "%.0f", min))")
        }
        
        if value > max {
            return .error("Amount cannot exceed $\(String(format: "%.0f", max))")
        }
        
        return .success
    }
}

#Preview("Text Field Styles") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggyTextField("Artist Name", text: .constant("BTS"), style: .primary)
            
            PiggyTextField("Search events...", text: .constant(""), style: .search)
            
            PiggyTextField("Budget Amount", text: .constant("250"), style: .currency)
            
            PiggyTextField("Password", text: .constant(""), style: .primary, isSecure: true)
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Validation States") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggyTextField(
                "Required Field", 
                text: .constant(""),
                validation: .error("This field is required")
            )
            
            PiggyTextField(
                "Email Address",
                text: .constant("user@example.com"),
                validation: .success,
                keyboardType: .emailAddress
            )
            
            PiggyTextField(
                "Normal Field",
                text: .constant("Some text"),
                validation: .normal
            )
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Interactive Features") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggyTextField(
                "Search with clear",
                text: .constant("search query"),
                style: .search,
                trailingIcon: "xmark.circle.fill",
                onTrailingIconTap: {
                    print("Clear tapped")
                }
            )
            
            PiggyTextField(
                "Password with show",
                text: .constant("password123"),
                trailingIcon: "eye.slash",
                onTrailingIconTap: {
                    print("Toggle visibility")
                },
                isSecure: true
            )
            
            PiggyTextField(
                "Comments",
                text: .constant("This is a longer text that spans multiple lines..."),
                style: .multiline
            )
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Real World Form") {
    ZStack {
        PiggyGradients.background
        
        ScrollView {
            VStack(spacing: PiggySpacing.lg) {
                PiggySectionHeader("Add New Activity", style: .primary)
                
                PiggyCard(style: .secondary) {
                    VStack(spacing: PiggySpacing.md) {
                        PiggyTextField(
                            "Activity Name",
                            text: .constant(""),
                            validation: .error("Activity name is required")
                        )
                        
                        PiggyTextField(
                            "Amount Spent",
                            text: .constant(""),
                            style: .currency,
                            keyboardType: .decimalPad
                        )
                        
                        PiggyTextField(
                            "Notes (Optional)",
                            text: .constant(""),
                            style: .multiline
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
}