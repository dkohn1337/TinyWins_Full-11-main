import SwiftUI

// MARK: - Coach Mark Step Model

/// Represents a single step in a coach mark sequence
struct CoachMarkStep: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let icon: String
    let target: CoachMarkTarget

    static func == (lhs: CoachMarkStep, rhs: CoachMarkStep) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Coach Mark Target

/// Defines the UI element to spotlight
enum CoachMarkTarget: String {
    // Today tab targets
    case addButton = "addButton"
    case streakBadge = "streakBadge"
    case dailyFocusCard = "dailyFocusCard"
    case greetingCard = "greetingCard"

    // Kids tab targets
    case kidCard = "kidCard"
    case kidQuickAdd = "kidQuickAdd"

    // Goals tab targets
    case goalProgress = "goalProgress"
    case addGoalButton = "addGoalButton"

    // Insights tab targets
    case insightCard = "insightCard"

    // Tab bar targets
    case kidsTab = "kidsTab"
    case goalsTab = "goalsTab"
    case insightsTab = "insightsTab"
}

// MARK: - Coach Mark Sequence

/// Defines which sequences are available
enum CoachMarkSequence: String, CaseIterable {
    case today = "today"
    case kids = "kids"
    case goals = "goals"
    case insights = "insights"
}

// MARK: - Coach Mark Content

/// Static content definitions for all coach mark sequences
/// Language is warm, conversational, and speaks to overwhelmed parents
enum CoachMarkContent {

    // MARK: - Today Tab Sequence (Simplified to 2 key steps)

    static let todaySequence: [CoachMarkStep] = [
        CoachMarkStep(
            id: "today_notice",
            title: "Notice something good?",
            message: "Tap here to capture the moment. Even tiny wins count.",
            icon: "plus.circle.fill",
            target: .kidCard  // Point to the child card where they tap to log
        ),
        CoachMarkStep(
            id: "today_streak",
            title: "You're building a habit",
            message: "Just one moment a day keeps the streak going. No pressure.",
            icon: "flame.fill",
            target: .streakBadge
        ),
    ]

    // MARK: - Kids Tab Sequence (Keep for future, but disabled initially)

    static let kidsSequence: [CoachMarkStep] = [
        CoachMarkStep(
            id: "kids_card",
            title: "See their journey",
            message: "Tap to see stars earned and recent wins.",
            icon: "person.fill",
            target: .kidCard
        ),
    ]

    // MARK: - Goals Tab Sequence (Keep for future, but disabled initially)

    static let goalsSequence: [CoachMarkStep] = [
        CoachMarkStep(
            id: "goals_progress",
            title: "Watch progress grow",
            message: "Every star brings them closer to their goal.",
            icon: "star.fill",
            target: .goalProgress
        ),
    ]

    // MARK: - Insights Tab Sequence (Keep for future, but disabled initially)

    static let insightsSequence: [CoachMarkStep] = [
        CoachMarkStep(
            id: "insights_patterns",
            title: "Patterns emerge over time",
            message: "After a few days, you'll start seeing what works.",
            icon: "chart.line.uptrend.xyaxis",
            target: .insightCard
        ),
    ]

    // MARK: - Helper Methods

    static func sequence(for type: CoachMarkSequence) -> [CoachMarkStep] {
        switch type {
        case .today: return todaySequence
        case .kids: return kidsSequence
        case .goals: return goalsSequence
        case .insights: return insightsSequence
        }
    }
}
