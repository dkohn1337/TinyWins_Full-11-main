import SwiftUI

// MARK: - Urgency & Countdown Components
// Components for time-sensitive displays and countdowns

/// Countdown timer with pulsing urgency effect
struct UrgencyTimerView: View {
    @Environment(\.theme) private var theme
    let targetDate: Date
    let label: String?

    @State private var timeRemaining: String = ""
    @State private var pulse: CGFloat = 1.0
    @State private var timer: Timer?

    private var isUrgent: Bool {
        targetDate.timeIntervalSinceNow < 86400 // Less than 24 hours
    }

    private var isCritical: Bool {
        targetDate.timeIntervalSinceNow < 3600 // Less than 1 hour
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 18))
                .foregroundColor(isCritical ? .red : (isUrgent ? .orange : .blue))
                .scaleEffect(isCritical ? pulse : 1.0)

            VStack(alignment: .leading, spacing: 2) {
                if let label = label {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                Text(timeRemaining)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(isCritical ? .red : (isUrgent ? .orange : theme.textPrimary))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isCritical ? Color.red.opacity(0.15) : (isUrgent ? Color.orange.opacity(0.15) : Color.blue.opacity(0.1)))
        )
        .onAppear {
            updateTimeRemaining()
            startTimer()
            if isCritical {
                startPulse()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeRemaining()
        }
    }

    private func updateTimeRemaining() {
        let interval = targetDate.timeIntervalSinceNow
        if interval <= 0 {
            timeRemaining = "Expired!"
            timer?.invalidate()
            return
        }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if days > 0 {
            timeRemaining = "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            timeRemaining = "\(hours)h \(minutes)m \(seconds)s"
        } else {
            timeRemaining = "\(minutes)m \(seconds)s"
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulse = 1.2
        }
    }
}

/// Pulsing "READY!" badge for completed goals
struct ReadyBadgeView: View {
    let size: BadgeSize
    @State private var pulse: CGFloat = 1.0
    @State private var glow: CGFloat = 0.3

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 40
            case .large: return 56
            }
        }

        var textSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 18
            case .large: return 24
            }
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: size.iconSize))
                .foregroundColor(.green)
                .scaleEffect(pulse)
                .shadow(color: .green.opacity(glow), radius: 20)

            Text("READY!")
                .font(.system(size: size.textSize, weight: .black))
                .foregroundColor(.green)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = 1.15
                glow = 0.7
            }
        }
    }
}

/// Urgency banner for limited-time offers
struct FOMOBannerView: View {
    let message: String
    let deadline: Date?
    let action: () -> Void

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    if let deadline = deadline {
                        UrgencyTimerView(targetDate: deadline, label: nil)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset)
                .mask(
                    RoundedRectangle(cornerRadius: 16)
                )
            )
            .cornerRadius(16)
            .shadow(color: .purple.opacity(0.4), radius: 16, y: 8)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

/// Deadline proximity warning badge for goals
struct DeadlineProximityBadge: View {
    let daysRemaining: Int

    private var urgencyLevel: UrgencyLevel {
        if daysRemaining <= 1 { return .critical }
        if daysRemaining <= 3 { return .high }
        if daysRemaining <= 7 { return .medium }
        return .low
    }

    private enum UrgencyLevel {
        case critical, high, medium, low

        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            }
        }

        var icon: String {
            switch self {
            case .critical: return "exclamationmark.triangle.fill"
            case .high: return "clock.badge.exclamationmark.fill"
            case .medium: return "clock.fill"
            case .low: return "calendar.badge.clock"
            }
        }

        var message: String {
            switch self {
            case .critical: return "Ends soon!"
            case .high: return "Hurry!"
            case .medium: return "Time limit"
            case .low: return "Deadline"
            }
        }
    }

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: urgencyLevel.icon)
                .font(.system(size: 10, weight: .semibold))
                .scaleEffect(pulse && urgencyLevel == .critical ? 1.1 : 1.0)

            if daysRemaining == 0 {
                Text("Today!")
                    .font(.system(size: 10, weight: .bold))
            } else if daysRemaining == 1 {
                Text("1 day left")
                    .font(.system(size: 10, weight: .semibold))
            } else {
                Text("\(daysRemaining) days")
                    .font(.system(size: 10, weight: .semibold))
            }
        }
        .foregroundColor(urgencyLevel == .low ? urgencyLevel.color : .white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(urgencyLevel == .low ? urgencyLevel.color.opacity(0.15) : urgencyLevel.color)
        )
        .onAppear {
            if urgencyLevel == .critical {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}

/// Inline deadline warning text for compact displays
struct DeadlineWarningText: View {
    @Environment(\.theme) private var theme
    let daysRemaining: Int

    private var isUrgent: Bool { daysRemaining <= 3 }
    private var isCritical: Bool { daysRemaining <= 1 }

    var body: some View {
        HStack(spacing: 4) {
            if isCritical {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
            }

            if daysRemaining == 0 {
                Text("Ends today!")
            } else if daysRemaining == 1 {
                Text("1 day left!")
            } else {
                Text("\(daysRemaining) days remaining")
            }
        }
        .font(.system(size: 11, weight: isUrgent ? .semibold : .regular))
        .foregroundColor(isCritical ? .red : (isUrgent ? .orange : theme.textSecondary))
    }
}

// MARK: - Preview

#Preview("Ready Badge") {
    HStack(spacing: 40) {
        ReadyBadgeView(size: .small)
        ReadyBadgeView(size: .medium)
        ReadyBadgeView(size: .large)
    }
    .padding()
}
