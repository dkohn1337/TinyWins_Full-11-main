import Foundation

/// Media attachment type for behavior events
struct MediaAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    var fileName: String
    var mediaType: MediaType
    var localPath: String // Relative path in app's documents directory
    var thumbnailPath: String? // For videos
    var createdAt: Date
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    init(
        id: UUID = UUID(),
        fileName: String,
        mediaType: MediaType,
        localPath: String,
        thumbnailPath: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.mediaType = mediaType
        self.localPath = localPath
        self.thumbnailPath = thumbnailPath
        self.createdAt = createdAt
    }
}

struct BehaviorEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let childId: UUID
    let behaviorTypeId: UUID
    let timestamp: Date
    let pointsApplied: Int
    var note: String? // Optional note from parent
    var mediaAttachments: [MediaAttachment] // Photos/videos
    var earnedAllowance: Double? // Money earned for this event
    var rewardId: UUID? // Which reward these points go toward (nil = primary/all rewards)

    // MARK: - Co-Parent Tracking (NEW)
    var loggedByParentId: String? // Firebase UID or local ID of parent who logged this
    var loggedByParentName: String? // Denormalized name for display without lookup

    init(
        id: UUID = UUID(),
        childId: UUID,
        behaviorTypeId: UUID,
        timestamp: Date = Date(),
        pointsApplied: Int,
        note: String? = nil,
        mediaAttachments: [MediaAttachment] = [],
        earnedAllowance: Double? = nil,
        rewardId: UUID? = nil,
        loggedByParentId: String? = nil,
        loggedByParentName: String? = nil
    ) {
        self.id = id
        self.childId = childId
        self.behaviorTypeId = behaviorTypeId
        self.timestamp = timestamp
        self.pointsApplied = pointsApplied
        self.note = note
        self.mediaAttachments = mediaAttachments
        self.earnedAllowance = earnedAllowance
        self.rewardId = rewardId
        self.loggedByParentId = loggedByParentId
        self.loggedByParentName = loggedByParentName
    }
}

// MARK: - Migration Support for Co-Parent Fields

extension BehaviorEvent {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        childId = try container.decode(UUID.self, forKey: .childId)
        behaviorTypeId = try container.decode(UUID.self, forKey: .behaviorTypeId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        pointsApplied = try container.decode(Int.self, forKey: .pointsApplied)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        mediaAttachments = try container.decodeIfPresent([MediaAttachment].self, forKey: .mediaAttachments) ?? []
        earnedAllowance = try container.decodeIfPresent(Double.self, forKey: .earnedAllowance)
        rewardId = try container.decodeIfPresent(UUID.self, forKey: .rewardId)

        // New optional fields with migration support
        loggedByParentId = try container.decodeIfPresent(String.self, forKey: .loggedByParentId)
        loggedByParentName = try container.decodeIfPresent(String.self, forKey: .loggedByParentName)
    }
}

extension BehaviorEvent {
    var isPositive: Bool {
        pointsApplied >= 0
    }

    func isFromToday(calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(timestamp)
    }

    func isFrom(date: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(timestamp, inSameDayAs: date)
    }

    var hasMedia: Bool {
        !mediaAttachments.isEmpty
    }

    // MARK: - Co-Parent Helpers

    /// Whether this event was logged by a specific parent
    func wasLoggedBy(parentId: String) -> Bool {
        loggedByParentId == parentId
    }

    /// Display name for who logged this event
    var loggedByDisplayName: String {
        loggedByParentName ?? "Unknown"
    }

    /// Whether we know who logged this event
    var hasParentAttribution: Bool {
        loggedByParentId != nil
    }

    /// Create a copy with parent attribution
    func withParentAttribution(parentId: String, parentName: String) -> BehaviorEvent {
        var copy = self
        copy.loggedByParentId = parentId
        copy.loggedByParentName = parentName
        return copy
    }
}

// MARK: - Time Period Filter
enum TimePeriod: String, CaseIterable, Identifiable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth
    case last3Months
    case last6Months
    case lastYear
    case allTime
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .lastWeek: return "Last Week"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last3Months: return "Last 3 Months"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Past 12 Months"
        case .allTime: return "All Time"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "Week"
        case .lastWeek: return "Last Week"
        case .thisMonth: return "Month"
        case .lastMonth: return "Last Month"
        case .last3Months: return "3 Months"
        case .last6Months: return "6 Months"
        case .lastYear: return "Year"
        case .allTime: return "All"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        switch self {
        case .today:
            return (startOfToday, now)
            
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            return (yesterday, startOfToday)
            
        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (startOfWeek, now)
            
        case .lastWeek:
            let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek)!
            return (startOfLastWeek, startOfThisWeek)
            
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (startOfMonth, now)
            
        case .lastMonth:
            let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
            return (startOfLastMonth, startOfThisMonth)
            
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return (threeMonthsAgo, now)
            
        case .last6Months:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return (sixMonthsAgo, now)
            
        case .lastYear:
            let oneYearAgo = calendar.date(byAdding: .month, value: -12, to: now)!
            return (oneYearAgo, now)
            
        case .allTime:
            // Return a very old date for "all time"
            let distantPast = calendar.date(byAdding: .year, value: -100, to: now)!
            return (distantPast, now)
        }
    }
}
