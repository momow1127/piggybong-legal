import Foundation
import SwiftUI
import Combine

// MARK: - Idol Management Service
class IdolManagementService: ObservableObject {
    static let shared = IdolManagementService()
    
    // MARK: - Published Properties
    @Published var userIdols: [IdolModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Subscription Status
    @Published var subscriptionStatus: (isPro: Bool, idolLimit: Int) = (false, 3)
    @Published var currentIdolCount = 0
    @Published var canAddMoreIdols: Bool = true
    
    // MARK: - Services
    private let supabaseService = SupabaseService.shared
    private let userSession = UserSession.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadUserIdols()
        updateSubscriptionStatus()
    }
    
    // MARK: - Public Methods
    
    /// Load user's current idols from database - optimized for background processing
    func loadUserIdols() {
        Task {
            await loadUserIdolsAsync()
        }
    }

    private func loadUserIdolsAsync() async {
        // Prevent concurrent loading
        guard !isLoading else { return }

        // UI updates on main thread
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showError = false
        }

        do {
            // Heavy database operations on background thread
            let fanIdols = try await supabaseService.getFanIdols(userId: userSession.currentUserId)

            // Heavy data processing on background thread
            let idolModels = fanIdols.map { $0.toIdolModel() }

            // UI updates back on main thread
            await MainActor.run {
                self.userIdols = idolModels
                self.currentIdolCount = idolModels.count
                self.updateCanAddMoreStatus()
                self.isLoading = false
            }

            print("✅ Loaded \(idolModels.count) user idols")

        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }
    
    /// Add a new idol to user's list
    func addIdol(artistId: UUID, artistName: String, imageURL: String?) async throws -> String {
        // Pre-flight check
        guard canAddMoreIdols else {
            let errorMessage = subscriptionStatus.isPro
                ? "You've reached the Pro limit of \(subscriptionStatus.idolLimit) idols"
                : "You've reached the free limit of \(subscriptionStatus.idolLimit) idols. Upgrade to Pro for up to 6 idols!"
            throw IdolManagementError.limitReached(errorMessage)
        }

        // Check for duplicates
        if userIdols.contains(where: { $0.id == artistId.uuidString }) {
            throw IdolManagementError.duplicate("This artist is already in your idols list")
        }

        // Try to save to database, but continue with local storage if it fails (MVP fallback)
        var successMessage = "Artist added successfully!"

        do {
            // Ensure user is authenticated before making the request
            if try await supabaseService.getCurrentUser() == nil {
                print("🔓 User not authenticated - anonymous sign-in disabled")
                print("⚠️ Skipping database save - user must sign in with Google, Apple, or Email")
                throw IdolManagementError.authenticationRequired
            }

            successMessage = try await supabaseService.addFanIdol(artistId: artistId)
            print("✅ Successfully saved idol to database: \(artistName)")
        } catch {
            print("⚠️ Database save failed for idol '\(artistName)': \(error)")
            print("📱 Using local storage for MVP - artist will be available in this session")

            // For MVP: Continue with local storage even if database fails
            successMessage = "Artist added locally (offline mode)"
        }

        // Add to local cache regardless of database success/failure
        let newIdol = IdolModel(
            id: artistId.uuidString,
            name: artistName,
            profileImageURL: imageURL ?? ""
        )

        await MainActor.run {
            self.userIdols.append(newIdol)
            self.currentIdolCount = self.userIdols.count
            self.updateCanAddMoreStatus()
        }

        print("✅ Added idol to local cache: \(artistName)")
        return successMessage
    }
    
    /// Delete an idol from user's list
    func deleteIdol(artistId: UUID) async throws -> String {
        // Find the idol to delete
        guard let idolToDelete = userIdols.first(where: { $0.id == artistId.uuidString }) else {
            throw IdolManagementError.notFound("Idol not found in your list")
        }

        var successMessage = "Artist removed successfully!"

        // Try to delete from database, but continue with local removal if it fails (MVP fallback)
        do {
            successMessage = try await supabaseService.deleteFanIdol(artistId: artistId)
            print("✅ Successfully deleted idol from database: \(idolToDelete.name)")
        } catch {
            print("⚠️ Database delete failed for idol '\(idolToDelete.name)': \(error)")
            print("📱 Using local removal for MVP - artist removed from this session")

            // For MVP: Continue with local removal even if database fails
            successMessage = "Artist removed locally (offline mode)"
        }

        // Remove from local cache regardless of database success/failure
        await MainActor.run {
            self.userIdols.removeAll { $0.id == artistId.uuidString }
            self.currentIdolCount = self.userIdols.count
            self.updateCanAddMoreStatus()
        }

        print("✅ Removed idol from local cache: \(idolToDelete.name)")
        return successMessage
    }
    
