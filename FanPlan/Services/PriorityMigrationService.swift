import Foundation

// MARK: - Priority Migration Service
/// Handles migration of priorities from UserDefaults to Supabase database
@MainActor
class PriorityMigrationService: ObservableObject {
    static let shared = PriorityMigrationService()
    
    private let migrationKey = "priority_migration_completed"
    
    private init() {}
    
    /// Migrates user priorities from UserDefaults to database if needed
    func migratePrioritiesIfNeeded() async {
        // Check if migration has already been completed
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("✅ Priority migration already completed, skipping")
            return
        }
        
        // Check if user is authenticated
        guard let authUser = try? await SupabaseService.shared.getCurrentUser() else {
            print("⚠️ No authenticated user for priority migration")
            return
        }
        
        // Check if priorities exist in UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "onboarding_category_priorities"),
              let categoryPriorities = try? JSONDecoder().decode([String: PriorityLevel].self, from: data) else {
            print("ℹ️ No priorities in UserDefaults to migrate")
            markMigrationComplete()
            return
        }
        
        print("🔄 Starting priority migration for user: \(authUser.id)")
        print("📋 Migrating \(categoryPriorities.count) priorities from UserDefaults to database")
        
        // Check if database priorities already exist
        let existingPriorities = await DatabaseService.shared.getUserPriorities(userId: authUser.id)
        
        if !existingPriorities.isEmpty {
            print("✅ Database priorities already exist (\(existingPriorities.count)), skipping migration")
            markMigrationComplete()
            return
        }
        
        // Migrate priorities to database
        await DatabaseService.shared.saveOnboardingPriorities(
            userId: authUser.id,
            categoryPriorities: categoryPriorities
        )
        
        print("✅ Priority migration completed successfully")
        markMigrationComplete()
    }
    
    /// Forces re-migration (for testing purposes)
    func forceMigration() async {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        await migratePrioritiesIfNeeded()
    }
    
    /// Marks migration as complete
    private func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Priority migration marked as complete")
    }
    
    /// Checks if priorities exist in both UserDefaults and database
    func debugPriorityStatus() async {
        guard let authUser = try? await SupabaseService.shared.getCurrentUser() else {
            print("❌ No authenticated user for debug")
            return
        }
        
        // Check UserDefaults
        let hasUserDefaultsPriorities = UserDefaults.standard.data(forKey: "onboarding_category_priorities") != nil
        
        // Check database
        let databasePriorities = await DatabaseService.shared.getUserPriorities(userId: authUser.id)
        
        print("🔍 Priority Debug Status:")
        print("   - User ID: \(authUser.id)")
        print("   - UserDefaults has priorities: \(hasUserDefaultsPriorities ? "✅" : "❌")")
        print("   - Database has priorities: \(databasePriorities.isEmpty ? "❌" : "✅ (\(databasePriorities.count))")")
        print("   - Migration completed: \(UserDefaults.standard.bool(forKey: migrationKey) ? "✅" : "❌")")
        
        if !databasePriorities.isEmpty {
            print("📋 Database priorities:")
            for priority in databasePriorities {
                print("      - \(priority.category.displayName): Priority \(priority.priority)")
            }
        }
        
        if hasUserDefaultsPriorities {
            if let data = UserDefaults.standard.data(forKey: "onboarding_category_priorities"),
               let categoryPriorities = try? JSONDecoder().decode([String: PriorityLevel].self, from: data) {
                print("📋 UserDefaults priorities:")
                for (category, level) in categoryPriorities {
                    print("      - \(category): \(level.rawValue)")
                }
            }
        }
    }
}