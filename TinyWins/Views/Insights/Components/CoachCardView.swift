import SwiftUI

// MARK: - Coach Card View

/// Displays a single CoachCard from the deterministic InsightsEngine.
/// Redesigned for 5-10 second value delivery.
///
/// ## Design Principles
/// - Visual first: Calendar dots show pattern at a glance
/// - Celebration over prescription: No generic tips
/// - One encouraging line: Context without cognitive load
/// - Clear CTA: "See moments" is the primary action
struct CoachCardView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository

    let card: CoachCard
    let onShowEvidence: () -> Void

    // Calculate which days of the week have events
    private var weekDayActivity: [Bool] {
        let calendar = Calendar.current
        let now = Date()

        // Get the start of the week (Monday)
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        // Adjust if week starts on Sunday (make it Monday-based for school week)
        if calendar.component(.weekday, from: weekStart) == 1 {
            weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart
        }

        // Get actual events from repository
        let events = repository.appData.behaviorEvents.filter { event in
            card.evidenceEventIds.contains(event.id.uuidString)
        }

        // Map events to days of week (0 = Monday, 6 = Sunday)
        var dayHasActivity = [Bool](repeating: false, count: 7)

        for event in events {
            let dayOfWeek = calendar.component(.weekday, from: event.timestamp)
            // Convert Sunday=1, Monday=2, etc. to Monday=0, Sunday=6
            let normalizedDay = (dayOfWeek + 5) % 7
            if normalizedDay < 7 {
                dayHasActivity[normalizedDay] = true
            }
        }

        return dayHasActivity
    }

    private var activeDayCount: Int {
        weekDayActivity.filter { $0 }.count
    }

    private var totalDaysInPeriod: Int {
        // For a school week focus, use 5 days
        // For full week, use 7
        card.evidenceWindow == 7 ? 5 : card.evidenceWindow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Icon + Title
            headerSection

            // Visual week pattern - the star of the show
            weekPatternSection

            // One encouraging line (replaces "Try this" list)
            encouragementLine

            // Footer: See moments button only
            footerSection
        }
        .padding(20)
        .background(cardBackgroundView)
        .shadow(color: priorityColor.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Priority indicator
            priorityBadge

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)

                Text(card.oneLiner)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    private var priorityBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [priorityColor, priorityColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: priorityColor.opacity(0.35), radius: 4, y: 2)

            Image(systemName: priorityIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var priorityColor: Color {
        switch card.priority {
        case 5: return Color(red: 0.95, green: 0.4, blue: 0.4)  // Soft coral red
        case 4: return Color(red: 1.0, green: 0.6, blue: 0.3)   // Warm orange
        case 3: return theme.success                             // Green for positive
        default: return Color(red: 0.5, green: 0.7, blue: 0.9)  // Soft blue
        }
    }

    private var priorityIcon: String {
        switch card.priority {
        case 5: return "heart.fill"
        case 4: return "star.fill"
        case 3: return "lightbulb.fill"
        default: return "sparkle"
        }
    }

    // MARK: - Week Pattern Section

    private var weekPatternSection: some View {
        VStack(spacing: 12) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Activity dots
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    dayDot(isActive: weekDayActivity[index], isWeekend: index >= 5)
                        .frame(maxWidth: .infinity)
                }
            }

            // Progress summary
            HStack {
                // Count badge
                HStack(spacing: 4) {
                    Text("\(card.evidenceEventIds.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(theme.success)

                    Text(card.evidenceEventIds.count == 1 ? "time" : "times")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Achievement badge
                achievementBadge
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.success.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.success.opacity(0.15), lineWidth: 1)
        )
    }

    private func dayDot(isActive: Bool, isWeekend: Bool) -> some View {
        ZStack {
            if isActive {
                // Active day - filled circle with glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.success, theme.success.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: theme.success.opacity(0.4), radius: 3, y: 1)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                // Inactive day - subtle ring
                Circle()
                    .stroke(
                        isWeekend ? theme.textDisabled.opacity(0.2) : theme.textDisabled.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)

                // Dot in center for weekdays only
                if !isWeekend {
                    Circle()
                        .fill(theme.textDisabled.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    @ViewBuilder
    private var achievementBadge: some View {
        let count = card.evidenceEventIds.count

        HStack(spacing: 4) {
            if count >= 5 {
                // Perfect or near-perfect
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)

                Text("Amazing week!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.success)
            } else if count >= 3 {
                // Good progress
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text("Building momentum")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            } else {
                // Getting started
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.success)

                Text("Growing habit")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.success)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    count >= 5
                        ? Color.yellow.opacity(0.15)
                        : count >= 3
                            ? Color.orange.opacity(0.12)
                            : theme.success.opacity(0.1)
                )
        )
    }

    // MARK: - Encouragement Line

    private var encouragementLine: some View {
        let count = card.evidenceEventIds.count
        let message: String

        if count >= 5 {
            message = "Consistency is building real character strength."
        } else if count >= 3 {
            message = "Great progress! A few more days locks this in."
        } else {
            message = "Every moment logged nurtures this behavior."
        }

        return HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(.yellow)

            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: 12) {
            Spacer()

            // Primary CTA: See moments
            if card.hasValidEvidence {
                Button(action: onShowEvidence) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))

                        Text("See moments (\(card.evidenceEventIds.count))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [theme.success, theme.success.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: theme.success.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("See \(card.evidenceEventIds.count) moments that show this pattern"))
                .accessibilityIdentifier(InsightsAccessibilityIdentifiers.evidenceButton(cardId: card.id))
            }
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackgroundView: some View {
        ZStack {
            // Base card background
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)

            // Subtle warm tint at top based on priority
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            priorityColor.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            // Soft border for definition
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(priorityColor.opacity(0.1), lineWidth: 1)
        }
    }
}

// MARK: - Preview

#Preview("Coach Card - High Activity") {
    let repository = Repository.preview

    let sampleCard = CoachCard(
        id: "preview-1",
        childId: "child-1",
        priority: 4,
        title: "Homework completed is becoming a habit",
        oneLiner: "Mia has done this 5 times in the last 7 days.",
        steps: [], // Not used anymore
        whySummary: "Consistency builds character.",
        evidenceEventIds: ["e1", "e2", "e3", "e4", "e5"],
        cta: .openHistory(childId: "child-1", filter: .routines(days: 7)),
        expiresAt: Date().addingTimeInterval(86400),
        templateId: "routine_forming",
        evidenceWindow: 7,
        primaryEntityId: "behavior-1",
        localizedContent: nil
    )

    CoachCardView(card: sampleCard) {
        print("Show evidence")
    }
    .padding()
    .environmentObject(repository)
    .withTheme(Theme())
}

