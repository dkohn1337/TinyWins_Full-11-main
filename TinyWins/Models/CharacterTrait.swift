import SwiftUI

// MARK: - CharacterTrait

/// Character traits that behaviors can map to.
/// Used for Growth Rings visualization to show character development over time.
enum CharacterTrait: String, CaseIterable, Codable, Identifiable {
    case kindness
    case courage
    case patience
    case responsibility
    case creativity
    case resilience

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .kindness: return "Kindness"
        case .courage: return "Courage"
        case .patience: return "Patience"
        case .responsibility: return "Responsibility"
        case .creativity: return "Creativity"
        case .resilience: return "Resilience"
        }
    }

    var description: String {
        switch self {
        case .kindness:
            return "Showing empathy, sharing, and helping others"
        case .courage:
            return "Trying new things and speaking up"
        case .patience:
            return "Waiting calmly and handling frustration"
        case .responsibility:
            return "Taking care of tasks and self"
        case .creativity:
            return "Using imagination and problem-solving"
        case .resilience:
            return "Bouncing back from setbacks"
        }
    }

    var icon: String {
        switch self {
        case .kindness: return "heart.fill"
        case .courage: return "flame.fill"
        case .patience: return "clock.fill"
        case .responsibility: return "checkmark.shield.fill"
        case .creativity: return "lightbulb.fill"
        case .resilience: return "arrow.up.heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .kindness: return Color(red: 0.3, green: 0.75, blue: 0.4) // Green
        case .courage: return Color(red: 1.0, green: 0.55, blue: 0.2) // Orange
        case .patience: return Color(red: 0.35, green: 0.55, blue: 0.9) // Blue
        case .responsibility: return Color(red: 0.6, green: 0.4, blue: 0.85) // Purple
        case .creativity: return Color(red: 0.95, green: 0.45, blue: 0.6) // Pink
        case .resilience: return Color(red: 0.3, green: 0.7, blue: 0.7) // Teal
        }
    }

    // MARK: - Behavior Mapping

    /// Keywords that indicate this trait in behavior names.
    /// Used for auto-mapping behaviors to traits.
    var relatedKeywords: [String] {
        switch self {
        case .kindness:
            return [
                "share", "shared", "sharing",
                "help", "helped", "helping",
                "kind", "kindness",
                "empathy", "empathetic",
                "include", "included",
                "compliment", "nice", "friendly",
                "sibling", "others",
                "care", "caring"
            ]
        case .courage:
            return [
                "try", "tried", "new",
                "brave", "bravery",
                "speak", "spoke up",
                "fear", "faced",
                "ask", "asked",
                "admit", "admitted",
                "mistake", "first time"
            ]
        case .patience:
            return [
                "wait", "waited", "waiting", "patient", "patience",
                "calm", "calmly",
                "turn", "turns",
                "listen", "listening",
                "interrupt", "frustration",
                "frustrated"
            ]
        case .responsibility:
            return [
                "routine", "morning", "bedtime",
                "homework", "chore", "chores",
                "clean", "cleaned", "room",
                "brush", "teeth",
                "bed", "made",
                "put away", "feed", "fed",
                "pet", "complete", "completed"
            ]
        case .creativity:
            return [
                "creative", "creativity",
                "art", "draw", "drew", "drawing",
                "build", "built",
                "imagine", "imagination",
                "solve", "solved", "problem",
                "play", "pretend"
            ]
        case .resilience:
            return [
                "kept trying", "try again",
                "failure", "bounce", "bounced",
                "disappoint", "disappointed",
                "accept", "accepted", "no",
                "gracefully", "recover", "recovered",
                "tantrum", "persist"
            ]
        }
    }

    /// Check if a behavior name matches this trait.
    /// - Parameter behaviorName: The name of the behavior to check
    /// - Returns: True if the behavior matches this trait
    func matches(behaviorName: String) -> Bool {
        let lowercased = behaviorName.lowercased()
        return relatedKeywords.contains { keyword in
            lowercased.contains(keyword)
        }
    }

    /// Get all traits that match a behavior name.
    /// - Parameter behaviorName: The name of the behavior
    /// - Returns: Array of matching traits (usually 1-2)
    static func traitsFor(behaviorName: String) -> [CharacterTrait] {
        CharacterTrait.allCases.filter { $0.matches(behaviorName: behaviorName) }
    }
}

