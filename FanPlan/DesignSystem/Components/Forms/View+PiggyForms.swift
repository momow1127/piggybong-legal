import SwiftUI

// MARK: - Form Helper Extensions
extension View {
    
    // MARK: - Form Layout Helpers
    func piggyFormGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            content()
        }
    }
    
    func piggyFormSection<Header: View, Content: View>(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            header()
            content()
        }
        .padding(.bottom, PiggySpacing.lg)
    }
    
    func piggyFormCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        PiggyCard(style: .secondary) {
            VStack(alignment: .leading, spacing: PiggySpacing.md) {
                content()
            }
        }
    }
    
    // MARK: - Input Focus Management
    func piggyFormFocus(
        _ isFocused: Binding<Bool>,
        onFocus: (() -> Void)? = nil,
        onBlur: (() -> Void)? = nil
    ) -> some View {
        self.onChange(of: isFocused.wrappedValue) { _, newValue in
            if newValue {
                onFocus?()
            } else {
                onBlur?()
            }
        }
    }
    
    // MARK: - Validation Helpers
    func piggyValidated<T: Equatable>(
        _ value: T,
        validator: @escaping (T) -> PiggyTextField.ValidationState,
        onValidationChange: @escaping (PiggyTextField.ValidationState) -> Void
    ) -> some View {
        self.onChange(of: value) { _, newValue in
            let validation = validator(newValue)
            onValidationChange(validation)
        }
    }
    
    // MARK: - Form Submission
    func piggyFormSubmission(
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        self.overlay(
            Button(action: action) {
                Text("Submit")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: PiggySpacing.buttonHeight)
                    .background(enabled ? AnyShapeStyle(PiggyGradients.primaryButton) : AnyShapeStyle(Color.gray.opacity(0.3)))
                    .cornerRadius(PiggyBorderRadius.button)
            }
            .disabled(!enabled)
            .padding(.top, PiggySpacing.lg),
            alignment: .bottom
        )
    }
    
    // MARK: - Currency Formatting Helpers
    func currencyFormatted() -> some View {
        self.keyboardType(.decimalPad)
            .textContentType(.none)
    }
    
    // MARK: - Email Formatting Helpers  
    func emailFormatted() -> some View {
        self.keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
    
    // MARK: - Phone Formatting Helpers
    func phoneFormatted() -> some View {
        self.keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
    }
    
    // MARK: - Search Formatting Helpers
    func searchFormatted() -> some View {
        self.autocapitalization(.none)
            .disableAutocorrection(false)
    }
}

// MARK: - Form Container
struct PiggyForm<Content: View>: View {
    let title: String
    let subtitle: String?
    let isValid: Bool
    let onSubmit: () -> Void
    let submitText: String
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        isValid: Bool = true,
        submitText: String = "Submit",
        onSubmit: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isValid = isValid
        self.submitText = submitText
        self.onSubmit = onSubmit
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: PiggySpacing.lg) {
                // Form Header
                PiggySectionHeader(
                    title,
                    subtitle: subtitle,
                    style: .primary
                )
                
                // Form Content
                content()
                
                // Submit Button
                Button(action: {
                    piggyHapticFeedback(.success)
                    onSubmit()
                }) {
                    Text(submitText)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: PiggySpacing.buttonHeight)
                        .background(isValid ? AnyShapeStyle(PiggyGradients.primaryButton) : AnyShapeStyle(Color.gray.opacity(0.3)))
                        .cornerRadius(PiggyBorderRadius.button)
                }
                .disabled(!isValid)
            }
            .padding(PiggySpacing.lg)
            .padding(.bottom, 100) // Extra bottom padding for keyboard
        }
    }
}

// MARK: - Form Field Builder
@resultBuilder
struct PiggyFormBuilder {
    static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }
    
    static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> some View {
        VStack(spacing: PiggySpacing.md) {
            c0
            c1
        }
    }
    
    static func buildBlock<C0: View, C1: View, C2: View>(_ c0: C0, _ c1: C1, _ c2: C2) -> some View {
        VStack(spacing: PiggySpacing.md) {
            c0
            c1
            c2
        }
    }
    
    static func buildBlock<C0: View, C1: View, C2: View, C3: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> some View {
        VStack(spacing: PiggySpacing.md) {
            c0
            c1
            c2
            c3
        }
    }
    
    static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> some View {
        VStack(spacing: PiggySpacing.md) {
            c0
            c1
            c2
            c3
            c4
        }
    }
}

#Preview("Form Helpers") {
    ZStack {
        PiggyGradients.background
        
        PiggyForm(
            title: "Add Fan Activity",
            subtitle: "Track your K-pop spending",
            isValid: true,
            submitText: "Save Activity",
            onSubmit: {
                print("Form submitted")
            }
        ) {
            VStack(spacing: PiggySpacing.md) {
                PiggyCard(style: .secondary) {
                    VStack(alignment: .leading, spacing: PiggySpacing.md) {
                        PiggyTextField("Activity Name", text: .constant("Concert Ticket"))
                        
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
                        .currencyFormatted()
                    }
                }
                
                PiggyCard(style: .secondary) {
                    VStack(alignment: .leading, spacing: PiggySpacing.md) {
                        PiggyTextField(
                            "Email (Optional)",
                            text: .constant(""),
                            validation: PiggyFormValidation.email("")
                        )
                        .emailFormatted()
                        
                        PiggyTextField(
                            "Notes",
                            text: .constant("Amazing concert experience!"),
                            style: .multiline
                        )
                    }
                }
            }
        }
    }
}

#Preview("Form Layout Helpers") {
    ZStack {
        PiggyGradients.background
        
        ScrollView {
            VStack(spacing: PiggySpacing.xl) {
                VStack {}
                    .piggyFormSection(
                        header: {
                            PiggySectionHeader("Personal Information", style: .primary)
                        },
                        content: {
                            VStack {}
                                .piggyFormGroup {
                                    PiggyTextField("Full Name", text: .constant(""))
                                    PiggyTextField("Email Address", text: .constant(""))
                                        .emailFormatted()
                                }
                        }
                    )
                
                VStack {}
                    .piggyFormSection(
                        header: {
                            PiggySectionHeader("Preferences", style: .primary)
                        },
                        content: {
                            VStack {}
                                .piggyFormCard {
                                    PiggyMenu(
                                        "Favorite Genre",
                                        selection: .constant(nil as String?),
                                        options: ["K-pop", "J-pop", "Pop", "Rock"],
                                        style: .dropdown
                                    )
                                    
                                    PiggyMenu(
                                        "Notification Level",
                                        selection: .constant("Medium" as String?),
                                        options: ["High", "Medium", "Low", "Off"],
                                        style: .actionSheet
                                    )
                                }
                        }
                    ) // Close piggyFormSection call
            } // Close VStack
            .padding(PiggySpacing.lg)
        } // Close ScrollView
    } // Close ZStack
}