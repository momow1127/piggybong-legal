import Foundation

// MARK: - Onboarding Content Service
@MainActor
class OnboardingContentService: ObservableObject {
    @Published var availableArtists: [MockArtist] = []
    @Published var availableGoals: [OnboardingGoal] = []
    @Published var selectedArtists: Set<UUID> = []
    @Published var selectedGoals: Set<UUID> = []
    
    // Notification preferences
    @Published var enableConcertNotifications = true
    @Published var enableMerchNotifications = true
    @Published var enableBudgetNotifications = true
    
    init() {
        loadContent()
    }
    
    private func loadContent() {
        loadArtists()
        loadGoals()
    }
    
    private func loadArtists() {
        // Load the 42 real K-pop artists from CSV with proper UUIDs
        availableArtists = [
            MockArtist(id: UUID(uuidString: "18dd2150-6cea-4209-b1cf-cd752d80750f")!, name: "Jungkook", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "193e711b-b10d-4314-b73a-98fbe554699a")!, name: "V", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "1c0cbb1d-8259-475d-83f6-b0dd68b307f9")!, name: "LE SSERAFIM", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "1c12fbdc-5a41-4e99-a14b-01cd8d66160c")!, name: "BABYMONSTER", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "1f4d8003-1af5-4913-845e-a779246c425b")!, name: "Taeyeon", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "2cf2abb0-5cdf-4886-a3ac-a1ffb5033556")!, name: "i-dle", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "30097cb9-174f-43d6-8804-06fc90aefc92")!, name: "RIIZE", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "358a2151-6c14-4517-8da6-7ce5db4d3758")!, name: "Jennie", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "3c95c84e-19fb-478a-9cdc-59e234bdba88")!, name: "Rosé", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "48126d6f-9cf0-45aa-a040-12b7cfa05c1f")!, name: "J-Hope", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "4cab2b65-94fa-4247-8714-2d1c6353b561")!, name: "BTS", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "5558d691-03dc-471b-85e7-775c2cded74d")!, name: "ATEEZ", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "5840f8ce-42a5-4ccf-ac63-f67fe422bf9e")!, name: "SEVENTEEN", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "5b1cd5d6-c34c-4857-9999-f0b88f194214")!, name: "2NE1", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "61417fa5-fa2e-46d7-a3ba-958e5c58f527")!, name: "ENHYPEN", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "65f54088-7a67-4d25-b707-d1fc23bb7a0f")!, name: "BOYNEXTDOOR", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "69b41ce2-5eb4-4766-adb6-2ba6124dfb2e")!, name: "CL", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "7bdd0c21-4f53-46fe-86df-5d40362a4f1e")!, name: "Jimin", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "8866b088-a8f3-4092-9c0c-620ec13e5b23")!, name: "PSY", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "8a2d1528-4be5-4c56-9a31-af687a1d0dde")!, name: "RM", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "8ea6563b-3b52-4d39-a407-c3b407e1f21b")!, name: "aespa", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "8fc2ae57-e562-479a-bd74-e0881cbc72bd")!, name: "ITZY", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "ae6bd741-920c-452e-b651-f15ddd20e6bf")!, name: "BLACKPINK", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "bbb6a9f0-34f6-43f1-ae36-a8606334f626")!, name: "ALLDAY PROJECT", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "bf86bf36-18bd-43c2-9046-ffc737942a7e")!, name: "ZEROBASEONE", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "c163e508-3c74-47b1-ac56-2486d734425d")!, name: "IVE", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "c90ef5c8-6a37-4b62-95d8-658d422d5383")!, name: "Jisoo", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "c9ac5c3f-59ae-43d0-85d7-67c74c975e10")!, name: "ILLIT", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "ce8142e3-07df-46e1-8176-b77080faab10")!, name: "JEON SOMI", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "cfb1c685-7751-498d-be90-5b8ff6859a87")!, name: "BIGBANG", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "d0700f24-a962-472f-b185-cf5a6cc8fdd5")!, name: "TWICE", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "d209847b-d314-4485-90da-810200eb50df")!, name: "Jin", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "d25d2dec-da17-483b-9aac-dcd2e8fa2e6f")!, name: "TOMORROW X TOGETHER", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "d8c0a943-63dd-4292-a9b8-c1c9e09daa82")!, name: "NewJeans", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "de1301f1-dfc3-458d-9852-c349c402ad79")!, name: "Taemin", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "e8aa1fbe-24ec-4c72-bcee-3fd534a884e9")!, name: "Lisa", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "ef0ce331-1605-457f-bf30-e3b4ea4f27df")!, name: "IU", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "f12b5fb2-dcc2-4b99-91fb-c5190b91b288")!, name: "Stray Kids", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "f1fe4987-da75-44dc-afa1-e3483f00bdb5")!, name: "Suga", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "f4d7de69-728c-4c44-b47f-5e838f92e458")!, name: "G-Dragon", genre: "K-Pop", imageURL: nil),
            MockArtist(id: UUID(uuidString: "fa6d9eea-0ddd-4095-be2d-d662321d8de2")!, name: "KATSEYE", genre: "K-Pop", imageURL: nil)
        ]
    }
    
    private func loadGoals() {
        availableGoals = [
            OnboardingGoal(
                id: UUID(),
                title: "Attend Live Concerts",
                description: "Save for tickets to see your favorite artists perform live",
                icon: "music.mic",
                category: .concerts,
                estimatedCost: 200
            ),
            OnboardingGoal(
                id: UUID(),
                title: "Collect Albums",
                description: "Build your physical album collection",
                icon: "opticaldisc",
                category: .albums,
                estimatedCost: 30
            ),
            OnboardingGoal(
                id: UUID(),
                title: "Buy Official Merchandise",
                description: "Get official apparel and accessories",
                icon: "tshirt",
                category: .merch,
                estimatedCost: 50
            ),
            OnboardingGoal(
                id: UUID(),
                title: "Support Digital Releases",
                description: "Stream and purchase digital content",
                icon: "music.note",
                category: .subscriptions,
                estimatedCost: 15
            ),
            OnboardingGoal(
                id: UUID(),
                title: "Fan Club Membership",
                description: "Join official fan clubs for exclusive content",
                icon: "person.3.fill",
                category: .events,
                estimatedCost: 25
            ),
            OnboardingGoal(
                id: UUID(),
                title: "Meet & Greet Events",
                description: "Save for special fan meeting opportunities",
                icon: "hand.wave",
                category: .events,
                estimatedCost: 150
            )
        ]
    }
    
    func toggleArtistSelection(_ artistId: UUID) {
        if selectedArtists.contains(artistId) {
            selectedArtists.remove(artistId)
        } else {
            selectedArtists.insert(artistId)
        }
    }
    
    func toggleGoalSelection(_ goalId: UUID) {
        if selectedGoals.contains(goalId) {
            selectedGoals.remove(goalId)
        } else {
            selectedGoals.insert(goalId)
        }
    }
    
    func getSelectedArtistNames() -> [String] {
        return availableArtists
            .filter { selectedArtists.contains($0.id) }
            .map { $0.name }
    }
    
    func getSelectedGoalTitles() -> [String] {
        return availableGoals
            .filter { selectedGoals.contains($0.id) }
            .map { $0.title }
    }
    
    func getTotalEstimatedMonthlyCost() -> Double {
        return availableGoals
            .filter { selectedGoals.contains($0.id) }
            .reduce(0) { $0 + $1.estimatedCost }
    }
    
    func getFallbackArtists() -> [PopularArtist] {
        return availableArtists.map { artist in
            PopularArtist(
                artist: Artist(id: artist.id, name: artist.name, group: artist.genre, imageURL: artist.imageURL),
                followerCount: Int.random(in: 100000...5000000),
                recentActivity: "Recent activity"
            )
        }
    }
    
    func resetSelections() {
        selectedArtists.removeAll()
        selectedGoals.removeAll()
        enableConcertNotifications = true
        enableMerchNotifications = true
        enableBudgetNotifications = true
    }
}

// MARK: - Supporting Models
struct MockArtist: Identifiable, Equatable {
    let id: UUID
    let name: String
    let genre: String
    let imageURL: String?
}

struct OnboardingGoal: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: FanCategory
    let estimatedCost: Double
}

// GoalCategory is defined in OnboardingDataService.swift