    /// Delete an idol by idol record ID
    func deleteIdol(idolId: UUID) async throws -> String {
        do {
            let successMessage = try await supabaseService.deleteFanIdol(idolId: idolId)
            
            // Refresh the full list since we don't know which artist was deleted
            loadUserIdols()
            
            print("✅ Deleted idol by ID: \(idolId)")
            return successMessage
            
        } catch {
            print("❌ Failed to delete idol by ID: \(error)")
            throw error
        }
    }
    
    /// Refresh idol list and subscription status
    func refresh() {
        updateSubscriptionStatus()
        loadUserIdols()
    }
    
    /// Update subscription status (integrate with RevenueCat)
    func updateSubscriptionStatus() {
        Task {
            // TODO: Integrate with actual subscription service
            let status = await supabaseService.getSubscriptionStatus()
            await MainActor.run {
                self.subscriptionStatus = status
                self.updateCanAddMoreStatus()
            }
        }
    }
    
    /// Check if user can add more idols based on current count and subscription
    private func updateCanAddMoreStatus() {
        canAddMoreIdols = currentIdolCount < subscriptionStatus.idolLimit
    }
    
    /// Handle subscription downgrade (remove excess idols)
    func handleSubscriptionDowngrade(newLimit: Int) async {
        guard currentIdolCount > newLimit else { return }
        
        let excessCount = currentIdolCount - newLimit
        print("⚠️ User exceeded new limit by \(excessCount) idols")
        
        // Remove excess idols (lowest priority first)
        let idolsToRemove = Array(userIdols.suffix(excessCount))
        
        for idol in idolsToRemove {
            do {
                // Safe UUID conversion to prevent crashes
                guard let artistId = UUID(uuidString: idol.id) else {
                    print("❌ Invalid UUID for idol: \(idol.id)")
                    continue
                }
                _ = try await deleteIdol(artistId: artistId)
            } catch {
                print("❌ Failed to remove excess idol: \(error)")
                // Continue trying to remove others
            }
        }
        
        // Show notification to user about the changes
        await MainActor.run {
            self.errorMessage = "Your subscription was downgraded. We've kept your top \(newLimit) idols."
            self.showError = true
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get remaining idol slots
    var remainingSlots: Int {
        max(0, subscriptionStatus.idolLimit - currentIdolCount)
    }
    
    /// Get upgrade message when at limit
    var upgradeMessage: String {
        if subscriptionStatus.isPro {
            return "You've reached the Pro limit of \(subscriptionStatus.idolLimit) idols."
        } else {
            return "Upgrade to Pro to add up to 6 idols! Currently: \(currentIdolCount)/\(subscriptionStatus.idolLimit)"
        }
    }
    
    /// Check if specific artist is already an idol
    func isIdol(artistId: String) -> Bool {
        return userIdols.contains { $0.id == artistId }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        isLoading = false
        
        if let idolError = error as? IdolManagementError {
            errorMessage = idolError.localizedDescription
        } else if let supabaseError = error as? SupabaseService.SupabaseError {
            switch supabaseError {
            case .networkError:
                errorMessage = "Network connection failed. Please check your internet connection."
            case .unauthorized:
                errorMessage = "Authentication required. Please log in again."
            case .notFound:
                errorMessage = "Data not found. Please try refreshing."
            case .dataParsingError:
                errorMessage = "Failed to load data. Please try again."
            case .serverError(let message):
                errorMessage = "Server error: \(message)"
            default:
                errorMessage = "Something went wrong. Please try again."
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        showError = true
        print("❌ Idol management error: \(errorMessage ?? "Unknown error")")
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    /// Retry failed operation
    func retryLastOperation() {
        clearError()
        loadUserIdols()
    }
}

// MARK: - Idol Management Errors

enum IdolManagementError: LocalizedError, Equatable {
    case limitReached(String)
    case duplicate(String)
    case notFound(String)
    case networkError(String)
    case unauthorized
    case authenticationRequired
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .limitReached(let message):
            return message
        case .duplicate(let message):
            return message
        case .notFound(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Authentication required. Please log in again."
        case .authenticationRequired:
            return "Please sign in to save your idols permanently."
        case .invalidData:
            return "Invalid data provided."
        }
    }
}

// MARK: - Toast Integration

extension IdolManagementService {
    /// Show success toast
    func showSuccessToast(_ message: String) {
        // TODO: Integrate with ToastManager
        print("🎉 Success: \(message)")
    }
    
    /// Show error toast
    func showErrorToast(_ message: String) {
        // TODO: Integrate with ToastManager
        print("❌ Error: \(message)")
    }
}