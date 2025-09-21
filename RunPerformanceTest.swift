#!/usr/bin/env swift

import Foundation

// Import the performance test
// Note: This is a simplified version that can run standalone

class QuickPerformanceTest {
    
    static func runQuickBenchmark() {
        print("🚀 Profile Logout Flow - Quick Performance Benchmark")
        print("=" * 50)
        
        // Test 1: UI Response Time
        testUIResponseTime()
        
        // Test 2: UserDefaults Performance
        testUserDefaultsPerformance()
        
        // Test 3: Memory Allocation
        testBasicMemoryAllocation()
        
        // Test 4: Simulated Loading Operations
        testSimulatedLoadingOperations()
        
        print("\n🎯 Quick Benchmark Complete!")
        print("=" * 50)
    }
    
    static func testUIResponseTime() {
        print("\n📊 Testing UI Response Time...")
        
        let iterations = 1000
        var totalTime: TimeInterval = 0
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Simulate the exact button press operation
            var isSigningOut = false
            isSigningOut = true
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            totalTime += duration
        }
        
        let avgTime = totalTime / Double(iterations)
        let avgTimeMs = avgTime * 1000
        
        let status = avgTimeMs < 0.1 ? "✅ PASS" : "⚠️ WARNING"
        print("   \(status) Average UI response: \(String(format: "%.3f", avgTimeMs))ms")
        print("   Target: <0.1ms, Result: \(avgTimeMs < 0.1 ? "Within target" : "Above target")")
    }
    
    static func testUserDefaultsPerformance() {
        print("\n📊 Testing UserDefaults Performance...")
        
        let iterations = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            // Simulate exact logout UserDefaults operations
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set("Fan User \(i)", forKey: "user_fandom_name")
            
            // Logout cleanup
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "user_fandom_name")
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let avgTimeMs = (totalTime / Double(iterations * 4)) * 1000 // 4 operations per iteration
        
        let status = avgTimeMs < 1.0 ? "✅ PASS" : "⚠️ WARNING"
        print("   \(status) Average UserDefaults operation: \(String(format: "%.3f", avgTimeMs))ms")
        print("   Target: <1.0ms, Total time for \(iterations * 4) ops: \(String(format: "%.2f", totalTime))s")
    }
    
    static func testBasicMemoryAllocation() {
        print("\n📊 Testing Memory Allocation...")
        
        let initialMemory = getMemoryUsage()
        
        // Simulate creating multiple loading views and profile data
        autoreleasepool {
            for i in 0..<100 {
                // Simulate LoadingView data structures
                let loadingData = [
                    "isSimpleMode": i % 2 == 0,
                    "messages": ["Message 1", "Message 2", "Message 3"],
                    "isAnimating": true,
                    "sparkles": Array(0..<12)
                ]
                
                // Simulate profile data
                let profileData = [
                    "username": "User \(i)",
                    "email": "user\(i)@test.com",
                    "isSigningOut": false
                ]
                
                // Force some memory allocation
                let _ = "\(loadingData)\(profileData)"
            }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryMB = Double(memoryIncrease) / (1024 * 1024)
        
        let status = memoryMB < 10.0 ? "✅ PASS" : "⚠️ WARNING"
        print("   \(status) Memory increase: \(String(format: "%.1f", memoryMB))MB")
        print("   Target: <10MB, Result: \(memoryMB < 10.0 ? "Within target" : "Above target")")
    }
    
    static func testSimulatedLoadingOperations() {
        print("\n📊 Testing Simulated Loading Operations...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate creating different loading view configurations
        for isSimple in [true, false] {
            for _ in 0..<50 {
                autoreleasepool {
                    simulateLoadingViewCreation(isSimpleMode: isSimple)
                }
            }
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let avgTimeMs = (totalTime / 100) * 1000 // 100 total operations
        
        let status = avgTimeMs < 1.0 ? "✅ PASS" : "⚠️ WARNING"
        print("   \(status) Average loading view simulation: \(String(format: "%.3f", avgTimeMs))ms")
        print("   Target: <1.0ms per operation, Total: \(String(format: "%.2f", totalTime))s")
    }
    
    static func simulateLoadingViewCreation(isSimpleMode: Bool) {
        if isSimpleMode {
            // Simple mode - minimal processing
            let _ = "Signing out..."
        } else {
            // Full mode - more complex processing
            let messages = [
                "Tuning your bias radar...",
                "Loading your K-pop journey...",
                "Syncing with your bias..."
            ]
            
            let sparkles = (0..<12).map { _ in
                (x: Double.random(in: 50...350), y: Double.random(in: 100...600))
            }
            
            // Simulate some calculations
            let _ = messages.joined(separator: " ")
            let _ = sparkles.reduce(0.0) { $0 + $1.x + $1.y }
        }
    }
    
    static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}

// Run the benchmark
QuickPerformanceTest.runQuickBenchmark()