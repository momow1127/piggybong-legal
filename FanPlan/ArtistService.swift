import Foundation

/// Convenient service for artist-related operations
class ArtistService {
    private let databaseService: SupabaseDatabaseService
    
    init(databaseService: SupabaseDatabaseService) {
        self.databaseService = databaseService
    }
    
    // MARK: - Artist Name Fetching
    
    /// Fetch artist name by UUID
    func getArtistName(for artistId: UUID) async throws -> String {
        if let name = try await databaseService.getArtistName(byId: artistId) {
            return name
        } else {
            return "Unknown Artist"
        }
    }
    
    /// Fetch multiple artist names by UUIDs
    func getArtistNames(for artistIds: [UUID]) async throws -> [UUID: String] {
        var names: [UUID: String] = [:]
        
        // Use TaskGroup for concurrent fetching
        await withTaskGroup(of: (UUID, String?).self) { group in
            for artistId in artistIds {
                group.addTask {
                    do {
                        let name = try await self.databaseService.getArtistName(byId: artistId)
                        return (artistId, name)
                    } catch {
                        print("Failed to fetch name for artist \(artistId): \(error)")
                        return (artistId, nil)
                    }
                }
            }
            
            for await (artistId, name) in group {
                names[artistId] = name ?? "Unknown Artist"
            }
        }
        
        return names
    }
    
    /// Get full artist object by UUID
    func getArtist(for artistId: UUID) async throws -> Artist? {
        return try await databaseService.getArtist(byId: artistId)
    }
    
    // MARK: - Batch Operations
    
    /// Get artist details for a list of UUIDs
    func getArtists(for artistIds: [UUID]) async throws -> [Artist] {
        var artists: [Artist] = []
        
        await withTaskGroup(of: Artist?.self) { group in
            for artistId in artistIds {
                group.addTask {
                    try? await self.databaseService.getArtist(byId: artistId)
                }
            }
            
            for await artist in group {
                if let artist = artist {
                    artists.append(artist)
                }
            }
        }
        
        return artists
    }
    
    // MARK: - Caching (Simple in-memory cache)
    
    private var nameCache: [UUID: String] = [:]
    private var artistCache: [UUID: Artist] = [:]
    
    /// Get artist name with caching
    func getCachedArtistName(for artistId: UUID) async throws -> String {
        if let cachedName = nameCache[artistId] {
            return cachedName
        }
        
        let name = try await getArtistName(for: artistId)
        nameCache[artistId] = name
        return name
    }
    
    /// Get artist with caching
    func getCachedArtist(for artistId: UUID) async throws -> Artist? {
        if let cachedArtist = artistCache[artistId] {
            return cachedArtist
        }
        
        let artist = try await getArtist(for: artistId)
        if let artist = artist {
            artistCache[artistId] = artist
        }
        return artist
    }
    
    /// Clear cache (useful for testing or memory management)
    func clearCache() {
        nameCache.removeAll()
        artistCache.removeAll()
    }
    
    // MARK: - Convenience Methods for UI
    
    /// Get displayable artist name (handles unknown artists gracefully)
    func getDisplayName(for artistId: UUID?) async -> String {
        guard let artistId = artistId else {
            return "No Artist"
        }
        
        do {
            return try await getCachedArtistName(for: artistId)
        } catch {
            print("Failed to get display name for artist \(artistId): \(error)")
            return "Unknown Artist"
        }
    }
    
    /// Get multiple display names for UI
    func getDisplayNames(for artistIds: [UUID]) async -> [String] {
        await withTaskGroup(of: String.self, returning: [String].self) { group in
            for artistId in artistIds {
                group.addTask {
                    await self.getDisplayName(for: artistId)
                }
            }
            
            var names: [String] = []
            for await name in group {
                names.append(name)
            }
            return names
        }
    }
}

// MARK: - Global convenience instance
extension ArtistService {
    /// Shared instance using the default database service
    static var shared: ArtistService {
        let databaseService = SupabaseService.shared.databaseService
        return ArtistService(databaseService: databaseService)
    }
}