import SwiftUI

// MARK: - WeekHighlightsCard

/// Beautiful card showing this week's top moments for a child.
/// Replaces Character Radar with something more emotionally engaging.
///
/// Design principles:
/// - Celebrates the child's wins visually
/// - Quick to understand at a glance
/// - Warm, encouraging colors
/// - Drives engagement (parents want to log more to see moments featured)
struct WeekHighlightsCard: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository

    let child: Child
    let maxMoments: Int

    init(child: Child, maxMoments: Int = 5) {
        self.child = child
        self.maxMoments = maxMoments
    }

    // Computed highlights from this week's events
    private var weekHighlights: [HighlightMoment] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        // Get this week's positive events for this child
        let events = repository.appData.behaviorEvents
            .filter { $0.childId == child.id }
            .filter { $0.timestamp >= weekAgo }
            .filter { event in
                // Only positive behaviors
                if let behaviorType = repository.appData.behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                    return behaviorType.category == .positive || behaviorType.category == .routinePositive
                }
                return false
            }
            .sorted { $0.timestamp > $1.timestamp }

        // Convert to highlight moments
        return events.prefix(maxMoments).compactMap { event -> HighlightMoment? in
            guard let behaviorType = repository.appData.behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                return nil
            }

            let traits = CharacterTrait.traitsForBehavior(behaviorType.name)
            let primaryTrait = traits.first

            return HighlightMoment(
                id: event.id,
                behaviorName: behaviorType.name,
                iconName: behaviorType.iconName,
                timestamp: event.timestamp,
                points: event.pointsApplied,
                trait: primaryTrait,
                category: behaviorType.category
            )
        }
    }

    private var totalWinsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        return repository.appData.behaviorEvents
            .filter { $0.childId == child.id }
            .filter { $0.timestamp >= weekAgo }
            .filter { event in
                if let behaviorType = repository.appData.behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                    return behaviorType.category == .positive || behaviorType.category == .routinePositive
                }
                return false
            }
            .count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection

            if weekHighlights.isEmpty {
                emptyState
            } else {
                // Highlights list
                VStack(spacing: 10) {
                    ForEach(weekHighlights) { moment in
                        highlightRow(moment)
                    }
                }

                // Footer with total
                if totalWinsThisWeek > maxMoments {
                    footerSection
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: Color.yellow.opacity(0.08), radius: 12, y: 4)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)

                    Text("This Week's Highlights")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                }

                Text("\(child.name)'s best moments")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            // Week badge
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text("\(totalWinsThisWeek)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text("wins")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.12))
            )
        }
    }

    // MARK: - Highlight Row

    private func highlightRow(_ moment: HighlightMoment) -> some View {
        HStack(spacing: 12) {
            // Icon circle with category color
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [categoryColor(moment.category), categoryColor(moment.category).opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: categoryColor(moment.category).opacity(0.3), radius: 4, y: 2)

                Image(systemName: moment.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(moment.behaviorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Day
                    Text(dayString(moment.timestamp))
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)

                    // Trait tag if available
                    if let trait = moment.trait {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(trait.color)
                                .frame(width: 6, height: 6)

                            Text(trait.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(trait.color)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(trait.color.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Points
            HStack(spacing: 2) {
                Text("+\(moment.points)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(theme.success)

                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor(moment.category).opacity(0.05), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor(moment.category).opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
            }

            Text("No moments yet this week")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            Text("Log some wins to see them celebrated here!")
                .font(.caption)
                .foregroundColor(theme.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Footer

    private var footerSection: some View {
        Button {
            // Navigate to full history - this would trigger navigation via coordinator
        } label: {
            HStack(spacing: 8) {
                Text("+ \(totalWinsThisWeek - maxMoments) more wins this week")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(theme.accentPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accentPrimary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.accentPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)

            // Subtle warm gradient at top
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.06),
                            Color.orange.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color.yellow.opacity(0.12), lineWidth: 1)
        }
    }

    // MARK: - Helpers

    // Warm, vibrant colors for icon backgrounds
    private let positiveIconColor = Color(red: 0.4, green: 0.78, blue: 0.55) // Bright green
    private let routineIconColor = Color(red: 0.6, green: 0.5, blue: 0.85) // Warm purple
    private let challengeIconColor = Color(red: 1.0, green: 0.6, blue: 0.4) // Warm orange

    private func categoryColor(_ category: BehaviorCategory) -> Color {
        switch category {
        case .positive:
            return positiveIconColor
        case .routinePositive:
            return routineIconColor
        case .negative:
            return challengeIconColor
        }
    }

    private func dayString(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        }
    }
}

// MARK: - Highlight Moment Model

struct HighlightMoment: Identifiable {
    let id: UUID
    let behaviorName: String
    let iconName: String
    let timestamp: Date
    let points: Int
    let trait: CharacterTrait?
    let category: BehaviorCategory
}

// MARK: - Preview

#Preview("Week Highlights Card") {
    let repository = Repository.preview

    ScrollView {
        VStack(spacing: 20) {
            WeekHighlightsCard(child: Child.preview)
                .environmentObject(repository)

            WeekHighlightsCard(child: Child.preview, maxMoments: 3)
                .environmentObject(repository)
        }
        .padding()
    }
    .background(Theme().bg1)
    .withTheme(Theme())
}
