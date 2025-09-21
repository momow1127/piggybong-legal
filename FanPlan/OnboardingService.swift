import Foundation

// MARK: - Main Onboarding Service (Refactored)
@MainActor
class OnboardingService: ObservableObject {
    // MARK: - Dependencies
    private let dataService: OnboardingDataService
    private let contentService: OnboardingContentService
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Published Properties (Delegated)
    @Published var availableArtists: [Artist] = []
    @Published var availableGoals: [OnboardingGoal] = []
    @Published var selectedArtists: Set<UUID> = []
    @Published var selectedGoals: Set<UUID> = []
    @Published var enableConcertNotifications = true
    @Published var enableMerchNotifications = true
    @Published var enableBudgetNotifications = true
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Singleton
    static let shared = OnboardingService()
    
    private init() {
        self.dataService = OnboardingDataService()
        self.contentService = OnboardingContentService()
        setupBindings()
        loadArtistsFromSupabase()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind content service to selected items and notifications only
        contentService.$selectedArtists.assign(to: &$selectedArtists)
        contentService.$selectedGoals.assign(to: &$selectedGoals)
        contentService.$enableConcertNotifications.assign(to: &$enableConcertNotifications)
        contentService.$enableMerchNotifications.assign(to: &$enableMerchNotifications)
        contentService.$enableBudgetNotifications.assign(to: &$enableBudgetNotifications)
    }
    
    // MARK: - Artist Selection (Delegated)
    func toggleArtistSelection(_ artistId: UUID) {
        contentService.toggleArtistSelection(artistId)
    }
    
    func toggleGoalSelection(_ goalId: UUID) {
        contentService.toggleGoalSelection(goalId)
    }
    
    // MARK: - Onboarding Completion
    func completeOnboarding(
        for userId: UUID? = nil,
        name: String,
        monthlyBudget: Double,
        selectedArtists: [Artist] = [],
        selectedGoals: [BiasGoalTemplate] = [],
        customGoalAmounts: [UUID: Double] = [:],
        preferences: FanPlanningPreferences = .default
    ) {
        completeOnboarding(name: name, monthlyBudget: monthlyBudget)
    }
    
    private func completeOnboarding(name: String, monthlyBudget: Double) {
        Task {
            isLoading = true
            errorMessage = nil
            
            // Create user profile with onboarding data
            let userId = UUID()
            
            // Save to database if available
            if let user = try? await supabaseService.createUser(
                name: name,
                email: "\(name.lowercased())@example.com", // Temporary email
                monthlyBudget: monthlyBudget
            ) {
                // Add selected artists to user's preferences
                for artistId in selectedArtists {
                    if availableArtists.first(where: { $0.id == artistId }) != nil {
                        _ = try? await supabaseService.createUserArtist(
                            userId: user,
                            artistId: artistId,
                            priorityRank: 1,
                            monthlyAllocation: monthlyBudget / Double(selectedArtists.count)
                        )
                    }
                }
            }
            
            // Save onboarding completion
            await dataService.completeOnboarding(for: userId)
            
            // Reset selections for next user
            contentService.resetSelections()
            
            isLoading = false
        }
    }
    
    // MARK: - Progress Management
    func markStepCompleted(_ step: String) {
        dataService.markStepCompleted(step)
    }
    
    func getProgress(for userId: UUID) -> OnboardingProgress? {
        return dataService.loadProgress(for: userId)
    }
    
    // MARK: - Missing Methods for OnboardingCoordinator
    func updateOnboardingStep(userId: UUID, currentStep: String, markCompleted: Bool = true) async throws {
        // For now, just mark the step as completed locally
        if markCompleted {
            markStepCompleted(currentStep)
        }
    }
    
