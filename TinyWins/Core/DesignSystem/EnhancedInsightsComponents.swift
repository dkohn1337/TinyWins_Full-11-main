import SwiftUI

// MARK: - Enhanced Insights Components
// Emotion-driven analytics with rich visualizations

// MARK: - Hero Stats Card

/// Large emotional impact card showing parenting stats
struct InsightsHeroCard: View {
    let totalMoments: Int
    let positivePercentage: Int
    let currentStreak: Int
    let goalsCompleted: Int

    @Environment(\.theme) private var theme
    private var emotionalMessage: String {
        if totalMoments == 0 {
            return "Start logging moments to see your impact unfold."
        } else if totalMoments < 10 {
            return "Every moment you notice matters. Keep going."
        } else if totalMoments < 50 {
            return "You're building powerful awareness. Your attention is changing everything."
        } else if totalMoments < 100 {
            return "This many moments? You're showing your child what matters most."
        } else if totalMoments < 500 {
            return "You've created \(totalMoments) memories of noticing the good. That's legacy-building."
        } else {
            return "You're in the top 1% of mindful parents. Your children will remember this."
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.pink)
                        .shadow(color: .pink.opacity(0.4), radius: 8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Parenting Impact")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)

                    Text("\(totalMoments) Moments Captured")
                        .font(.system(size: 28, weight: .black))
                }

                Spacer()
            }

            // Emotional message
            Text(emotionalMessage)
                .font(.system(size: 17))
                .foregroundColor(theme.textSecondary)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Quick stats
            HStack(spacing: 16) {
                QuickStatItem(
                    value: "\(positivePercentage)%",
                    label: "Positive",
                    icon: "sun.max.fill",
                    color: .green
                )

                QuickStatItem(
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )

                QuickStatItem(
                    value: "\(goalsCompleted)",
                    label: "Goals Won",
                    icon: "trophy.fill",
                    color: .purple
                )
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.1),
                    Color.purple.opacity(0.05),
                    theme.surface1
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
    }
}

/// Small stat item for the hero card
struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pattern Discovery Card

/// Interactive pattern discovery with reveal animation
struct PatternDiscoveryCard: View {
    let pattern: DiscoveredPattern
    @State private var isRevealed = false

    @Environment(\.theme) private var theme

    struct DiscoveredPattern: Identifiable {
        let id = UUID()
        let title: String
        let category: String
        let icon: String
        let color: Color
        let insight: String
        let suggestion: String?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [pattern.color, pattern.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: pattern.color.opacity(0.4), radius: 8)

                    Image(systemName: pattern.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.title)
                        .font(.system(size: 18, weight: .bold))
                    Text(pattern.category)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                if !isRevealed {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isRevealed = true
                        }
                        HapticManager.shared.success()
                    }) {
                        Text("Reveal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(pattern.color)
                            .cornerRadius(8)
                    }
                }
            }

            if isRevealed {
                VStack(alignment: .leading, spacing: 12) {
                    Text(pattern.insight)
                        .font(.system(size: 16))
                        .foregroundColor(theme.textPrimary)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    if let suggestion = pattern.suggestion {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.yellow)

                            Text(suggestion)
                                .font(.system(size: 15))
                                .italic()
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(14)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(pattern.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(pattern.color.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Animated Weekly Chart

/// Bar chart with animated entrance
struct AnimatedWeeklyChart: View {
    let data: [DayData]
    @State private var animatedValues: [CGFloat]

    @Environment(\.theme) private var theme
    struct DayData: Identifiable {
        let id = UUID()
        let shortName: String
        let positive: Int
        let challenges: Int
        let isToday: Bool
    }

    init(data: [DayData]) {
        self.data = data
        self._animatedValues = State(initialValue: Array(repeating: 0, count: data.count))
    }

    private var maxValue: Int {
        data.map { $0.positive + $0.challenges }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Week at a Glance")
                .font(.system(size: 22, weight: .bold))

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, day in
                    VStack(spacing: 8) {
                        // Stacked bar
                        VStack(spacing: 2) {
                            // Positive moments (green)
                            if day.positive > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .green.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: barHeight(for: day.positive) * animatedValues[index])
                            }

                            // Challenge moments (orange)
                            if day.challenges > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .orange.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: barHeight(for: day.challenges) * animatedValues[index])
                            }

                            // Empty placeholder if no data
                            if day.positive == 0 && day.challenges == 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.borderSoft)
                                    .frame(height: 8)
                            }
                        }
                        .frame(height: 140, alignment: .bottom)

                        // Day label
                        Text(day.shortName)
                            .font(.system(size: 12, weight: day.isToday ? .bold : .medium))
                            .foregroundColor(day.isToday ? theme.textPrimary : theme.textSecondary)

                        // Today indicator
                        if day.isToday {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Legend
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("Positive")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                    Text("Challenges")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.surface1)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        )
        .onAppear {
            for i in 0..<data.count {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.08)) {
                    animatedValues[i] = 1.0
                }
            }
        }
    }

    private func barHeight(for value: Int) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value) / CGFloat(maxValue) * 120
    }
}

// MARK: - Streak Calendar

/// Visual calendar showing streak progression
struct StreakCalendarView: View {
    let streakDays: [Date]
    let currentStreak: Int

