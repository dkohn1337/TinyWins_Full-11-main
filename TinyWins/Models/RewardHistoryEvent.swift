import Foundation

/// Tracks important reward milestone events for History display
struct RewardHistoryEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let childId: UUID
    let rewardId: UUID
    let rewardName: String
    let rewardIcon: String?
    let timestamp: Date
    let eventType: EventType
    let starsRequired: Int
    let starsEarnedAtEvent: Int
    
    enum EventType: String, Codable {
        case earned   // Goal reached, ready to redeem
        case given    // Reward delivered to child
        case expired  // Deadline passed before completion

        var displayName: String {
            switch self {
            case .earned: return "Earned"
            case .given: return "Complete"
            case .expired: return "Expired"
            }
        }
        
        var icon: String {
            switch self {
            case .earned: return "star.circle.fill"
            case .given: return "checkmark.circle.fill"
            case .expired: return "clock.badge.xmark.fill"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        childId: UUID,
        rewardId: UUID,
        rewardName: String,
        rewardIcon: String? = nil,
        timestamp: Date = Date(),
        eventType: EventType,
        starsRequired: Int,
        starsEarnedAtEvent: Int
    ) {
        self.id = id
        self.childId = childId
        self.rewardId = rewardId
        self.rewardName = rewardName
        self.rewardIcon = rewardIcon
        self.timestamp = timestamp
        self.eventType = eventType
        self.starsRequired = starsRequired
        self.starsEarnedAtEvent = starsEarnedAtEvent
    }
}

extension RewardHistoryEvent {
    func isFromToday(calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(timestamp)
    }
    
    func isInPeriod(_ period: TimePeriod) -> Bool {
        let range = period.dateRange
        return timestamp >= range.start && timestamp <= range.end
    }
}
