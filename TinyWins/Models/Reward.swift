import Foundation

struct Reward: Identifiable, Codable, Equatable {
    let id: UUID
    let childId: UUID
    var name: String
    var targetPoints: Int
    var imageName: String?
    var isRedeemed: Bool // True when reward has been delivered to child
    var redeemedDate: Date? // When the reward was given to the child
    var createdDate: Date
    var priority: Int // Lower number = higher priority (shown first)
    
    // Time window properties
    var startDate: Date? // When the reward goal became active
    var dueDate: Date? // Optional deadline
    var autoResetOnExpire: Bool // If true, reduce progress when deadline passes
    
    // Progress tracking
    var progressReductionFactor: Double // Applied after soft reset (1.0 = no reduction)
    var frozenEarnedPoints: Int? // Locked in when redeemed or expired - stops further changes
    
    // Migration support: map old field names
    enum CodingKeys: String, CodingKey {
        case id, childId, name, targetPoints, imageName
        case isRedeemed = "isCompleted" // Map from old name
        case redeemedDate = "completedDate" // Map from old name
        case createdDate, priority, startDate, dueDate
        case autoResetOnExpire, progressReductionFactor, frozenEarnedPoints
    }
    
    init(
        id: UUID = UUID(),
        childId: UUID,
        name: String,
        targetPoints: Int,
        imageName: String? = nil,
        isRedeemed: Bool = false,
        redeemedDate: Date? = nil,
        createdDate: Date = Date(),
        priority: Int = 0,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        autoResetOnExpire: Bool = false,
        progressReductionFactor: Double = 1.0,
        frozenEarnedPoints: Int? = nil
    ) {
        self.id = id
        self.childId = childId
        self.name = name
        self.targetPoints = targetPoints
        self.imageName = imageName
        self.isRedeemed = isRedeemed
        self.redeemedDate = redeemedDate
        self.createdDate = createdDate
        self.priority = priority
        self.startDate = startDate ?? createdDate
        self.dueDate = dueDate
        self.autoResetOnExpire = autoResetOnExpire
        self.progressReductionFactor = progressReductionFactor
        self.frozenEarnedPoints = frozenEarnedPoints
    }
}

extension Reward {
    /// Calculate points earned within the reward's time window
    /// Returns frozen points if reward is redeemed (prevents further changes)
    func pointsEarnedInWindow(from events: [BehaviorEvent], isPrimaryReward: Bool = false) -> Int {
        // If redeemed, return frozen points (no more changes allowed)
        if isRedeemed, let frozen = frozenEarnedPoints {
            return frozen
        }
        
        let start = startDate ?? createdDate
        
        let filteredEvents = events.filter { event in
            guard event.childId == childId else { return false }
            guard event.timestamp >= start else { return false }
            guard event.pointsApplied > 0 else { return false } // Only positive points
            
            // Check reward assignment
            if let eventRewardId = event.rewardId {
                // Event is assigned to a specific reward - must match this one
                guard eventRewardId == id else { return false }
            } else {
                // Event has no specific reward - only count for primary reward
                guard isPrimaryReward else { return false }
            }
            
            if let end = dueDate {
                return event.timestamp <= end
            }
            return true
        }
        
        let rawPoints = filteredEvents.reduce(0) { $0 + max(0, $1.pointsApplied) }
        return Int(Double(rawPoints) * progressReductionFactor)
    }
    
    /// Progress towards the reward (0.0 to 1.0)
    func progress(from events: [BehaviorEvent], isPrimaryReward: Bool = false) -> Double {
        guard targetPoints > 0 else { return 0 }
        let earned = pointsEarnedInWindow(from: events, isPrimaryReward: isPrimaryReward)
        return min(max(Double(earned) / Double(targetPoints), 0), 1.0)
    }
    
    /// Points remaining to reach goal
    func pointsRemaining(from events: [BehaviorEvent], isPrimaryReward: Bool = false) -> Int {
        max(0, targetPoints - pointsEarnedInWindow(from: events, isPrimaryReward: isPrimaryReward))
    }
    
    /// Whether the reward is ready to be redeemed (convenience method)
    func isRedeemable(from events: [BehaviorEvent], isPrimaryReward: Bool = false) -> Bool {
        status(from: events, isPrimaryReward: isPrimaryReward) == .readyToRedeem
    }
    
    /// Whether the timed reward has expired
    var isExpired: Bool {
        guard let deadline = dueDate else { return false }
        return Date() > deadline && !isRedeemed
    }
    
    /// Whether this reward has a deadline
    var hasDeadline: Bool {
        dueDate != nil
    }
    
