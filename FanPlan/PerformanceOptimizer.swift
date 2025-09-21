import Foundation
import SwiftUI
import Combine

// MARK: - Performance Optimizer for UI Operations
/// Handles UI performance monitoring and optimization
final class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()

    @Published var uiPerformanceMetrics: [String: Double] = [:]
    @Published var warningThresholds: [String: Double] = [
        "screen_render": 1000.0,     // 1 second
        "data_load": 2000.0,         // 2 seconds
        "network_request": 5000.0,   // 5 seconds
        "heavy_computation": 500.0   // 0.5 seconds
    ]

    private var activeTraces: [String: Date] = [:]
    private let performanceQueue = DispatchQueue(label: "performance.monitoring", qos: .utility)

    private init() {}

    // MARK: - UI Performance Monitoring

    /// Start monitoring a UI operation
    func startUITrace(operation: String) -> String {
        let traceId = "\(operation)_\(UUID().uuidString.prefix(8))"

        performanceQueue.async { [weak self] in
            self?.activeTraces[traceId] = Date()
        }

        print("🚀 [Performance] Started: \(operation)")
        return traceId
    }

    /// Complete UI operation monitoring
    func completeUITrace(_ traceId: String, operation: String) {
        performanceQueue.async { [weak self] in
            guard let self = self,
                  let startTime = self.activeTraces.removeValue(forKey: traceId) else {
                return
            }

            let duration = Date().timeIntervalSince(startTime) * 1000 // milliseconds

            DispatchQueue.main.async {
                self.uiPerformanceMetrics[operation] = duration

                // Check for performance warnings
                if let threshold = self.warningThresholds[operation],
                   duration > threshold {
                    print("⚠️ [Performance Warning] \(operation): \(Int(duration))ms (threshold: \(Int(threshold))ms)")
                    self.reportPerformanceIssue(operation: operation, duration: duration, threshold: threshold)
                } else {
                    print("✅ [Performance] \(operation): \(Int(duration))ms")
                }
            }
        }
    }

    /// Monitor view rendering performance
    @MainActor
    func monitorViewRender<T: View>(_ view: T, name: String) -> some View {
        let traceId = startUITrace(operation: "screen_render")

        return view
            .onAppear {
                self.completeUITrace(traceId, operation: "screen_render_\(name)")
            }
            .task {
                // Monitor any async operations in the view
                let dataTraceId = self.startUITrace(operation: "data_load")

                // Simulate completion - views should call this when their data loads
                do {
                    self.completeUITrace(dataTraceId, operation: "data_load_\(name)")
                }
            }
    }

    // MARK: - Heavy Operation Optimization

    /// Execute heavy computation on background thread with performance monitoring
    func executeHeavyOperation<T>(
        operation: String,
        work: @escaping () async throws -> T
    ) async throws -> T {
        let traceId = startUITrace(operation: "heavy_computation")

        // Ensure work happens on background thread
        let result = try await Task.detached(priority: .userInitiated) {
            return try await work()
        }.value

        completeUITrace(traceId, operation: "heavy_computation_\(operation)")
        return result
    }

    /// Execute network operation with timeout and performance monitoring
    func executeNetworkOperation<T>(
        operation: String,
        timeout: TimeInterval = 10.0,
        work: @escaping () async throws -> T
    ) async throws -> T {
        let traceId = startUITrace(operation: "network_request")

        let result = try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                return try await work()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PerformanceError.timeout
            }

            guard let result = try await group.next() else {
                throw PerformanceError.operationFailed
            }

            group.cancelAll()
            return result
        }

        completeUITrace(traceId, operation: "network_request_\(operation)")
        return result
    }

    // MARK: - Performance Issue Reporting

    private func reportPerformanceIssue(operation: String, duration: Double, threshold: Double) {
        // Log to console for debugging
        print("""
        🔥 PERFORMANCE ISSUE DETECTED 🔥
        Operation: \(operation)
        Duration: \(Int(duration))ms
        Threshold: \(Int(threshold))ms
        Overage: \(Int(duration - threshold))ms
        """)

        // Optional: Report to external monitoring service
        // PerformanceService.shared.quickTrace(name: "performance_warning", attributes: [...])
    }

    // MARK: - Performance Analytics

    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            metrics: uiPerformanceMetrics,
            warningCount: uiPerformanceMetrics.filter { metric in
                guard let threshold = warningThresholds[metric.key] else { return false }
                return metric.value > threshold
            }.count,
            averageRenderTime: uiPerformanceMetrics
                .filter { $0.key.contains("screen_render") }
                .values
                .reduce(0, +) / Double(max(1, uiPerformanceMetrics.count))
        )
    }
}

// MARK: - Performance Error Types
enum PerformanceError: LocalizedError {
    case timeout
    case operationFailed

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Operation timed out"
        case .operationFailed:
            return "Operation failed to complete"
        }
    }
}

// MARK: - Performance Report
struct PerformanceReport {
    let metrics: [String: Double]
    let warningCount: Int
    let averageRenderTime: Double

    var isHealthy: Bool {
        return warningCount == 0 && averageRenderTime < 500.0
    }
}

// MARK: - SwiftUI Performance Extensions
extension View {
    /// Monitor the performance of this view
    func monitorPerformance(name: String) -> some View {
        PerformanceOptimizer.shared.monitorViewRender(self, name: name)
    }

    /// Execute heavy work in background with performance monitoring
    func withHeavyWork<T>(
        operation: String,
        work: @escaping () async throws -> T,
        onComplete: @escaping (T) -> Void,
        onError: @escaping (Error) -> Void
    ) -> some View {
        self.task {
            do {
                let result = try await PerformanceOptimizer.shared.executeHeavyOperation(
                    operation: operation,
                    work: work
                )
                await MainActor.run {
                    onComplete(result)
                }
            } catch {
                await MainActor.run {
                    onError(error)
                }
            }
        }
    }
}