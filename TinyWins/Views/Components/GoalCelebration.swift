import SwiftUI

// MARK: - Goal Celebration Full-Screen View

/// Full-screen celebration when a child reaches a goal
/// Photo-worthy moment designed for sharing
struct GoalCelebrationView: View {
    let childName: String
    let childColor: Color
    let rewardName: String
    let onDismiss: () -> Void
    let onShare: () -> Void

    @State private var showConfetti = false
    @State private var showContent = false
    @State private var pulseScale: CGFloat = 1.0

    /// Celebration gold color
    private let celebrationGold = Color(red: 0.95, green: 0.75, blue: 0.2)

    var body: some View {
        ZStack {
            // Gradient background - warm gold celebration theme
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.25),
                    Color.orange.opacity(0.15),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Enhanced confetti layer
            if showConfetti {
                EnhancedConfettiView(particleCount: 120, duration: 3.5)
                    .ignoresSafeArea()
            }

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Large trophy icon with pulse animation
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(celebrationGold)
                    .scaleEffect(showContent ? pulseScale : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)
                    .onAppear {
                        // Pulse animation
                        withAnimation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.1
                        }
                    }

                Spacer()
                    .frame(height: AppSpacing.xl)

                VStack(spacing: AppSpacing.md) {
                    Text("🎉 Goal Achieved! 🎉")
                        .font(AppTypography.display)
                        .foregroundColor(.primary)

                    Text(rewardName)
                        .font(AppTypography.title2)
                        .foregroundColor(celebrationGold)
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: AppSpacing.sm)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("You both worked toward this goal.")
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                            .frame(height: AppSpacing.xxs)

                        Text("Try saying:")
                            .font(AppTypography.label)
                            .foregroundColor(.secondary)

                        Text("\"\(childName), I noticed how hard you tried. I'm proud of your effort.\"")
                            .font(AppTypography.body)
                            .italic()
                            .foregroundColor(.secondary)
                            .padding(AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer()

                // Action buttons
                VStack(spacing: AppSpacing.sm) {
                    PrimaryButton(
                        title: "Go Celebrate Together",
                        action: {
                            triggerSuccessHaptic()
                            onDismiss()
                        }
                    )

                    SecondaryButton(
                        title: "Share This Moment",
                        action: {
                            triggerLightHaptic()
                            onShare()
                        }
                    )
                }
                .padding(.horizontal, AppSpacing.xl)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer()
                    .frame(height: AppSpacing.xxl)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Goal Reached celebration for \(childName)")
        .accessibilityHint("Celebrating reaching the goal: \(rewardName)")
        .onAppear {
            // Trigger success haptic
            triggerSuccessHaptic()

            // Animate in
            showConfetti = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }

            // Announce celebration to VoiceOver
            UIAccessibility.post(notification: .announcement, argument: "Congratulations! \(childName) reached the goal: \(rewardName)")
        }
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func triggerLightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Milestone Celebration

/// Celebration for non-goal milestones (e.g., "10 stars earned")
struct MilestoneCelebrationView: View {
    let childName: String
    let childColor: Color
    let milestoneName: String
    let milestoneIcon: String
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    childColor.opacity(0.2),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Lighter confetti for milestones
            if showConfetti {
                EnhancedConfettiView(particleCount: 60, duration: 2.5)
                    .ignoresSafeArea()
            }

            VStack(spacing: AppSpacing.xxl) {
                Spacer()

                // Icon
                Image(systemName: milestoneIcon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(childColor)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)

                VStack(spacing: AppSpacing.sm) {
                    Text("Milestone!")
                        .font(AppTypography.displayLarge)
                        .foregroundColor(.primary)

                    Text(milestoneName)
                        .font(AppTypography.title3)
                        .foregroundColor(childColor)
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer()

                PrimaryButton(title: "Great Progress!", action: onDismiss)
                    .padding(.horizontal, AppSpacing.xl)
                    .opacity(showContent ? 1.0 : 0.0)

                Spacer()
                    .frame(height: AppSpacing.xxl)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Milestone celebration")
        .accessibilityHint("Celebrating milestone: \(milestoneName)")
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            showConfetti = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
                showContent = true
            }

            // Announce milestone to VoiceOver
            let announcement = childName.isEmpty ? "Milestone reached: \(milestoneName)" : "Milestone for \(childName): \(milestoneName)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
}

// MARK: - Gold Star Day Celebration

/// Celebration for parents who logged many positive moments
struct GoldStarDayCelebrationView: View {
    let momentCount: Int
    let onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Gold gradient background
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.2),
                    Color.orange.opacity(0.1),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: AppSpacing.xxl) {
                Spacer()

                // Star icon
                Image(systemName: "star.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.3), radius: 20)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)

                VStack(spacing: AppSpacing.md) {
                    Text("Gold Star Day!")
                        .font(AppTypography.display)
                        .foregroundColor(.primary)

                    Text("You noticed \(momentCount) positive moments today.")
                        .font(AppTypography.bodyLarge)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Text("That attention matters more than you know.")
                        .font(AppTypography.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, AppSpacing.xl)
                }
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer()

                PrimaryButton(title: "Keep It Up!", action: onDismiss)
                    .padding(.horizontal, AppSpacing.xl)
                    .opacity(showContent ? 1.0 : 0.0)

                Spacer()
                    .frame(height: AppSpacing.xxl)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gold Star Day celebration")
        .accessibilityHint("You noticed \(momentCount) positive moments today")
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }

            // Announce Gold Star Day to VoiceOver
            UIAccessibility.post(notification: .announcement, argument: "Gold Star Day! You noticed \(momentCount) positive moments today. That attention matters more than you know.")
        }
    }
}

// MARK: - Preview

#Preview("Goal Celebration") {
    GoalCelebrationView(
        childName: "Emma",
        childColor: .purple,
        rewardName: "Ice Cream Trip",
        onDismiss: {},
        onShare: {}
    )
}

#Preview("Milestone Celebration") {
    MilestoneCelebrationView(
        childName: "Alex",
        childColor: .blue,
        milestoneName: "10 Stars Earned This Week!",
        milestoneIcon: "star.circle.fill",
        onDismiss: {}
    )
}

#Preview("Gold Star Day") {
    GoldStarDayCelebrationView(
        momentCount: 5,
        onDismiss: {}
    )
}
