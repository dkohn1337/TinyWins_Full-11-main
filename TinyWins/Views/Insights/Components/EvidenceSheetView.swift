import SwiftUI

// MARK: - Evidence Sheet View

/// Shows the moments that support a coaching card.
/// Builds trust by showing "here's the story" for each insight.
///
/// ## Design Principles
/// - Transparent: shows exactly which moments led to this insight
/// - Warm & encouraging: celebrates the journey
/// - Accessible: full VoiceOver support
struct EvidenceSheetView: View {
    @Environment(\.themeProvider) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var repository: Repository

    let card: CoachCard

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header: What this insight says
                    headerSection

                    // Summary of what we noticed
                    summarySection

                    // The moments list
                    evidenceListSection
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, 16)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.03),
                        theme.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
            .navigationTitle(Text("The Story", tableName: "Insights"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Text("Done", tableName: "Common")
                            .fontWeight(.medium)
                            .foregroundColor(theme.accentColor)
                    }
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.evidenceSheetDoneButton)
                }
            }
        }
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.evidenceSheetRoot)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 14) {
            // Warm icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, y: 2)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Card title
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                // Card one-liner
                Text(card.oneLiner)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.cardBackground)

                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.08), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
            }
        )
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)

                Text("What We Noticed", tableName: "Insights")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
            }

            HStack(spacing: 12) {
                summaryChip(
                    icon: "calendar",
                    value: "\(card.evidenceWindow)",
                    label: String(localized: "days", table: "Insights"),
                    color: .blue
                )

                summaryChip(
                    icon: "star.fill",
                    value: "\(evidenceEvents.count)",
                    label: String(localized: "moments", table: "Insights"),
                    color: .yellow
                )

                if let templateName = templateDisplayName {
                    summaryChip(
                        icon: "heart.fill",
                        value: templateName,
                        label: String(localized: "pattern", table: "Insights"),
                        color: .pink
                    )
                }
            }
        }
    }

    private func summaryChip(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.03))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Evidence List Section

    private var evidenceListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "list.star")
                    .font(.caption)
                    .foregroundColor(theme.positiveColor)

                Text("Moments That Show This", tableName: "Insights")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
            }

            if evidenceEvents.isEmpty {
                emptyEvidenceState
            } else {
                ForEach(evidenceEvents) { event in
                    EvidenceEventRow(event: event)
                }
            }
        }
    }

    private var emptyEvidenceState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
            }

            VStack(spacing: 4) {
                Text("Moments archived", tableName: "Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)

                Text("The specific moments have been cleaned up, but the pattern was real!", tableName: "Insights")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(Color.yellow.opacity(0.03))
                )
        )
    }

    // MARK: - Helpers

    private var evidenceEvents: [BehaviorEvent] {
        let eventIds = Set(card.evidenceEventIds.compactMap { UUID(uuidString: $0) })
        return repository.appData.behaviorEvents.filter { eventIds.contains($0.id) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var templateDisplayName: String? {
        switch card.templateId {
        case "goal_at_risk": return String(localized: "Goal at risk", table: "Insights")
        case "goal_stalled": return String(localized: "Goal stalled", table: "Insights")
        case "routine_forming": return String(localized: "Habit forming", table: "Insights")
        case "routine_slipping": return String(localized: "Habit slipping", table: "Insights")
        case "high_challenge_week": return String(localized: "Challenge pattern", table: "Insights")
        default: return nil
        }
    }
}

// MARK: - Evidence Event Row

private struct EvidenceEventRow: View {
    @Environment(\.themeProvider) private var theme
    @EnvironmentObject private var repository: Repository

    let event: BehaviorEvent

    private var isPositive: Bool {
        event.pointsApplied > 0
    }

    private var rowColor: Color {
        isPositive ? theme.positiveColor : theme.challengeColor
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator with gradient
            typeIndicator

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(behaviorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)

                HStack(spacing: 8) {
                    // Date
                    Text(event.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)

                    // Time
                    Text(event.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                }

                // Note (if any)
                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()

            // Points
            pointsBadge
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [rowColor.opacity(0.04), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(rowColor.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Type Indicator

    private var typeIndicator: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [rowColor, rowColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: rowColor.opacity(0.3), radius: 3, y: 2)

            Image(systemName: isPositive ? "star.fill" : "cloud.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Points Badge

    private var pointsBadge: some View {
        let points = event.pointsApplied

        return HStack(spacing: 2) {
            Text(isPositive ? "+\(points)" : "\(points)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(rowColor)

            if isPositive {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(rowColor.opacity(0.12))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private var behaviorName: String {
        repository.appData.behaviorTypes
            .first { $0.id == event.behaviorTypeId }?
            .name ?? String(localized: "Unknown behavior", table: "Insights")
    }
}

// MARK: - Preview

#Preview("Evidence Sheet") {
    let repository = Repository.preview

    let sampleCard = CoachCard(
        id: "preview-1",
        childId: "child-1",
        priority: 3,
        title: "Sharing is becoming a habit",
        oneLiner: "Emma has shown sharing 5 times in the last 7 days.",
        steps: ["Keep acknowledging when it happens"],
        whySummary: "5 occurrences in 7 days shows a pattern forming.",
        evidenceEventIds: [],
        cta: .openHistory(childId: "child-1", filter: .routines(days: 7)),
        expiresAt: Date().addingTimeInterval(86400),
        templateId: "routine_forming",
        evidenceWindow: 7,
        primaryEntityId: nil,
        localizedContent: nil
    )

    EvidenceSheetView(card: sampleCard)
        .environmentObject(repository)
        .withThemeProvider(ThemeProvider())
}
