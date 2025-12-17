import Foundation

// MARK: - Insight Copy Helper

/// Centralized helper for generating consistent insight card copy
/// Reduces duplication and ensures uniform language across cards
struct InsightCopyHelper {

    /// Minimum sample count for confident patterns
    static let confidenceThreshold = 5

    /// Generates footer text based on sample count
    /// - Parameter sampleCount: Number of moments/data points
    /// - Returns: Appropriate footer string
    static func footerText(sampleCount: Int) -> String {
        if sampleCount < confidenceThreshold {
            return "Early pattern from \(sampleCount) moments"
        } else {
            return "Based on \(sampleCount) moments"
        }
    }

    /// Generates footer text with period context
    /// - Parameters:
    ///   - sampleCount: Number of moments/data points
    ///   - period: Time period description (e.g., "this week")
    /// - Returns: Appropriate footer string with period
    static func footerText(sampleCount: Int, period: String) -> String {
        if sampleCount < confidenceThreshold {
            return "Early pattern from \(sampleCount) moments"
        } else {
            return "Based on \(sampleCount) moments \(period)"
        }
    }
}
