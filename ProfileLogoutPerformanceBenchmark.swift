import SwiftUI
import XCTest
import Combine
@testable import FanPlan

/**
 * Performance Benchmark Test Suite for Profile Screen Logout Flow
 * 
 * This comprehensive benchmark tests all critical performance aspects of the logout flow:
 * - LoadingView rendering performance (simple vs full mode)
 * - Authentication flow timing
 * - Memory management during logout operations
 * - UI responsiveness and animation smoothness
 * - Network operations performance
 * - UserDefaults operations performance
 */

class ProfileLogoutPerformanceBenchmark: XCTestCase {
    
    var mockAuthService: MockAuthenticationService!
    var mockNetworkManager: MockNetworkManager!
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Performance Baseline Targets
    
    private struct PerformanceTargets {
        static let loadingViewRenderTime: TimeInterval = 0.016 // 16ms (60fps)
        static let simpleLoadingRenderTime: TimeInterval = 0.008 // 8ms (faster for overlay)
        static let logoutProcessTime: TimeInterval = 2.0 // 2 seconds max
        static let authStateChangeTime: TimeInterval = 0.5 // 500ms max
        static let userDefaultsWriteTime: TimeInterval = 0.01 // 10ms max
        static let profileViewRenderTime: TimeInterval = 0.033 // 33ms (30fps)
        static let memoryUsageThreshold: Int64 = 50 * 1024 * 1024 // 50MB
        static let networkConnectivityCheckTime: TimeInterval = 2.0 // 2 seconds max
    }
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        mockNetworkManager = MockNetworkManager()
        
