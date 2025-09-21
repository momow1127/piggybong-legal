import Foundation
import SwiftUI

// MARK: - Network Retry Service
class NetworkRetryService {
    static let shared = NetworkRetryService()
    private init() {}
    
    // MARK: - Retry Configuration
    struct RetryConfig {
        let maxAttempts: Int
        let baseDelay: TimeInterval
        let maxDelay: TimeInterval
        
        static let `default` = RetryConfig(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 8.0
        )
    }
    
    // MARK: - Retry Result
    enum RetryResult<T> {
        case success(T)
        case failure(Error, totalAttempts: Int)
    }
    
    // MARK: - Loading State
    enum LoadingState {
        case idle
        case saving
        case retrying(attempt: Int, total: Int)
        
        var isLoading: Bool {
            switch self {
            case .idle: return false
            case .saving, .retrying: return true
            }
        }
        
        var displayText: String {
            switch self {
            case .idle: return ""
            case .saving: return "Saving..."
            case .retrying(let attempt, let total):
                return "Retrying... (\(attempt)/\(total))"
            }
        }
    }
    
    // MARK: - Network Error Classification
    private func isRetryableError(_ error: Error) -> Bool {
        // Handle URLError (most common network errors)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .networkConnectionLost,
                 .notConnectedToInternet,
                 .timedOut,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .internationalRoamingOff,
                 .callIsActive,
                 .dataNotAllowed,
                 .requestBodyStreamExhausted:
                return true
            default:
                return false
            }
        }
        
        // Handle NSError with network-related domains
        if let nsError = error as NSError? {
            switch nsError.domain {
            case NSURLErrorDomain:
                return isRetryableURLErrorCode(nsError.code)
            case "NSPOSIXErrorDomain":
                // POSIX errors like connection refused, network unreachable
                return nsError.code == 61 || nsError.code == 51
            default:
                return false
            }
        }
        
        // Don't retry Supabase-specific errors (auth, validation, constraints)
        let errorDescription = error.localizedDescription.lowercased()
        let nonRetryableKeywords = [
            "unauthorized", "forbidden", "invalid", "constraint",
            "duplicate", "unique", "validation", "permission"
        ]
        
        return !nonRetryableKeywords.contains { errorDescription.contains($0) }
    }
    
    private func isRetryableURLErrorCode(_ code: Int) -> Bool {
        let retryableCodes = [
            -1005, // networkConnectionLost
            -1009, // notConnectedToInternet  
            -1001, // timedOut
            -1004, // cannotConnectToHost
            -1003, // cannotFindHost
            -1006, // dnsLookupFailed
            -1018, // internationalRoamingOff
            -1019, // callIsActive
            -1020, // dataNotAllowed
            -1021  // requestBodyStreamExhausted
        ]
        return retryableCodes.contains(code)
    }
    
    // MARK: - Exponential Backoff Calculation
    private func calculateDelay(attempt: Int, config: RetryConfig) -> TimeInterval {
        let exponentialDelay = config.baseDelay * pow(2.0, Double(attempt - 1))
        return min(exponentialDelay, config.maxDelay)
    }
    
    // MARK: - Generic Retry Function
    func retryAsync<T>(
        config: RetryConfig = .default,
        onStateChange: @escaping (LoadingState) -> Void = { _ in },
        operation: @escaping () async throws -> T
    ) async -> RetryResult<T> {
        
        onStateChange(.saving)
        
        var lastError: Error?
        
        for attempt in 1...config.maxAttempts {
            do {
                if attempt > 1 {
                    onStateChange(.retrying(attempt: attempt, total: config.maxAttempts))
                }
                
                let result = try await operation()
                onStateChange(.idle)
                return .success(result)
                
            } catch {
                lastError = error
                
                // Don't retry if it's not a network error
                guard isRetryableError(error) else {
                    onStateChange(.idle)
                    return .failure(error, totalAttempts: attempt)
                }
                
                // Don't delay after the last attempt
                if attempt < config.maxAttempts {
                    let delay = calculateDelay(attempt: attempt, config: config)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        onStateChange(.idle)
        return .failure(lastError ?? NetworkRetryError.unknownError, totalAttempts: config.maxAttempts)
    }
}

// MARK: - Custom Errors
enum NetworkRetryError: LocalizedError {
    case unknownError
    case maxAttemptsExceeded(attempts: Int)
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred"
        case .maxAttemptsExceeded(let attempts):
            return "Failed after \(attempts) attempts. Please check your connection and try again."
        }
    }
}

// MARK: - SwiftUI Integration Extensions
extension NetworkRetryService.LoadingState {
    var buttonTitle: String {
        switch self {
        case .idle: return "Save Activity"
        case .saving: return "Saving..."
        case .retrying(let attempt, let total): return "Retrying (\(attempt)/\(total))"
        }
    }
}