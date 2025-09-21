import Foundation
import SwiftUI

// MARK: - High Traffic Handling Extensions
extension DatabaseService {
    
    // MARK: - Request Batching
    
    private actor BatchProcessor {
        private var pendingOperations: [() async throws -> Void] = []
        private var isProcessing = false
        
        func addOperation(_ operation: @escaping () async throws -> Void) {
            pendingOperations.append(operation)
            
            if !isProcessing {
                Task {
                    await processBatch()
                }
            }
        }
        
        private func processBatch() async {
            isProcessing = true
            defer { isProcessing = false }
            
            // Process operations in batches of 10
            while !pendingOperations.isEmpty {
                let batch = Array(pendingOperations.prefix(10))
                pendingOperations.removeFirst(min(10, pendingOperations.count))
                
                // Execute batch operations concurrently
                await withTaskGroup(of: Void.self) { group in
                    for operation in batch {
                        group.addTask {
                            do {
                                try await operation()
                            } catch {
                                print("❌ Batch operation failed: \(error)")
                            }
                        }
                    }
                }
                
                // Small delay to prevent overwhelming the server
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }
    
    private static let batchProcessor = BatchProcessor()
    
    // MARK: - Circuit Breaker Pattern
    
    private actor CircuitBreaker {
        private var failureCount = 0
        private var lastFailureTime: Date?
        private var state: State = .closed
        
        private enum State {
            case closed    // Normal operation
            case open      // Failing, reject requests
            case halfOpen  // Testing if service recovered
        }
        
        private let failureThreshold = 5
        private let recoveryTimeout: TimeInterval = 30
        
        func canExecute() -> Bool {
            switch state {
            case .closed:
                return true
            case .open:
                // Check if recovery timeout has passed
                if let lastFailure = lastFailureTime,
                   Date().timeIntervalSince(lastFailure) > recoveryTimeout {
                    state = .halfOpen
                    return true
                }
                return false
            case .halfOpen:
                return true
            }
        }
        
        func recordSuccess() {
            failureCount = 0
            state = .closed
            lastFailureTime = nil
        }
        
        func recordFailure() {
            failureCount += 1
            lastFailureTime = Date()
            
            if failureCount >= failureThreshold {
                state = .open
            } else if state == .halfOpen {
                state = .open
            }
        }
    }
    
    private static let circuitBreaker = CircuitBreaker()
    
    // MARK: - Enhanced Operations with High Traffic Support
    
    func fetchArtistsOptimized() async {
        // Check circuit breaker
        guard await Self.circuitBreaker.canExecute() else {
            print("⚡ Circuit breaker open - using cached artists")
            loadCachedArtists()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use batch processor for non-critical operations
            // Execute with performance measurement
            let fetchedArtists = try await measurePerformance(
                operation: { try await self.supabase.getArtists() },
                operationName: "fetchArtists"
            )
            
            await MainActor.run {
                self.artists = fetchedArtists
                print("✅ Optimized: Fetched \(fetchedArtists.count) artists")
            }
            
            // Cache the results
            await cacheArtists(fetchedArtists)
            await Self.circuitBreaker.recordSuccess()
        } catch {
            await Self.circuitBreaker.recordFailure()
            print("❌ Error fetching artists: \(error)")
            errorMessage = "Failed to load artists"
            loadCachedArtists()
        }
        
        isLoading = false
    }
    
    // MARK: - Smart Caching
    
    private func cacheArtists(_ artists: [Artist]) async {
        // Simple memory cache using UserDefaults for persistence
        do {
            let data = try JSONEncoder().encode(artists)
            UserDefaults.standard.set(data, forKey: "cached_artists")
            UserDefaults.standard.set(Date(), forKey: "artists_cache_time")
            print("💾 Cached \(artists.count) artists")
        } catch {
            print("❌ Failed to cache artists: \(error)")
        }
    }
    
    private func getCachedArtists() -> [Artist]? {
        // Check if cache is still valid (24 hours)
        if let cacheTime = UserDefaults.standard.object(forKey: "artists_cache_time") as? Date,
           Date().timeIntervalSince(cacheTime) > 24 * 60 * 60 {
            return nil
        }
        
        guard let data = UserDefaults.standard.data(forKey: "cached_artists") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode([Artist].self, from: data)
        } catch {
            print("❌ Failed to decode cached artists: \(error)")
            return nil
        }
    }
    
    private func loadCachedArtists() {
        if let cached = getCachedArtists() {
            self.artists = cached
            print("📱 Using cached artists (\(cached.count) artists)")
            return
        }
        
        // Final fallback to hardcoded artists
        if artists.isEmpty {
            artists = [
                Artist(name: "BTS", group: "BTS"),
                Artist(name: "BLACKPINK", group: "BLACKPINK"),
                Artist(name: "NewJeans", group: "NewJeans"),
                Artist(name: "Stray Kids", group: "Stray Kids"),
                Artist(name: "SEVENTEEN", group: "SEVENTEEN"),
                Artist(name: "i-dle", group: "i-dle"),
                Artist(name: "aespa", group: "aespa"),
                Artist(name: "ITZY", group: "ITZY"),
                Artist(name: "TWICE", group: "TWICE"),
                Artist(name: "Red Velvet", group: "Red Velvet")
            ]
            print("🔄 Using fallback artists (offline mode)")
        }
    }
    
    // MARK: - Rate Limiting
    
    private actor RateLimiter {
        private var requestTimes: [Date] = []
        private let maxRequests = 30 // requests per minute
        private let timeWindow: TimeInterval = 60
        
        func canMakeRequest() -> Bool {
            let now = Date()
            
            // Remove old requests outside the time window
            requestTimes = requestTimes.filter { now.timeIntervalSince($0) < timeWindow }
            
            if requestTimes.count < maxRequests {
                requestTimes.append(now)
                return true
            }
            
            return false
        }
        
        func timeUntilNextRequest() -> TimeInterval {
            guard let oldestRequest = requestTimes.first else {
                return 0
            }
            
            let timeSinceOldest = Date().timeIntervalSince(oldestRequest)
            return max(0, timeWindow - timeSinceOldest)
        }
    }
    
    private static let rateLimiter = RateLimiter()
    
    // MARK: - Enhanced Retry Logic
    
    func executeWithRetry<T>(
        _ operation: () async throws -> T,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            // Check rate limiting
            guard await Self.rateLimiter.canMakeRequest() else {
                let delay = await Self.rateLimiter.timeUntilNextRequest()
                print("⏱️ Rate limited, waiting \(delay) seconds")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
            
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if isNonRetryableError(error) {
                    throw error
                }
                
                if attempt < maxRetries - 1 {
                    // Exponential backoff with jitter
                    let delay = baseDelay * pow(2.0, Double(attempt)) * Double.random(in: 0.8...1.2)
                    print("🔄 Retry attempt \(attempt + 1) after \(delay) seconds")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? DatabaseError.networkError
    }
    
    private func isNonRetryableError(_ error: Error) -> Bool {
        // Don't retry on authentication or validation errors
        let errorString = error.localizedDescription.lowercased()
        return errorString.contains("unauthorized") ||
               errorString.contains("forbidden") ||
               errorString.contains("invalid") ||
               errorString.contains("not found")
    }
    
    // MARK: - Connection Health Monitoring
    
    func monitorConnectionHealth() {
        Task {
            while true {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                do {
                    // Simple health check
                    _ = try await self.supabase.getArtists()
                    await Self.circuitBreaker.recordSuccess()
                    print("💚 Connection health check: OK")
                } catch {
                    await Self.circuitBreaker.recordFailure()
                    print("💔 Connection health check: FAILED - \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Performance Metrics
    
    private struct PerformanceMetrics {
        static var requestCount = 0
        static var totalResponseTime: TimeInterval = 0
        static var errorCount = 0
        static var lastMetricReset = Date()
        
        static func recordRequest(responseTime: TimeInterval, success: Bool) {
            requestCount += 1
            totalResponseTime += responseTime
            
            if !success {
                errorCount += 1
            }
            
            // Reset metrics every hour
            if Date().timeIntervalSince(lastMetricReset) > 3600 {
                printMetrics()
                reset()
            }
        }
        
        static func printMetrics() {
            let avgResponseTime = requestCount > 0 ? totalResponseTime / Double(requestCount) : 0
            let errorRate = requestCount > 0 ? Double(errorCount) / Double(requestCount) * 100 : 0
            
            print("📊 Performance Metrics:")
            print("   • Requests: \(requestCount)")
            print("   • Avg Response: \(String(format: "%.2f", avgResponseTime))s")
            print("   • Error Rate: \(String(format: "%.1f", errorRate))%")
        }
        
        static func reset() {
            requestCount = 0
            totalResponseTime = 0
            errorCount = 0
            lastMetricReset = Date()
        }
    }
    
    func measurePerformance<T>(
        operation: () async throws -> T,
        operationName: String = "Unknown"
    ) async rethrows -> T {
        let startTime = Date()
        var success = true
        
        defer {
            let responseTime = Date().timeIntervalSince(startTime)
            PerformanceMetrics.recordRequest(responseTime: responseTime, success: success)
            
            if responseTime > 2.0 { // Warn on slow operations
                print("⚠️ Slow operation '\(operationName)': \(String(format: "%.2f", responseTime))s")
            }
        }
        
        do {
            return try await operation()
        } catch {
            success = false
            throw error
        }
    }
}

// MARK: - Usage Examples

extension DatabaseService {
    
    // Enhanced public methods that use high-traffic optimizations
    
    func initializeForProduction() {
        initialize()
        
        // Start health monitoring
        monitorConnectionHealth()
        
        // Use optimized artist loading
        Task {
            await fetchArtistsOptimized()
        }
        
        print("🚀 DatabaseService initialized for high-traffic production use")
    }
    
    func addPurchaseWithRetry(_ purchase: Purchase) async {
        do {
            try await executeWithRetry {
                await self.addPurchase(purchase)
            }
        } catch {
            print("❌ Failed to add purchase after retries: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to save purchase. Please try again."
            }
        }
    }
}