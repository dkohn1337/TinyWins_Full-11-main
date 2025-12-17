import SwiftUI

/// View showing correlation between parent reflection and kid's positive moments (Plus feature)
/// Uses soft, celebratory language - NO causation claims
struct KidConnectionInsightView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    private let calendar = Calendar.current

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    private var insight: ConnectionInsight? {
        generateInsight()
    }

    var body: some View {
        if let insight = insight {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.title2)

                    Text("Connection Moment")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text("PLUS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }

                // Main message
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Supporting detail
                if let detail = insight.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Visual representation
                if let childName = insight.childName {
                    HStack(spacing: 12) {
                        // Parent side
                        VStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundColor(.purple)
                            Text("You")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 50)

                        // Connection line
                        ZStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 2)

                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                        }

                        // Child side
                        VStack(spacing: 4) {
                            Image(systemName: "face.smiling.fill")
                                .font(.title3)
                                .foregroundColor(.pink)
                            Text(childName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 50)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.08), Color.pink.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Insight Generation

    struct ConnectionInsight {
        let message: String
        let detail: String?
        let childName: String?
    }

    private func generateInsight() -> ConnectionInsight? {
        guard isPlusSubscriber else { return nil }

        // Get data for analysis (last 30 days)
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // Parent reflection data
        let daysWithReflections = repository.getDaysWithReflections(from: startDate, to: Date())
        let reflectionStreak = repository.appData.calculateReflectionStreak()

        // Child data
        let children = childrenStore.children
        guard !children.isEmpty else { return nil }

        // Need at least 7 reflection days to show insight
        guard daysWithReflections.count >= 7 else { return nil }

        // Get behavior events by day
        let events = behaviorsStore.behaviorEvents.filter { $0.timestamp >= startDate }
        let positiveEvents = events.filter { $0.pointsApplied > 0 }

        guard positiveEvents.count >= 10 else { return nil }

        // Find child with most positive moments
        let childPositiveCounts = Dictionary(grouping: positiveEvents) { $0.childId }
            .mapValues { $0.count }
        guard let topChildId = childPositiveCounts.max(by: { $0.value < $1.value })?.key,
              let topChild = children.first(where: { $0.id == topChildId }) else {
            return nil
        }

        let topChildPositiveCount = childPositiveCounts[topChildId] ?? 0

        // Generate appropriate message based on patterns
        // IMPORTANT: All messages use soft, celebratory language - NO causation!

        if reflectionStreak >= 14 {
            return ConnectionInsight(
                message: "Your reflection streak is growing beautifully. \(topChild.name) has had \(topChildPositiveCount) positive moments this month too!",
                detail: "Both of you are thriving together.",
                childName: topChild.name
            )
        }

        if reflectionStreak >= 7 {
            return ConnectionInsight(
                message: "A week of reflection! \(topChild.name) has also been shining with \(topChildPositiveCount) wins this month.",
                detail: "Great things are happening for your family.",
                childName: topChild.name
            )
        }

        if daysWithReflections.count >= 14 {
            return ConnectionInsight(
                message: "You've been reflecting regularly. \(topChild.name) has been having a wonderful month with \(topChildPositiveCount) positive moments!",
                detail: "Your family is in a good rhythm.",
                childName: topChild.name
            )
        }

        // Default: Just celebrate both doing well
        return ConnectionInsight(
            message: "You're showing up for yourself, and \(topChild.name) is doing great with \(topChildPositiveCount) wins this month!",
            detail: nil,
            childName: topChild.name
        )
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    KidConnectionInsightView()
        .environmentObject(repository)
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(SubscriptionManager.shared)
        .padding()
}