    @Environment(\.theme) private var theme
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var last28Days: [Date] {
        (0..<28).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: Date())
        }.reversed()
    }

    private func isStreakDay(_ date: Date) -> Bool {
        streakDays.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StreakFlameView(streakCount: currentStreak)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentStreak) Day Streak")
                        .font(.system(size: 24, weight: .bold))

                    Text(streakMessage)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(last28Days, id: \.self) { date in
                    let isStreak = isStreakDay(date)
                    let isToday = calendar.isDateInToday(date)

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isStreak ? Color.orange : theme.surface2)
                            .frame(height: 32)

                        if isStreak {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        } else {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 10))
                                .foregroundColor(theme.textSecondary)
                        }

                        if isToday {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.blue, lineWidth: 2)
                        }
                    }
                }
            }

            // Milestone markers
            HStack(spacing: 16) {
                StreakMilestone(days: 7, achieved: currentStreak >= 7, label: "1 Week")
                StreakMilestone(days: 14, achieved: currentStreak >= 14, label: "2 Weeks")
                StreakMilestone(days: 30, achieved: currentStreak >= 30, label: "1 Month")
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.1), .yellow.opacity(0.05), theme.surface1],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var streakMessage: String {
        switch currentStreak {
        case 0: return "Start your streak today!"
        case 1...2: return "Great start! Keep going!"
        case 3...6: return "Building momentum!"
        case 7...13: return "One full week! Amazing!"
        case 14...29: return "Two weeks strong!"
        default: return "You're unstoppable!"
        }
    }
}

/// Individual streak milestone indicator
struct StreakMilestone: View {
    let days: Int
    let achieved: Bool
    let label: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achieved ? Color.orange : theme.borderSoft)
                    .frame(width: 44, height: 44)

                if achieved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(days)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(achieved ? .orange : theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Emotional Timeline

/// Visual timeline of moments with emotional context
struct EmotionalTimelineView: View {
    let moments: [MomentData]

    @Environment(\.theme) private var theme
    struct MomentData: Identifiable {
        let id = UUID()
        let childName: String
        let childColor: Color
        let momentType: MomentType
        let description: String
        let time: Date

        enum MomentType {
            case positive, challenge

            var color: Color {
                switch self {
                case .positive: return .green
                case .challenge: return .orange
                }
            }

            var icon: String {
                switch self {
                case .positive: return "sun.max.fill"
                case .challenge: return "cloud.fill"
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Moments")
                .font(.system(size: 22, weight: .bold))

            ForEach(moments.prefix(5)) { moment in
                HStack(alignment: .top, spacing: 16) {
                    // Timeline dot
                    VStack(spacing: 0) {
                        Circle()
                            .fill(moment.momentType.color)
                            .frame(width: 14, height: 14)

                        if moment.id != moments.prefix(5).last?.id {
                            Rectangle()
                                .fill(theme.borderStrong)
                                .frame(width: 2, height: 60)
                        }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle()
                                .fill(moment.childColor)
                                .frame(width: 24, height: 24)

                            Text(moment.childName)
                                .font(.system(size: 14, weight: .semibold))

                            Spacer()

                            Text(timeAgoString(from: moment.time))
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: moment.momentType.icon)
                                .font(.system(size: 14))
                                .foregroundColor(moment.momentType.color)

                            Text(moment.description)
                                .font(.system(size: 15))
                                .foregroundColor(theme.textPrimary)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(moment.momentType.color.opacity(0.08))
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.surface1)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        )
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Child Comparison Cards (Optional Premium Feature)

/// Compare insights across children
struct ChildComparisonCard: View {
    let children: [ChildInsightData]

    @Environment(\.theme) private var theme
    struct ChildInsightData: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
        let totalMoments: Int
        let positiveRatio: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                Text("By Child")
                    .font(.system(size: 22, weight: .bold))
            }

            ForEach(children) { child in
                HStack(spacing: 12) {
                    Circle()
                        .fill(child.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(child.name.prefix(1))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 16, weight: .semibold))

                        Text("\(child.totalMoments) moments")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    // Positive ratio visual
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(child.positiveRatio * 100))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)

                        Text("positive")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(child.color.opacity(0.08))
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.surface1)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        )
    }
}

// MARK: - Previews

#Preview("Hero Card") {
    InsightsHeroCard(
        totalMoments: 247,
        positivePercentage: 78,
        currentStreak: 12,
        goalsCompleted: 5
    )
    .padding()
}

#Preview("Pattern Discovery") {
    PatternDiscoveryCard(
        pattern: .init(
            title: "Morning Success",
            category: "Time Pattern",
            icon: "sunrise.fill",
            color: .orange,
            insight: "Sarah has had 4 cooperative mornings this week - you're seeing real progress in the morning routine.",
            suggestion: "Try noting what specifically worked on those mornings to replicate it."
        )
    )
    .padding()
}

#Preview("Weekly Chart") {
    AnimatedWeeklyChart(data: [
        .init(shortName: "Mon", positive: 5, challenges: 2, isToday: false),
        .init(shortName: "Tue", positive: 3, challenges: 1, isToday: false),
        .init(shortName: "Wed", positive: 7, challenges: 0, isToday: false),
        .init(shortName: "Thu", positive: 4, challenges: 2, isToday: false),
        .init(shortName: "Fri", positive: 6, challenges: 1, isToday: false),
        .init(shortName: "Sat", positive: 8, challenges: 0, isToday: false),
        .init(shortName: "Sun", positive: 2, challenges: 0, isToday: true)
    ])
    .padding()
}
