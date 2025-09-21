import Foundation
import XCTest
@testable import Piggy_Bong

// MARK: - Test Configuration and Utilities

class TestConfiguration {
    static let shared = TestConfiguration()
    
    private init() {}
    
    // MARK: - Environment Detection
    
    var isRunningInCI: Bool {
        return ProcessInfo.processInfo.environment["CI"] == "true" ||
               ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true"
    }
    
    var isRunningUnitTests: Bool {
        return ProcessInfo.processInfo.environment["RUNNING_UNIT_TESTS"] == "true"
    }
    
    var isRunningIntegrationTests: Bool {
        return ProcessInfo.processInfo.environment["RUNNING_INTEGRATION_TESTS"] == "true"
    }
    
    var isRunningUITests: Bool {
        return ProcessInfo.processInfo.environment["RUNNING_UI_TESTS"] == "true"
    }
    
    var isRunningPerformanceTests: Bool {
        return ProcessInfo.processInfo.environment["RUNNING_PERFORMANCE_TESTS"] == "true"
    }
    
    // MARK: - Test Data Configuration
    
    var shouldUseMockData: Bool {
        return ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "true" || isRunningInCI
    }
    
    var testDatabaseURL: String {
        return ProcessInfo.processInfo.environment["TEST_DATABASE_URL"] ?? "mock://test-database"
    }
    
    var testSupabaseURL: String {
        return ProcessInfo.processInfo.environment["TEST_SUPABASE_URL"] ?? "https://test.supabase.co"
    }
    
    var testSupabaseKey: String {
        return ProcessInfo.processInfo.environment["TEST_SUPABASE_ANON_KEY"] ?? "test-key"
    }
    
    var testRevenueCatKey: String {
        return ProcessInfo.processInfo.environment["TEST_REVENUECAT_API_KEY"] ?? "test-revenue-cat-key"
    }
    
    // MARK: - Test Timeouts
    
    var defaultTimeout: TimeInterval {
        return isRunningInCI ? 30.0 : 10.0
    }
    
    var networkTimeout: TimeInterval {
        return isRunningInCI ? 60.0 : 20.0
    }
    
    var performanceTimeout: TimeInterval {
        return isRunningInCI ? 120.0 : 30.0
    }
    
    var uiTestTimeout: TimeInterval {
        return isRunningInCI ? 45.0 : 15.0
    }
    
    // MARK: - Performance Thresholds
    
    var databaseQueryPerformanceThreshold: TimeInterval {
        return isRunningInCI ? 10.0 : 5.0
    }
    
    var authenticationPerformanceThreshold: TimeInterval {
        return isRunningInCI ? 5.0 : 2.0
    }
    
    var uiInteractionPerformanceThreshold: TimeInterval {
        return isRunningInCI ? 3.0 : 1.0
    }
}

// MARK: - Test Utilities

class TestUtilities {
    
    // MARK: - Mock Data Generation
    
    static func generateMockUser(name: String = "Test User") -> AuthenticationService.AuthUser {
        return AuthenticationService.AuthUser(
            id: UUID(),
            email: "\(name.lowercased().replacingOccurrences(of: " ", with: ""))@test.com",
            name: name,
            monthlyBudget: Double.random(in: 100...2000),
            createdAt: Date()
        )
    }
    
    static func generateMockArtist(name: String = "Test Artist") -> Artist {
        return Artist(
            id: UUID(),
            name: name,
            group: "\(name) Group",
            imageURL: "https://test.com/image.jpg",
            spotifyID: "spotify_\(UUID().uuidString.prefix(8))",
            isFollowing: Bool.random()
        )
    }
    
    static func generateMockGoal(name: String = "Test Goal") -> Goal {
        return Goal(
            id: UUID(),
            name: name,
            targetAmount: Double.random(in: 50...500),
            currentAmount: Double.random(in: 0...100),
            deadline: Calendar.current.date(byAdding: .month, value: Int.random(in: 1...6), to: Date()) ?? Date(),
            category: [.concert, .album, .merchandise, .fanmeet].randomElement() ?? .concert,
            imageURL: "https://test.com/goal.jpg",
            artistName: "Test Artist",
            priority: [.high, .medium, .low].randomElement() ?? .medium,
            createdAt: Date()
        )
    }
    
