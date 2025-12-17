import SwiftUI

// MARK: - Habits Forming Card (Premium)

/// Premium card showing habit formation progress with momentum visualization.
/// Designed to deliver 5-second analytical value with premium visual language.
///
/// ## Design Principles
/// - Momentum ring: Single glanceable score (like Premium Analytics)
/// - Ranked list: Habits ordered by strength with week-over-week comparison
/// - Insight callout: Forward-looking, actionable intelligence
/// - Premium feel: Gauges, gradients, sophisticated typography
struct HabitsFormingCard: View {
    @Environment(\.themeProvider) private var theme
    @EnvironmentObject private var repository: Repository

    let cards: [CoachCard]
    let onShowEvidence: (CoachCard) -> Void

    // MARK: - Computed Properties

    /// Total moments across all cards this week
    private var totalMoments: Int {
        cards.reduce(0) { $0 + $1.evidenceEventIds.count }
    }

    /// Total moments from last week for comparison
    private var lastWeekMoments: Int {
        // Calculate based on repository data for the same behaviors
        let calendar = Calendar.current
        let now = Date()
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now),
              let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return 0
        }

        // Get behavior names from current cards
        let behaviorNames = Set(cards.compactMap { extractBehaviorName(from: $0.title).lowercased() })

        // Count matching events from last week
        return repository.appData.behaviorEvents.filter { event in
            guard event.timestamp >= twoWeeksAgo && event.timestamp < oneWeekAgo else { return false }
            guard let behaviorType = repository.appData.behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else { return false }
            return behaviorNames.contains(behaviorType.name.lowercased())
        }.count
    }

    /// Week-over-week change
    private var weekOverWeekChange: Int {
        totalMoments - lastWeekMoments
    }

    /// Momentum score (0-100) based on habit strength
    private var momentumScore: Double {
        // Score based on: total moments, consistency, and improvement
        let baseScore = min(Double(totalMoments) * 10, 60) // Up to 60 from volume
        let consistencyBonus = Double(cards.filter { $0.evidenceEventIds.count >= 3 }.count) * 10 // Up to 30 for consistent habits
        let improvementBonus = weekOverWeekChange > 0 ? min(Double(weekOverWeekChange) * 5, 10) : 0 // Up to 10 for improvement
        return min(baseScore + consistencyBonus + improvementBonus, 100)
    }

    /// Momentum trend description
    private var momentumTrend: (label: String, color: Color, icon: String) {
        if momentumScore >= 70 {
            return ("Strong", Color.green, "arrow.up.right")
        } else if momentumScore >= 40 {
            return ("Building", Color.orange, "arrow.right")
        } else {
            return ("Emerging", Color.blue, "leaf.fill")
        }
    }

    /// Cards sorted by strength (evidence count)
    private var rankedCards: [CoachCard] {
        cards.sorted { $0.evidenceEventIds.count > $1.evidenceEventIds.count }
    }

    /// Strongest habit insight
    private var strongestHabitInsight: String? {
        guard let strongest = rankedCards.first else { return nil }
        let name = extractBehaviorName(from: strongest.title)
        let count = strongest.evidenceEventIds.count

        if count >= 5 {
            return "\(name) is your strongest - almost locked in!"
        } else if count >= 3 {
            return "\(name) is building well - keep it going!"
        } else {
            return "Great start! \(name) is emerging as a pattern."
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with momentum ring
            headerWithMomentum

            Divider()
                .padding(.horizontal, 20)

            // Ranked habits list
            rankedHabitsList

            // Insight callout
            if let insight = strongestHabitInsight {
                insightCallout(insight)
            }

            // CTA
            ctaButton
        }
        .background(cardBackground)
        .shadow(color: theme.accentColor.opacity(0.1), radius: 16, x: 0, y: 6)
    }

    // MARK: - Header with Momentum Ring

    private var headerWithMomentum: some View {
        HStack(spacing: 16) {
            // Momentum Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(theme.accentColor.opacity(0.15), lineWidth: 8)
                    .frame(width: 72, height: 72)

                // Progress ring
                Circle()
                    .trim(from: 0, to: momentumScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: [momentumTrend.color, momentumTrend.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 1) {
                    Text("\(Int(momentumScore))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryText)

                    HStack(spacing: 2) {
                        Image(systemName: momentumTrend.icon)
                            .font(.system(size: 8, weight: .bold))
                        Text(momentumTrend.label)
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundColor(momentumTrend.color)
                }
            }

            // Title & stats
            VStack(alignment: .leading, spacing: 6) {
                Text("Habit Momentum")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                Text("\(cards.count) habits forming this week")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)

                // Week-over-week badge
                weekOverWeekBadge
            }

            Spacer()
        }
        .padding(20)
    }

    private var weekOverWeekBadge: some View {
        HStack(spacing: 4) {
            if weekOverWeekChange > 0 {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                Text("+\(weekOverWeekChange)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            } else if weekOverWeekChange < 0 {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                Text("\(weekOverWeekChange)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            } else {
                Image(systemName: "equal")
                    .font(.system(size: 10, weight: .bold))
                Text("same")
                    .font(.system(size: 12, weight: .medium))
            }
            Text("vs last week")
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText)
        }
        .foregroundColor(weekOverWeekChange > 0 ? .green : weekOverWeekChange < 0 ? .orange : theme.secondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(weekOverWeekChange > 0 ? Color.green.opacity(0.12) : weekOverWeekChange < 0 ? Color.orange.opacity(0.12) : theme.cardBackground)
        )
    }

    // MARK: - Ranked Habits List

    private var rankedHabitsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(rankedCards.enumerated()), id: \.element.id) { index, card in
                rankedHabitRow(card: card, rank: index + 1)

                if index < rankedCards.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func rankedHabitRow(card: CoachCard, rank: Int) -> some View {
        let thisWeekCount = card.evidenceEventIds.count
        let lastWeekCount = calculateLastWeekCount(for: card)
        let change = thisWeekCount - lastWeekCount

        return HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 28, height: 28)

                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Behavior info
            VStack(alignment: .leading, spacing: 2) {
                Text(extractBehaviorName(from: card.title))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)

                Text("\(thisWeekCount)x this week")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            // Change indicator
            changeIndicator(change: change)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onShowEvidence(card)
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.75, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.8) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return theme.secondaryText.opacity(0.5)
        }
    }

    private func changeIndicator(change: Int) -> some View {
        HStack(spacing: 3) {
            if change > 0 {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                Text("+\(change)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            } else if change < 0 {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                Text("\(change)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            } else {
                Text("=")
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .foregroundColor(change > 0 ? .green : change < 0 ? .orange : theme.secondaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(change > 0 ? Color.green.opacity(0.12) : change < 0 ? Color.orange.opacity(0.12) : Color.clear)
        )
    }

    // MARK: - Insight Callout

    private func insightCallout(_ insight: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)

            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.primaryText)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            if let strongest = rankedCards.first {
                onShowEvidence(strongest)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))

                Text("See all \(totalMoments) moments")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .padding(20)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.cardBackground)

            // Premium gradient tint
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accentColor.opacity(0.04),
                            Color.clear,
                            theme.positiveColor.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.accentColor.opacity(0.12), lineWidth: 1)
        }
    }

    // MARK: - Helpers

    private func calculateLastWeekCount(for card: CoachCard) -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now),
              let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return 0
        }

        let behaviorName = extractBehaviorName(from: card.title).lowercased()

        return repository.appData.behaviorEvents.filter { event in
            guard event.timestamp >= twoWeeksAgo && event.timestamp < oneWeekAgo else { return false }
            guard let behaviorType = repository.appData.behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else { return false }
            return behaviorType.name.lowercased().contains(behaviorName) || behaviorName.contains(behaviorType.name.lowercased())
        }.count
    }

    private func extractBehaviorName(from title: String) -> String {
        let patterns = [
            " is becoming a habit",
            " is forming",
            " is growing",
            " is emerging"
        ]

        var name = title
        for pattern in patterns {
            if let range = name.range(of: pattern, options: .caseInsensitive) {
                name = String(name[..<range.lowerBound])
                break
            }
        }

        return name
    }
}

