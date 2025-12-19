import SwiftUI

// MARK: - PartnerDashboardView

/// Dashboard showing co-parent activity comparison and alignment.
/// Shows side-by-side stats and celebrates shared observations.
/// Design philosophy: Celebration, not competition. "Together we noticed X wins!"
struct PartnerDashboardView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var selectedPeriod: TimePeriod = .thisWeek
    @State private var selectedChildId: UUID?
    @State private var showingPaywall = false

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    private var totalWinsThisPeriod: Int {
        let range = selectedPeriod.dateRange
        return repository.appData.behaviorEvents.filter {
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end &&
            $0.pointsApplied > 0
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Selector
                periodSelector

                // Together Summary - Celebration Card
                togetherSummaryCard

                // Parent Comparison
                if repository.appData.hasCoParentSync {
                    parentComparisonSection
                    alignmentSection
                    recentActivitySection
                } else {
                    notConnectedView
                }
            }
            .padding()
        }
        .background(theme.bg0.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Better Together")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    Text(repository.appData.family.name)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Together Summary Card

    private var togetherSummaryCard: some View {
        VStack(spacing: 16) {
            // Heart Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "heart.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Together Message
            VStack(spacing: 8) {
                Text("Together you noticed")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)

                HStack(spacing: 4) {
                    Text("\(totalWinsThisPeriod)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(totalWinsThisPeriod == 1 ? "win" : "wins")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                }

                Text(selectedPeriod.displayName.lowercased())
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }

            // Encouragement
            if totalWinsThisPeriod > 0 {
                Text(encouragementMessage)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    private var encouragementMessage: String {
        switch totalWinsThisPeriod {
        case 0:
            return "Start logging together to see your combined wins!"
        case 1...5:
            return "Every small win matters. Keep noticing the good!"
        case 6...15:
            return "Great teamwork! Your attention makes a difference."
        case 16...30:
            return "Amazing! Your kids are lucky to have such observant parents."
        default:
            return "Incredible dedication! You're building something beautiful together."
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([TimePeriod.today, .thisWeek, .thisMonth], id: \.rawValue) { period in
                    Button {
                        withAnimation {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedPeriod == period ? .white : theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPeriod == period ?
                                          theme.accentPrimary : theme.accentMuted)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Parent Comparison Section

    private var parentComparisonSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Activity Comparison")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }

            // Parent Cards Side by Side
            HStack(spacing: 16) {
                if let parent1 = repository.appData.currentParent {
                    parentStatCard(parent: parent1, isCurrentUser: true)
                }

                if let parent2 = repository.appData.partnerParent {
                    parentStatCard(parent: parent2, isCurrentUser: false)
                }
            }
        }
    }

    private func parentStatCard(parent: Parent, isCurrentUser: Bool) -> some View {
        let stats = calculateParentStats(parentId: parent.id)

        return VStack(spacing: 12) {
            // Avatar and Name
            VStack(spacing: 8) {
                Text(parent.avatarEmoji)
                    .font(.system(size: 40))

                Text(isCurrentUser ? "You" : parent.shortName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)

                // Activity indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(parent.isRecentlyActive ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text(parent.isRecentlyActive ? "Active" : "Away")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                }
            }

            Divider()

            // Stats
            VStack(spacing: 8) {
                statRow(label: "Wins Logged", value: "\(stats.totalEvents)", icon: "star.fill", color: theme.star)
                statRow(label: "Positive", value: "\(stats.positiveEvents)", icon: "hand.thumbsup.fill", color: theme.success)
                statRow(label: "Challenges", value: "\(stats.challengeEvents)", icon: "exclamationmark.triangle.fill", color: theme.danger)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(isCurrentUser ? theme.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private func statRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
        }
    }

    // MARK: - Alignment Section

    private var alignmentSection: some View {
        let alignmentData = calculateAlignmentScore()

        return VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Alignment")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()

                // Alignment Score
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                    Text("\(Int(alignmentData.score * 100))%")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }

            // Alignment Card
            VStack(spacing: 16) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(theme.textDisabled)
                            .frame(height: 12)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * alignmentData.score, height: 12)
                    }
                }
                .frame(height: 12)

                // Alignment Message
                Text(alignmentMessage(score: alignmentData.score))
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)

                // Shared Observations
                if !alignmentData.sharedBehaviors.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Both parents noticed:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textSecondary)

                        ForEach(alignmentData.sharedBehaviors.prefix(3), id: \.self) { behaviorName in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.success)
                                    .font(.caption)

                                Text(behaviorName)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(theme.surface1)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
        }
    }

    private func alignmentMessage(score: Double) -> String {
        switch score {
        case 0.8...1.0:
            return "Amazing! You and your partner are noticing the same behaviors."
        case 0.6..<0.8:
            return "Great teamwork! You're both tuned in to your child's wins."
        case 0.4..<0.6:
            return "Good balance! Different perspectives help see the whole picture."
        case 0.2..<0.4:
            return "You're catching different moments. That's valuable coverage!"
        default:
            return "Start logging together to see your alignment score."
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        let recentEvents = getRecentPartnerEvents()

        return VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Recent Partner Activity")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }

            if recentEvents.isEmpty {
                Text("No recent activity from your partner")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentEvents.prefix(5)) { event in
                        partnerEventRow(event)
                    }
                }
            }
        }
    }

    private func partnerEventRow(_ event: BehaviorEvent) -> some View {
        let behaviorType = repository.appData.behaviorTypes.first { $0.id == event.behaviorTypeId }
        let child = repository.appData.children.first { $0.id == event.childId }

        return HStack(spacing: 12) {
            // Partner Avatar
            if let partnerName = event.loggedByParentName,
               let partner = repository.appData.parents.first(where: { $0.displayName == partnerName }) {
                Text(partner.avatarEmoji)
                    .font(.title3)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(theme.textDisabled)
            }

            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                Text(behaviorType?.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)

                HStack(spacing: 4) {
                    Text(child?.name ?? "")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)

                    Text("•")
                        .foregroundColor(theme.textSecondary)

                    Text(event.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }

            Spacer()

            // Points
            PointsBadge(points: event.pointsApplied, useStars: true)
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(12)
    }

    // MARK: - Not Connected View

    private var notConnectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(theme.textDisabled)

            Text("Partner Not Connected")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Text("Invite your partner to see activity comparisons and celebrate alignment.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: CoParentSettingsView()) {
                Text("Set Up Co-Parent Sync")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accentPrimary)
                    .cornerRadius(theme.cornerRadius)
            }
        }
        .padding(32)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
    }

    // MARK: - Data Calculations

    private func calculateParentStats(parentId: String) -> ParentStats {
        let events = repository.appData.events(loggedBy: parentId, in: selectedPeriod)

        let positiveEvents = events.filter { $0.pointsApplied > 0 }.count
        let challengeEvents = events.filter { $0.pointsApplied < 0 }.count

        return ParentStats(
            totalEvents: events.count,
            positiveEvents: positiveEvents,
            challengeEvents: challengeEvents
        )
    }

    private func calculateAlignmentScore() -> AlignmentData {
        guard let parent1 = repository.appData.currentParent,
              let parent2 = repository.appData.partnerParent else {
            return AlignmentData(score: 0, sharedBehaviors: [])
        }

        let parent1Events = repository.appData.events(loggedBy: parent1.id, in: selectedPeriod)
        let parent2Events = repository.appData.events(loggedBy: parent2.id, in: selectedPeriod)

        // Get unique behavior types logged by each parent
        let parent1BehaviorIds = Set(parent1Events.map { $0.behaviorTypeId })
        let parent2BehaviorIds = Set(parent2Events.map { $0.behaviorTypeId })

        // Find shared behaviors
        let sharedBehaviorIds = parent1BehaviorIds.intersection(parent2BehaviorIds)
        let allBehaviorIds = parent1BehaviorIds.union(parent2BehaviorIds)

        // Calculate Jaccard similarity
        let score = allBehaviorIds.isEmpty ? 0 :
            Double(sharedBehaviorIds.count) / Double(allBehaviorIds.count)

        // Get names of shared behaviors
        let sharedBehaviors = sharedBehaviorIds.compactMap { behaviorId in
            repository.appData.behaviorTypes.first { $0.id == behaviorId }?.name
        }

        return AlignmentData(score: score, sharedBehaviors: sharedBehaviors)
    }

    private func getRecentPartnerEvents() -> [BehaviorEvent] {
        guard let partnerId = repository.appData.partnerParent?.id else {
            return []
        }

        return repository.appData.behaviorEvents
            .filter { $0.loggedByParentId == partnerId }
            .sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Helper Types

private struct ParentStats {
    let totalEvents: Int
    let positiveEvents: Int
    let challengeEvents: Int
}

private struct AlignmentData {
    let score: Double
    let sharedBehaviors: [String]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PartnerDashboardView()
    }
    .environmentObject(Repository.preview)
    .environmentObject(SubscriptionManager.shared)
    .withTheme(Theme())
}
