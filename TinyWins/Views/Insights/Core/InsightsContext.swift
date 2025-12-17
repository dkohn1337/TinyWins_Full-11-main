import SwiftUI
import Combine

// MARK: - Insights Scope

/// The scope for viewing insights - Family aggregate, specific Child, or parent's "You" view
enum InsightsScopeType: Equatable, Hashable {
    case family
    case child(UUID)
    case you

    var displayKey: LocalizedStringKey {
        switch self {
        case .family: return "Family"
        case .child: return "Child"
        case .you: return "You"
        }
    }

    var icon: String {
        switch self {
        case .family: return "house.fill"
        case .child: return "figure.child"
        case .you: return "person.fill"
        }
    }
}

// MARK: - Time Range

/// Unified time range used across ALL Insights screens
enum InsightsTimeRange: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case sixMonths = "sixMonths"

    var id: String { rawValue }

    var displayKey: LocalizedStringKey {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "3 Months"
        case .sixMonths: return "6 Months"
        }
    }

    var shortDisplayKey: LocalizedStringKey {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "3mo"
        case .sixMonths: return "6mo"
        }
    }

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let end = now

        let start: Date
        switch self {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            start = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        }

        return (start, end)
    }

    /// Convert to legacy TimePeriod for compatibility
    var asTimePeriod: TimePeriod {
        switch self {
        case .week: return .thisWeek
        case .month: return .thisMonth
        case .quarter, .sixMonths: return .last3Months
        }
    }
}

// MARK: - Insights Context

/// Global shared state for Insights navigation
/// Persists scope, child selection, and time range across all Insights screens
@Observable
final class InsightsContext {

    // MARK: - Published State

    var scope: InsightsScopeType = .family
    var timeRange: InsightsTimeRange = .week

    // Track recently viewed children for sorting
    private(set) var recentlyViewedChildIds: [UUID] = []

    // MARK: - Computed Properties

    var selectedChildId: UUID? {
        if case .child(let id) = scope {
            return id
        }
        return nil
    }

    var isFamily: Bool {
        scope == .family
    }

    var isYou: Bool {
        scope == .you
    }

    // MARK: - Actions

    func selectFamily() {
        scope = .family
    }

    func selectChild(_ childId: UUID) {
        scope = .child(childId)
        trackRecentlyViewed(childId)
    }

    func selectYou() {
        scope = .you
    }

    func setTimeRange(_ range: InsightsTimeRange) {
        timeRange = range
    }

    // MARK: - Recently Viewed Tracking

    private func trackRecentlyViewed(_ childId: UUID) {
        recentlyViewedChildIds.removeAll { $0 == childId }
        recentlyViewedChildIds.insert(childId, at: 0)

        // Keep only last 10
        if recentlyViewedChildIds.count > 10 {
            recentlyViewedChildIds = Array(recentlyViewedChildIds.prefix(10))
        }
    }

    /// Sort children by recently viewed, then alphabetically
    func sortedChildren(_ children: [Child]) -> [Child] {
        children.sorted { a, b in
            let aIndex = recentlyViewedChildIds.firstIndex(of: a.id)
            let bIndex = recentlyViewedChildIds.firstIndex(of: b.id)

            switch (aIndex, bIndex) {
            case (.some(let ai), .some(let bi)):
                return ai < bi
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }

    // MARK: - Accessibility

    func accessibilityLabel(for child: Child?) -> String {
        switch scope {
        case .family:
            return String(localized: "Viewing family insights for \(timeRange.shortDisplayKey)")
        case .child:
            let name = child?.name ?? String(localized: "selected child")
            return String(localized: "Viewing \(name)'s insights for \(timeRange.shortDisplayKey)")
        case .you:
            return String(localized: "Viewing your parent journey for \(timeRange.shortDisplayKey)")
        }
    }
}

// MARK: - Environment Key

private struct InsightsContextKey: EnvironmentKey {
    static let defaultValue: InsightsContext = InsightsContext()
}

extension EnvironmentValues {
    var insightsContext: InsightsContext {
        get { self[InsightsContextKey.self] }
        set { self[InsightsContextKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func withInsightsContext(_ context: InsightsContext) -> some View {
        self.environment(\.insightsContext, context)
    }
}