// MARK: - Preview

#Preview("Habits Forming Card - Premium") {
    let repository = Repository.preview

    let cards = [
        CoachCard(
            id: "1",
            childId: "child-1",
            priority: 4,
            title: "Homework completed is becoming a habit",
            oneLiner: "Mia has done this 5 times in the last 7 days.",
            steps: [],
            whySummary: "",
            evidenceEventIds: ["e1", "e2", "e3", "e4", "e5"],
            cta: .openHistory(childId: "child-1", filter: .routines(days: 7)),
            expiresAt: Date(),
            templateId: "routine_forming",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        ),
        CoachCard(
            id: "2",
            childId: "child-1",
            priority: 4,
            title: "Managed screen time is becoming a habit",
            oneLiner: "Mia has done this 4 times in the last 7 days.",
            steps: [],
            whySummary: "",
            evidenceEventIds: ["e1", "e2", "e3", "e4"],
            cta: .openHistory(childId: "child-1", filter: .routines(days: 7)),
            expiresAt: Date(),
            templateId: "routine_forming",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        ),
        CoachCard(
            id: "3",
            childId: "child-1",
            priority: 3,
            title: "Sharing is becoming a habit",
            oneLiner: "Mia has done this 2 times in the last 7 days.",
            steps: [],
            whySummary: "",
            evidenceEventIds: ["e1", "e2"],
            cta: .openHistory(childId: "child-1", filter: .positive(days: 7)),
            expiresAt: Date(),
            templateId: "positive_pattern",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        )
    ]

    ScrollView {
        HabitsFormingCard(cards: cards) { card in
            print("Show evidence for: \(card.title)")
        }
        .padding()
    }
    .environmentObject(repository)
    .withThemeProvider(ThemeProvider())
}
