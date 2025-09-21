import Foundation
import Network

private final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    
    init() {}
    
    func exchange(_ newValue: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = value
        value = newValue
        return oldValue
    }
}

/// Centralized network manager for handling timeouts, connectivity, and network operations
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkManager")
    
    // MARK: - Timeout Configurations

    /// Standard timeout for most API requests (increased for iOS Simulator stability)
    static let standardTimeout: TimeInterval = 30.0

    /// Timeout for authentication requests
    static let authTimeout: TimeInterval = 25.0

    /// Timeout for quick data fetches (like artists list)
    static let quickFetchTimeout: TimeInterval = 35.0

    /// Timeout for file uploads/downloads
    static let uploadTimeout: TimeInterval = 60.0

    /// Timeout for RevenueCat operations
    static let revenueCatTimeout: TimeInterval = 20.0
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                if !path.status.isConnected {
                    print("📡 Network disconnected")
                } else {
                    print("📡 Network connected via \(self?.connectionType?.description ?? "unknown")")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - URLSession Configuration
    
    /// Create a configured URLSession with proper timeouts
    static func createURLSession(timeout: TimeInterval = standardTimeout) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.waitsForConnectivity = false // Don't wait indefinitely for connectivity
        config.allowsCellularAccess = true

        // Optimize for mobile networks
        config.httpMaximumConnectionsPerHost = 4
        config.requestCachePolicy = .useProtocolCachePolicy

        // Set reasonable limits
        config.httpCookieAcceptPolicy = .never

        // Handle QUIC/HTTP3 connectivity issues by forcing HTTP/2
        if #available(iOS 15.0, *) {
            // Allow HTTP/3 but fallback gracefully to HTTP/2
            config.allowsExpensiveNetworkAccess = true
            config.allowsConstrainedNetworkAccess = true

            // Disable HTTP/3 for iOS Simulator stability
            #if targetEnvironment(simulator)
            config.httpAdditionalHeaders = ["Connection": "keep-alive"]
            // Explicitly set protocolClasses to empty array to prevent any URLProtocol conflicts
            config.protocolClasses = []
            #endif
        }

        // Additional network stability settings
        config.networkServiceType = .default
        config.shouldUseExtendedBackgroundIdleMode = false

        // Force HTTP/1.1 connections for better simulator compatibility
        #if targetEnvironment(simulator)
        config.httpShouldUsePipelining = false
        config.httpShouldSetCookies = false
        #endif

        return URLSession(configuration: config)
    }
    
    // MARK: - Network Request Wrapper
    
    /// Perform network request with timeout and retry logic
    static func performRequest<T>(
        timeout: TimeInterval = standardTimeout,
        maxRetries: Int = 2,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        print("🔄 Starting network request (timeout: \(timeout)s, max retries: \(maxRetries))")
        
        for attempt in 0...maxRetries {
            do {
                print("🔍 Attempt \(attempt + 1)/\(maxRetries + 1)")
                return try await withTimeout(timeout: timeout) {
                    try await operation()
                }
            } catch {
                lastError = error
                
                // Analyze error type for better handling
                let networkError = NetworkManager.shared.handleNetworkError(error)
                
                // Don't retry on certain errors
                switch networkError {
                case .invalidCredentials:
                    print("🚫 Authentication error - not retrying")
                    throw error
                case .invalidURL:
                    print("🚫 Invalid URL error - not retrying")
                    throw error
                default:
                    break
                }
                
                if attempt < maxRetries {
                    // Exponential backoff with jitter to avoid thundering herd
                    let baseDelay = TimeInterval(pow(2.0, Double(attempt)))
                    let jitter = Double.random(in: 0.1...0.3)
                    let delay = baseDelay + jitter
                    
                    print("⚠️ Request failed (\(networkError.localizedDescription)), retrying in \(String(format: "%.1f", delay))s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    print("❌ Network request failed after \(maxRetries + 1) attempts: \(networkError.localizedDescription)")
                }
            }
        }
        
        throw lastError ?? NetworkError.requestFailed
    }
    
    /// Execute operation with timeout
    private static func withTimeout<T>(
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
                throw NetworkError.timeout
            }
            
            // Return first completed task and cancel others
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
    
    // MARK: - Connectivity Checks
    
    func checkConnectivity() async -> Bool {
        return await withCheckedContinuation { continuation in
            let hasResumed = AtomicBool()
            let probe = NWConnection(
                to: .hostPort(host: "1.1.1.1", port: 53),
                using: .udp
            )
            
            probe.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if !hasResumed.exchange(true) {
                        probe.cancel()
                        print("✅ Network connectivity confirmed")
                        continuation.resume(returning: true)
                    }
                case .failed(let error):
                    if !hasResumed.exchange(true) {
                        probe.cancel()
                        print("❌ Network connectivity failed: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                    }
                case .cancelled:
                    if !hasResumed.exchange(true) {
                        print("⚠️ Network connectivity check cancelled")
                        continuation.resume(returning: false)
                    }
                default:
                    break
                }
            }
            
            probe.start(queue: queue)
            
            // Reduced timeout to 2 seconds for faster failure detection
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                if !hasResumed.exchange(true) {
                    probe.cancel()
                    print("⏰ Network connectivity check timed out after 2 seconds")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Error Recovery
    
    func handleNetworkError(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost:
                return .noConnection
            case .cannotFindHost, .dnsLookupFailed:
                return .hostUnreachable
            case .badURL:
                return .invalidURL
            case .userAuthenticationRequired:
                return .invalidCredentials
            default:
                return .requestFailed
            }
        }
        
        return .unknown(error)
    }
}

// MARK: - Network Error Types

enum NetworkError: LocalizedError {
    case timeout
    case noConnection
    case hostUnreachable
    case invalidURL
    case invalidCredentials
    case requestFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .noConnection:
            return "No internet connection available."
        case .hostUnreachable:
            return "Server is unreachable. Please try again later."
        case .invalidURL:
            return "Invalid server URL."
        case .invalidCredentials:
            return "Authentication failed. Please check your credentials."
        case .requestFailed:
            return "Network request failed. Please try again."
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - NWInterface.InterfaceType Extension

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .other:
            return "Other"
        case .loopback:
            return "Loopback"
        @unknown default:
            return "Unknown"
        }
    }
}

extension NWPath.Status {
    var isConnected: Bool {
        return self == .satisfied
    }
}