import Foundation
import UIKit

/// Critical error boundary utilities to prevent app crashes
enum CrashPrevention {

    // MARK: - Safe URL Creation
    static func safeURL(from string: String?) -> URL? {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty,
              let url = URL(string: string) else {
            print("⚠️ CrashPrevention: Invalid URL string: '\(string ?? "nil")'")
            return nil
        }
        return url
    }

    // MARK: - Safe Array Access
    static func safeRandomElement<T>(from array: [T]) -> T? {
        guard !array.isEmpty else {
            print("⚠️ CrashPrevention: Attempted to get random element from empty array")
            return nil
        }
        return array.randomElement()
    }

    // MARK: - Safe Environment Variable Access
    static func safeEnvironmentVariable(_ key: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[key],
              !value.isEmpty,
              value != "$(ENVIRONMENT_VARIABLE_PLACEHOLDER)" else {
            print("⚠️ CrashPrevention: Missing or invalid environment variable: \(key)")
            return nil
        }
        return value
    }

    // MARK: - Safe Force Unwrapping Replacement
    static func safeUnwrap<T>(_ optional: T?, errorMessage: String, file: String = #file, line: Int = #line) throws -> T {
        guard let value = optional else {
            let error = NSError(domain: "CrashPrevention", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "\(errorMessage) at \(file):\(line)"
            ])
            print("🚨 CrashPrevention: \(errorMessage) at \(URL(fileURLWithPath: file).lastPathComponent):\(line)")
            throw error
        }
        return value
    }

    // MARK: - UI Error Boundaries
    static func withErrorBoundary<T>(
        operation: () throws -> T,
        fallback: T,
        errorContext: String
    ) -> T {
        do {
            return try operation()
        } catch {
            print("🛡️ Error boundary caught: \(errorContext) - \(error.localizedDescription)")

            // Log error for debugging
            print("📊 Error logged: \(error)")

            return fallback
        }
    }

    // MARK: - Async Error Boundaries
    static func withAsyncErrorBoundary<T>(
        operation: () async throws -> T,
        fallback: T,
        errorContext: String
    ) async -> T {
        do {
            return try await operation()
        } catch {
            print("🛡️ Async error boundary caught: \(errorContext) - \(error.localizedDescription)")

            // Log error for debugging
            print("📊 Error logged: \(error)")

            return fallback
        }
    }
}

// MARK: - Safe Extensions
extension Collection {
    /// Safe subscript that returns nil instead of crashing
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    /// Safe random element that won't crash on empty arrays
    var safeRandomElement: Element? {
        return CrashPrevention.safeRandomElement(from: self)
    }
}

extension String {
    /// Safe URL creation
    var safeURL: URL? {
        return CrashPrevention.safeURL(from: self)
    }
}