import SwiftUI

// MARK: - Enhanced Rewards Components
// Premium redesign components for the Goals/Rewards View

// MARK: - Giant Goal Progress Card

/// Hero progress card for the primary goal with massive visuals
struct GiantGoalProgressCard: View {
    let child: Child
    let reward: Reward
    let currentStars: Int
    let targetStars: Int
    let deadline: Date?
    let isReady: Bool
    let onCelebrate: () -> Void
    let onShowKidView: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.3

    private var progress: CGFloat {
        guard targetStars > 0 else { return 0 }
        return min(CGFloat(currentStars) / CGFloat(targetStars), 1.0)
    }

    private var starsRemaining: Int {
        max(targetStars - currentStars, 0)
    }

    private var proximityMessage: String? {
        switch starsRemaining {
        case 0: return nil
        case 1: return "Just 1 more star!"
        case 2: return "Only 2 more!"
        case 3: return "Almost there!"
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with child info and urgency
            HStack {
                // Child avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text(child.emoji)
                            .font(.system(size: 28))
                    )
                    .shadow(color: child.colorTag.color.opacity(0.3), radius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 28, weight: .bold))

                    Text("Working toward a goal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Urgency timer if deadline exists
                if let deadline = deadline, !isReady {
                    UrgencyTimerView(targetDate: deadline, label: "Time left")
                }
            }
            .padding(24)

            // GIANT Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 28)
                    .frame(width: 260, height: 260)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                child.colorTag.color,
                                child.colorTag.color.opacity(0.7),
                                child.colorTag.color.opacity(0.5),
                                child.colorTag.color
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 28, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: child.colorTag.color.opacity(0.4), radius: 12)

                // Milestone markers
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { milestone in
                    Circle()
                        .fill(progress >= milestone ? child.colorTag.color : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .shadow(color: progress >= milestone ? child.colorTag.color.opacity(0.5) : .clear, radius: 8)
                        .offset(y: -130)
                        .rotationEffect(.degrees(milestone * 360 - 90))
                }

                // Center content
                VStack(spacing: 8) {
                    if isReady {
                        // Ready state
                        Image(systemName: "gift.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                            .scaleEffect(pulseScale)
                            .shadow(color: .green.opacity(glowOpacity), radius: 20)

                        Text("READY!")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.green)
                    } else {
                        // Progress state
                        Text("\(currentStars)")
                            .font(.system(size: 88, weight: .black, design: .rounded))
                            .foregroundColor(child.colorTag.color)

                        Text("of \(targetStars) stars")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.secondary)

                        if let message = proximityMessage {
                            Text(message)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(.vertical, 32)

            // Reward Card
            HStack(spacing: 16) {
                // Reward emoji/icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [child.colorTag.color.opacity(0.3), child.colorTag.color.opacity(0.1)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: reward.imageName ?? "gift.fill")
                        .font(.system(size: 40))
                        .foregroundColor(child.colorTag.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(reward.name)
                        .font(.system(size: 24, weight: .bold))

                    if let category = reward.category {
                        Text(category)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray6))
                            )
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            )
            .padding(.horizontal, 24)

            // Action buttons
            VStack(spacing: 12) {
                if isReady {
                    Button(action: onCelebrate) {
                        HStack(spacing: 12) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 20))
                            Text("Celebrate & Give Reward!")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.4), radius: 16, y: 8)
                    }
                }

                Button(action: onShowKidView) {
                    HStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 20))
                        Text("Show \(child.name)")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(isReady ? child.colorTag.color : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        isReady ?
                        AnyShapeStyle(child.colorTag.color.opacity(0.15)) :
                        AnyShapeStyle(LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                    .cornerRadius(16)
                    .shadow(color: isReady ? .clear : child.colorTag.color.opacity(0.3), radius: 12, y: 6)
                }
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            child.colorTag.color.opacity(0.08),
                            Color(.systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
        )
        .onAppear {
            if isReady {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                    glowOpacity = 0.7
                }
            }
        }
    }
}

// MARK: - Goal Card (Compact for Multiple Goals)

/// Compact goal card for secondary/upcoming goals
struct CompactGoalCard: View {
    let reward: Reward
    let child: Child
    let currentStars: Int
    let isReady: Bool
    let onTap: () -> Void
    let onMakePrimary: () -> Void

    @State private var isPressed = false

    private var progress: CGFloat {
        guard reward.targetPoints > 0 else { return 0 }
        return min(CGFloat(currentStars) / CGFloat(reward.targetPoints), 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            child.colorTag.color,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: reward.imageName ?? "gift.fill")
                        .font(.system(size: 24))
                        .foregroundColor(child.colorTag.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(reward.name)
                            .font(.system(size: 18, weight: .semibold))
                            .lineLimit(1)

                        if isReady {
                            ReadyBadgeView(size: .small)
                        }
                    }

                    Text("\(currentStars) of \(reward.targetPoints) stars")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(child.colorTag.color)
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer()

                // Make primary button
                Button(action: onMakePrimary) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(child.colorTag.color.opacity(0.6))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isPressed ? 0.12 : 0.06), radius: isPressed ? 8 : 12, y: isPressed ? 4 : 6)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Enhanced Child Switcher