    static func generateMockPurchase(amount: Double = 29.99) -> DashboardTransaction {
        return DashboardTransaction(
            id: UUID(),
            title: "Test Purchase",
            subtitle: "Test Artist",
            amount: -amount,
            type: .expense,
            category: [.album, .concert, .merchandise].randomElement() ?? .album,
            date: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...30), to: Date()) ?? Date(),
            artistName: "Test Artist"
        )
    }
    
    // MARK: - Async Test Utilities
    
    static func waitForCondition(
        timeout: TimeInterval = TestConfiguration.shared.defaultTimeout,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let endTime = Date().addingTimeInterval(timeout)
        
        while Date() < endTime {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return false
    }
    
    static func waitForAsyncOperation<T>(
        timeout: TimeInterval = TestConfiguration.shared.defaultTimeout,
        operation: @escaping () async throws -> T
    ) async -> Result<T, Error> {
        do {
            return try await withTimeout(timeout: timeout) {
                let result = try await operation()
                return .success(result)
            }
        } catch {
            return .failure(error)
        }
    }
    
    static func withTimeout<T>(
        timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestTimeoutError()
            }
            
            // Return first completed task and cancel others
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
    
    // MARK: - UI Test Utilities
    
    static func resetAppState() {
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Clear Keychain items
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "piggy_bong_user"
        ]
        SecItemDelete(query as CFDictionary)
        
        // Reset any singleton states if needed
        Task {
            await AuthenticationService.shared.signOut()
        }
    }
    
    static func setupMockEnvironment() {
        // Set environment variables for mocking
        setenv("USE_MOCK_DATA", "true", 1)
        setenv("MOCK_SUPABASE_SERVICE", "true", 1)
        setenv("MOCK_REVENUECAT_SERVICE", "true", 1)
    }
    
    // MARK: - Performance Test Utilities
    
    static func measureAverageTime(
        iterations: Int = 10,
        operation: () throws -> Void
    ) rethrows -> TimeInterval {
        var totalTime: TimeInterval = 0
        
        for _ in 0..<iterations {
            let startTime = Date()
            try operation()
            totalTime += Date().timeIntervalSince(startTime)
        }
        
        return totalTime / Double(iterations)
    }
    
    static func measureAsyncAverageTime(
        iterations: Int = 10,
        operation: () async throws -> Void
    ) async rethrows -> TimeInterval {
        var totalTime: TimeInterval = 0
        
        for _ in 0..<iterations {
            let startTime = Date()
            try await operation()
            totalTime += Date().timeIntervalSince(startTime)
        }
        
        return totalTime / Double(iterations)
    }
}

// MARK: - Test Errors

struct TestTimeoutError: Error {
    let message = "Test operation timed out"
}

struct TestSetupError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

struct TestValidationError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

// MARK: - Test Base Classes

class BaseTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        if TestConfiguration.shared.shouldUseMockData {
            TestUtilities.setupMockEnvironment()
        }
        
        // Set longer timeouts for CI
        if TestConfiguration.shared.isRunningInCI {
            continueAfterFailure = false
        }
    }
    
    override func tearDown() {
        // Clean up any test state
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func skipTestIfInCI(_ reason: String = "Test not suitable for CI environment") throws {
        if TestConfiguration.shared.isRunningInCI {
            throw XCTSkip(reason)
        }
    }
    
    func skipTestIfNotCI(_ reason: String = "Test only suitable for CI environment") throws {
        if !TestConfiguration.shared.isRunningInCI {
            throw XCTSkip(reason)
        }
    }
    
    func expectationWithTimeout(_ description: String, timeout: TimeInterval? = nil) -> XCTestExpectation {
        let exp = expectation(description: description)
        return exp
    }
    
    func waitForExpectations(timeout: TimeInterval? = nil) {
        let timeoutValue = timeout ?? TestConfiguration.shared.defaultTimeout
        wait(for: [], timeout: timeoutValue)
    }
}

class BaseIntegrationTestCase: BaseTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Skip integration tests if running in unit test mode
        if TestConfiguration.shared.isRunningUnitTests {
            continueAfterFailure = false
            // Note: We can't throw XCTSkip in setUp, so we'll check in individual tests
        }
    }
    
    func requiresNetworkConnection() throws {
        if TestConfiguration.shared.shouldUseMockData && !TestConfiguration.shared.isRunningIntegrationTests {
            throw XCTSkip("Integration test requires network connection")
        }
    }
}

class BaseUITestCase: BaseTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        
        if TestConfiguration.shared.shouldUseMockData {
            app.launchEnvironment["USE_MOCK_DATA"] = "true"
        }
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func launchApp(with environment: [String: String] = [:]) {
        for (key, value) in environment {
            app.launchEnvironment[key] = value
        }
        app.launch()
    }
}

class BasePerformanceTestCase: BaseTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Skip performance tests if not explicitly running them
        if !TestConfiguration.shared.isRunningPerformanceTests && !TestConfiguration.shared.isRunningInCI {
            continueAfterFailure = false
        }
    }
    
    func measurePerformance(
        metrics: [XCTMetric] = [XCTClockMetric()],
        block: () -> Void
    ) {
        measure(metrics: metrics, block: block)
    }
    
    func measureAsyncPerformance(
        metrics: [XCTMetric] = [XCTClockMetric()],
        block: @escaping () async -> Void
    ) async {
        await withCheckedContinuation { continuation in
            measure(metrics: metrics) {
                Task {
                    await block()
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Test Matchers and Assertions

extension XCTestCase {
    
    func XCTAssertEqualWithAccuracy<T: FloatingPoint>(
        _ expression1: T,
        _ expression2: T,
        accuracy: T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(expression1, expression2, accuracy: accuracy, message(), file: file, line: line)
    }
    
    func XCTAssertAsyncNoThrow<T>(
        _ expression: @escaping () async throws -> T,
        timeout: TimeInterval = TestConfiguration.shared.defaultTimeout,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await TestUtilities.withTimeout(timeout: timeout) {
                try await expression()
            }
        } catch {
            XCTFail("XCTAssertAsyncNoThrow failed: \(error) - \(message())", file: file, line: line)
        }
    }
    
    func XCTAssertAsyncThrowsError<T>(
        _ expression: @escaping () async throws -> T,
        timeout: TimeInterval = TestConfiguration.shared.defaultTimeout,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await TestUtilities.withTimeout(timeout: timeout) {
                try await expression()
            }
            XCTFail("XCTAssertAsyncThrowsError failed: expression did not throw - \(message())", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}