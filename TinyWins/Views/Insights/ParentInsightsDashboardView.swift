import SwiftUI

/// Dashboard view showing parent reflection insights (Plus feature)
struct ParentInsightsDashboardView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var insights: ReflectionInsightUseCase.ParentInsightsSummary?
    @State private var isLoading = true

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.purple)
                Text("Your Parenting Journey")
                    .font(.headline)

                Spacer()

                if isPlusSubscriber {
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
            }

            if isLoading {
                loadingView
            } else if let insights = insights {
                insightsContent(insights)
            } else {
                emptyState
            }
        }
        .padding()
        .background(theme.bg0)
        .cornerRadius(16)
        .task {
            await loadInsights()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.title)
                .foregroundColor(theme.textSecondary.opacity(0.5))

            Text("Start reflecting to see your insights")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Insights Content

    @ViewBuilder
    private func insightsContent(_ insights: ReflectionInsightUseCase.ParentInsightsSummary) -> some View {
        VStack(spacing: 12) {
            // Streak card
            if insights.currentStreak > 0 {
                streakCard(streak: insights.currentStreak)
            }

            // Top strength card
            if let topStrength = insights.topStrength {
                topStrengthCard(topStrength)
            }

            // Correlation insight (Plus only)
            if isPlusSubscriber, let correlation = insights.correlation {
                correlationCard(correlation)
            }

            // Month in review (Plus only, at 30+ day streak)
            if isPlusSubscriber, insights.currentStreak >= 7, let monthReview = insights.monthInReview {
                monthInReviewCard(monthReview)
            }
        }
    }

    // MARK: - Reflection Consistency Card

    private func streakCard(streak: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) days of reflection")
                    .font(.subheadline.weight(.semibold))
                Text(consistencyMessage(streak))
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
    }

    private func consistencyMessage(_ days: Int) -> String {
        if days >= 30 {
            return "A month of self-care"
        } else if days >= 14 {
            return "Your reflection practice is growing"
        } else if days >= 7 {
            return "A full week of taking time for yourself"
        } else {
            return "Building your practice"
        }
    }

    // MARK: - Top Strength Card

    private func topStrengthCard(_ topStrength: ReflectionInsightUseCase.TopStrengthInsight) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.pink)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your top strength \(topStrength.period)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Text(topStrength.strength)
                    .font(.subheadline.weight(.semibold))
                Text("\(topStrength.count)x this period")
                    .font(.caption)
                    .foregroundColor(.pink)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.pink.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Correlation Card

    private func correlationCard(_ correlation: ReflectionInsightUseCase.CorrelationInsight) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.teal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Reflection Impact")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Text("\(correlation.percentageMorePositive)% more positive moments")
                    .font(.subheadline.weight(.semibold))
                Text("on days you reflect")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.teal.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Month in Review Card

    private func monthInReviewCard(_ review: ReflectionInsightUseCase.MonthInReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.indigo)
                Text("\(review.month) in Review")
                    .font(.subheadline.weight(.semibold))
            }

            Divider()

            // Stats grid
            HStack(spacing: 0) {
                MonthStatCell(
                    value: "\(review.totalReflections)",
                    label: "Reflections",
                    color: .purple
                )

                Divider()
                    .frame(height: 40)

                MonthStatCell(
                    value: "\(review.totalPositiveMoments)",
                    label: "Wins Logged",
                    color: .green
                )

                if review.reflectionStreak > 0 {
                    Divider()
                        .frame(height: 40)

                    MonthStatCell(
                        value: "\(review.reflectionStreak)",
                        label: "Day Streak",
                        color: .orange
                    )
                }
            }

            // Top strengths
            if !review.topStrengths.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Top strengths this month:")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)

                    FlowLayout(spacing: 6) {
                        ForEach(review.topStrengths, id: \.self) { strength in
                            Text(strength)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.pink.opacity(0.1))
                                .foregroundColor(.pink)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.indigo.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Load Insights

    @MainActor
    private func loadInsights() async {
        isLoading = true

        // Small delay for UX
        try? await Task.sleep(nanoseconds: 200_000_000)

        let useCase = ReflectionInsightUseCase(
            repository: repository,
            behaviorsStore: behaviorsStore,
            childrenStore: childrenStore
        )

        insights = useCase.generateAllInsights()
        isLoading = false
    }
}

// MARK: - Month Stat Cell

private struct MonthStatCell: View {
    @Environment(\.theme) private var theme
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    ScrollView {
        ParentInsightsDashboardView()
            .environmentObject(repository)
            .environmentObject(BehaviorsStore(repository: repository))
            .environmentObject(ChildrenStore(repository: repository))
            .environmentObject(SubscriptionManager.shared)
            .padding()
    }
}
