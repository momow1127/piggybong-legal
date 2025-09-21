import Foundation

// MARK: - Fixed Artist Service
/// Updated service that uses the complete 'artists' table instead of limited 'app_artists'
@MainActor
class FixedArtistService: ObservableObject {
    static let shared = FixedArtistService()
    
    @Published var allArtists: [CompleteArtist] = []
    @Published var isLoading = false
    @Published var searchResults: [CompleteArtist] = []
    
    private let supabaseService = SupabaseService.shared
    private var cachedArtists: [CompleteArtist] = []
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load all 41 artists from the complete artists table
    func loadAllArtists() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            let artists = try await fetchArtistsFromCompleteTable()
            allArtists = artists
            cachedArtists = artists
            print("✅ Loaded \(artists.count) artists from complete database")
        } catch {
            print("❌ Error loading artists: \(error)")
        }
        
        isLoading = false
    }
    
    /// Search artists in the complete database (includes BABYMONSTER!)
    func searchArtists(query: String) async -> [CompleteArtist] {
        guard !query.isEmpty else { return [] }
        
        do {
            let results = try await searchArtistsInCompleteTable(query: query)
            searchResults = results
            print("🔍 Found \(results.count) artists for '\(query)'")
            return results
        } catch {
            print("❌ Error searching artists: \(error)")
            return []
        }
    }
    
    /// Get popular artists for onboarding (prioritized list)
    func getPopularArtistsForOnboarding() -> [CompleteArtist] {
        if cachedArtists.isEmpty {
            Task { await loadAllArtists() }
            return []
        }
        
        // Return groups first, then solos, sorted by popularity
        return cachedArtists.filter { artist in
            ["boy_group", "girl_group", "co_ed_group"].contains(artist.type)
        }.sorted { first, second in
            getPopularityScore(first) > getPopularityScore(second)
        }
    }
    
    /// Check if BABYMONSTER is available (for testing)
    func isBabymonsterAvailable() async -> Bool {
        let results = await searchArtists(query: "BABYMONSTER")
        return !results.isEmpty
    }
    
    // MARK: - Private Methods
    
    /// Fetch all artists from the complete 'artists' table
    private func fetchArtistsFromCompleteTable() async throws -> [CompleteArtist] {
        guard let url = URL(string: "\(supabaseService.supabaseURL)/rest/v1/artists") else {
            throw ArtistServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseService.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseService.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ArtistServiceError.networkError
        }
        
        let decoder = JSONDecoder()
        let rawArtists = try decoder.decode([RawArtist].self, from: data)
        
        // Convert to CompleteArtist and deduplicate
        let artists = rawArtists.compactMap { raw -> CompleteArtist? in
            guard let id = raw.id else { return nil }
            return CompleteArtist(
                id: id,
                name: raw.name,
                displayName: raw.name, // Use name as display name
                type: raw.type,
                agency: raw.agency,
                debutYear: raw.debut_year,
                genres: raw.genres ?? [],
                imageURL: raw.image_url,
                popularityScore: getPopularityScore(raw.name, raw.type, raw.agency, raw.debut_year)
            )
        }
        
        // Remove duplicates by name
        var seenNames = Set<String>()
        let uniqueArtists = artists.filter { artist in
            if seenNames.contains(artist.name) {
                return false
            } else {
                seenNames.insert(artist.name)
                return true
            }
        }
        
        return uniqueArtists
    }
    
    /// Search artists in the complete table
    private func searchArtistsInCompleteTable(query: String) async throws -> [CompleteArtist] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(supabaseService.supabaseURL)/rest/v1/artists?or=(name.ilike.*\(encodedQuery)*,agency.ilike.*\(encodedQuery)*,type.ilike.*\(encodedQuery)*)&limit=20") else {
            throw ArtistServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseService.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseService.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ArtistServiceError.networkError
        }
        
        let decoder = JSONDecoder()
        let rawArtists = try decoder.decode([RawArtist].self, from: data)
        
        // Convert and deduplicate
        let artists = rawArtists.compactMap { raw -> CompleteArtist? in
            guard let id = raw.id else { return nil }
            return CompleteArtist(
                id: id,
                name: raw.name,
                displayName: raw.name,
                type: raw.type,
                agency: raw.agency,
                debutYear: raw.debut_year,
                genres: raw.genres ?? [],
                imageURL: raw.image_url,
                popularityScore: getPopularityScore(raw.name, raw.type, raw.agency, raw.debut_year)
            )
        }
        
        // Remove duplicates and sort by relevance
        var seenNames = Set<String>()
        let uniqueArtists = artists.filter { artist in
            if seenNames.contains(artist.name) {
                return false
            } else {
                seenNames.insert(artist.name)
                return true
            }
        }
        
        return uniqueArtists.sorted { first, second in
            // Exact matches first
            if first.name.lowercased() == query.lowercased() && second.name.lowercased() != query.lowercased() {
                return true
            } else if second.name.lowercased() == query.lowercased() && first.name.lowercased() != query.lowercased() {
                return false
            }
            // Then by popularity
            return first.popularityScore > second.popularityScore
        }
    }
    
    /// Calculate popularity score for an artist
    private func getPopularityScore(_ artist: CompleteArtist) -> Int {
        return getPopularityScore(artist.name, artist.type, artist.agency, artist.debutYear)
    }
    
    private func getPopularityScore(_ name: String, _ type: String, _ agency: String, _ debutYear: Int) -> Int {
        // Top tier artists
        if ["BTS", "BLACKPINK"].contains(name) {
            return 100
        }
        
        // High tier artists
        if ["NewJeans", "TWICE", "SEVENTEEN", "Stray Kids"].contains(name) {
            return 95
        }
        
        // Popular tier artists
        if ["aespa", "LE SSERAFIM", "BABYMONSTER", "ITZY", "IVE", "ENHYPEN", "ATEEZ"].contains(name) {
            return 90
        }
        
        // BTS solo members
        if type == "solo_male" && agency == "HYBE Labels" {
            return 85
        }
        
        // BLACKPINK solo members  
        if type == "solo_female" && agency == "YG Entertainment" {
            return 85
        }
        
        // Recent debuts (2020+)
        if debutYear >= 2020 {
            return 80
        }
        
        // Default
        return 75
    }
}

// MARK: - Models

struct CompleteArtist: Identifiable, Codable {
    let id: UUID
    let name: String
    let displayName: String
    let type: String
    let agency: String
    let debutYear: Int
    let genres: [String]
    let imageURL: String?
    let popularityScore: Int
    
    var typeDisplayName: String {
        switch type {
        case "boy_group": return "Boy Group"
        case "girl_group": return "Girl Group"
        case "co_ed_group": return "Co-ed Group"
        case "solo_male": return "Solo Male"
        case "solo_female": return "Solo Female"
        default: return type.capitalized
        }
    }
    
    var genreDisplayName: String {
        if genres.isEmpty {
            return "K-Pop"
        } else {
            return genres.joined(separator: ", ")
        }
    }
}

struct RawArtist: Codable {
    let id: UUID?
    let name: String
    let type: String
    let agency: String
    let debut_year: Int
    let genres: [String]?
    let image_url: String?
}

enum ArtistServiceError: Error {
    case invalidURL
    case networkError
    case decodingError
}