// MARK: - Trait Score

/// Represents a trait's score for a specific time period.
struct TraitScore: Identifiable, Equatable {
    let id = UUID()
    let trait: CharacterTrait
    let score: Double // 0-100 normalized score
    let eventCount: Int
    let totalPoints: Int

    var color: Color { trait.color }
    var displayName: String { trait.displayName }
}

// MARK: - Trait Trend

/// Represents how a trait has changed over time.
struct TraitTrend: Identifiable {
    let id = UUID()
    let trait: CharacterTrait
    let currentScore: Double
    let previousScore: Double
    let isGrowing: Bool

    var percentChange: Double {
        guard previousScore > 0 else { return currentScore > 0 ? 100 : 0 }
        return ((currentScore - previousScore) / previousScore) * 100
    }

    var trendIcon: String {
        if percentChange > 10 {
            return "arrow.up.right"
        } else if percentChange < -10 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
}

// MARK: - Default Behavior Trait Mappings

extension CharacterTrait {

    /// Predefined mappings for common default behaviors.
    /// This supplements the keyword-based auto-mapping for accuracy.
    static let defaultBehaviorMappings: [String: [CharacterTrait]] = [
        // Kindness behaviors
        "Shared toys/items": [.kindness],
        "Helped sibling": [.kindness],
        "Said kind words": [.kindness],
        "Showed empathy": [.kindness],
        "Included others": [.kindness],
        "Gave compliment": [.kindness],

        // Courage behaviors
        "Tried something new": [.courage],
        "Spoke up for self": [.courage],
        "Faced a fear": [.courage],
        "Asked for help": [.courage],
        "Admitted mistake": [.courage, .responsibility],

        // Patience behaviors
        "Waited patiently": [.patience],
        "Stayed calm when upset": [.patience, .resilience],
        "Took turns": [.patience, .kindness],
        "Listened without interrupting": [.patience],
        "Handled frustration well": [.patience, .resilience],

        // Responsibility behaviors
        "Morning routine completed": [.responsibility],
        "Bedtime routine completed": [.responsibility],
        "Homework completed": [.responsibility],
        "Cleaned room": [.responsibility],
        "Brushed teeth": [.responsibility],
        "Made bed": [.responsibility],
        "Put away toys": [.responsibility],
        "Fed pet": [.responsibility, .kindness],

        // Creativity behaviors
        "Creative play": [.creativity],
        "Art project": [.creativity],
        "Built something": [.creativity],
        "Solved problem creatively": [.creativity, .resilience],
        "Used imagination": [.creativity],

        // Resilience behaviors
        "Kept trying after failure": [.resilience, .courage],
        "Bounced back from disappointment": [.resilience],
        "Accepted 'no' gracefully": [.resilience, .patience],
        "Recovered from tantrum quickly": [.resilience, .patience]
    ]

    /// Get traits for a behavior, using predefined mappings first, then auto-mapping.
    /// - Parameter behaviorName: The name of the behavior
    /// - Returns: Array of traits (1-2 typically)
    static func traitsForBehavior(_ behaviorName: String) -> [CharacterTrait] {
        // First check predefined mappings
        if let traits = defaultBehaviorMappings[behaviorName] {
            return traits
        }

        // Fall back to keyword auto-mapping
        let autoMapped = traitsFor(behaviorName: behaviorName)
        if !autoMapped.isEmpty {
            return Array(autoMapped.prefix(2)) // Limit to 2 traits
        }

        // Default to responsibility for routine behaviors, kindness for others
        if behaviorName.lowercased().contains("routine") {
            return [.responsibility]
        }

        return []
    }
}
