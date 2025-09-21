import Foundation

// MARK: - Production-Ready Input Validation
class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // MARK: - Validation Rules
    struct ValidationRule {
        let validate: (String) -> Bool
        let errorMessage: String
    }
    
    // MARK: - Common Validation Rules
    static let emailRules: [ValidationRule] = [
        ValidationRule(
            validate: { !$0.isEmpty },
            errorMessage: "Email is required"
        ),
        ValidationRule(
            validate: { $0.count <= 254 },
            errorMessage: "Email is too long"
        ),
        ValidationRule(
            validate: { email in
                let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
                return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
            },
            errorMessage: "Please enter a valid email address"
        )
    ]
    
    static let passwordRules: [ValidationRule] = [
        ValidationRule(
            validate: { !$0.isEmpty },
            errorMessage: "Password is required"
        ),
        ValidationRule(
            validate: { $0.count >= 6 },
            errorMessage: "Password must be at least 6 characters"
        ),
        ValidationRule(
            validate: { $0.count <= 128 },
            errorMessage: "Password is too long"
        ),
        ValidationRule(
            validate: { password in
                // Check for at least one letter and one number for basic security
                let hasLetter = password.rangeOfCharacter(from: .letters) != nil
                let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
                return hasLetter && hasNumber
            },
            errorMessage: "Password must contain at least one letter and one number"
        )
    ]
    
    static let nameRules: [ValidationRule] = [
        ValidationRule(
            validate: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            errorMessage: "Name is required"
        ),
        ValidationRule(
            validate: { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 },
            errorMessage: "Name must be at least 2 characters"
        ),
        ValidationRule(
            validate: { $0.trimmingCharacters(in: .whitespacesAndNewlines).count <= 50 },
            errorMessage: "Name is too long"
        ),
        ValidationRule(
            validate: { name in
                // Allow letters, spaces, hyphens, apostrophes
                let allowedCharacters = CharacterSet.letters
                    .union(.whitespaces)
                    .union(CharacterSet(charactersIn: "-'"))
                return name.trimmingCharacters(in: allowedCharacters).isEmpty
            },
            errorMessage: "Name contains invalid characters"
        )
    ]
    
    static let budgetRules: [ValidationRule] = [
        ValidationRule(
            validate: { budget in
                guard let amount = Double(budget.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) else {
                    return false
                }
                return amount > 0
            },
            errorMessage: "Budget must be greater than $0"
        ),
        ValidationRule(
            validate: { budget in
                guard let amount = Double(budget.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) else {
                    return false
                }
                return amount <= 100000
            },
            errorMessage: "Budget cannot exceed $100,000"
        )
    ]
    
    // MARK: - Validation Methods
    func validate(_ input: String, against rules: [ValidationRule]) -> String? {
        for rule in rules {
            if !rule.validate(input) {
                return rule.errorMessage
            }
        }
        return nil
    }
    
    func validateEmail(_ email: String) -> String? {
        return validate(email, against: Self.emailRules)
    }
    
    func validatePassword(_ password: String) -> String? {
        return validate(password, against: Self.passwordRules)
    }
    
    func validateName(_ name: String) -> String? {
        return validate(name, against: Self.nameRules)
    }
    
    func validateBudget(_ budget: String) -> String? {
        return validate(budget, against: Self.budgetRules)
    }
    
    // MARK: - Input Sanitization
    func sanitizeUserInput(_ input: String) -> String {
        // Remove potentially dangerous characters and limit length
        let sanitized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "&", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "'")
        
        // Limit length to prevent abuse
        return String(sanitized.prefix(1000))
    }
    
    func sanitizeBudgetInput(_ input: String) -> String {
        // Only allow digits, decimal point, dollar sign, and comma
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,$")
        let sanitized = input.components(separatedBy: allowedCharacters.inverted).joined()
        
        // Ensure only one decimal point
        let components = sanitized.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        
        return sanitized
    }
    
    // MARK: - Real-time Validation
    func validateAsUserTypes(_ input: String, rules: [ValidationRule], showAllErrors: Bool = false) -> [String] {
        var errors: [String] = []
        
        for rule in rules {
            if !rule.validate(input) {
                errors.append(rule.errorMessage)
                if !showAllErrors {
                    break // Only show first error for better UX
                }
            }
        }
        
        return errors
    }
}

// MARK: - Error Sanitization for Production
extension ValidationService {
    
    enum SanitizedError: LocalizedError {
        case validationFailed
        case networkUnavailable
        case authenticationRequired
        case resourceNotFound
        case serverError
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .validationFailed:
                return "Please check your input and try again"
            case .networkUnavailable:
                return "Please check your internet connection"
            case .authenticationRequired:
                return "Please sign in to continue"
            case .resourceNotFound:
                return "The requested information could not be found"
            case .serverError:
                return "Service temporarily unavailable. Please try again later"
            case .unknownError:
                return "Something went wrong. Please try again"
            }
        }
    }
    
    func sanitizeError(_ error: Error) -> SanitizedError {
        let errorString = error.localizedDescription.lowercased()
        
        // Map specific errors to sanitized versions
        if errorString.contains("validation") || errorString.contains("invalid") {
            return .validationFailed
        } else if errorString.contains("network") || errorString.contains("connection") {
            return .networkUnavailable
        } else if errorString.contains("unauthorized") || errorString.contains("authentication") {
            return .authenticationRequired
        } else if errorString.contains("not found") || errorString.contains("404") {
            return .resourceNotFound
        } else if errorString.contains("server") || errorString.contains("500") {
            return .serverError
        } else {
            return .unknownError
        }
    }
}

// MARK: - Rate Limiting for Security
extension ValidationService {
    private static var attemptCounts: [String: (count: Int, lastAttempt: Date)] = [:]
    private static let maxAttempts = 5
    private static let timeWindow: TimeInterval = 300 // 5 minutes
    
    func checkRateLimit(for identifier: String) -> Bool {
        let now = Date()
        
        if let record = Self.attemptCounts[identifier] {
            // Reset if time window has passed
            if now.timeIntervalSince(record.lastAttempt) > Self.timeWindow {
                Self.attemptCounts[identifier] = (count: 1, lastAttempt: now)
                return true
            }
            
            // Check if under limit
            if record.count < Self.maxAttempts {
                Self.attemptCounts[identifier] = (count: record.count + 1, lastAttempt: now)
                return true
            }
            
            return false // Rate limited
        } else {
            // First attempt
            Self.attemptCounts[identifier] = (count: 1, lastAttempt: now)
            return true
        }
    }
    
    func getRemainingCooldown(for identifier: String) -> TimeInterval {
        guard let record = Self.attemptCounts[identifier] else { return 0 }
        
        let elapsed = Date().timeIntervalSince(record.lastAttempt)
        return max(0, Self.timeWindow - elapsed)
    }
}