#Preview("Coach Card - Medium Activity") {
    let repository = Repository.preview

    let sampleCard = CoachCard(
        id: "preview-2",
        childId: "child-1",
        priority: 3,
        title: "Sharing is growing",
        oneLiner: "Emma has shown sharing 3 times this week.",
        steps: [],
        whySummary: "Building empathy through action.",
        evidenceEventIds: ["e1", "e2", "e3"],
        cta: .openHistory(childId: "child-1", filter: .positive(days: 7)),
        expiresAt: Date().addingTimeInterval(86400),
        templateId: "positive_pattern",
        evidenceWindow: 7,
        primaryEntityId: "behavior-2",
        localizedContent: nil
    )

    CoachCardView(card: sampleCard) {
        print("Show evidence")
    }
    .padding()
    .environmentObject(repository)
    .withTheme(Theme())
}

#Preview("Coach Card - Low Activity") {
    let repository = Repository.preview

    let sampleCard = CoachCard(
        id: "preview-3",
        childId: "child-1",
        priority: 2,
        title: "Patience is emerging",
        oneLiner: "Jake waited calmly 2 times this week.",
        steps: [],
        whySummary: "Every patient moment counts.",
        evidenceEventIds: ["e1", "e2"],
        cta: .openHistory(childId: "child-1", filter: .positive(days: 7)),
        expiresAt: Date().addingTimeInterval(86400),
        templateId: "positive_pattern",
        evidenceWindow: 7,
        primaryEntityId: "behavior-3",
        localizedContent: nil
    )

    CoachCardView(card: sampleCard) {
        print("Show evidence")
    }
    .padding()
    .environmentObject(repository)
    .withTheme(Theme())
}
