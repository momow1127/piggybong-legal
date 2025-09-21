import SwiftUI

// MARK: - Form Validation Utilities
struct PiggyFormValidation {
    
    // MARK: - Common Validation Rules
    static func required(_ value: String, fieldName: String = "Field") -> PiggyTextField.ValidationState {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        ? .error("\(fieldName) is required") 
        : .normal
    }
    
    static func minLength(_ value: String, min: Int, fieldName: String = "Field") -> PiggyTextField.ValidationState {
        value.count < min 
        ? .error("\(fieldName) must be at least \(min) characters") 
        : .normal
    }
    
    static func maxLength(_ value: String, max: Int, fieldName: String = "Field") -> PiggyTextField.ValidationState {
        value.count > max 
        ? .error("\(fieldName) cannot exceed \(max) characters") 
        : .normal
    }
    
    static func email(_ email: String) -> PiggyTextField.ValidationState {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if email.isEmpty {
            return .normal
        } else if emailPredicate.evaluate(with: email) {
            return .success
        } else {
            return .error("Enter a valid email address")
        }
    }
    
    static func currency(_ text: String, min: Double = 0, max: Double = 999999) -> PiggyTextField.ValidationState {
        let cleanedText = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedText.isEmpty {
            return .normal
        }
        
        guard let value = Double(cleanedText) else {
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
    
    static func positiveNumber(_ text: String) -> PiggyTextField.ValidationState {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedText.isEmpty {
            return .normal
        }
        
        guard let value = Double(cleanedText), value > 0 else {
            return .error("Enter a positive number")
        }
        
        return .success
    }
    
    static func phoneNumber(_ phone: String) -> PiggyTextField.ValidationState {
        let phoneRegex = "^[\\+]?[1-9]?[0-9]{7,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if phone.isEmpty {
            return .normal
        } else if phonePredicate.evaluate(with: phone) {
            return .success
        } else {
            return .error("Enter a valid phone number")
        }
    }
    
    // MARK: - K-pop Specific Validations
    static func artistName(_ name: String) -> PiggyTextField.ValidationState {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .error("Artist name is required")
        }
        
        if trimmedName.count < 2 {
            return .error("Artist name must be at least 2 characters")
        }
        
        if trimmedName.count > 50 {
            return .error("Artist name cannot exceed 50 characters")
        }
        
        return .success
    }
    
    static func activityName(_ name: String) -> PiggyTextField.ValidationState {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .error("Activity name is required")
        }
        
        if trimmedName.count > 100 {
            return .error("Activity name cannot exceed 100 characters")
        }
        
        return .success
    }
    
    static func budgetAmount(_ text: String) -> PiggyTextField.ValidationState {
        return currency(text, min: 1, max: 10000)
    }
    
    // MARK: - Composite Validators
    static func combine(_ validations: [PiggyTextField.ValidationState]) -> PiggyTextField.ValidationState {
        // Return first error found, or success if all are successful, or normal if all are normal
        for validation in validations {
            if case .error = validation {
                return validation
            }
        }
        
        for validation in validations {
            if case .success = validation {
                return .success
            }
        }
        
        return .normal
    }
    
    static func validateMultiple<T>(_ value: T, validators: [(T) -> PiggyTextField.ValidationState]) -> PiggyTextField.ValidationState {
        let validations = validators.map { $0(value) }
        return combine(validations)
    }
}

// MARK: - Form State Management
@MainActor
class PiggyFormState: ObservableObject {
    @Published var fields: [String: String] = [:]
    @Published var validationStates: [String: PiggyTextField.ValidationState] = [:]
    @Published var isValid: Bool = false
    
    func setValue(_ value: String, for key: String) {
        fields[key] = value
        updateValidation()
    }
    
    func setValidation(_ state: PiggyTextField.ValidationState, for key: String) {
        validationStates[key] = state
        updateValidation()
    }
    
    func getValue(for key: String) -> String {
        return fields[key] ?? ""
    }
    
    func getValidation(for key: String) -> PiggyTextField.ValidationState {
        return validationStates[key] ?? .normal
    }
    
    private func updateValidation() {
        // Form is valid if no fields have error states
        isValid = !validationStates.values.contains { 
            if case .error = $0 { return true }
            return false
        }
    }
    
    func reset() {
        fields.removeAll()
        validationStates.removeAll()
        isValid = false
    }
    
    func validateAll(rules: [String: (String) -> PiggyTextField.ValidationState]) {
        for (key, rule) in rules {
            let value = getValue(for: key)
            let validation = rule(value)
            setValidation(validation, for: key)
        }
    }
}

// MARK: - Convenience Extensions
extension Binding where Value == String {
    func withValidation(
        using rule: @escaping (String) -> PiggyTextField.ValidationState,
        in formState: PiggyFormState,
        key: String
    ) -> Binding<String> {
        return Binding<String>(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                Task { @MainActor in
                    formState.setValue(newValue, for: key)
                    let validation = rule(newValue)
                    formState.setValidation(validation, for: key)
                }
            }
        )
    }
}

#Preview("Validation Examples") {
    ZStack {
        PiggyGradients.background
        
        ScrollView {
            VStack(spacing: PiggySpacing.lg) {
                PiggySectionHeader("Form Validation Examples", style: .primary)
                
                PiggyCard(style: .secondary) {
                    VStack(spacing: PiggySpacing.md) {
                        PiggyTextField(
                            "Required Field",
                            text: .constant(""),
                            validation: PiggyFormValidation.required("", fieldName: "Name")
                        )
                        
                        PiggyTextField(
                            "Email Address",
                            text: .constant("test@example.com"),
                            validation: PiggyFormValidation.email("test@example.com"),
                            keyboardType: .emailAddress
                        )
                        
                        PiggyTextField(
                            "Budget Amount",
                            text: .constant("250.50"),
                            style: .currency,
                            validation: PiggyFormValidation.budgetAmount("250.50"),
                            keyboardType: .decimalPad
                        )
                        
                        PiggyTextField(
                            "Artist Name",
                            text: .constant("BTS"),
                            validation: PiggyFormValidation.artistName("BTS")
                        )
                        
                        // Combined validation example
                        let combinedValidation = PiggyFormValidation.combine([
                            PiggyFormValidation.required("Hello", fieldName: "Message"),
                            PiggyFormValidation.minLength("Hello", min: 3, fieldName: "Message"),
                            PiggyFormValidation.maxLength("Hello", max: 100, fieldName: "Message")
                        ])
                        
                        PiggyTextField(
                            "Message",
                            text: .constant("Hello"),
                            validation: combinedValidation
                        )
                    }
                }
                
                // Success and error states
                PiggyCard(style: .primary) {
                    VStack(spacing: PiggySpacing.md) {
                        Text("Validation States")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        
                        PiggyTextField(
                            "Success State",
                            text: .constant("valid@email.com"),
                            validation: .success
                        )
                        
                        PiggyTextField(
                            "Error State",
                            text: .constant("invalid-email"),
                            validation: .error("Invalid email format")
                        )
                        
                        PiggyTextField(
                            "Normal State",
                            text: .constant("Some text"),
                            validation: .normal
                        )
                    }
                }
            }
            .padding(PiggySpacing.lg)
        }
    }
}