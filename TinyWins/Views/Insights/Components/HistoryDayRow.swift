import SwiftUI

// MARK: - Cached Formatters

private enum DayRowFormatterCache {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - Partner Attribution Helper

private enum PartnerAttributionConfig {
    /// Determines if partner attribution should be shown.
    /// In DEBUG mode, respects the developer toggle.
    /// In production, requires Plus subscription and user preference enabled.
    @MainActor
    static func isEnabled(isPlusSubscriber: Bool) -> Bool {
        let userPrefs = UserPreferencesStore()

        #if DEBUG
        // In debug mode, the developer toggle overrides everything
        if userPrefs.showPartnerAttribution {
            return true
        }
        #endif

        // In production (or if debug toggle is off), require Plus + preference
        return isPlusSubscriber && userPrefs.partnerAttributionEnabled
    }
}

// MARK: - Unified Day Row

/// Row displaying all history items for a single day
struct UnifiedDayRow: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    let date: Date
    let items: [HistoryItem]
    let onBehaviorTapped: (BehaviorEvent) -> Void
    let onRewardTapped: (RewardHistoryEvent) -> Void

    private var showPartnerAttribution: Bool {
        PartnerAttributionConfig.isEnabled(isPlusSubscriber: subscriptionManager.effectiveIsPlusSubscriber)
    }

    private var sortedItems: [HistoryItem] {
        items.sorted { $0.timestamp > $1.timestamp }
    }

    private var positiveCount: Int {
        items.compactMap { item -> Int? in
            if case .behavior(let event) = item, event.pointsApplied > 0 {
                return 1
            }
            return nil
        }.count
    }

    private var challengeCount: Int {
        items.compactMap { item -> Int? in
            if case .behavior(let event) = item, event.pointsApplied < 0 {
                return 1
            }
            return nil
        }.count
    }

    private var rewardCount: Int {
        items.compactMap { item -> Int? in
            if case .reward = item { return 1 }
            return nil
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header
            HStack(spacing: 8) {
                Text(dayOfWeek)
                    .font(.subheadline.weight(.semibold))
                Text(dayNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Summary badges
                HStack(spacing: 8) {
                    if positiveCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.caption2)
                            Text("\(positiveCount)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(AppColors.positive)
                    }

                    if challengeCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("\(challengeCount)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(AppColors.challenge)
                    }

                    if rewardCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "gift.fill")
                                .font(.caption2)
                            Text("\(rewardCount)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.purple)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Items card
            VStack(spacing: 0) {
                ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                    itemRow(item: item)

                    if index < sortedItems.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(AppStyles.cardCornerRadius)
            .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func itemRow(item: HistoryItem) -> some View {
        switch item {
        case .behavior(let event):
            Button(action: { onBehaviorTapped(event) }) {
                behaviorEventRow(event: event)
            }
            .buttonStyle(.plain)

        case .reward(let event):
            Button(action: { onRewardTapped(event) }) {
                rewardEventRow(event: event)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func behaviorEventRow(event: BehaviorEvent) -> some View {
        HStack(spacing: 12) {
            if let behavior = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
                ZStack {
                    Circle()
                        .fill((event.pointsApplied >= 0 ? AppColors.positive : AppColors.challenge).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: behavior.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(event.pointsApplied >= 0 ? AppColors.positive : AppColors.challenge)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if let behavior = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
                    Text(behavior.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(formatTime(event.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if childrenStore.children.count > 1, let child = childrenStore.child(id: event.childId) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(child.colorTag.color)
                                .frame(width: 6, height: 6)
                            Text(child.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Partner Attribution - show who logged this event
                    if showPartnerAttribution,
                       event.hasParentAttribution,
                       let parentName = event.loggedByParentName {
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 8))
                            Text(parentName)
                                .font(.caption2)
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(4)
                    }

                    if event.hasMedia {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if event.note != nil {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text(event.pointsApplied >= 0 ? "+\(event.pointsApplied)" : "\(event.pointsApplied)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(event.pointsApplied >= 0 ? AppColors.positive : AppColors.challenge)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func rewardEventRow(event: RewardHistoryEvent) -> some View {
        HStack(spacing: 12) {
            // Reward icon
            ZStack {
                Circle()
                    .fill(rewardEventColor(event.eventType).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: event.rewardIcon ?? "gift.fill")
                    .font(.system(size: 16))
                    .foregroundColor(rewardEventColor(event.eventType))
            }

            VStack(alignment: .leading, spacing: 2) {
                // Title based on event type
                Text(rewardEventTitle(event))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(formatTime(event.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if childrenStore.children.count > 1, let child = childrenStore.child(id: event.childId) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(child.colorTag.color)
                                .frame(width: 6, height: 6)
                            Text(child.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Stars info
                    Text("\(event.starsEarnedAtEvent) stars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Event type badge
            Text(event.eventType.displayName)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(rewardEventColor(event.eventType).opacity(0.15))
                .foregroundColor(rewardEventColor(event.eventType))
                .cornerRadius(8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func rewardEventTitle(_ event: RewardHistoryEvent) -> String {
        guard let child = childrenStore.child(id: event.childId) else {
            return event.rewardName
        }

        switch event.eventType {
        case .earned:
            return "\(child.name) earned \"\(event.rewardName)\""
        case .given:
            return "\(child.name) got \"\(event.rewardName)\""
        case .expired:
            return "\"\(event.rewardName)\" expired"
        }
    }

    private func rewardEventColor(_ type: RewardHistoryEvent.EventType) -> Color {
        switch type {
        case .earned: return .purple
        case .given: return AppColors.positive
        case .expired: return .orange
        }
    }

    private var dayOfWeek: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return DayRowFormatterCache.dayFormatter.string(from: date)
        }
    }

    private var dayNumber: String {
        DayRowFormatterCache.dayMonthFormatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        DayRowFormatterCache.timeFormatter.string(from: date)
    }
}
