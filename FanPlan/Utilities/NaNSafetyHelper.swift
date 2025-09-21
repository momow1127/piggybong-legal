import Foundation
import CoreGraphics

// MARK: - NaN Safety Helper
// Comprehensive utility to prevent CoreGraphics NaN errors

struct NaNSafetyHelper {

    // MARK: - CGFloat Safety

    /// Returns a safe CGFloat, replacing NaN/infinity with fallback
    static func safeCGFloat(_ value: CGFloat, fallback: CGFloat = 0) -> CGFloat {
        guard value.isFinite else { return fallback }
        return value
    }

    /// Returns a safe CGFloat for width calculations
    static func safeWidth(_ value: CGFloat, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        let safeValue = safeCGFloat(value)
        return max(0, min(safeValue, maxWidth))
    }

    /// Returns a safe CGFloat for height calculations
    static func safeHeight(_ value: CGFloat, maxHeight: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        let safeValue = safeCGFloat(value)
        return max(0, min(safeValue, maxHeight))
    }

    // MARK: - Division Safety

    /// Safe division that returns fallback if divisor is zero or result is invalid
    static func safeDivision(
        _ dividend: CGFloat,
        _ divisor: CGFloat,
        fallback: CGFloat = 0
    ) -> CGFloat {
        guard divisor != 0, dividend.isFinite, divisor.isFinite else {
            return fallback
        }
        let result = dividend / divisor
        return result.isFinite ? result : fallback
    }

    /// Safe percentage calculation (0.0 to 1.0)
    static func safePercentage(
        _ part: CGFloat,
        _ total: CGFloat,
        fallback: CGFloat = 0
    ) -> CGFloat {
        let percentage = safeDivision(part, total, fallback: fallback)
        return max(0, min(percentage, 1.0))
    }

    // MARK: - Animation Safety

    /// Returns safe animation progress (0.0 to 1.0)
    static func safeAnimationProgress(_ progress: CGFloat) -> CGFloat {
        let safeProgress = safeCGFloat(progress)
        return max(0, min(safeProgress, 1.0))
    }

    /// Returns safe scale effect value (prevents negative or extreme scales)
    static func safeScaleEffect(
        _ scale: CGFloat,
        minScale: CGFloat = 0.1,
        maxScale: CGFloat = 3.0
    ) -> CGFloat {
        let safeScale = safeCGFloat(scale, fallback: 1.0)
        return max(minScale, min(safeScale, maxScale))
    }

    // MARK: - Geometry Safety

    /// Returns safe frame size
    static func safeFrameSize(
        width: CGFloat,
        height: CGFloat,
        maxWidth: CGFloat = .greatestFiniteMagnitude,
        maxHeight: CGFloat = .greatestFiniteMagnitude
    ) -> (width: CGFloat, height: CGFloat) {
        return (
            width: safeWidth(width, maxWidth: maxWidth),
            height: safeHeight(height, maxHeight: maxHeight)
        )
    }

    /// Returns safe offset values
    static func safeOffset(
        x: CGFloat,
        y: CGFloat,
        maxOffset: CGFloat = 1000
    ) -> (x: CGFloat, y: CGFloat) {
        return (
            x: max(-maxOffset, min(safeCGFloat(x), maxOffset)),
            y: max(-maxOffset, min(safeCGFloat(y), maxOffset))
        )
    }

    // MARK: - Diagnostic Logging

    /// Logs NaN detection for debugging
    static func logNaNDetection(_ value: CGFloat, context: String = "Unknown") {
        if !value.isFinite {
            print("⚠️ NaN/Infinity detected in \(context): \(value)")
            if value.isNaN {
                print("   → Value is NaN (Not a Number)")
            } else if value.isInfinite {
                print("   → Value is Infinite")
            }
        }
    }

    /// Comprehensive validation for UI calculations
    static func validateUIValues(
        _ values: [String: CGFloat],
        context: String = "UI Calculation"
    ) -> Bool {
        var isValid = true
        for (key, value) in values {
            if !value.isFinite {
                print("❌ Invalid value in \(context): \(key) = \(value)")
                isValid = false
                logNaNDetection(value, context: "\(context).\(key)")
            }
        }
        return isValid
    }
}

// MARK: - CGFloat Extensions

extension CGFloat {
    /// Returns true if the value is finite (not NaN or infinite)
    var isSafeForUI: Bool {
        return self.isFinite
    }

    /// Returns a UI-safe version of this value
    func safeForUI(fallback: CGFloat = 0) -> CGFloat {
        return NaNSafetyHelper.safeCGFloat(self, fallback: fallback)
    }
}

// MARK: - Double Extensions

extension Double {
    /// Returns true if the value is finite (not NaN or infinite)
    var isSafeForUI: Bool {
        return self.isFinite
    }

    /// Returns a UI-safe version of this value
    func safeForUI(fallback: Double = 0) -> Double {
        guard self.isFinite else { return fallback }
        return self
    }
}