    func searchArtists(query: String) async throws -> [Artist] {
        // Enhanced search implementation with fallback handling
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return availableArtists
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try database search first if we have network connectivity
        if NetworkManager.shared.isConnected && !availableArtists.isEmpty {
            do {
                let databaseResults = try await supabaseService.searchArtists(query: trimmedQuery)
                print("✅ Database search for '\(trimmedQuery)' returned \(databaseResults.count) results")
                return databaseResults
            } catch {
                print("⚠️ Database search failed, using local search: \(error.localizedDescription)")
            }
        }
        
        // Fallback to local search
        let localResults = availableArtists.filter { artist in
            artist.name.localizedCaseInsensitiveContains(trimmedQuery) ||
            (artist.group?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
        }
        
        // If no local results and we have fallback artists, search them too
        if localResults.isEmpty {
            let fallbackResults = getFallbackArtists().compactMap { popularArtist -> Artist? in
                let artist = popularArtist.artist
                if artist.name.localizedCaseInsensitiveContains(trimmedQuery) ||
                   (artist.group?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) {
                    return artist
                }
                return nil
            }
            
            print("🔍 Local search for '\(trimmedQuery)': \(localResults.count) main + \(fallbackResults.count) fallback results")
            return localResults + fallbackResults
        }
        
        print("🔍 Local search for '\(trimmedQuery)': \(localResults.count) results")
        return localResults
    }
    
    // MARK: - Supabase Integration
    private func loadArtistsFromSupabase() {
        Task {
            isLoading = true
            
            do {
                print("🎵 Loading K-pop artists from database...")
                let artists = try await supabaseService.getArtists()
                
                await MainActor.run {
                    self.availableArtists = artists
                    self.errorMessage = nil
                    self.isLoading = false
                    
                    print("✅ Successfully loaded \(artists.count) artists for onboarding")
                    
                    // Log artist details for debugging
                    let artistSample = artists.prefix(3).map { "\($0.name) (\($0.id))" }.joined(separator: ", ")
                    print("🎤 Available artists sample: \(artistSample)")
                }
                
            } catch {
                await MainActor.run {
                    // Set error message but don't fail completely
                    let networkError = NetworkManager.shared.handleNetworkError(error)
                    
                    switch networkError {
                    case .timeout:
                        self.errorMessage = "Artist loading timed out. Using offline data."
                    case .noConnection:
                        self.errorMessage = "No internet connection. Using offline artist data."
                    case .hostUnreachable:
                        self.errorMessage = "Cannot reach servers. Using offline artist data."
                    default:
                        self.errorMessage = "Failed to load artists: \(networkError.localizedDescription)"
                    }
                    
                    // Ensure we have fallback artists available
                    if self.availableArtists.isEmpty {
                        // Convert PopularArtist to Artist for compatibility
                        let fallbackArtists = self.getFallbackArtists().map { popularArtist in
                            popularArtist.artist
                        }
                        self.availableArtists = fallbackArtists
                        print("✅ Loaded \(fallbackArtists.count) fallback artists")
                    }
                    
                    self.isLoading = false
                    print("⚠️ Artist loading failed, but \(self.availableArtists.count) artists available")
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    func getSelectedArtistNames() -> [String] {
        return contentService.getSelectedArtistNames()
    }
    
    func getSelectedGoalTitles() -> [String] {
        return contentService.getSelectedGoalTitles()
    }
    
    func getTotalEstimatedMonthlyCost() -> Double {
        return contentService.getTotalEstimatedMonthlyCost()
    }
    
    func getFallbackArtists() -> [PopularArtist] {
        return contentService.getFallbackArtists()
    }
    
    // MARK: - Validation
    func validateSelections() -> Bool {
        return !selectedArtists.isEmpty && !selectedGoals.isEmpty
    }
    
    func canProceedFromStep(_ step: OnboardingStep) -> Bool {
        switch step {
        case .artistSelection:
            return !selectedArtists.isEmpty
        case .goalSetting:
            return !selectedGoals.isEmpty
        default:
            return true
        }
    }
}

// OnboardingStep extension moved to OnboardingModels.swift to avoid duplication