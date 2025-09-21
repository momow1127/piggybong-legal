import Foundation

// MARK: - K-pop Themed Loading Messages
enum LoadingMessage {

    // MARK: - General Loading Messages
    static let general = "Preparing your comeback..."
    static let loading = "Until the next comeback..."

    // MARK: - Authentication & Account
    static let authentication = "Signing in with your bias..."
    static let logout = "Signing out gracefully..."
    static let accountCreation = "Creating your fan profile..."
    static let accountDeletion = "Ending your fan journey..."
    static let emailVerification = "Verifying your stan credentials..."

    // MARK: - Onboarding Flow
    static let onboardingFinalization = "Finalizing your setup..."
    static let savingPreferences = "Saving your bias preferences..."
    static let artistSelection = "Adding your ultimate bias..."
    static let prioritySetting = "Organizing your wishlist..."

    // MARK: - Data Operations
    static let dataSync = "Syncing with your bias..."
    static let uploading = "Uploading to the cloud..."
    static let downloading = "Downloading latest updates..."
    static let saving = "Saving your fan memories..."
    static let processing = "Processing your request..."

    // MARK: - AI & Analytics
    static let aiInsight = "Analyzing your fan journey..."
    static let generatingInsight = "Generating personalized insights..."
    static let calculatingSpending = "Calculating bias spending patterns..."
    static let smartRecommendations = "Finding perfect recommendations..."

    // MARK: - Shopping & Commerce
    static let processingPayment = "Processing your fan purchase..."
    static let subscription = "Activating your VIP membership..."
    static let orderProcessing = "Preparing your K-pop treasures..."

    // MARK: - Events & Updates
    static let eventsLoading = "Loading upcoming events..."
    static let newsUpdates = "Fetching latest idol news..."
    static let ticketSearch = "Searching for concert tickets..."
    static let calendarSync = "Syncing with your schedule..."

    // MARK: - Network & Background
    static let networkSync = "Connecting to the fandom..."
    static let backgroundUpdate = "Updating silently..."
    static let cacheRefresh = "Refreshing your feed..."

    // MARK: - Error Recovery
    static let retrying = "Trying again like a true fan..."
    static let reconnecting = "Reconnecting to the fandom..."
    static let recovery = "Getting back on track..."

    // MARK: - Seasonal/Special
    static let comebackSeason = "Preparing for comeback season..."
    static let concertMode = "Entering concert mode..."
    static let biasWrecking = "Calculating bias wrecker potential..."
    static let fanMode = "Loading ultimate fan mode..."

    // MARK: - Quick Access Methods
    static func forPriority(_ priority: LoadingPriority) -> String {
        switch priority {
        case .critical:
            return [accountDeletion, onboardingFinalization, processingPayment].randomElement() ?? general
        case .high:
            return [authentication, logout, subscription].randomElement() ?? general
        case .normal:
            return [aiInsight, dataSync, eventsLoading].randomElement() ?? general
        case .low:
            return [backgroundUpdate, cacheRefresh, networkSync].randomElement() ?? general
        }
    }

    static func forOperation(_ operation: LoadingOperation) -> String {
        switch operation {
        case .authentication: return authentication
        case .logout: return logout
        case .onboarding: return onboardingFinalization
        case .aiInsight: return aiInsight
        case .dataSync: return dataSync
        case .accountDeletion: return accountDeletion
        case .payment: return processingPayment
        case .events: return eventsLoading
        case .general: return general
        }
    }
}

// MARK: - Loading Operation Types
enum LoadingOperation {
    case authentication
    case logout
    case onboarding
    case aiInsight
    case dataSync
    case accountDeletion
    case payment
    case events
    case general
}

// MARK: - LoadingPriority Extension for Default Messages
extension LoadingPriority {
    var defaultMessage: String {
        return LoadingMessage.forPriority(self)
    }
}