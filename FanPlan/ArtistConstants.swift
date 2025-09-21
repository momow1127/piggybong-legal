import Foundation

// MARK: - Artist UUID Constants
/// Stable UUID constants that match Supabase database exactly
/// These UUIDs ensure consistent referencing between embedded data and backend
enum ArtistUUIDs {
    // MARK: - Top Tier Groups
    static let bts = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440001")!
    static let blackpink = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440002")!
    static let twice = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440003")!
    static let seventeen = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440004")!
    
    // MARK: - 4th Gen Leaders
    static let newjeans = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440005")!
    static let aespa = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440006")!
    static let strayKids = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440007")!
    static let lesserafim = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440008")!
    static let ive = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440009")!
    static let enhypen = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544000a")!
    
    // MARK: - Popular Active Groups
    static let itzy = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544000b")!
    static let txt = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544000c")!
    static let gidle = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544000d")!
    static let ateez = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544000e")!
    static let redVelvet = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544000f")!
    
    // MARK: - Rising 4th Gen
    static let babymonster = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440010")!
    static let nmixx = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440011")!
    static let illit = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440012")!
    static let riize = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440013")!
    static let kissOfLife = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440014")!
    
    // MARK: - Solo Artists (BLACKPINK)
    static let lisa = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440015")!
    static let jennie = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440016")!
    static let rose = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440017")!
    static let jisoo = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440018")!
    
    // MARK: - BTS Solo
    static let jungkook = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440019")!
    static let v = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544001a")!
    static let jimin = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544001b")!
    
    // MARK: - Legendary Groups
    static let girlsGeneration = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544001c")!
    static let shinee = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544001d")!
    static let bigbang = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544001e")!
    
    // MARK: - Other Popular Acts
    static let iu = UUID(uuidString: "550e8400-e29b-41d4-a716-44665544001f")!
    static let mamamoo = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440020")!
    static let twoNE1 = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440021")!
    
    // MARK: - 2025 New Debuts
    static let hearts2Hearts = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440022")!
    static let kiiiKiii = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440023")!
    static let alldayProject = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440024")!
}

// MARK: - Artist Data Structures
/// Complete embedded artist database with stable UUIDs
struct EmbeddedArtistData {
    let id: UUID
    let name: String
    let group: String
    let followerCount: Int
    let recentActivity: String
    let tier: ArtistTier
    let generation: KpopGeneration
    
    enum ArtistTier: String, CaseIterable {
        case legendary = "legendary"    // BTS, BLACKPINK level
        case topTier = "top_tier"      // TWICE, SEVENTEEN level
        case popular = "popular"       // Most 4th gen groups
        case rising = "rising"         // New debuts, growing groups
        case solo = "solo"             // Individual artists
    }
    
    enum KpopGeneration: String, CaseIterable {
        case second = "2nd_gen"    // 2005-2012
        case third = "3rd_gen"     // 2012-2018
        case fourth = "4th_gen"    // 2018-2025
        case fifth = "5th_gen"     // 2025+
    }
}

