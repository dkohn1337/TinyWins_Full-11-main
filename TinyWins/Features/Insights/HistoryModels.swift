import Foundation

/// Filter types for history display
enum HistoryTypeFilter: String, CaseIterable {
    case allMoments = "All"
    case positiveOnly = "Positive"
    case challengesOnly = "Challenges"
    case goalsOnly = "Goals"

    var icon: String? {
        switch self {
        case .allMoments: return nil
        case .positiveOnly: return "hand.thumbsup.fill"
        case .challengesOnly: return "exclamationmark.triangle.fill"
        case .goalsOnly: return "flag.fill"
        }
    }
}

/// Unified history item that can represent either a behavior event or reward event
enum HistoryItem: Identifiable {
    case behavior(BehaviorEvent)
    case reward(RewardHistoryEvent)

    var id: UUID {
        switch self {
        case .behavior(let event): return event.id
        case .reward(let event): return event.id
        }
    }

    var timestamp: Date {
        switch self {
        case .behavior(let event): return event.timestamp
        case .reward(let event): return event.timestamp
        }
    }

    var childId: UUID {
        switch self {
        case .behavior(let event): return event.childId
        case .reward(let event): return event.childId
        }
    }
}