        // Clear UserDefaults for clean testing
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "user_fandom_name")
    }
    
    override func tearDown() {
        mockAuthService = nil
        mockNetworkManager = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - 1. Loading View Performance Tests
    
    func testLoadingViewSimpleModeRenderingPerformance() throws {
        let renderingMetrics = [XCTPerformanceMetric.wallClockTime]
        let options = XCTMeasureOptions()
        options.iterationCount = 100
        
        measure(metrics: renderingMetrics, options: options) {
            autoreleasepool {
                let loadingView = LoadingView(isSimpleMode: true)
                let hostingController = UIHostingController(rootView: loadingView)
                
                // Simulate view appearance to trigger all animations
                hostingController.beginAppearanceTransition(true, animated: false)
                hostingController.endAppearanceTransition()
                
                // Force a layout pass
                hostingController.view.layoutIfNeeded()
            }
        }
    }
    
    func testLoadingViewFullModeRenderingPerformance() throws {
        let renderingMetrics = [XCTPerformanceMetric.wallClockTime]
        let options = XCTMeasureOptions()
        options.iterationCount = 50
        
        measure(metrics: renderingMetrics, options: options) {
            autoreleasepool {
                let loadingView = LoadingView(isSimpleMode: false)
                let hostingController = UIHostingController(rootView: loadingView)
                
                hostingController.beginAppearanceTransition(true, animated: false)
                hostingController.endAppearanceTransition()
                
                hostingController.view.layoutIfNeeded()
            }
        }
    }
    
    func testLoadingViewMemoryUsage() throws {
        let memoryMetrics = [XCTPerformanceMetric.memoryPhysical]
        let options = XCTMeasureOptions()
        options.iterationCount = 20
        
        measure(metrics: memoryMetrics, options: options) {
            autoreleasepool {
                var loadingViews: [LoadingView] = []
                
                // Create multiple LoadingView instances to test memory usage
                for _ in 0..<10 {
                    loadingViews.append(LoadingView(isSimpleMode: true))
                    loadingViews.append(LoadingView(isSimpleMode: false))
                }
                
                // Force retention
                _ = loadingViews.count
                
                // Clear to test deallocation
                loadingViews.removeAll()
            }
        }
    }
    
    // MARK: - 2. Authentication Flow Performance
    
    func testLogoutProcessTiming() throws {
        let expectation = expectation(description: "Logout process completion")
        var startTime: CFAbsoluteTime = 0
        var endTime: CFAbsoluteTime = 0
        
        // Setup authenticated state
        mockAuthService.isAuthenticated = true
        mockAuthService.currentUser = createMockUser()
        
        // Monitor state changes
        mockAuthService.$isAuthenticated
            .dropFirst() // Skip initial value
            .sink { isAuthenticated in
                if !isAuthenticated {
                    endTime = CFAbsoluteTimeGetCurrent()
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        startTime = CFAbsoluteTimeGetCurrent()
        
        Task {
            await mockAuthService.signOut()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        let logoutTime = endTime - startTime
        print("📊 Logout process time: \(String(format: "%.3f", logoutTime))s")
        
        XCTAssertLessThan(logoutTime, PerformanceTargets.logoutProcessTime,
                         "Logout process took \(logoutTime)s, expected < \(PerformanceTargets.logoutProcessTime)s")
    }
    
    func testUserDefaultsOperationsPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 1000
        
        measure(metrics: [XCTPerformanceMetric.wallClockTime], options: options) {
            // Test UserDefaults.removeObject performance (used in logout)
            UserDefaults.standard.set("test_value", forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            
            UserDefaults.standard.set("Fan User", forKey: "user_fandom_name")
            UserDefaults.standard.removeObject(forKey: "user_fandom_name")
        }
    }
    
    func testConcurrentLogoutAttempts() throws {
        let expectation = expectation(description: "Concurrent logout completion")
        expectation.expectedFulfillmentCount = 3
        
        mockAuthService.isAuthenticated = true
        mockAuthService.currentUser = createMockUser()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate multiple concurrent logout attempts
        for i in 0..<3 {
            Task {
                await mockAuthService.signOut()
                print("📊 Logout attempt \(i + 1) completed")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        print("📊 Concurrent logout attempts completed in: \(String(format: "%.3f", totalTime))s")
        
        // All attempts should complete within reasonable time
        XCTAssertLessThan(totalTime, 5.0)
    }
    
    // MARK: - 3. Profile Screen Rendering Performance
    
    func testProfileSettingsViewRenderingPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 50
        
        measure(metrics: [XCTPerformanceMetric.wallClockTime], options: options) {
            autoreleasepool {
                let profileView = ProfileSettingsView()
                    .environmentObject(mockAuthService)
                
                let hostingController = UIHostingController(rootView: profileView)
                
                hostingController.beginAppearanceTransition(true, animated: false)
                hostingController.endAppearanceTransition()
                
                // Force layout to measure rendering time
                hostingController.view.layoutIfNeeded()
                
                // Simulate scroll performance by forcing multiple layout passes
                for _ in 0..<5 {
                    hostingController.view.setNeedsLayout()
                    hostingController.view.layoutIfNeeded()
                }
            }
        }
    }
    
    func testProfileViewWithLoadingOverlayPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 30
        
        measure(metrics: [XCTPerformanceMetric.wallClockTime], options: options) {
            autoreleasepool {
                // Create ProfileSettingsView with isSigningOut = true to show overlay
                mockAuthService.isAuthenticated = true
                mockAuthService.currentUser = createMockUser()
                
                let profileView = ProfileSettingsViewWithLoadingState(
                    authService: mockAuthService,
                    isSigningOut: true
                )
                
                let hostingController = UIHostingController(rootView: profileView)
                
                hostingController.beginAppearanceTransition(true, animated: false)
                hostingController.endAppearanceTransition()
                hostingController.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - 4. Memory Management Tests
    
    func testLogoutMemoryUsage() throws {
        let memoryMetrics = [XCTPerformanceMetric.memoryPhysical]
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        
        measure(metrics: memoryMetrics, options: options) {
            autoreleasepool {
                // Setup authenticated state with user data
                mockAuthService.isAuthenticated = true
                mockAuthService.currentUser = createMockUser()
                
                // Create profile view
                let profileView = ProfileSettingsView()
                    .environmentObject(mockAuthService)
                
                let hostingController = UIHostingController(rootView: profileView)
                hostingController.beginAppearanceTransition(true, animated: false)
                hostingController.endAppearanceTransition()
                
                // Perform logout
                Task {
                    await mockAuthService.signOut()
                }
                
                // Force cleanup
                hostingController.beginAppearanceTransition(false, animated: false)
                hostingController.endAppearanceTransition()
            }
        }
    }
    
    func testRapidLogoutLoginCycleMemory() throws {
        let expectation = expectation(description: "Rapid logout/login cycle")
        let cycles = 5
        var currentCycle = 0
        
        func performCycle() {
            Task {
                // Login
                mockAuthService.isAuthenticated = true
                mockAuthService.currentUser = createMockUser()
                
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                
                // Logout
                await mockAuthService.signOut()
                
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                
                currentCycle += 1
                if currentCycle < cycles {
                    performCycle()
                } else {
                    expectation.fulfill()
                }
            }
        }
        
        let startMemory = getMemoryUsage()
        performCycle()
        
        wait(for: [expectation], timeout: 10.0)
        
        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory
        
        print("📊 Memory increase after \(cycles) logout/login cycles: \(memoryIncrease / 1024 / 1024)MB")
        
        // Memory increase should be minimal
        XCTAssertLessThan(memoryIncrease, PerformanceTargets.memoryUsageThreshold)
    }
    
    // MARK: - 5. Network Operations Performance
    
    func testNetworkConnectivityCheckPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 20
        
        measure(metrics: [XCTPerformanceMetric.wallClockTime], options: options) {
            let expectation = self.expectation(description: "Network check")
            
            Task {
                let isConnected = await mockNetworkManager.checkConnectivity()
                print("📊 Network connectivity: \(isConnected)")
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - 6. Animation Performance Tests
    
    func testLoadingOverlayTransitionPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 100
        
        measure(metrics: [XCTPerformanceMetric.wallClockTime], options: options) {
            autoreleasepool {
                let profileView = ProfileSettingsViewWithAnimationTest()
                let hostingController = UIHostingController(rootView: profileView)
                
                hostingController.beginAppearanceTransition(true, animated: true)
                hostingController.endAppearanceTransition()
                hostingController.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockUser() -> AuthenticationService.AuthUser {
        return AuthenticationService.AuthUser(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            monthlyBudget: 100.0,
            createdAt: Date()
        )
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        }
        return 0
    }
}

// MARK: - Mock Services for Testing

class MockAuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AuthenticationService.AuthUser?
    @Published var isLoading = false
    
    func signOut() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
            isLoading = false
        }
    }
}

class MockNetworkManager: ObservableObject {
    @Published var isConnected = true
    
    func checkConnectivity() async -> Bool {
        // Simulate connectivity check delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        return isConnected
    }
}

// MARK: - Test Helper Views

struct ProfileSettingsViewWithLoadingState: View {
    @ObservedObject var authService: MockAuthenticationService
    let isSigningOut: Bool
    
    var body: some View {
        ZStack {
            // Simulate profile content
            VStack {
                Text("Profile Content")
                Button("Logout") {
                    Task {
                        await authService.signOut()
                    }
                }
            }
            
            if isSigningOut {
                LoadingView(isSimpleMode: true)
                    .allowsHitTesting(false)
            }
        }
    }
}

struct ProfileSettingsViewWithAnimationTest: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue)
                .opacity(isAnimating ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}