/// Premium child switcher with ready badges and visual feedback
struct EnhancedChildSwitcher: View {
    let children: [Child]
    let selectedChildId: UUID?
    let childSummary: (Child) -> String
    let hasReadyReward: (Child) -> Bool
    let onSelect: (Child) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(children) { child in
                    EnhancedChildPill(
                        child: child,
                        isSelected: selectedChildId == child.id,
                        summary: childSummary(child),
                        hasReadyReward: hasReadyReward(child),
                        onTap: { onSelect(child) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

/// Individual child pill with premium styling
struct EnhancedChildPill: View {
    let child: Child
    let isSelected: Bool
    let summary: String
    let hasReadyReward: Bool
    let onTap: () -> Void

    @State private var readyPulse: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar with glow when selected
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(child.colorTag.color.opacity(0.3))
                            .frame(width: 52, height: 52)
                            .blur(radius: 8)
                    }

                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [.white, .white.opacity(0.9)], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [child.colorTag.color.opacity(0.2), child.colorTag.color.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(child.emoji)
                                .font(.system(size: 24))
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.system(size: 16, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                // Ready indicator
                if hasReadyReward && !isSelected {
                    VStack(spacing: 2) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .scaleEffect(readyPulse)

                        Text("Ready")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            readyPulse = 1.15
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        isSelected ?
                        LinearGradient(colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: isSelected ? child.colorTag.color.opacity(0.4) : .black.opacity(0.06), radius: isSelected ? 12 : 8, y: isSelected ? 6 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        isSelected ? Color.clear : Color(.systemGray5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State (No Goals)

/// Premium empty state for when no goals are set
struct NoGoalsEmptyStateView: View {
    let children: [Child]
    let onAddGoal: (Child) -> Void

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated illustration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.2), .pink.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "target")
                    .font(.system(size: 100))
                    .foregroundColor(.purple.opacity(0.4))
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .offset(x: 30, y: -30)
                    .shadow(color: .yellow.opacity(0.5), radius: 12)
            }

            VStack(spacing: 12) {
                Text("Set Your First Goal!")
                    .font(.system(size: 32, weight: .bold))

                Text("Goals turn everyday moments into exciting achievements your child can see and celebrate.")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Child buttons
            VStack(spacing: 12) {
                ForEach(children) { child in
                    Button(action: { onAddGoal(child) }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(child.colorTag.color.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(child.emoji)
                                        .font(.system(size: 24))
                                )

                            Text("Pick a goal for \(child.name)")
                                .font(.system(size: 18, weight: .semibold))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(child.colorTag.color)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(child.colorTag.color.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Add Goal Prompt

/// Premium prompt to add a new goal
struct AddGoalPromptView: View {
    let child: Child
    let hasCompletedGoals: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [child.colorTag.color.opacity(0.2), child.colorTag.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(child.colorTag.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(hasCompletedGoals ? "Set Another Goal" : "Add a Goal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(hasCompletedGoals ? "Keep the momentum going!" : "Pick something exciting to work toward")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(child.colorTag.color.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completed Goals Section

/// Section showing past completed goals with celebration history
struct CompletedGoalsSection: View {
    let rewards: [Reward]
    let childColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)

                Text("Past Victories")
                    .font(.system(size: 20, weight: .bold))

                Spacer()

                Text("\(rewards.count) completed")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            ForEach(rewards.prefix(3)) { reward in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reward.name)
                            .font(.system(size: 16, weight: .semibold))

                        if let date = reward.redeemedDate {
                            Text("Earned \(formattedDate(date))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Text("\(reward.targetPoints)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(childColor)
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }

            if rewards.count > 3 {
                Text("+ \(rewards.count - 3) more completed goals")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Giant Goal Card") {
    let child = Child(name: "Emma", colorTag: .purple)
    let reward = Reward(childId: child.id, name: "Ice Cream Trip", targetPoints: 10, imageName: "gift.fill")

    GiantGoalProgressCard(
        child: child,
        reward: reward,
        currentStars: 7,
        targetStars: 10,
        deadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
        isReady: false,
        onCelebrate: {},
        onShowKidView: {}
    )
    .padding()
}

#Preview("Ready State") {
    let child = Child(name: "Noah", colorTag: .blue)
    let reward = Reward(childId: child.id, name: "Movie Night", targetPoints: 10, imageName: "star.fill")

    GiantGoalProgressCard(
        child: child,
        reward: reward,
        currentStars: 10,
        targetStars: 10,
        deadline: nil,
        isReady: true,
        onCelebrate: {},
        onShowKidView: {}
    )
    .padding()
}
