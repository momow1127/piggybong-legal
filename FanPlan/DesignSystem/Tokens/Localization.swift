import Foundation

// MARK: - PiggyBong Localization System
// 🚨 SINGLE SOURCE OF TRUTH - Do not create string literals elsewhere
// All components and views must import and use these localization tokens ONLY

struct PiggyLocalization {
    
    // MARK: - General App Strings
    struct General {
        static let appName = NSLocalizedString("piggy.general.appName", value: "PiggyBong", comment: "App name")
        static let cancel = NSLocalizedString("piggy.general.cancel", value: "Cancel", comment: "Cancel button")
        static let done = NSLocalizedString("piggy.general.done", value: "Done", comment: "Done button")
        static let save = NSLocalizedString("piggy.general.save", value: "Save", comment: "Save button")
        static let delete = NSLocalizedString("piggy.general.delete", value: "Delete", comment: "Delete button")
        static let edit = NSLocalizedString("piggy.general.edit", value: "Edit", comment: "Edit button")
        static let next = NSLocalizedString("piggy.general.next", value: "Next", comment: "Next button")
        static let back = NSLocalizedString("piggy.general.back", value: "Back", comment: "Back button")
        static let close = NSLocalizedString("piggy.general.close", value: "Close", comment: "Close button")
        static let loading = NSLocalizedString("piggy.general.loading", value: "Loading...", comment: "Loading state")
        static let error = NSLocalizedString("piggy.general.error", value: "Error", comment: "Error label")
        static let success = NSLocalizedString("piggy.general.success", value: "Success", comment: "Success label")
    }
    
    // MARK: - Form Strings
    struct Form {
        static let required = NSLocalizedString("piggy.form.required", value: "Required", comment: "Required field indicator")
        static let optional = NSLocalizedString("piggy.form.optional", value: "Optional", comment: "Optional field indicator")
        static let invalidInput = NSLocalizedString("piggy.form.invalidInput", value: "Invalid input", comment: "Invalid input error")
        static let fieldEmpty = NSLocalizedString("piggy.form.fieldEmpty", value: "This field is required", comment: "Empty field error")
        static let emailInvalid = NSLocalizedString("piggy.form.emailInvalid", value: "Please enter a valid email", comment: "Invalid email error")
        static let passwordTooShort = NSLocalizedString("piggy.form.passwordTooShort", value: "Password must be at least 8 characters", comment: "Password too short error")
        static let currencyFormat = NSLocalizedString("piggy.form.currencyFormat", value: "$%.2f", comment: "Currency format string")
        static let percentageFormat = NSLocalizedString("piggy.form.percentageFormat", value: "%.1f%%", comment: "Percentage format string")
    }
    
    // MARK: - Settings Strings
    struct Settings {
        static let title = NSLocalizedString("piggy.settings.title", value: "Settings", comment: "Settings screen title")
        static let profile = NSLocalizedString("piggy.settings.profile", value: "Profile", comment: "Profile section")
        static let notifications = NSLocalizedString("piggy.settings.notifications", value: "Notifications", comment: "Notifications section")
        static let privacy = NSLocalizedString("piggy.settings.privacy", value: "Privacy", comment: "Privacy section")
        static let support = NSLocalizedString("piggy.settings.support", value: "Support", comment: "Support section")
        static let about = NSLocalizedString("piggy.settings.about", value: "About", comment: "About section")
        static let logout = NSLocalizedString("piggy.settings.logout", value: "Logout", comment: "Logout button")
        static let deleteAccount = NSLocalizedString("piggy.settings.deleteAccount", value: "Delete Account", comment: "Delete account button")
        static let version = NSLocalizedString("piggy.settings.version", value: "Version", comment: "App version label")
    }
    
