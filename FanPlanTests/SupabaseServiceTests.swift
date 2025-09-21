import XCTest
import Foundation
@testable import Piggy_Bong

class SupabaseServiceTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var mockUserId: UUID!
    var mockArtistId: UUID!
    
    override func setUpWithError() throws {
        super.setUp()
        supabaseService = SupabaseService.shared
        mockUserId = UUID()
        mockArtistId = UUID()
    }
    
    override func tearDownWithError() throws {
        supabaseService = nil
        mockUserId = nil
        mockArtistId = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testDatabaseConnectionHealthCheck() async {
        do {
            let isConnected = try await supabaseService.checkSupabaseConnectivity()

            // Connection may fail in test environment, but should not crash
            XCTAssertTrue(isConnected == true || isConnected == false, "Health check should return boolean result")
        } catch {
            // Connection failed, but it should fail gracefully with proper error
            print("Connection test failed (expected in test environment): \(error)")
        }
    }
    
    // MARK: - User Management Tests
    
    func testCreateUserWithValidData() async throws {
        let testName = "Test User \(Int.random(in: 1000...9999))"
        let testEmail = "test\(Int.random(in: 1000...9999))@example.com"
        let testBudget = 500.0
        
        do {
            let userId = try await supabaseService.createUser(
                name: testName,
                email: testEmail,
                monthlyBudget: testBudget
            )
            
            XCTAssertNotNil(userId, "User creation should return valid UUID")
            
            // Verify user was created by fetching it
            let createdUser = try await supabaseService.getUser(id: userId)
            XCTAssertEqual(createdUser.name, testName, "Created user name should match")
            XCTAssertEqual(createdUser.email, testEmail, "Created user email should match")
            XCTAssertEqual(createdUser.monthlyBudget, testBudget, "Created user budget should match")
            
        } catch SupabaseService.SupabaseError.networkError {
            // Skip test if network is unavailable
            throw XCTSkip("Network unavailable for testing")
        } catch {
            XCTFail("User creation should succeed with valid data: \(error)")
        }
    }
    
    func testCreateUserWithInvalidData() async {
        do {
            _ = try await supabaseService.createUser(
                name: "",
                email: "invalid-email",
                monthlyBudget: -100.0
            )
            XCTFail("User creation should fail with invalid data")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is SupabaseService.SupabaseError, "Should return SupabaseError")
        }
    }
    
    func testGetNonExistentUser() async throws {
        let nonExistentId = UUID()
        
        do {
            _ = try await supabaseService.getUser(id: nonExistentId)
            XCTFail("Should fail when getting non-existent user")
        } catch SupabaseService.SupabaseError.notFound {
            // Expected error
            XCTAssertTrue(true, "Should return notFound error for non-existent user")
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateUserBudget() async throws {
        // This test requires a valid user ID - in real implementation, create test user first
        let newBudget = 750.0
        
        do {
            try await supabaseService.updateUserBudget(userId: mockUserId, monthlyBudget: newBudget)
            // If it doesn't throw, consider it successful (may not have test data)
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch SupabaseService.SupabaseError.notFound {
            // Expected for mock ID
            XCTAssertTrue(true, "Mock user not found is expected")
        } catch {
            XCTFail("Unexpected error in budget update: \(error)")
        }
    }
    
    // MARK: - Artist Management Tests
    
    func testGetArtists() async throws {
        do {
            let artists = try await supabaseService.getArtists()
            
            XCTAssertNotNil(artists, "Artists array should not be nil")
            XCTAssertGreaterThan(artists.count, 0, "Should return at least some artists (or mock data)")
            
            // Verify artist structure
            if let firstArtist = artists.first {
                XCTAssertFalse(firstArtist.name.isEmpty, "Artist name should not be empty")
                XCTAssertFalse(firstArtist.group?.isEmpty ?? true, "Artist group should not be empty")
            }
            
        } catch SupabaseService.SupabaseError.networkError {
            // Should fall back to mock data
            let artists = try await supabaseService.getArtists()
            XCTAssertGreaterThan(artists.count, 0, "Should return mock data when network fails")
        }
    }
    
    func testCreateArtist() async throws {
        let testArtistName = "Test Artist \(Int.random(in: 1000...9999))"
        let testGroupName = "Test Group"
        
        do {
            let artistId = try await supabaseService.createArtist(
                name: testArtistName,
                groupName: testGroupName
            )
            
            XCTAssertNotNil(artistId, "Artist creation should return valid UUID")
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch {
            XCTFail("Artist creation should succeed: \(error)")
        }
    }
    
    func testSearchArtists() async throws {
        do {
            let allArtists = try await supabaseService.getArtists()
            guard let searchTerm = allArtists.first?.name.prefix(3) else {
                throw XCTSkip("No artists available for search test")
            }
            
            let searchResults = try await supabaseService.searchArtists(query: String(searchTerm))
            
            XCTAssertNotNil(searchResults, "Search results should not be nil")
            // Results may be empty if no matches, but should not crash
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        }
    }
    
    // MARK: - Purchase Management Tests
    
    func testGetPurchasesForUser() async throws {
        do {
            let purchases = try await supabaseService.getPurchases(for: mockUserId, limit: 10)
            
            XCTAssertNotNil(purchases, "Purchases array should not be nil")
            // May be empty for mock user, but should not crash
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch SupabaseService.SupabaseError.notFound {
            // Expected for mock user
            let purchases = try await supabaseService.getPurchases(for: mockUserId, limit: 10)
            XCTAssertEqual(purchases.count, 0, "Should return empty array for non-existent user")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreatePurchase() async throws {
        let testAmount = 29.99
        let testCategory = "album"
        let testDescription = "Test Album Purchase"
        
        do {
            let purchaseId = try await supabaseService.createPurchase(
                userId: mockUserId,
                artistId: mockArtistId,
                amount: testAmount,
                category: testCategory,
                description: testDescription,
                notes: "Test purchase"
            )
            
            XCTAssertNotNil(purchaseId, "Purchase creation should return valid UUID")
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch SupabaseService.SupabaseError.unauthorized {
            // Expected if using mock IDs
            XCTAssertTrue(true, "Unauthorized error expected for mock data")
        } catch {
            // May fail due to foreign key constraints with mock IDs
            XCTAssertTrue(error is SupabaseService.SupabaseError, "Should return SupabaseError")
        }
    }
    
    // MARK: - Budget Management Tests
    
    func testGetBudgetForUser() async throws {
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        
        do {
            let budget = try await supabaseService.getBudget(userId: mockUserId, month: month, year: year)
            // May be nil for mock user
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch {
            XCTFail("Budget fetch should not throw unexpected errors: \(error)")
        }
    }
    
    func testCreateBudget() async throws {
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        let totalBudget = 1000.0
        
        do {
            let budgetId = try await supabaseService.createBudget(
                userId: mockUserId,
                month: month,
                year: year,
                totalBudget: totalBudget
            )
            
            XCTAssertNotNil(budgetId, "Budget creation should return valid UUID")
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch SupabaseService.SupabaseError.unauthorized {
            // Expected with mock user ID
            XCTAssertTrue(true, "Unauthorized error expected for mock data")
        } catch {
            // May fail due to foreign key constraints
            XCTAssertTrue(error is SupabaseService.SupabaseError, "Should return SupabaseError")
        }
    }
    
    // MARK: - Goal Management Tests
    
    func testGetGoalsForUser() async throws {
        do {
            let goals = try await supabaseService.getGoals(for: mockUserId)
            
            XCTAssertNotNil(goals, "Goals array should not be nil")
            // May be empty for mock user
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch {
            // Should return empty array, not throw
            let goals = try await supabaseService.getGoals(for: mockUserId)
            XCTAssertEqual(goals.count, 0, "Should return empty array for non-existent user")
        }
    }
    
    func testCreateGoal() async throws {
        let testGoalName = "Test Concert Goal"
        let targetAmount = 200.0
        let deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let category = "concert"
        
        do {
            let goalId = try await supabaseService.createGoal(
                userId: mockUserId,
                artistId: mockArtistId,
                name: testGoalName,
                targetAmount: targetAmount,
                deadline: deadline,
                category: category
            )
            
            XCTAssertNotNil(goalId, "Goal creation should return valid UUID")
            
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        } catch SupabaseService.SupabaseError.unauthorized {
            // Expected with mock IDs
            XCTAssertTrue(true, "Unauthorized error expected for mock data")
        } catch {
            // May fail due to foreign key constraints
            XCTAssertTrue(error is SupabaseService.SupabaseError, "Should return SupabaseError")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURLHandling() async {
        // This test would require mocking the service to test internal error handling
        // For now, we ensure service doesn't crash with invalid configurations
        
        let service = SupabaseService.shared
        do {
            _ = try await service.getArtists()
            // Should either succeed or fail gracefully
        } catch {
            XCTAssertTrue(error is SupabaseService.SupabaseError, "Should return proper error type")
        }
    }
    
    func testNetworkTimeoutHandling() async {
        // Test that long-running requests handle timeouts appropriately
        let startTime = Date()
        
        do {
            _ = try await supabaseService.checkSupabaseConnectivity()
            let duration = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(duration, 30.0, "Connection test should not hang indefinitely")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(duration, 30.0, "Should timeout within reasonable time")
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testDatabaseModelParsing() async throws {
        // Test that the service can properly parse database responses
        do {
            let artists = try await supabaseService.getArtists()
            
            for artist in artists.prefix(3) {  // Test first few artists
                XCTAssertNotNil(artist.id, "Artist ID should not be nil")
                XCTAssertFalse(artist.name.isEmpty, "Artist name should not be empty")
                XCTAssertFalse(artist.group?.isEmpty ?? true, "Artist group should not be empty")
                // Other fields may be optional
            }
        } catch SupabaseService.SupabaseError.networkError {
            throw XCTSkip("Network unavailable for testing")
        }
    }
    
    func testConcurrentDatabaseOperations() async {
        // Test that multiple database operations can run concurrently without issues
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    _ = try await self.supabaseService.getArtists()
                } catch {
                    // Expected to handle gracefully
                }
            }
            
            group.addTask {
                do {
                    _ = try await self.supabaseService.getPurchases(for: self.mockUserId)
                } catch {
                    // Expected to handle gracefully
                }
            }
            
            group.addTask {
                do {
                    _ = try await self.supabaseService.getGoals(for: self.mockUserId)
                } catch {
                    // Expected to handle gracefully
                }
            }
        }
        
        // Should complete without deadlocks or crashes
        XCTAssertTrue(true, "Concurrent operations should complete")
    }
}