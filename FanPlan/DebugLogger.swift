import Foundation

/// Centralized debug logging with different levels and toggle control
enum DebugLogger {
    enum Level: String, CaseIterable {
        case verbose = "🔍"  // All details
        case info = "ℹ️"     // Important info
        case warning = "⚠️"  // Warnings
        case error = "❌"    // Errors only
        case success = "✅"  // Success messages
        case network = "🌐"  // Network calls
        case auth = "🔐"     // Authentication
        case data = "🗄️"     // Database operations
    }
    
    // MARK: - Configuration
    #if DEBUG
    static let isEnabled = true
    static let enabledLevels: Set<Level> = [.info, .warning, .error, .success, .network, .auth, .data]
    static let maxLogBufferSize = 100 // Keep recent logs for debugging
    // Remove .verbose from enabledLevels to reduce spam
    #else
    static let isEnabled = true // Enable for production crash analytics
    static let enabledLevels: Set<Level> = [.error, .warning] // Critical issues only
    static let maxLogBufferSize = 50 // Smaller buffer for production
    #endif
    
    // MARK: - Production Analytics
    private static var logBuffer: [(timestamp: Date, level: Level, message: String)] = []
    private static let bufferLock = NSLock()
    
    // Remote logging integration points
    static var crashlyticsLogger: ((String) -> Void)?
    static var analyticsLogger: ((String, [String: Any]) -> Void)?
    
    // MARK: - Logging Methods
    static func log(_ level: Level, _ message: String, function: String = #function, line: Int = #line) {
        guard isEnabled && enabledLevels.contains(level) else { return }
        
        let timestamp = Date()
        let prefix = level.rawValue
        let location = "\(function):\(line)"
        
        // Add to buffer for crash reporting
        bufferLock.lock()
        logBuffer.append((timestamp: timestamp, level: level, message: message))
        if logBuffer.count > maxLogBufferSize {
            logBuffer.removeFirst()
        }
        bufferLock.unlock()
        
        // Console logging
        let logMessage: String
        switch level {
        case .verbose:
            logMessage = "\(prefix) \(message)"
        case .info, .success, .network, .auth, .data:
            logMessage = "\(prefix) \(message)"
        case .warning, .error:
            logMessage = "\(prefix) [\(location)] \(message)"
        }
        
        print(logMessage)
        
        // Production integrations
        #if !DEBUG
        if level == .error {
            crashlyticsLogger?(logMessage)
            
            // Send to analytics with context
            analyticsLogger?("error_occurred", [
                "error_message": message,
                "function": function,
                "line": line,
                "timestamp": timestamp.timeIntervalSince1970
            ])
        }
        #endif
    }
    
    // Convenience methods
    static func verbose(_ message: String, function: String = #function, line: Int = #line) {
        log(.verbose, message, function: function, line: line)
    }
    
    static func info(_ message: String, function: String = #function, line: Int = #line) {
        log(.info, message, function: function, line: line)
    }
    
    static func warning(_ message: String, function: String = #function, line: Int = #line) {
        log(.warning, message, function: function, line: line)
    }
    
    static func error(_ message: String, function: String = #function, line: Int = #line) {
        log(.error, message, function: function, line: line)
    }
    
    static func success(_ message: String, function: String = #function, line: Int = #line) {
        log(.success, message, function: function, line: line)
    }
    
    static func network(_ message: String, function: String = #function, line: Int = #line) {
        log(.network, message, function: function, line: line)
    }
    
    static func auth(_ message: String, function: String = #function, line: Int = #line) {
        log(.auth, message, function: function, line: line)
    }
    
    static func data(_ message: String, function: String = #function, line: Int = #line) {
        log(.data, message, function: function, line: line)
    }
    
    // MARK: - Flow Tracing
    static func flowStart(_ flowName: String, function: String = #function) {
        info("🔄 START: \(flowName)")
    }
    
    static func flowEnd(_ flowName: String, success: Bool, function: String = #function) {
        if success {
            self.success("🔄 END: \(flowName) - SUCCESS")
        } else {
            error("🔄 END: \(flowName) - FAILED")
        }
    }
    
    // MARK: - Conditional Logging
    static func logIf(_ condition: Bool, level: Level, _ message: String, function: String = #function, line: Int = #line) {
        guard condition else { return }
        log(level, message, function: function, line: line)
    }
}

// MARK: - Extensions for Common Patterns
extension DebugLogger {
    /// Log validation results in a compact format
    static func logValidation(field: String, value: Any?, isValid: Bool) {
        let status = isValid ? "✅" : "❌"
        verbose("Validation \(status) \(field): \(value ?? "nil")")
    }
    
    /// Log network request/response in structured format
    static func logNetworkCall(url: String, method: String, statusCode: Int?, error: Error?) {
        if let error = error {
            self.error("Network \(method) \(url) failed: \(error.localizedDescription)")
        } else if let status = statusCode {
            if (200..<300).contains(status) {
                network("Network \(method) \(url) → \(status)")
            } else {
                warning("Network \(method) \(url) → \(status)")
            }
        }
    }
    
    // MARK: - Crash Reporting & Analytics
    static func getLogBuffer() -> [(timestamp: Date, level: Level, message: String)] {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return Array(logBuffer)
    }
    
    static func clearLogBuffer() {
        bufferLock.lock()
        logBuffer.removeAll()
        bufferLock.unlock()
    }
    
    static func exportLogBuffer() -> String {
        let buffer = getLogBuffer()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        return buffer.map { entry in
            let timeStr = dateFormatter.string(from: entry.timestamp)
            return "[\(timeStr)] \(entry.level.rawValue) \(entry.message)"
        }.joined(separator: "\n")
    }
    
    // Integration setup methods
    static func setupCrashlyticsIntegration(logger: @escaping (String) -> Void) {
        crashlyticsLogger = logger
    }
    
    static func setupAnalyticsIntegration(logger: @escaping (String, [String: Any]) -> Void) {
        analyticsLogger = logger
    }
}