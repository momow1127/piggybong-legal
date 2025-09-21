import Foundation

extension Double {
    /// Formats the double as a currency string
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // TODO: Make this configurable based on user preference
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    /// Formats the double as a currency string without the currency symbol
    var currencyStringWithoutSymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "0.00"
    }
    
    /// Formats the double as a percentage
    var percentageString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "0%"
    }
    
    /// Rounds the double to a specified number of decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Returns true if the value is positive
    var isPositive: Bool {
        return self > 0
    }
    
    /// Returns true if the value is negative
    var isNegative: Bool {
        return self < 0
    }
    
    /// Returns the absolute value
    var absolute: Double {
        return abs(self)
    }
    
    /// Clamps the value between a minimum and maximum
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}