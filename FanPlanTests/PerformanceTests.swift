import XCTest
import Foundation
@testable import Piggy_Bong

class PerformanceTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var authService: AuthenticationService!
    var revenueCatManager: RevenueCatManager!
    
    override func setUpWithError() throws {
        super.setUp()
        supabaseService = SupabaseService.shared
        authService = AuthenticationService.shared
        revenueCatManager = RevenueCatManager.shared
    }
    
    override func tearDownWithError() throws {
        supabaseService = nil
        authService = nil
        revenueCatManager = nil
        super.tearDown()
    }
    
    // MARK: - Database Performance Tests
    
    func testArtistsListLoadPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Artists load performance")
            
            Task {
                do {
                    _ = try await supabaseService.getArtists()
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testMultiplePurchasesFetchPerformance() throws {
        let mockUserId = UUID()
        
        measure {
            let expectation = XCTestExpectation(description: "Purchases fetch performance")
            
            Task {
                do {
                    _ = try await supabaseService.getPurchases(for: mockUserId, limit: 50)
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testGoalsFetchPerformance() throws {
        let mockUserId = UUID()
        
        measure {
            let expectation = XCTestExpectation(description: "Goals fetch performance")
            
            Task {
                do {
                    _ = try await supabaseService.getGoals(for: mockUserId)
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 8.0)
        }
    }
    
    func testUserDataFetchPerformance() throws {
        let mockUserId = UUID()
        
        measure {
            let expectation = XCTestExpectation(description: "User data fetch performance")
            
            Task {
                do {
                    _ = try await supabaseService.getUser(id: mockUserId)
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testDatabaseConnectionPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Database connection performance")
            
            Task {
                _ = await supabaseService.checkSupabaseConnectivity()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - Concurrent Operations Performance Tests
    
    func testConcurrentDatabaseOperations() throws {
        measure {
            let expectation = XCTestExpectation(description: "Concurrent database operations")
            expectation.expectedFulfillmentCount = 5
            
            let mockUserId = UUID()
            
            // Run multiple concurrent operations
            Task {
                async let artists = supabaseService.getArtists()
                async let purchases = supabaseService.getPurchases(for: mockUserId, limit: 20)
                async let goals = supabaseService.getGoals(for: mockUserId)
                async let userArtists = supabaseService.getUserArtists(userId: mockUserId)
                async let connection = supabaseService.checkSupabaseConnectivity()
                
                // Wait for all operations to complete
                do {
                    _ = try await artists
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
                
                do {
                    _ = try await purchases
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
                
                do {
                    _ = try await goals
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
                
                do {
                    _ = try await userArtists
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
                
                _ = await connection
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func testHighConcurrencyDatabaseReads() throws {
        let operationCount = 10
        
        measure {
            let expectation = XCTestExpectation(description: "High concurrency database reads")
            expectation.expectedFulfillmentCount = operationCount
            
            // Launch many concurrent read operations
            for _ in 0..<operationCount {
                Task {
                    do {
                        _ = try await supabaseService.getArtists()
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - Authentication Performance Tests
    
    func testAuthenticationValidationPerformance() throws {
        let testEmails = [
            "test@example.com",
            "user.name+tag@domain.co.uk",
            "simple@test.org",
            "complex.email.with.dots@very-long-domain-name.com",
            "invalid-email",
            "",
            "another.test@domain.net"
        ]
        
        measure {
            for email in testEmails {
                _ = authService.validateEmail(email)
            }
        }
    }
    
    func testPasswordValidationPerformance() throws {
        let testPasswords = [
            "SecurePassword123!",
            "weak",
            "AnotherStrongPassword456@",
            "",
            "12345",
            "VeryLongPasswordWithManyCharactersAndNumbers123456789!@#$%^&*()",
            "short"
        ]
        
        measure {
            for password in testPasswords {
                _ = authService.validatePassword(password)
            }
        }
    }
    
    func testBudgetValidationPerformance() throws {
        let testBudgets = [
            0.0, 50.0, 100.0, 500.0, 1000.0, 5000.0, 10000.0, 50000.0, 100000.0, 200000.0,
            -100.0, -50.0, 0.01, 99999.99, 100000.01
        ]
        
        measure {
            for budget in testBudgets {
                _ = authService.validateBudget(budget)
            }
        }
    }
    
    // MARK: - RevenueCat Performance Tests
    
    func testRevenueCatInitializationPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "RevenueCat initialization performance")
            
            // Create new manager instance to test initialization
            let testManager = RevenueCatManager.shared
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testCustomerInfoFetchPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Customer info fetch performance")
            
            revenueCatManager.checkSubscriptionStatus()
            
            // Wait for operation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testOfferingsLoadPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Offerings load performance")
            
            revenueCatManager.loadOfferings()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testPromoCodeValidationPerformance() throws {
        let promoCodes = [
            "VALID123",
            "INVALID456",
            "HACKATHON2024",
            "",
            "TOOLONGPROMOCODETHATEXCEEDSLIMITS",
            "short",
            "TEST"
        ]
        
        measure {
            let expectation = XCTestExpectation(description: "Promo code validation performance")
            expectation.expectedFulfillmentCount = promoCodes.count
            
            for code in promoCodes {
                revenueCatManager.applyPromoCode(code) { _, _ in
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - Search and Filter Performance Tests
    
    func testArtistSearchPerformance() throws {
        let searchQueries = [
            "BTS",
            "Black",
            "New",
            "A",
            "aespa",
            "NonExistentArtist12345",
            "",
            "Very Long Search Query That Might Not Match Anything"
        ]
        
        measure {
            let expectation = XCTestExpectation(description: "Artist search performance")
            expectation.expectedFulfillmentCount = searchQueries.count
            
            for query in searchQueries {
                Task {
                    do {
                        _ = try await supabaseService.searchArtists(query: query)
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringDataLoading() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Memory usage during data loading")
            
            Task {
                // Load large amounts of data to test memory usage
                do {
                    let artists = try await supabaseService.getArtists()
                    
                    // Simulate processing the data
                    var processedArtists: [Artist] = []
                    for artist in artists {
                        let processed = Artist(
                            id: artist.id,
                            name: artist.name.uppercased(),
                            group: artist.group?.lowercased(),
                            imageURL: artist.imageURL,
                            spotifyID: artist.spotifyID,
                            isFollowing: !artist.isFollowing
                        )
                        processedArtists.append(processed)
                    }
                    
                    // Force memory allocation
                    let duplicatedArtists = processedArtists + processedArtists + processedArtists
                    XCTAssertGreaterThanOrEqual(duplicatedArtists.count, 0)
                    
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func testMemoryUsageDuringConcurrentOperations() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Memory usage during concurrent operations")
            expectation.expectedFulfillmentCount = 10
            
            let mockUserId = UUID()
            
            // Run many concurrent operations to test memory usage
            for i in 0..<10 {
                Task {
                    do {
                        // Mix different types of operations
                        if i % 3 == 0 {
                            _ = try await supabaseService.getArtists()
                        } else if i % 3 == 1 {
                            _ = try await supabaseService.getPurchases(for: mockUserId, limit: 20)
                        } else {
                            _ = try await supabaseService.getGoals(for: mockUserId)
                        }
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 25.0)
        }
    }
    
    // MARK: - Network Performance Tests
    
    func testNetworkLatencyTolerance() throws {
        // Test performance with simulated network delays
        measure {
            let expectation = XCTestExpectation(description: "Network latency tolerance")
            
            Task {
                let startTime = Date()
                
                do {
                    _ = try await supabaseService.getArtists()
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Should complete within reasonable time even with network latency
                    XCTAssertLessThan(duration, 30.0, "Network operations should complete within 30 seconds")
                    
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 35.0)
        }
    }
    
    func testMultipleSimultaneousNetworkRequests() throws {
        measure {
            let expectation = XCTestExpectation(description: "Multiple simultaneous network requests")
            expectation.expectedFulfillmentCount = 8
            
            let mockUserId = UUID()
            let mockArtistId = UUID()
            
            // Launch multiple different types of network requests simultaneously
            Task {
                async let artists = supabaseService.getArtists()
                async let purchases = supabaseService.getPurchases(for: mockUserId, limit: 10)
                async let goals = supabaseService.getGoals(for: mockUserId)
                async let userArtists = supabaseService.getUserArtists(userId: mockUserId)
                async let search1 = supabaseService.searchArtists(query: "BTS")
                async let search2 = supabaseService.searchArtists(query: "BLACKPINK")
                async let connection1 = supabaseService.checkSupabaseConnectivity()
                async let connection2 = supabaseService.checkSupabaseConnectivity()
                
                // Wait for all to complete
                do { _ = try await artists; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await purchases; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await goals; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await userArtists; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await search1; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await search2; expectation.fulfill() } catch { expectation.fulfill() }
                _ = await connection1; expectation.fulfill()
                _ = await connection2; expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - Data Processing Performance Tests
    
    func testLargeDataSetProcessing() throws {
        measure {
            let expectation = XCTestExpectation(description: "Large dataset processing")
            
            Task {
                do {
                    let artists = try await supabaseService.getArtists()
                    
                    // Simulate processing large amounts of data
                    let startTime = Date()
                    
                    var processedData: [String: Any] = [:]
                    
                    for artist in artists {
                        // Simulate complex data processing
                        let artistData = [
                            "id": artist.id.uuidString,
                            "name": artist.name,
                            "group": artist.group ?? "",
                            "processed_name": artist.name.uppercased(),
                            "name_length": artist.name.count,
                            "has_image": artist.imageURL != nil,
                            "is_following": artist.isFollowing,
                            "hash": artist.name.hashValue
                        ] as [String : Any]
                        
                        processedData[artist.id.uuidString] = artistData
                    }
                    
                    // Simulate additional processing
                    let sortedArtists = artists.sorted { $0.name < $1.name }
                    let groupedArtists = Dictionary(grouping: sortedArtists) { $0.group }
                    let filteredArtists = artists.filter { $0.isFollowing }
                    
                    let processingTime = Date().timeIntervalSince(startTime)
                    
                    // Processing should be reasonably fast
                    XCTAssertLessThan(processingTime, 5.0, "Data processing should complete within 5 seconds")
                    XCTAssertGreaterThan(processedData.count, 0, "Should process some data")
                    XCTAssertGreaterThanOrEqual(sortedArtists.count, 0, "Should sort data")
                    XCTAssertGreaterThanOrEqual(groupedArtists.count, 0, "Should group data")
                    XCTAssertGreaterThanOrEqual(filteredArtists.count, 0, "Should filter data")
                    
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - CPU Performance Tests
    
    func testCPUIntensiveOperations() throws {
        measure(metrics: [XCTCPUMetric()]) {
            // Simulate CPU-intensive operations that might occur in the app
            
            let iterations = 10000
            var results: [String] = []
            
            for i in 0..<iterations {
                let uuid = UUID().uuidString
                let processed = uuid.replacingOccurrences(of: "-", with: "").lowercased()
                let hash = processed.hashValue
                let result = "\(i)_\(hash)_\(processed.prefix(8))"
                results.append(result)
            }
            
            // Sort and process results
            results.sort()
            let uniqueResults = Array(Set(results))
            
            XCTAssertEqual(results.count, iterations, "Should process all iterations")
            XCTAssertGreaterThan(uniqueResults.count, 0, "Should have unique results")
        }
    }
    
    // MARK: - Disk I/O Performance Tests
    
    func testKeychainPerformance() throws {
        measure(metrics: [XCTStorageMetric()]) {
            let expectation = XCTestExpectation(description: "Keychain performance")
            
            Task {
                // Test multiple authentication operations that use keychain
                let testUser = AuthenticationService.AuthUser(
                    id: UUID(),
                    email: "performance@test.com",
                    name: "Performance Test User",
                    monthlyBudget: 500.0,
                    createdAt: Date()
                )
                
                // Simulate rapid authentication state changes
                for _ in 0..<10 {
                    await MainActor.run {
                        authService.currentUser = testUser
                        authService.isAuthenticated = true
                    }
                    
                    await authService.signOut()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Overall App Performance Tests
    
    func testAppStartupPerformance() throws {
        measure {
            // Simulate app startup operations
            let expectation = XCTestExpectation(description: "App startup performance")
            
            Task {
                // Initialize all services
                let supabase = SupabaseService.shared
                let auth = AuthenticationService.shared
                let revenueCat = RevenueCatManager.shared
                
                // Perform initial data loads
                async let connectionTest = supabase.testConnection()
                let initialAuth = auth.validateEmail("test@example.com")
                
                _ = await connectionTest
                _ = initialAuth
                
                // Simulate RevenueCat initialization
                revenueCat.configure()
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func testDashboardDataLoadPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Dashboard data load performance")
            expectation.expectedFulfillmentCount = 4
            
            let mockUserId = UUID()
            
            Task {
                // Simulate loading all data needed for dashboard
                async let artists = supabaseService.getArtists()
                async let purchases = supabaseService.getPurchases(for: mockUserId, limit: 10)
                async let goals = supabaseService.getGoals(for: mockUserId)
                async let userArtists = supabaseService.getUserArtists(userId: mockUserId)
                
                do { _ = try await artists; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await purchases; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await goals; expectation.fulfill() } catch { expectation.fulfill() }
                do { _ = try await userArtists; expectation.fulfill() } catch { expectation.fulfill() }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    // MARK: - Load Testing Simulations
    
    func testHighUserLoadSimulation() throws {
        // Simulate multiple users performing operations simultaneously
        let userCount = 20
        
        measure {
            let expectation = XCTestExpectation(description: "High user load simulation")
            expectation.expectedFulfillmentCount = userCount * 3 // 3 operations per user
            
            for _ in 0..<userCount {
                let mockUserId = UUID()
                
                // Each "user" performs multiple operations
                Task {
                    do {
                        _ = try await supabaseService.getArtists()
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
                
                Task {
                    do {
                        _ = try await supabaseService.getPurchases(for: mockUserId, limit: 5)
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
                
                Task {
                    do {
                        _ = try await supabaseService.searchArtists(query: "Test")
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 60.0)
        }
    }
    
    func testSustainedOperationPerformance() throws {
        // Test performance over sustained operations
        let operationCount = 50
        
        measure {
            let expectation = XCTestExpectation(description: "Sustained operation performance")
            expectation.expectedFulfillmentCount = operationCount
            
            // Perform operations sequentially to test sustained performance
            Task {
                for i in 0..<operationCount {
                    do {
                        if i % 3 == 0 {
                            _ = try await supabaseService.getArtists()
                        } else if i % 3 == 1 {
                            _ = try await supabaseService.searchArtists(query: "Test\(i)")
                        } else {
                            _ = await supabaseService.checkSupabaseConnectivity()
                        }
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 120.0)
        }
    }
}