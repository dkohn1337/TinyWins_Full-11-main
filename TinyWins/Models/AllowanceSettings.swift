import Foundation

/// Global allowance settings for the family
struct AllowanceSettings: Codable, Equatable {
    var isEnabled: Bool
    var currencyCode: String
    var pointsPerUnitCurrency: Double // e.g., 10 points = $1
    
    init(
        isEnabled: Bool = false,
        currencyCode: String = "USD",
        pointsPerUnitCurrency: Double = 10
    ) {
        self.isEnabled = isEnabled
        self.currencyCode = currencyCode
        self.pointsPerUnitCurrency = pointsPerUnitCurrency
    }
    
    /// Convert points to money
    func pointsToMoney(_ points: Int) -> Double {
        guard pointsPerUnitCurrency > 0 else { return 0 }
        return Double(points) / pointsPerUnitCurrency
    }
    
    /// Convert money to points
    func moneyToPoints(_ money: Double) -> Int {
        Int(money * pointsPerUnitCurrency)
    }
    
    /// Format money amount with currency symbol
    func formatMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(String(format: "%.2f", amount))"
    }
    
    /// Currency symbol for display
    var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode]))
        return locale.currencySymbol ?? "$"
    }
    
    /// Common currency options
    static let commonCurrencies: [(code: String, name: String)] = [
        ("USD", "US Dollar"),
        ("EUR", "Euro"),
        ("GBP", "British Pound"),
        ("ILS", "Israeli Shekel"),
        ("CAD", "Canadian Dollar"),
        ("AUD", "Australian Dollar"),
        ("JPY", "Japanese Yen"),
        ("CHF", "Swiss Franc"),
        ("CNY", "Chinese Yuan"),
        ("INR", "Indian Rupee"),
    ]
}

/// Parent check-in note
struct ParentNote: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var childId: UUID? // Optional - can be family-wide
    var content: String
    var noteType: NoteType

    // Co-parent sharing support
    var isSharedWithPartner: Bool
    var loggedByParentId: String?
    var loggedByParentName: String?

    // Context linking for personalized prompts
    var promptId: String?
    var linkedEventIds: [UUID]?

    enum NoteType: String, Codable {
        case parentWin // "I stayed calm"
        case goodMoment // General positive observation
        case reflection // End of day reflection
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        childId: UUID? = nil,
        content: String,
        noteType: NoteType = .goodMoment,
        isSharedWithPartner: Bool = false,
        loggedByParentId: String? = nil,
        loggedByParentName: String? = nil,
        promptId: String? = nil,
        linkedEventIds: [UUID]? = nil
    ) {
        self.id = id
        self.date = date
        self.childId = childId
        self.content = content
        self.noteType = noteType
        self.isSharedWithPartner = isSharedWithPartner
        self.loggedByParentId = loggedByParentId
        self.loggedByParentName = loggedByParentName
        self.promptId = promptId
        self.linkedEventIds = linkedEventIds
    }

    // MARK: - Migration Support (backward compatibility)

    private enum CodingKeys: String, CodingKey {
        case id, date, childId, content, noteType
        case isSharedWithPartner, loggedByParentId, loggedByParentName
        case promptId, linkedEventIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        childId = try container.decodeIfPresent(UUID.self, forKey: .childId)
        content = try container.decode(String.self, forKey: .content)
        noteType = try container.decode(NoteType.self, forKey: .noteType)

        // New fields with defaults for backward compatibility
        isSharedWithPartner = try container.decodeIfPresent(Bool.self, forKey: .isSharedWithPartner) ?? false
        loggedByParentId = try container.decodeIfPresent(String.self, forKey: .loggedByParentId)
        loggedByParentName = try container.decodeIfPresent(String.self, forKey: .loggedByParentName)
        promptId = try container.decodeIfPresent(String.self, forKey: .promptId)
        linkedEventIds = try container.decodeIfPresent([UUID].self, forKey: .linkedEventIds)
    }
}

/// Internal analytics for behavior consistency tracking
/// NOTE: This data is for internal analytics only and is NOT exposed to users.
/// User-facing UI shows non-consecutive "weekly activity" instead of "streaks".
struct BehaviorStreak: Identifiable, Codable, Equatable {
    let id: UUID
    let childId: UUID
    let behaviorTypeId: UUID
    var currentStreak: Int // Days in a row (internal metric only)
    var longestStreak: Int // Historical best (internal metric only)
    var lastCompletedDate: Date?
    
    init(
        id: UUID = UUID(),
        childId: UUID,
        behaviorTypeId: UUID,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil
    ) {
        self.id = id
        self.childId = childId
        self.behaviorTypeId = behaviorTypeId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
    }
    
    /// Internal: Update consecutive day count (for analytics purposes only)
    mutating func updateStreak(for date: Date = Date()) {
        let calendar = Calendar.current
        
        guard let lastDate = lastCompletedDate else {
            // First completion
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
            lastCompletedDate = date
            return
        }
        
        if calendar.isDate(date, inSameDayAs: lastDate) {
            // Already logged today
            return
        }
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))!
        
        if calendar.isDate(lastDate, inSameDayAs: yesterday) {
            // Continues
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Reset
            currentStreak = 1
        }
        
        lastCompletedDate = date
    }
}