    // MARK: - Priority System Strings
    struct Priority {
        static let title = NSLocalizedString("piggy.priority.title", value: "Artist Priorities", comment: "Priority screen title")
        static let rank = NSLocalizedString("piggy.priority.rank", value: "Rank", comment: "Priority rank label")
        static let artist = NSLocalizedString("piggy.priority.artist", value: "Artist", comment: "Artist label")
        static let allocation = NSLocalizedString("piggy.priority.allocation", value: "Allocation", comment: "Budget allocation label")
        static let dragToReorder = NSLocalizedString("piggy.priority.dragToReorder", value: "Drag to reorder", comment: "Drag instruction")
        static let topPriority = NSLocalizedString("piggy.priority.topPriority", value: "Top Priority", comment: "Top priority label")
        static let lowPriority = NSLocalizedString("piggy.priority.lowPriority", value: "Low Priority", comment: "Low priority label")
    }
    
    // MARK: - Authentication Strings
    struct Auth {
        static let signIn = NSLocalizedString("piggy.auth.signIn", value: "Sign In", comment: "Sign in button")
        static let signUp = NSLocalizedString("piggy.auth.signUp", value: "Sign Up", comment: "Sign up button")
        static let email = NSLocalizedString("piggy.auth.email", value: "Email", comment: "Email field label")
        static let password = NSLocalizedString("piggy.auth.password", value: "Password", comment: "Password field label")
        static let confirmPassword = NSLocalizedString("piggy.auth.confirmPassword", value: "Confirm Password", comment: "Confirm password field label")
        static let forgotPassword = NSLocalizedString("piggy.auth.forgotPassword", value: "Forgot Password?", comment: "Forgot password link")
        static let resetPassword = NSLocalizedString("piggy.auth.resetPassword", value: "Reset Password", comment: "Reset password button")
        static let signInWithApple = NSLocalizedString("piggy.auth.signInWithApple", value: "Sign in with Apple", comment: "Sign in with Apple button")
        static let signInWithGoogle = NSLocalizedString("piggy.auth.signInWithGoogle", value: "Sign in with Google", comment: "Sign in with Google button")
    }
    
    // MARK: - Dashboard Strings
    struct Dashboard {
        static let title = NSLocalizedString("piggy.dashboard.title", value: "Dashboard", comment: "Dashboard screen title")
        static let totalBudget = NSLocalizedString("piggy.dashboard.totalBudget", value: "Total Budget", comment: "Total budget label")
        static let spent = NSLocalizedString("piggy.dashboard.spent", value: "Spent", comment: "Spent amount label")
        static let remaining = NSLocalizedString("piggy.dashboard.remaining", value: "Remaining", comment: "Remaining amount label")
        static let thisMonth = NSLocalizedString("piggy.dashboard.thisMonth", value: "This Month", comment: "This month label")
        static let recentActivity = NSLocalizedString("piggy.dashboard.recentActivity", value: "Recent Activity", comment: "Recent activity section")
        static let viewAll = NSLocalizedString("piggy.dashboard.viewAll", value: "View All", comment: "View all button")
    }
    
    // MARK: - Error Messages
    struct Errors {
        static let networkError = NSLocalizedString("piggy.errors.networkError", value: "Network connection error", comment: "Network error message")
        static let serverError = NSLocalizedString("piggy.errors.serverError", value: "Server error occurred", comment: "Server error message")
        static let unknownError = NSLocalizedString("piggy.errors.unknownError", value: "An unknown error occurred", comment: "Unknown error message")
        static let authenticationFailed = NSLocalizedString("piggy.errors.authenticationFailed", value: "Authentication failed", comment: "Authentication error")
        static let permissionDenied = NSLocalizedString("piggy.errors.permissionDenied", value: "Permission denied", comment: "Permission error")
        static let dataNotFound = NSLocalizedString("piggy.errors.dataNotFound", value: "Data not found", comment: "Data not found error")
    }
    