    /// Time remaining until deadline
    var timeRemaining: TimeInterval? {
        guard let deadline = dueDate else { return nil }
        let remaining = deadline.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }
    
    /// Formatted time remaining string
    var timeRemainingString: String? {
        guard let remaining = timeRemaining else { return nil }
        if remaining <= 0 { return "Expired" }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        
        return formatter.string(from: remaining)
    }
    
    /// Days remaining as integer
    var daysRemaining: Int? {
        guard let remaining = timeRemaining else { return nil }
        return Int(remaining / (24 * 60 * 60))
    }
    
    /// Formatted redeemed date string
    var redeemedDateString: String? {
        guard let date = redeemedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Status (Purely Data-Driven)
    
    /// Status of the reward - derived purely from data fields
    /// Priority: completed > expired > readyToRedeem > active
    func status(from events: [BehaviorEvent], isPrimaryReward: Bool = false) -> RewardStatus {
        // 1. Completed: reward has been delivered to the child
        if isRedeemed {
            return .completed
        }
        
        // 2. Expired: deadline passed and not redeemed
        if isExpired {
            return .expired
        }
        
        // 3. ReadyToRedeem: earned >= target and not redeemed and not expired
        let earned = pointsEarnedInWindow(from: events, isPrimaryReward: isPrimaryReward)
        if earned >= targetPoints {
            return .readyToRedeem
        }
        
        // 4. Active: working toward goal
        if hasDeadline {
            return .activeWithDeadline
        }
        return .active
    }
    
    /// Check if reward can accept more points (not redeemed and not expired)
    var canAcceptPoints: Bool {
        !isRedeemed && !isExpired
    }
    
    enum RewardStatus: String, Codable {
        case active
        case activeWithDeadline
        case readyToRedeem
        case completed
        case expired
        
        var displayName: String {
            switch self {
            case .active: return "Active"
            case .activeWithDeadline: return "Timed"
            case .readyToRedeem: return "Earned"
            case .completed: return "Completed"
            case .expired: return "Expired"
            }
        }
        
        var color: String {
            switch self {
            case .active: return "blue"
            case .activeWithDeadline: return "orange"
            case .readyToRedeem: return "green"
            case .completed: return "gray"
            case .expired: return "red"
            }
        }
        
        /// Whether this is a terminal state (no more actions possible)
        var isTerminal: Bool {
            self == .completed || self == .expired
        }
    }
    
    /// Apply soft reset - reduces progress by half and resets start date
    mutating func applySoftReset() {
        progressReductionFactor *= 0.5
        startDate = Date()
        dueDate = nil // Clear deadline after soft reset
    }
}

// MARK: - Preset Deadline Options
extension Reward {
    enum DeadlinePreset: CaseIterable, Identifiable {
        case none
        case oneDay
        case threeDays
        case oneWeek
        case twoWeeks
        case oneMonth
        case custom
        
        var id: String { displayName }
        
        var displayName: String {
            switch self {
            case .none: return "No Deadline"
            case .oneDay: return "1 Day"
            case .threeDays: return "3 Days"
            case .oneWeek: return "1 Week"
            case .twoWeeks: return "2 Weeks"
            case .oneMonth: return "1 Month"
            case .custom: return "Custom"
            }
        }
        
        func deadline(from startDate: Date = Date()) -> Date? {
            let calendar = Calendar.current
            switch self {
            case .none:
                return nil
            case .oneDay:
                return calendar.date(byAdding: .day, value: 1, to: startDate)
            case .threeDays:
                return calendar.date(byAdding: .day, value: 3, to: startDate)
            case .oneWeek:
                return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)
            case .twoWeeks:
                return calendar.date(byAdding: .weekOfYear, value: 2, to: startDate)
            case .oneMonth:
                return calendar.date(byAdding: .month, value: 1, to: startDate)
            case .custom:
                return nil
            }
        }
    }
}

// MARK: - Reward Icons
extension Reward {
    static let availableIcons: [String] = [
        "gift.fill", "star.fill", "trophy.fill", "medal.fill",
        "heart.fill", "crown.fill", "sparkles", "party.popper.fill",
        "gamecontroller.fill", "tv.fill", "movieclapper.fill", "ticket.fill",
        "bicycle", "car.fill", "airplane", "figure.play",
        "teddybear.fill", "puzzlepiece.fill", "paintpalette.fill", "music.note",
        "cup.and.saucer.fill", "fork.knife", "birthday.cake.fill", "leaf.fill",
        "dollarsign.circle.fill", "banknote.fill", "creditcard.fill", "bag.fill"
    ]
}
