import Foundation

// MARK: - Date Decoding Manager
/// Handles robust ISO8601 date decoding for Supabase responses
/// Supports multiple date formats commonly used by Supabase/PostgreSQL
final class DateDecodingManager {

    // MARK: - Date Formatters

    /// Primary ISO8601 formatter with fractional seconds
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Fallback ISO8601 formatter without fractional seconds
    static let iso8601Standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// PostgreSQL timestamp formatter (no timezone)
    static let postgresTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// PostgreSQL timestamp with timezone
    static let postgresTimestampWithTimezone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS+HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - Universal Date Decoder

    /// Attempts to decode a date string using multiple common formats
    /// This handles the variety of date formats that Supabase might return
    static func decodeDate(from dateString: String) -> Date? {
        print("🗓️ Attempting to decode date string: '\(dateString)'")

        // Remove quotes if present
        let cleanDateString = dateString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        // Try each formatter in order of likelihood
        let formatters: [(String, (String) -> Date?)] = [
            ("ISO8601 with fractional seconds", { iso8601WithFractionalSeconds.date(from: $0) }),
            ("ISO8601 standard", { iso8601Standard.date(from: $0) }),
            ("PostgreSQL timestamp with timezone", { postgresTimestampWithTimezone.date(from: $0) }),
            ("PostgreSQL timestamp", { postgresTimestamp.date(from: $0) })
        ]

        for (name, formatter) in formatters {
            if let date = formatter(cleanDateString) {
                print("✅ Successfully decoded date using \(name): \(date)")
                return date
            }
        }

        print("❌ Failed to decode date string: '\(cleanDateString)'")
        print("🔍 Consider adding support for this format")
        return nil
    }

    /// Creates a custom JSONDecoder configured for Supabase date formats
    static func createSupabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        // Configure date decoding strategy
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            guard let date = decodeDate(from: dateString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unable to decode date from string: '\(dateString)'. Supported formats: ISO8601 with/without fractional seconds, PostgreSQL timestamps."
                    )
                )
            }

            return date
        }

        // Configure key decoding strategy for snake_case
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }

    /// Inspects a JSON response to show actual date format
    /// Use this for debugging when you encounter new date formats
    static func inspectDateFormats(in jsonData: Data) {
        print("🔍 Inspecting JSON for date patterns...")

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Could not convert data to string")
            return
        }

        // Look for common date patterns
        let datePatterns = [
            "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d+Z",        // ISO8601 with fractional seconds
            "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z",               // ISO8601 standard
            "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d+",         // PostgreSQL with fractional
            "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"                 // PostgreSQL standard
        ]

        for pattern in datePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: jsonString, range: NSRange(jsonString.startIndex..., in: jsonString))

                if !matches.isEmpty {
                    print("📅 Found date pattern: \(pattern)")
                    for match in matches.prefix(3) { // Show first 3 matches
                        let range = Range(match.range, in: jsonString)!
                        print("   Example: \(jsonString[range])")
                    }
                }
            } catch {
                print("❌ Regex error: \(error)")
            }
        }
    }
}

// MARK: - Extension for Easy Usage
extension SupabaseService {

    /// Get a properly configured decoder for Supabase responses
    var decoder: JSONDecoder {
        return DateDecodingManager.createSupabaseDecoder()
    }

    /// Decode response with enhanced error information
    func decodeSupabaseResponse<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            print("❌ Data corruption error: \(context.debugDescription)")
            print("📋 Coding path: \(context.codingPath)")

            // Show raw data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Raw JSON: \(jsonString.prefix(500))...")
            }

            // Inspect date formats
            DateDecodingManager.inspectDateFormats(in: data)

            throw DecodingError.dataCorrupted(context)
        } catch {
            print("❌ General decoding error: \(error)")
            throw error
        }
    }
}