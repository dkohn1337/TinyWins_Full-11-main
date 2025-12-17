import SwiftUI
import Observation

// MARK: - Data Layer Documentation
/*
 SOURCE OF TRUTH (existing data):
 - BehaviorEvent: timestamp: Date, pointsApplied: Int, childId: UUID, behaviorTypeId: UUID
 - BehaviorType: name: String → maps to CharacterTrait via traitsForBehavior()
 - CharacterTrait: 6 cases (kindness, courage, patience, responsibility, creativity, resilience)

 BUCKETING LOGIC:
 - Derives weekly/monthly buckets from existing timestamped events
 - No new data fields required
 - Supports: This Week (5 weeks), Last 4 Weeks, Last 6 Months
*/

// MARK: - Growth Rings Time Range

/// Time ranges for Growth Rings visualization
enum GrowthRingsTimeRange: String, CaseIterable, Identifiable {
    case thisWeek = "this_week"
    case last4Weeks = "last_4_weeks"
    case last6Months = "last_6_months"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .thisWeek: return "This Week"
        case .last4Weeks: return "Last 4 Weeks"
        case .last6Months: return "Last 6 Months"
        }
    }

    var shortName: String {
        switch self {
        case .thisWeek: return "Week"
        case .last4Weeks: return "4 Weeks"
        case .last6Months: return "6 Months"
        }
    }

    var bucketCount: Int {
        switch self {
        case .thisWeek: return 5      // Current week + 4 previous
        case .last4Weeks: return 4    // 4 weekly buckets
        case .last6Months: return 6   // 6 monthly buckets
        }
    }

    var isWeekly: Bool {
        switch self {
        case .thisWeek, .last4Weeks: return true
        case .last6Months: return false
        }
    }
}

// MARK: - Growth Rings Bucket

/// A single time bucket for the Growth Rings visualization
struct GrowthRingsBucket: Identifiable, Equatable {
    let id: UUID
    let labelShort: String           // "Nov", "Wk 42", "This week"
    let labelLong: String            // "November 2024", "Week of Nov 11"
    let dateRange: ClosedRange<Date>
    let traitScores: [CharacterTrait: TraitBucketScore]
    let totalMoments: Int
    let totalPoints: Int
    let isCurrentPeriod: Bool        // Is this the most recent bucket?

    /// Whether this bucket has enough data to show meaningful insights
    var hasMinimumData: Bool {
        totalMoments >= GrowthRingsViewModel.minimumMomentsPerBucket
    }

    /// Get normalized score for a trait (0-1 range)
    func normalizedScore(for trait: CharacterTrait) -> Double {
        guard let score = traitScores[trait] else { return 0 }
        // Normalize against max possible in this bucket
        let maxScore = traitScores.values.map { $0.points }.max() ?? 1
        return maxScore > 0 ? Double(score.points) / Double(maxScore) : 0
    }

    /// Get the strongest trait in this bucket
    var strongestTrait: CharacterTrait? {
        traitScores.max(by: { $0.value.points < $1.value.points })?.key
    }

    static func == (lhs: GrowthRingsBucket, rhs: GrowthRingsBucket) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Trait Bucket Score

/// Score data for a single trait within a bucket
struct TraitBucketScore: Equatable {
    let moments: Int
    let points: Int

    static let zero = TraitBucketScore(moments: 0, points: 0)
}

// MARK: - Trend Direction

enum TrendDirection {
    case up
    case down
    case flat
    case noData

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        case .noData: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .orange
        case .flat: return .gray
        case .noData: return .gray.opacity(0.5)
        }
    }

    /// Supportive language for weekly modes (avoid "declined")
    func weeklyDescription(for trait: CharacterTrait) -> LocalizedStringKey {
        switch self {
        case .up: return "\(trait.displayName) is building"
        case .down: return "\(trait.displayName) less visible this week"
        case .flat: return "\(trait.displayName) is steady"
        case .noData: return "Not enough data yet"
        }
    }

    /// Language for monthly modes
    func monthlyDescription(for trait: CharacterTrait) -> LocalizedStringKey {
        switch self {
        case .up: return "\(trait.displayName) is growing"
        case .down: return "\(trait.displayName) needs attention"
        case .flat: return "\(trait.displayName) is steady"
        case .noData: return "Not enough data yet"
        }
    }
}

// MARK: - Parent Brief Data

