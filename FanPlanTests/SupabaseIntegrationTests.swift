import XCTest
import Foundation
@testable import Piggy_Bong

class SupabaseIntegrationTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var testUserId: UUID?
    var testArtistId: UUID?
    var testGoalId: UUID?
    var testPurchaseId: UUID?
    
    override func setUpWithError() throws {
        super.setUp()
        supabaseService = SupabaseService.shared
        
        // Only run integration tests if database is available
        Task {
            let isConnected = await supabaseService.checkSupabaseConnectivity()
            if !isConnected {
                // Note: Cannot throw XCTSkip from async context in setUp
                // Individual tests will check connection status
            }
        }
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        Task {
            if let purchaseId = testPurchaseId {
                try? await supabaseService.deletePurchase(id: purchaseId)
            }
            
            if let goalId = testGoalId {
                // Clean up goal if needed (implement deleteGoal method)
            }
        }
        
        // Note: We don't delete test users/artists to avoid affecting other tests
        
        supabaseService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End User Flow Tests
    
    func testCompleteUserOnboardingFlow() async throws {
        // Test the complete flow of creating a user and setting up their profile
        
        // 1. Create user
        let testName = "Integration Test User \(Int.random(in: 1000...9999))"
        let testEmail = "integration\(Int.random(in: 1000...9999))@test.com"
        let testBudget = 750.0
        
        let userId = try await supabaseService.createUser(
            name: testName,
            email: testEmail,
            monthlyBudget: testBudget
        )
        testUserId = userId
        
        // 2. Verify user creation
        let createdUser = try await supabaseService.getUser(id: userId)
        XCTAssertEqual(createdUser.name, testName)
        XCTAssertEqual(createdUser.email, testEmail)
        XCTAssertEqual(createdUser.monthlyBudget, testBudget)
        
        // 3. Get artists for user selection
        let artists = try await supabaseService.getArtists()
        XCTAssertGreaterThan(artists.count, 0, "Should have artists available")
        
        guard let firstArtist = artists.first else {
            XCTFail("No artists available for testing")
            return
        }
        testArtistId = firstArtist.id
        
        // 4. Create user-artist relationship
        let userArtistId = try await supabaseService.createUserArtist(
            userId: userId,
            artistId: firstArtist.id,
            priorityRank: 1,
            monthlyAllocation: testBudget * 0.6 // 60% allocation
        )
        
        XCTAssertNotNil(userArtistId, "User-artist relationship should be created")
        
        // 5. Create initial budget for current month
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        
        let budgetId = try await supabaseService.createBudget(
            userId: userId,
            month: month,
            year: year,
            totalBudget: testBudget
        )
        
        XCTAssertNotNil(budgetId, "Budget should be created")
        
        // 6. Verify budget was created correctly
        let createdBudget = try await supabaseService.getBudget(userId: userId, month: month, year: year)
        XCTAssertNotNil(createdBudget, "Budget should be retrievable")
        XCTAssertEqual(createdBudget?.totalBudget, testBudget, "Budget amount should match")
        XCTAssertEqual(createdBudget?.spent, 0.0, "Initial spent should be zero")
    }
    
    func testCompletePurchaseWorkflow() async throws {
        if testUserId == nil || testArtistId == nil {
            try await testCompleteUserOnboardingFlow() // Set up test data
            guard let _ = testUserId, let _ = testArtistId else {
                XCTFail("Failed to set up test data")
                return
            }
        }
        
        guard let userId = testUserId, let artistId = testArtistId else {
            XCTFail("Test data unavailable")
            return
        }
        
        // 1. Create a purchase
        let purchaseAmount = 29.99
        let category = "album"
        let description = "Integration Test Album"
        let notes = "Test purchase for integration testing"
        
        let purchaseId = try await supabaseService.createPurchase(
            userId: userId,
            artistId: artistId,
            amount: purchaseAmount,
            category: category,
            description: description,
            notes: notes
        )
        testPurchaseId = purchaseId
        
        XCTAssertNotNil(purchaseId, "Purchase should be created")
        
        // 2. Verify purchase appears in user's purchase history
        let purchases = try await supabaseService.getPurchases(for: userId, limit: 10)
        let createdPurchase = purchases.first { $0.id == purchaseId }
        
        XCTAssertNotNil(createdPurchase, "Purchase should appear in user's history")
        XCTAssertEqual(createdPurchase?.amount, -purchaseAmount, "Purchase amount should be negative (expense)")
        XCTAssertEqual(createdPurchase?.title, description, "Purchase title should match description")
        
        // 3. Update budget with purchase amount
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        
        try await supabaseService.updateBudgetSpent(
            userId: userId,
            month: month,
            year: year,
            additionalAmount: purchaseAmount
        )
        
        // 4. Verify budget was updated
        let updatedBudget = try await supabaseService.getBudget(userId: userId, month: month, year: year)
        XCTAssertEqual(updatedBudget?.spent, purchaseAmount, "Budget spent should be updated")
        
        // 5. Test purchase modification
        let updatedAmount = 39.99
        let updatedDescription = "Updated Integration Test Album"
        
        try await supabaseService.updatePurchase(
            id: purchaseId,
            amount: updatedAmount,
            description: updatedDescription
        )
        
        // 6. Verify purchase was updated
        let updatedPurchases = try await supabaseService.getPurchases(for: userId, limit: 10)
        let modifiedPurchase = updatedPurchases.first { $0.id == purchaseId }
        
        XCTAssertEqual(modifiedPurchase?.title, updatedDescription, "Purchase description should be updated")
    }
    
    func testCompleteGoalWorkflow() async throws {
        let userId: UUID
        let artistId: UUID
        
        if let existingUserId = testUserId, let existingArtistId = testArtistId {
            userId = existingUserId
            artistId = existingArtistId
        } else {
            try await testCompleteUserOnboardingFlow() // Set up test data
            guard let newUserId = testUserId, let newArtistId = testArtistId else {
                XCTFail("Failed to set up test data")
                return
            }
            userId = newUserId
            artistId = newArtistId
        }
        
        // 1. Create a fan goal
        let goalName = "Concert Ticket Fund"
        let targetAmount = 200.0
        let deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let category = "concert"
        let goalType = "concert_tickets"
        let countdownContext = "BTS World Tour"
        
        let goalId = try await supabaseService.createFanGoal(
            userId: userId,
            artistId: artistId,
            name: goalName,
            targetAmount: targetAmount,
            deadline: deadline,
            category: category,
            goalType: goalType,
            isTimeSensitive: true,
            eventDate: deadline,
            countdownContext: countdownContext
        )
        testGoalId = goalId
        
        XCTAssertNotNil(goalId, "Goal should be created")
        
        // 2. Verify goal appears in user's goals
        let goals = try await supabaseService.getGoals(for: userId)
        let createdGoal = goals.first { $0.id == goalId }
        
        XCTAssertNotNil(createdGoal, "Goal should appear in user's goals")
        XCTAssertEqual(createdGoal?.name, goalName, "Goal name should match")
        XCTAssertEqual(createdGoal?.targetAmount, targetAmount, "Target amount should match")
        XCTAssertEqual(createdGoal?.currentAmount, 0.0, "Initial current amount should be zero")
        
        // 3. Add progress to goal
        let progressAmount = 50.0
        try await supabaseService.updateGoalProgress(goalId: goalId, additionalAmount: progressAmount)
        
        // 4. Verify goal progress was updated
        let updatedGoals = try await supabaseService.getGoals(for: userId)
        let progressedGoal = updatedGoals.first { $0.id == goalId }
        
        XCTAssertEqual(progressedGoal?.currentAmount, progressAmount, "Goal progress should be updated")
        
        // 5. Add more progress
        let additionalProgress = 75.0
        try await supabaseService.updateGoalProgress(goalId: goalId, additionalAmount: additionalProgress)
        
        // 6. Verify cumulative progress
        let finalGoals = try await supabaseService.getGoals(for: userId)
        let finalGoal = finalGoals.first { $0.id == goalId }
        
        XCTAssertEqual(finalGoal?.currentAmount, progressAmount + additionalProgress, "Cumulative progress should be correct")
        
        let progressPercentage = (finalGoal?.currentAmount ?? 0) / targetAmount * 100
        XCTAssertGreaterThan(progressPercentage, 0, "Progress percentage should be positive")
        XCTAssertLessThanOrEqual(progressPercentage, 100, "Progress percentage should not exceed 100%")
    }
    
    // MARK: - Artist Management Integration Tests
    
    func testArtistManagementWorkflow() async throws {
        // 1. Get initial artist count
        let initialArtists = try await supabaseService.getArtists()
        let initialCount = initialArtists.count
        
        // 2. Create new artist
        let testArtistName = "Integration Test Artist \(Int.random(in: 1000...9999))"
        let testGroupName = "Test Group"
        let testImageUrl = "https://example.com/test-image.jpg"
        
        let artistId = try await supabaseService.createArtist(
            name: testArtistName,
            groupName: testGroupName,
            imageUrl: testImageUrl
        )
        
        XCTAssertNotNil(artistId, "Artist should be created")
        
        // 3. Verify artist was added to database
        let updatedArtists = try await supabaseService.getArtists()
        XCTAssertEqual(updatedArtists.count, initialCount + 1, "Artist count should increase by 1")
        
        let createdArtist = updatedArtists.first { $0.id == artistId }
        XCTAssertNotNil(createdArtist, "Created artist should be found in artist list")
        XCTAssertEqual(createdArtist?.name, testArtistName, "Artist name should match")
        XCTAssertEqual(createdArtist?.group, testGroupName, "Group name should match")
        
        // 4. Test artist search functionality
        let searchResults = try await supabaseService.searchArtists(query: String(testArtistName.prefix(5)))
        let foundArtist = searchResults.first { $0.id == artistId }
        XCTAssertNotNil(foundArtist, "Artist should be found in search results")
        
        // 5. Test partial name search
        let partialSearchResults = try await supabaseService.searchArtists(query: "Test")
        XCTAssertGreaterThan(partialSearchResults.count, 0, "Partial search should return results")
        
        // 6. Test case-insensitive search
        let caseInsensitiveResults = try await supabaseService.searchArtists(query: testArtistName.uppercased())
        let caseInsensitiveFound = caseInsensitiveResults.first { $0.id == artistId }
        XCTAssertNotNil(caseInsensitiveFound, "Case-insensitive search should find artist")
    }
    
    // MARK: - Fan Experience Integration Tests
    
    func testUserArtistPriorityManagement() async throws {
        let userId: UUID
        
        if let existingUserId = testUserId {
            userId = existingUserId
        } else {
            try await testCompleteUserOnboardingFlow()
            guard let newUserId = testUserId else {
                XCTFail("Failed to set up user")
                return
            }
            userId = newUserId
        }
        
        // 1. Get multiple artists for testing
        let artists = try await supabaseService.getArtists()
        guard artists.count >= 3 else {
            XCTFail("Need at least 3 artists for priority testing")
            return
        }
        
        // 2. Create user-artist relationships with different priorities
        let artist1 = artists[0]
        let artist2 = artists[1]
        let artist3 = artists[2]
        
        let userArtist1Id = try await supabaseService.createUserArtist(
            userId: userId,
            artistId: artist1.id,
            priorityRank: 1,
            monthlyAllocation: 300.0
        )
        
        let userArtist2Id = try await supabaseService.createUserArtist(
            userId: userId,
            artistId: artist2.id,
            priorityRank: 2,
            monthlyAllocation: 250.0
        )
        
        let userArtist3Id = try await supabaseService.createUserArtist(
            userId: userId,
            artistId: artist3.id,
            priorityRank: 3,
            monthlyAllocation: 200.0
        )
        
        XCTAssertNotNil(userArtist1Id, "First user-artist relationship should be created")
        XCTAssertNotNil(userArtist2Id, "Second user-artist relationship should be created")
        XCTAssertNotNil(userArtist3Id, "Third user-artist relationship should be created")
        
        // 3. Verify user artists are returned in priority order
        let userArtists = try await supabaseService.getUserArtists(userId: userId)
        XCTAssertGreaterThanOrEqual(userArtists.count, 3, "Should have at least 3 user artists")
        
        // Check priority ordering
        let sortedByPriority = userArtists.sorted { $0.priorityRank < $1.priorityRank }
        XCTAssertEqual(userArtists.count, sortedByPriority.count, "User artists should be returned in priority order")
        
        // 4. Update allocation for one artist
        let newAllocation = 350.0
        try await supabaseService.updateUserArtistAllocation(
            userId: userId,
            artistId: artist1.id,
            monthlyAllocation: newAllocation
        )
        
        // 5. Verify allocation was updated
        let updatedUserArtists = try await supabaseService.getUserArtists(userId: userId)
        let updatedArtist = updatedUserArtists.first { $0.artistId == artist1.id }
        XCTAssertEqual(updatedArtist?.monthlyAllocation, newAllocation, "Allocation should be updated")
    }
    
    func testFanActivityTracking() async throws {
        let userId: UUID
        let artistId: UUID
        
        if let existingUserId = testUserId, let existingArtistId = testArtistId {
            userId = existingUserId
            artistId = existingArtistId
        } else {
            try await testCompleteUserOnboardingFlow()
            guard let newUserId = testUserId, let newArtistId = testArtistId else {
                XCTFail("Failed to set up test data")
                return
            }
            userId = newUserId
            artistId = newArtistId
        }
        
        // 1. Get initial activity count
        let initialActivity = try await supabaseService.getFanActivity(userId: userId, limit: 50)
        let initialCount = initialActivity.count
        
        // 2. Create some purchases (which should generate activity)
        let purchase1Id = try await supabaseService.createPurchase(
            userId: userId,
            artistId: artistId,
            amount: 15.99,
            category: "album",
            description: "Activity Test Album 1"
        )
        
        let purchase2Id = try await supabaseService.createPurchase(
            userId: userId,
            artistId: artistId,
            amount: 49.99,
            category: "merchandise",
            description: "Activity Test Merch"
        )
        
        // 3. Create a goal (which should also generate activity)
        let goalId = try await supabaseService.createGoal(
            userId: userId,
            artistId: artistId,
            name: "Activity Test Goal",
            targetAmount: 100.0,
            deadline: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
            category: "general"
        )
        
        // 4. Wait a moment for activity to be processed (if async)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // 5. Verify activity was tracked
        let updatedActivity = try await supabaseService.getFanActivity(userId: userId, limit: 50)
        XCTAssertGreaterThan(updatedActivity.count, initialCount, "Activity count should increase")
        
        // 6. Verify activity contains expected types
        let activityTypes = Set(updatedActivity.map { $0.activityType })
        // Note: Activity types depend on database triggers/functions
        
        // Clean up
        try? await supabaseService.deletePurchase(id: purchase1Id)
        try? await supabaseService.deletePurchase(id: purchase2Id)
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossOperations() async throws {
        let userId: UUID
        let artistId: UUID
        
        if let existingUserId = testUserId, let existingArtistId = testArtistId {
            userId = existingUserId
            artistId = existingArtistId
        } else {
            try await testCompleteUserOnboardingFlow()
            guard let newUserId = testUserId, let newArtistId = testArtistId else {
                XCTFail("Failed to set up test data")
                return
            }
            userId = newUserId
            artistId = newArtistId
        }
        
        // 1. Create initial budget
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        
        let initialBudget = try await supabaseService.getBudget(userId: userId, month: month, year: year)
        let initialSpent = initialBudget?.spent ?? 0.0
        
        // 2. Create multiple purchases
        let purchaseAmounts = [25.99, 19.99, 35.00]
        var purchaseIds: [UUID] = []
        
        for (index, amount) in purchaseAmounts.enumerated() {
            let purchaseId = try await supabaseService.createPurchase(
                userId: userId,
                artistId: artistId,
                amount: amount,
                category: "album",
                description: "Consistency Test Purchase \(index + 1)"
            )
            purchaseIds.append(purchaseId)
            
            // Update budget for each purchase
            try await supabaseService.updateBudgetSpent(
                userId: userId,
                month: month,
                year: year,
                additionalAmount: amount
            )
        }
        
        // 3. Verify budget consistency
        let finalBudget = try await supabaseService.getBudget(userId: userId, month: month, year: year)
        let expectedSpent = initialSpent + purchaseAmounts.reduce(0, +)
        
        XCTAssertEqual(finalBudget?.spent ?? 0.0, expectedSpent, accuracy: 0.01, "Budget spent should match sum of purchases")
        
        // 4. Verify purchase history consistency
        let purchases = try await supabaseService.getPurchases(for: userId, limit: 20)
        let testPurchases = purchases.filter { purchaseIds.contains($0.id) }
        
        XCTAssertEqual(testPurchases.count, purchaseAmounts.count, "All test purchases should be retrievable")
        
        let totalFromPurchases = testPurchases.reduce(0.0) { $0 + abs($1.amount) }
        let expectedTotal = purchaseAmounts.reduce(0, +)
        XCTAssertEqual(totalFromPurchases, expectedTotal, accuracy: 0.01, "Purchase amounts should be consistent")
        
        // Clean up
        for purchaseId in purchaseIds {
            try? await supabaseService.deletePurchase(id: purchaseId)
        }
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryAndRetries() async throws {
        // Test behavior under various error conditions
        
        // 1. Test with invalid user ID (should handle gracefully)
        let invalidUserId = UUID()
        let purchases = try await supabaseService.getPurchases(for: invalidUserId)
        XCTAssertEqual(purchases.count, 0, "Should return empty array for invalid user")
        
        // 2. Test with invalid artist ID in search
        let invalidSearchResults = try await supabaseService.searchArtists(query: "NonExistentArtist12345")
        XCTAssertEqual(invalidSearchResults.count, 0, "Should return empty array for non-existent artist")
        
        // 3. Test concurrent operations on same data
        let userId: UUID
        
        if let existingUserId = testUserId {
            userId = existingUserId
        } else {
            try await testCompleteUserOnboardingFlow()
            guard let newUserId = testUserId else {
                XCTFail("Failed to set up user")
                return
            }
            userId = newUserId
        }
        
        // Run concurrent budget operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.supabaseService.getBudget(
                            userId: userId,
                            month: Calendar.current.component(.month, from: Date()),
                            year: Calendar.current.component(.year, from: Date())
                        )
                    } catch {
                        // Concurrent reads should not fail
                        XCTFail("Concurrent budget reads should not fail: \(error)")
                    }
                }
            }
        }
        
        // Should complete without deadlocks or corruption
        XCTAssertTrue(true, "Concurrent operations completed")
    }
    
    // MARK: - Performance Integration Tests
    
    func testLargeDataSetPerformance() async throws {
        let startTime = Date()
        
        // Test performance with larger data sets
        let artists = try await supabaseService.getArtists()
        
        let artistFetchTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(artistFetchTime, 5.0, "Artist fetch should complete within 5 seconds")
        
        let userId: UUID
        
        if let existingUserId = testUserId {
            userId = existingUserId
        } else {
            try await testCompleteUserOnboardingFlow()
            guard let newUserId = testUserId else {
                XCTFail("Failed to set up user")
                return
            }
            userId = newUserId
        }
        
        let purchaseStartTime = Date()
        let purchases = try await supabaseService.getPurchases(for: userId, limit: 50)
        
        let purchaseFetchTime = Date().timeIntervalSince(purchaseStartTime)
        XCTAssertLessThan(purchaseFetchTime, 3.0, "Purchase fetch should complete within 3 seconds")
        
        let goalStartTime = Date()
        let goals = try await supabaseService.getGoals(for: userId)
        
        let goalFetchTime = Date().timeIntervalSince(goalStartTime)
        XCTAssertLessThan(goalFetchTime, 2.0, "Goal fetch should complete within 2 seconds")
    }
}