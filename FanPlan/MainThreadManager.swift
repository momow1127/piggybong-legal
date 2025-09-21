import UIKit
import SwiftUI

// MARK: - Main Thread Manager
/// Ensures all UI operations happen on the main thread
/// Prevents "Main Thread Checker: UI API called on a background thread" warnings
final class MainThreadManager {

    // MARK: - UI Thread Enforcement

    /// Execute UI code safely on main thread
    @MainActor
    static func runOnMainThread<T>(_ operation: @escaping () throws -> T) async rethrows -> T {
        return try operation()
    }

    /// Execute async UI code safely on main thread
    @MainActor
    static func runOnMainThread<T>(_ operation: @escaping () async throws -> T) async rethrows -> T {
        return try await operation()
    }

    /// Dispatch UI operation to main thread (legacy support)
    static func dispatchToMain<T>(_ operation: @escaping @Sendable () -> T, completion: @escaping @Sendable (T) -> Void) {
        DispatchQueue.main.async {
            let result = operation()
            completion(result)
        }
    }

    /// Check if currently on main thread
    static var isMainThread: Bool {
        return Thread.isMainThread
    }

    /// Assert main thread (for debugging)
    static func assertMainThread(file: String = #file, line: Int = #line) {
        assert(Thread.isMainThread, "⚠️ UI operation called on background thread at \(file):\(line)")
    }

    // MARK: - Google Sign-In Specific Helpers

    /// Get root view controller safely on main thread
    @MainActor
    static func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("❌ No active window scene found")
            return nil
        }

        // Get the root view controller
        var rootViewController = window.rootViewController

        // Navigate to the topmost presented view controller
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }

        return rootViewController
    }

    /// Get presenting view controller for Google Sign-In safely
    @MainActor
    static func getPresentingViewController() -> UIViewController? {
        assertMainThread()

        // Try to get the most appropriate presenting view controller
        if let rootVC = getRootViewController() {
            print("✅ Found presenting view controller: \(type(of: rootVC))")
            return rootVC
        }

        print("❌ Could not find suitable presenting view controller")
        return nil
    }
}

// MARK: - SwiftUI View Extensions
extension View {

    /// Ensure view operations happen on main thread
    func onMainThread() -> some View {
        self.onAppear {
            MainThreadManager.assertMainThread()
        }
    }

    /// Execute async operation with main thread UI updates
    func withMainThreadUpdates<T>(
        _ operation: @escaping () async throws -> T,
        onStart: (() -> Void)? = nil,
        onSuccess: @escaping (T) -> Void,
        onError: @escaping (Error) -> Void
    ) -> some View {
        self.task {
            // UI update on start
            if let onStart = onStart {
                await MainActor.run(body: onStart)
            }

            do {
                let result = try await operation()

                // UI update on success
                await MainActor.run {
                    onSuccess(result)
                }
            } catch {
                // UI update on error
                await MainActor.run {
                    onError(error)
                }
            }
        }
    }
}

// MARK: - UIViewController Extensions
extension UIViewController {

    /// Present view controller safely on main thread
    @MainActor
    func presentSafely(
        _ viewControllerToPresent: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        MainThreadManager.assertMainThread()
        present(viewControllerToPresent, animated: animated, completion: completion)
    }

    /// Dismiss view controller safely on main thread
    @MainActor
    func dismissSafely(
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        MainThreadManager.assertMainThread()
        dismiss(animated: animated, completion: completion)
    }
}

// MARK: - Error Prevention Helpers
extension MainThreadManager {

    /// Safely update Published properties on main thread
    @MainActor
    static func updatePublished<Object: ObservableObject, T>(_ keyPath: ReferenceWritableKeyPath<Object, T>, on object: Object, to value: T) {
        object[keyPath: keyPath] = value
    }

    /// Safely call completion handlers on main thread
    static func callCompletion<T>(_ completion: @escaping @Sendable (T) -> Void, with value: T) {
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async {
                completion(value)
            }
        }
    }

    /// Log thread violations for debugging
    static func logThreadViolation(operation: String, file: String = #file, line: Int = #line) {
        if !Thread.isMainThread {
            print("⚠️ THREAD VIOLATION: \(operation) called on background thread")
            print("   📁 File: \(URL(fileURLWithPath: file).lastPathComponent)")
            print("   📍 Line: \(line)")
            print("   🧵 Current thread: \(Thread.current)")
        }
    }
}