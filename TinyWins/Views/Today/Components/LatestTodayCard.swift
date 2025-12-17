import SwiftUI

// MARK: - LatestTodayCard

/// Compact card showing the most recent moment logged today.
/// Tappable to expand into full activity view.
struct LatestTodayCard: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var childrenStore: ChildrenStore

    let onTap: () -> Void

    private var todayEvents: [BehaviorEvent] {
        behaviorsStore.todayEvents.sorted { $0.timestamp > $1.timestamp }
    }

    private var latestEvent: BehaviorEvent? {
        todayEvents.first
    }

    private var eventCount: Int {
        todayEvents.count
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    Text("Latest Today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.secondaryText)

                    Spacer()

                    if eventCount > 0 {
                        Text("\(eventCount)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(themeProvider.accentColor)
                    }
                }
                .padding(.bottom, 10)

                // Content
                if let event = latestEvent {
                    eventRow(event)
                } else {
                    emptyState
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.cardBackground)
                    .shadow(color: themeProvider.cardShadow, radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeProvider.accentColor.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view all today's activity")
    }

    // MARK: - Event Row

    private func eventRow(_ event: BehaviorEvent) -> some View {
        HStack(spacing: 12) {
            // Child indicator
            if let child = childrenStore.child(id: event.childId) {
                Circle()
                    .fill(child.colorTag.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    // Child name (only if multiple children)
                    if childrenStore.activeChildren.count > 1 {
                        Text(child.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(child.colorTag.color)
                    }

                    // Behavior name
                    if let behaviorType = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
                        Text(behaviorType.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeProvider.primaryText)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Stars and time
            VStack(alignment: .trailing, spacing: 2) {
                // Stars badge
                HStack(spacing: 2) {
                    Text(event.pointsApplied >= 0 ? "+\(event.pointsApplied)" : "\(event.pointsApplied)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(event.pointsApplied >= 0 ? themeProvider.positiveColor : themeProvider.challengeColor)
                }

                // Relative time
                Text(relativeTime(from: event.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(themeProvider.secondaryText)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeProvider.secondaryText.opacity(0.5))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 20))
                .foregroundColor(themeProvider.starColor.opacity(0.6))

            VStack(alignment: .leading, spacing: 2) {
                Text("No moments yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeProvider.primaryText)

                Text("Your first one is just a tap away")
                    .font(.system(size: 13))
                    .foregroundColor(themeProvider.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeProvider.secondaryText.opacity(0.5))
        }
    }

    // MARK: - Helpers

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var accessibilityLabel: String {
        if let event = latestEvent,
           let child = childrenStore.child(id: event.childId),
           let behaviorType = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
            let stars = event.pointsApplied >= 0 ? "plus \(event.pointsApplied)" : "minus \(abs(event.pointsApplied))"
            return "Latest today: \(child.name), \(behaviorType.name), \(stars) stars, \(relativeTime(from: event.timestamp)). \(eventCount) total moments today."
        }
        return "No moments logged today. Tap to view activity."
    }
}

// MARK: - Preview

// Previews disabled - require full environment setup with repository injection
// See TodayView preview for complete preview configuration