/// Data for the "Parent Brief" card above the rings
struct ParentBrief {
    let strongestTrait: CharacterTrait?
    let momentsCount: Int
    let pointsCount: Int
    let trend: TrendDirection
    let previousBucketExists: Bool
    let suggestions: [String]
    let hasMinimumData: Bool
}

// MARK: - Growth Rings View Model

@Observable
final class GrowthRingsViewModel {

    // MARK: - Constants

    /// Minimum moments per bucket to show confident insights
    static let minimumMomentsPerBucket = 3

    // MARK: - Published State

    private(set) var buckets: [GrowthRingsBucket] = []
    private(set) var selectedBucket: GrowthRingsBucket?
    private(set) var selectedTrait: CharacterTrait?
    private(set) var parentBrief: ParentBrief?
    private(set) var isLoading = false
    private(set) var availableDateRange: ClosedRange<Date>?

    var timeRange: GrowthRingsTimeRange {
        didSet {
            if timeRange != oldValue {
                saveTimeRangePreference()
                loadData()
            }
        }
    }

    // MARK: - Dependencies

    private let child: Child
    private let events: [BehaviorEvent]
    private let behaviorTypes: [BehaviorType]
    private let calendar: Calendar

    // MARK: - Persistence Key

    private var timeRangeKey: String {
        "growthRings_timeRange_\(child.id.uuidString)"
    }

    // MARK: - Initialization

    init(
        child: Child,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        calendar: Calendar = .current
    ) {
        self.child = child
        self.events = events
        self.behaviorTypes = behaviorTypes
        self.calendar = calendar

        // Load persisted time range or determine default
        self.timeRange = Self.loadTimeRangePreference(for: child.id, events: events, calendar: calendar)

        loadData()
    }

    // MARK: - Public Actions

    func selectBucket(_ bucket: GrowthRingsBucket?) {
        selectedBucket = bucket
        updateParentBrief()
    }

    func selectTrait(_ trait: CharacterTrait?) {
        selectedTrait = trait
    }

    func refresh() {
        loadData()
    }

    // MARK: - Data Loading

    private func loadData() {
        isLoading = true

        // Calculate available date range for this child
        let childEvents = events.filter { $0.childId == child.id && $0.pointsApplied > 0 }
        if let earliest = childEvents.map({ $0.timestamp }).min(),
           let latest = childEvents.map({ $0.timestamp }).max() {
            availableDateRange = earliest...latest
        }

        // Generate buckets based on time range
        buckets = generateBuckets()

        // Auto-select most recent bucket
        if selectedBucket == nil {
            selectedBucket = buckets.last
        } else if let current = selectedBucket,
                  !buckets.contains(where: { $0.id == current.id }) {
            // Selected bucket no longer exists after range change
            selectedBucket = buckets.last
        }

        updateParentBrief()
        isLoading = false
    }

    // MARK: - Bucket Generation

    private func generateBuckets() -> [GrowthRingsBucket] {
        let now = Date()
        var result: [GrowthRingsBucket] = []

        if timeRange.isWeekly {
            result = generateWeeklyBuckets(endingAt: now, count: timeRange.bucketCount)
        } else {
            result = generateMonthlyBuckets(endingAt: now, count: timeRange.bucketCount)
        }

        return result
    }

    private func generateWeeklyBuckets(endingAt: Date, count: Int) -> [GrowthRingsBucket] {
        var buckets: [GrowthRingsBucket] = []

        // Get start of current week
        let currentWeekStart = calendar.startOfWeek(for: endingAt)

        for weekOffset in (0..<count).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                continue
            }

            let dateRange = weekStart...min(weekEnd, endingAt)
            let traitScores = calculateTraitScores(in: dateRange)
            let (totalMoments, totalPoints) = calculateTotals(in: dateRange)

            // Generate human-readable labels
            let label: String
            let longLabel: String
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"

            if weekOffset == 0 {
                label = String(localized: "This week", table: "Insights")
                longLabel = String(localized: "This week", table: "Insights")
            } else if weekOffset == 1 {
                label = String(localized: "Last week", table: "Insights")
                longLabel = String(localized: "Last week", table: "Insights")
            } else if weekOffset == 2 {
                label = String(localized: "2 wks ago", table: "Insights")
                longLabel = "Week of \(formatter.string(from: weekStart))"
            } else if weekOffset == 3 {
                label = String(localized: "3 wks ago", table: "Insights")
                longLabel = "Week of \(formatter.string(from: weekStart))"
            } else {
                // For older weeks, use the date
                label = formatter.string(from: weekStart)
                longLabel = "Week of \(formatter.string(from: weekStart))"
            }