    // MARK: - Toast Messages
    struct Toast {
        static let saved = NSLocalizedString("piggy.toast.saved", value: "Saved successfully", comment: "Save success toast")
        static let deleted = NSLocalizedString("piggy.toast.deleted", value: "Deleted successfully", comment: "Delete success toast")
        static let updated = NSLocalizedString("piggy.toast.updated", value: "Updated successfully", comment: "Update success toast")
        static let error = NSLocalizedString("piggy.toast.error", value: "Something went wrong", comment: "Error toast")
        static let tryAgain = NSLocalizedString("piggy.toast.tryAgain", value: "Please try again", comment: "Try again toast")
        static let offline = NSLocalizedString("piggy.toast.offline", value: "You're currently offline", comment: "Offline toast")
        static let online = NSLocalizedString("piggy.toast.online", value: "You're back online", comment: "Online toast")
    }
    
    // MARK: - Accessibility Strings
    struct Accessibility {
        static let button = NSLocalizedString("piggy.a11y.button", value: "Button", comment: "Button accessibility label")
        static let textField = NSLocalizedString("piggy.a11y.textField", value: "Text field", comment: "Text field accessibility label")
        static let image = NSLocalizedString("piggy.a11y.image", value: "Image", comment: "Image accessibility label")
        static let closeButton = NSLocalizedString("piggy.a11y.closeButton", value: "Close", comment: "Close button accessibility label")
        static let menuButton = NSLocalizedString("piggy.a11y.menuButton", value: "Menu", comment: "Menu button accessibility label")
        static let dragHandle = NSLocalizedString("piggy.a11y.dragHandle", value: "Drag to reorder", comment: "Drag handle accessibility hint")
        static let loading = NSLocalizedString("piggy.a11y.loading", value: "Loading content", comment: "Loading accessibility label")
    }
    
    // MARK: - Placeholder Strings
    struct Placeholders {
        static let searchArtists = NSLocalizedString("piggy.placeholders.searchArtists", value: "Search artists...", comment: "Search artists placeholder")
        static let enterAmount = NSLocalizedString("piggy.placeholders.enterAmount", value: "Enter amount", comment: "Enter amount placeholder")
        static let selectDate = NSLocalizedString("piggy.placeholders.selectDate", value: "Select date", comment: "Select date placeholder")
        static let addNotes = NSLocalizedString("piggy.placeholders.addNotes", value: "Add notes (optional)", comment: "Add notes placeholder")
        static let typeHere = NSLocalizedString("piggy.placeholders.typeHere", value: "Type here...", comment: "Generic type placeholder")
    }
}

// MARK: - Localization Helper Functions
extension PiggyLocalization {
    
    /// Get localized string with count formatting
    static func pluralized(key: String, count: Int) -> String {
        let format = NSLocalizedString(key, comment: "Pluralized string")
        return String.localizedStringWithFormat(format, count)
    }
    
    /// Get currency formatted string
    static func currency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? Form.currencyFormat
    }
    
    /// Get percentage formatted string
    static func percentage(value: Double) -> String {
        return String(format: Form.percentageFormat, value)
    }
}

// MARK: - Localization Usage Guidelines
/*
 🌍 LOCALIZATION USAGE GUIDELINES:

 ✅ DO:
 - Use PiggyLocalization.General.cancel instead of "Cancel"
 - Use PiggyLocalization.currency() for money formatting
 - Provide clear comment descriptions for all strings
 - Use semantic keys (not just the English text)

 ❌ DON'T:
 - Hardcode string literals in views: Text("Cancel")
 - Use string interpolation with hardcoded text
 - Create custom localization keys outside this system
 - Skip providing context comments

 🎯 SEMANTIC ORGANIZATION:
 - General: App-wide common strings (Cancel, Done, Save)
 - Form: Input validation and form-specific strings
 - Settings: Settings screen specific strings
 - Priority: Priority system specific strings
 - Auth: Authentication flow strings
 - Dashboard: Dashboard screen strings
 - Errors: Error messages and states
 - Toast: Toast notification messages
 - Accessibility: Screen reader and a11y labels
 - Placeholders: Input field placeholders

 📱 ACCESSIBILITY:
 - All interactive elements should have accessibility labels
 - Use PiggyLocalization.Accessibility for a11y strings
 - Provide context hints for complex interactions
 - Support VoiceOver and other assistive technologies
*/