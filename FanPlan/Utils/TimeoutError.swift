import Foundation

/// A simple timeout error for network operations and async tasks
struct TimeoutError: Error {
    var localizedDescription: String {
        return "Operation timed out"
    }
}