// MARK: - Embedded Artist Database
extension OnboardingService {
    /// Complete embedded artist database - GUARANTEED to be available
    static let embeddedArtists: [EmbeddedArtistData] = [
        // Top Tier Groups
        EmbeddedArtistData(id: ArtistUUIDs.bts, name: "BTS", group: "BTS", followerCount: 45000000, recentActivity: "World's biggest K-pop group", tier: .legendary, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.blackpink, name: "BLACKPINK", group: "BLACKPINK", followerCount: 32000000, recentActivity: "Global girl group sensation", tier: .legendary, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.twice, name: "TWICE", group: "TWICE", followerCount: 25000000, recentActivity: "Nation's girl group", tier: .topTier, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.seventeen, name: "SEVENTEEN", group: "SEVENTEEN", followerCount: 22000000, recentActivity: "Self-producing idols", tier: .topTier, generation: .third),
        
        // 4th Gen Leaders
        EmbeddedArtistData(id: ArtistUUIDs.newjeans, name: "NewJeans", group: "NewJeans", followerCount: 18000000, recentActivity: "Y2K concept pioneers", tier: .topTier, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.aespa, name: "aespa", group: "aespa", followerCount: 17000000, recentActivity: "SM's virtual concept", tier: .topTier, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.strayKids, name: "Stray Kids", group: "Stray Kids", followerCount: 16000000, recentActivity: "Billboard chart toppers", tier: .topTier, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.lesserafim, name: "LE SSERAFIM", group: "LE SSERAFIM", followerCount: 14000000, recentActivity: "HYBE's girl group", tier: .topTier, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.ive, name: "IVE", group: "IVE", followerCount: 13000000, recentActivity: "Starship's rising stars", tier: .topTier, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.enhypen, name: "ENHYPEN", group: "ENHYPEN", followerCount: 12000000, recentActivity: "BE:LIFT's success story", tier: .popular, generation: .fourth),
        
        // Popular Active Groups
        EmbeddedArtistData(id: ArtistUUIDs.itzy, name: "ITZY", group: "ITZY", followerCount: 11000000, recentActivity: "Teen crush concept", tier: .popular, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.txt, name: "TXT", group: "Tomorrow X Together", followerCount: 10000000, recentActivity: "BTS's little brothers", tier: .popular, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.gidle, name: "i-dle", group: "i-dle", followerCount: 9500000, recentActivity: "Self-producing girl group", tier: .popular, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.ateez, name: "ATEEZ", group: "ATEEZ", followerCount: 9000000, recentActivity: "International success", tier: .popular, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.redVelvet, name: "Red Velvet", group: "Red Velvet", followerCount: 8500000, recentActivity: "Dual concept masters", tier: .popular, generation: .third),
        
        // Rising 4th Gen
        EmbeddedArtistData(id: ArtistUUIDs.babymonster, name: "BABYMONSTER", group: "BABYMONSTER", followerCount: 8000000, recentActivity: "YG's new girl group", tier: .rising, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.nmixx, name: "NMIXX", group: "NMIXX", followerCount: 7500000, recentActivity: "JYP's experimental group", tier: .rising, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.illit, name: "ILLIT", group: "ILLIT", followerCount: 7000000, recentActivity: "Magnetic hit makers", tier: .rising, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.riize, name: "RIIZE", group: "RIIZE", followerCount: 6500000, recentActivity: "SM's boy group", tier: .rising, generation: .fourth),
        EmbeddedArtistData(id: ArtistUUIDs.kissOfLife, name: "KISS OF LIFE", group: "KISS OF LIFE", followerCount: 6000000, recentActivity: "Rising vocal powerhouse", tier: .rising, generation: .fourth),
        
        // Solo Artists (BLACKPINK)
        EmbeddedArtistData(id: ArtistUUIDs.lisa, name: "Lisa", group: "BLACKPINK", followerCount: 5500000, recentActivity: "Global fashion icon", tier: .solo, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.jennie, name: "Jennie", group: "BLACKPINK", followerCount: 5200000, recentActivity: "Solo rap queen", tier: .solo, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.rose, name: "Rosé", group: "BLACKPINK", followerCount: 5000000, recentActivity: "On The Ground success", tier: .solo, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.jisoo, name: "Jisoo", group: "BLACKPINK", followerCount: 4800000, recentActivity: "Actress and singer", tier: .solo, generation: .third),
        
        // BTS Solo
        EmbeddedArtistData(id: ArtistUUIDs.jungkook, name: "Jungkook", group: "BTS", followerCount: 4500000, recentActivity: "Golden maknae", tier: .solo, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.v, name: "V", group: "BTS", followerCount: 4300000, recentActivity: "Layover album", tier: .solo, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.jimin, name: "Jimin", group: "BTS", followerCount: 4100000, recentActivity: "FACE album success", tier: .solo, generation: .third),
        
        // Legendary Groups
        EmbeddedArtistData(id: ArtistUUIDs.girlsGeneration, name: "Girls' Generation", group: "Girls' Generation", followerCount: 3800000, recentActivity: "Legendary girl group", tier: .legendary, generation: .second),
        EmbeddedArtistData(id: ArtistUUIDs.shinee, name: "SHINee", group: "SHINee", followerCount: 3500000, recentActivity: "K-pop pioneers", tier: .legendary, generation: .second),
        EmbeddedArtistData(id: ArtistUUIDs.bigbang, name: "BIGBANG", group: "BIGBANG", followerCount: 3200000, recentActivity: "K-pop kings", tier: .legendary, generation: .second),
        
        // Other Popular Acts
        EmbeddedArtistData(id: ArtistUUIDs.iu, name: "IU", group: "IU", followerCount: 3000000, recentActivity: "Nation's little sister", tier: .solo, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.mamamoo, name: "MAMAMOO", group: "MAMAMOO", followerCount: 2800000, recentActivity: "Vocal powerhouse", tier: .popular, generation: .third),
        EmbeddedArtistData(id: ArtistUUIDs.twoNE1, name: "2NE1", group: "2NE1", followerCount: 2500000, recentActivity: "Legendary girl crush", tier: .legendary, generation: .second),
        
        // 2025 New Debuts
        EmbeddedArtistData(id: ArtistUUIDs.hearts2Hearts, name: "Hearts2Hearts", group: "Hearts2Hearts", followerCount: 2200000, recentActivity: "SM's new 8-member group", tier: .rising, generation: .fifth),
        EmbeddedArtistData(id: ArtistUUIDs.kiiiKiii, name: "KiiiKiii", group: "KiiiKiii", followerCount: 2000000, recentActivity: "Starship's rising stars", tier: .rising, generation: .fifth),
        EmbeddedArtistData(id: ArtistUUIDs.alldayProject, name: "ALLDAY PROJECT", group: "ALLDAY PROJECT", followerCount: 1800000, recentActivity: "THEBLACKLABEL's co-ed group", tier: .rising, generation: .fifth)
    ]
}