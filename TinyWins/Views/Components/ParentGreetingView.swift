import SwiftUI

/// A calm, time-of-day greeting with goal celebration and comparison
/// Shows meaningful context to make parents feel progress
struct ParentGreetingView: View {
    let totalPositiveToday: Int
    let totalChallengesToday: Int
    var yesterdayPositive: Int = 0
    var childrenWithGoalsReached: [String] = []
    var onAddTapped: (() -> Void)? = nil
    @Environment(\.theme) private var theme

    private var totalMomentsToday: Int {
        totalPositiveToday + totalChallengesToday
    }

    // MARK: - Time of Day

    private enum TimeOfDay {
        case morning      // 5-11
        case afternoon    // 12-17
        case evening      // 18-23
        case lateNight    // 0-4

        var iconName: String {
            switch self {
            case .morning: return "sun.max.fill"
            case .afternoon: return "sun.min.fill"
            case .evening, .lateNight: return "moon.fill"
            }
        }

        var greeting: String {
            switch self {
            case .morning: return "Good morning"
            case .afternoon: return "Good afternoon"
            case .evening, .lateNight: return "Good evening"
            }
        }

        var isEveningOrLateNight: Bool {
            self == .evening || self == .lateNight
        }
    }

    private var currentTimeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...11: return .morning
        case 12...17: return .afternoon
        case 18...23: return .evening
        default: return .lateNight // 0-4
        }
    }

    // MARK: - Comparison Text

    private var comparisonText: String? {
        guard yesterdayPositive > 0 || totalPositiveToday > 0 else { return nil }

        let diff = totalPositiveToday - yesterdayPositive
        if diff > 0 {
            return "\(diff) more than yesterday"
        } else if diff < 0 {
            return "\(abs(diff)) fewer than yesterday"
        } else if yesterdayPositive > 0 {
            return "Same as yesterday"
        }
        return nil
    }

    // MARK: - Goal Celebration Text

    private var goalCelebrationText: String? {
        guard !childrenWithGoalsReached.isEmpty else { return nil }

        if childrenWithGoalsReached.count == 1 {
            return "\(childrenWithGoalsReached[0]) hit their goal! 🎉"
        } else if childrenWithGoalsReached.count == 2 {
            return "\(childrenWithGoalsReached[0]) and \(childrenWithGoalsReached[1]) hit their goals! 🎉"
        } else {
            return "\(childrenWithGoalsReached.count) kids hit their goals! 🎉"
        }
    }

    // MARK: - Quiet Day Message

    private var quietDayMessage: String {
        let time = currentTimeOfDay
        switch time {
        case .morning:
            return "A fresh day to notice the good"
        case .afternoon:
            return "Quiet day — that's okay"
        case .evening, .lateNight:
            return "Every moment counts"
        }
    }

    // MARK: - Body

    var body: some View {
        let gradientColors = theme.accentGradient

        VStack(spacing: AppSpacing.md) {
            // Time-based icon and greeting
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: currentTimeOfDay.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text(currentTimeOfDay.greeting)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Goal celebration (if any)
            if let celebration = goalCelebrationText {
                HStack(spacing: 6) {
                    Text(celebration)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Main stat display
            if totalMomentsToday > 0 {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                    Text("\(totalPositiveToday)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("positive")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Text("moments today")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))

                        // Comparison to yesterday
                        if let comparison = comparisonText {
                            Text(comparison)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // No moments yet - encouraging message
                VStack(alignment: .leading, spacing: 4) {
                    Text(quietDayMessage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    if yesterdayPositive > 0 {
                        Text("You logged \(yesterdayPositive) yesterday")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Primary CTA button
            if let onAddTapped = onAddTapped {
                Button(action: onAddTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add a Tiny Win")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Add a tiny win for your child")
            }
        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [
                    gradientColors.first?.opacity(0.95) ?? Color.accentColor.opacity(0.9),
                    gradientColors.last?.opacity(0.85) ?? Color.accentColor.opacity(0.7),
                    theme.accentSecondary.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(theme.cornerRadius + 4)
        .shadow(color: (gradientColors.first ?? Color.accentColor).opacity(theme.isDark ? 0.4 : 0.3), radius: 16, y: 6)
        .transition(.opacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: totalPositiveToday)
    }
}

// MARK: - Preview

#Preview("Morning - No Moments") {
    VStack(spacing: 20) {
        ParentGreetingView(totalPositiveToday: 0, totalChallengesToday: 0)
        ParentGreetingView(totalPositiveToday: 3, totalChallengesToday: 1)
        ParentGreetingView(totalPositiveToday: 1, totalChallengesToday: 0)
    }
    .padding()
}

#Preview("Evening States") {
    VStack(spacing: 20) {
        ParentGreetingView(totalPositiveToday: 5, totalChallengesToday: 2)
        ParentGreetingView(totalPositiveToday: 2, totalChallengesToday: 5)
        ParentGreetingView(totalPositiveToday: 0, totalChallengesToday: 0)
    }
    .padding()
}