            buckets.append(GrowthRingsBucket(
                id: UUID(),
                labelShort: label,
                labelLong: longLabel,
                dateRange: dateRange,
                traitScores: traitScores,
                totalMoments: totalMoments,
                totalPoints: totalPoints,
                isCurrentPeriod: weekOffset == 0
            ))
        }

        return buckets
    }

    private func generateMonthlyBuckets(endingAt: Date, count: Int) -> [GrowthRingsBucket] {
        var buckets: [GrowthRingsBucket] = []

        for monthOffset in (0..<count).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: endingAt) else {
                continue
            }

            let startOfMonth = calendar.startOfMonth(for: monthStart)
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?
                    .addingTimeInterval(-1) else {
                continue
            }

            let dateRange = startOfMonth...min(endOfMonth, endingAt)
            let traitScores = calculateTraitScores(in: dateRange)
            let (totalMoments, totalPoints) = calculateTotals(in: dateRange)

            let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: startOfMonth) - 1]
            let year = calendar.component(.year, from: startOfMonth)

            buckets.append(GrowthRingsBucket(
                id: UUID(),
                labelShort: monthName,
                labelLong: "\(monthName) \(year)",
                dateRange: dateRange,
                traitScores: traitScores,
                totalMoments: totalMoments,
                totalPoints: totalPoints,
                isCurrentPeriod: monthOffset == 0
            ))
        }

        return buckets
    }

    // MARK: - Trait Calculations

    private func calculateTraitScores(in dateRange: ClosedRange<Date>) -> [CharacterTrait: TraitBucketScore] {
        var scores: [CharacterTrait: TraitBucketScore] = [:]

        // Initialize all traits
        for trait in CharacterTrait.allCases {
            scores[trait] = .zero
        }

        // Filter events for this child in the date range
        let rangeEvents = events.filter {
            $0.childId == child.id &&
            $0.timestamp >= dateRange.lowerBound &&
            $0.timestamp <= dateRange.upperBound &&
            $0.pointsApplied > 0
        }

        // Accumulate scores
        for event in rangeEvents {
            guard let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                continue
            }

            let traits = CharacterTrait.traitsForBehavior(behaviorType.name)

            for trait in traits {
                let current = scores[trait] ?? .zero
                scores[trait] = TraitBucketScore(
                    moments: current.moments + 1,
                    points: current.points + event.pointsApplied
                )
            }
        }

        return scores
    }

    private func calculateTotals(in dateRange: ClosedRange<Date>) -> (moments: Int, points: Int) {
        let rangeEvents = events.filter {
            $0.childId == child.id &&
            $0.timestamp >= dateRange.lowerBound &&
            $0.timestamp <= dateRange.upperBound &&
            $0.pointsApplied > 0
        }

        let moments = rangeEvents.count
        let points = rangeEvents.reduce(0) { $0 + $1.pointsApplied }

        return (moments, points)
    }

    // MARK: - Parent Brief

    private func updateParentBrief() {
        guard let bucket = selectedBucket else {
            parentBrief = nil
            return
        }

        let strongestTrait = bucket.strongestTrait
        let trend = calculateTrend(for: bucket)
        let previousExists = buckets.firstIndex(where: { $0.id == bucket.id }).map { $0 > 0 } ?? false

        parentBrief = ParentBrief(
            strongestTrait: strongestTrait,
            momentsCount: bucket.totalMoments,
            pointsCount: bucket.totalPoints,
            trend: trend,
            previousBucketExists: previousExists,
            suggestions: strongestTrait.map { suggestionsFor(trait: $0) } ?? [],
            hasMinimumData: bucket.hasMinimumData
        )
    }

    private func calculateTrend(for bucket: GrowthRingsBucket) -> TrendDirection {
        guard let currentIndex = buckets.firstIndex(where: { $0.id == bucket.id }),
              currentIndex > 0 else {
            return .noData
        }

        let previousBucket = buckets[currentIndex - 1]

        // Compare total moments or strongest trait
        let currentTotal = bucket.totalMoments
        let previousTotal = previousBucket.totalMoments

        guard previousTotal > 0 else {
            return currentTotal > 0 ? .up : .noData
        }

        let change = Double(currentTotal - previousTotal) / Double(previousTotal)

        if change > 0.1 {
            return .up
        } else if change < -0.1 {
            return .down
        } else {
            return .flat
        }
    }

    // MARK: - Suggestions

    private func suggestionsFor(trait: CharacterTrait) -> [String] {
        switch trait {
        case .kindness:
            return [
                String(localized: "Notice when they share without being asked", table: "Insights"),
                String(localized: "Point out the impact of their kind actions", table: "Insights"),
                String(localized: "Model kindness in your interactions", table: "Insights")
            ]
        case .courage:
            return [
                String(localized: "Celebrate small brave moments", table: "Insights"),
                String(localized: "Share stories of your own challenges", table: "Insights"),
                String(localized: "Create safe opportunities to try new things", table: "Insights")
            ]
        case .patience:
            return [
                String(localized: "Acknowledge when they wait calmly", table: "Insights"),
                String(localized: "Practice waiting together", table: "Insights"),
                String(localized: "Use timers to make waiting tangible", table: "Insights")
            ]
        case .responsibility:
            return [
                String(localized: "Keep routines consistent", table: "Insights"),
                String(localized: "Let them own age-appropriate tasks", table: "Insights"),
                String(localized: "Focus on effort, not perfection", table: "Insights")
            ]
        case .creativity:
            return [
                String(localized: "Provide open-ended materials", table: "Insights"),
                String(localized: "Ask 'what if' questions together", table: "Insights"),
                String(localized: "Value the process over the product", table: "Insights")
            ]
        case .resilience:
            return [
                String(localized: "Normalize setbacks as learning", table: "Insights"),
                String(localized: "Share your own bounce-back moments", table: "Insights"),
                String(localized: "Celebrate trying again", table: "Insights")
            ]
        }
    }

    // MARK: - Trait Detail Data

    func traitDetailData(for trait: CharacterTrait) -> TraitDetailData {
        guard let bucket = selectedBucket else {
            return TraitDetailData(
                trait: trait,
                currentMoments: 0,
                currentPoints: 0,
                trend: .noData,
                trendValues: [],
                hasMinimumData: false
            )
        }

        let score = bucket.traitScores[trait] ?? .zero
        let trend = calculateTraitTrend(for: trait, in: bucket)

        // Get trend values across all buckets
        let trendValues = buckets.map { b -> Int in
            b.traitScores[trait]?.points ?? 0
        }

        return TraitDetailData(
            trait: trait,
            currentMoments: score.moments,
            currentPoints: score.points,
            trend: trend,
            trendValues: trendValues,
            hasMinimumData: score.moments >= Self.minimumMomentsPerBucket
        )
    }

    private func calculateTraitTrend(for trait: CharacterTrait, in bucket: GrowthRingsBucket) -> TrendDirection {
        guard let currentIndex = buckets.firstIndex(where: { $0.id == bucket.id }),
              currentIndex > 0 else {
            return .noData
        }

        let previousBucket = buckets[currentIndex - 1]
        let currentPoints = bucket.traitScores[trait]?.points ?? 0
        let previousPoints = previousBucket.traitScores[trait]?.points ?? 0

        guard previousPoints > 0 else {
            return currentPoints > 0 ? .up : .noData
        }

        let change = Double(currentPoints - previousPoints) / Double(previousPoints)

        if change > 0.15 {
            return .up
        } else if change < -0.15 {
            return .down
        } else {
            return .flat
        }
    }

    // MARK: - Time Range Persistence

    private func saveTimeRangePreference() {
        UserDefaults.standard.set(timeRange.rawValue, forKey: timeRangeKey)
    }

    private static func loadTimeRangePreference(
        for childId: UUID,
        events: [BehaviorEvent],
        calendar: Calendar
    ) -> GrowthRingsTimeRange {
        let key = "growthRings_timeRange_\(childId.uuidString)"

        if let stored = UserDefaults.standard.string(forKey: key),
           let range = GrowthRingsTimeRange(rawValue: stored) {
            return range
        }

        // Default: Last 4 Weeks if enough data, otherwise Last 6 Months
        let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
        let recentEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= twoWeeksAgo &&
            $0.pointsApplied > 0
        }

        return recentEvents.count >= 6 ? .last4Weeks : .last6Months
    }
}

// MARK: - Trait Detail Data

struct TraitDetailData {
    let trait: CharacterTrait
    let currentMoments: Int
    let currentPoints: Int
    let trend: TrendDirection
    let trendValues: [Int]  // Points across all buckets for mini chart
    let hasMinimumData: Bool
}

// MARK: - Calendar Extensions

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }

    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
