import SwiftUI

// MARK: - Milestone Celebration Overlay

struct MilestoneCelebrationOverlay: View {
    let milestone: CelebrationStore.MilestoneCelebration
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Darkened background overlay - tap to dismiss
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Card container
            VStack(spacing: 0) {
                // Card with all content inside
                VStack(spacing: 20) {
                    // Close button at top right
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                    .padding(.bottom, -8)

                    // Star icon - inside the card
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .orange.opacity(0.4), radius: 12)

                        Image(systemName: "star.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    // Progress text
                    VStack(spacing: 6) {
                        Text(" Milestone Reached!")
                            .font(.title2.bold())

                        Text("\(milestone.milestone) of \(milestone.target) stars")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("toward \(milestone.rewardName)")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }

                    // Progress bar
                    VStack(spacing: 6) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 14)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(milestone.milestone) / CGFloat(milestone.target), height: 14)
                            }
                        }
                        .frame(height: 14)

                        Text("\(Int((Double(milestone.milestone) / Double(milestone.target)) * 100))% complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Message - allow full wrapping
                    Text(milestone.message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)

                    // Dismiss button
                    Button(action: onDismiss) {
                        Text("Keep Going!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            }
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Reward Earned Celebration Overlay (Goal Reached 100%)

struct RewardEarnedCelebrationOverlay: View {
    let celebration: CelebrationStore.RewardEarnedCelebration
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Darkened background overlay - tap to dismiss
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Card container
            VStack(spacing: 0) {
                // Card with all content inside
                VStack(spacing: 20) {
                    // Close button at top right
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                    .padding(.bottom, -8)

                    // Trophy icon with glow - inside the card
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 110, height: 110)

                        // Inner gradient circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.2, green: 0.7, blue: 0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .green.opacity(0.4), radius: 12)

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    // Title and subtitle
                    VStack(spacing: 8) {
                        Text(" Goal Reached!")
                            .font(.title2.bold())

                        Text("\(celebration.childName) earned")
                            .font(.body)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            if let iconName = celebration.rewardIcon {
                                Image(systemName: iconName)
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            Text(celebration.rewardName)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.green)
                        }
                    }

                    // Encouragement message
                    Text("Take a moment to tell \(celebration.childName) what they did well.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .padding(.horizontal, 8)

                    // Primary button
                    Button(action: onDismiss) {
                        Text("Celebrate Together!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.2, green: 0.7, blue: 0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                    .padding(.top, 4)

                    // Secondary dismiss option
                    Button(action: onDismiss) {
                        Text("Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            }
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Bonus Insight Sheet

struct BonusInsightSheet: View {
    let insight: BonusInsight
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: insight.icon)
                    .font(.system(size: 36))
                    .foregroundColor(insight.color)
            }

            // Title
            Text(insight.title)
                .font(.title2.bold())

            // Message
            Text(insight.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Suggestion (if any)
            if let suggestion = insight.suggestion {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)

                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }

            Spacer()

            // Dismiss
            Button(action: onDismiss) {
                Text("Got it!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(insight.color)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Previews

#Preview("Milestone Celebration") {
    MilestoneCelebrationOverlay(
        milestone: CelebrationStore.MilestoneCelebration(
            childId: UUID(),
            childName: "Emma",
            rewardId: UUID(),
            rewardName: "Movie Night",
            milestone: 15,
            target: 20,
            message: "Emma is making great progress!"
        ),
        onDismiss: {}
    )
}

#Preview("Reward Earned") {
    RewardEarnedCelebrationOverlay(
        celebration: CelebrationStore.RewardEarnedCelebration(
            childId: UUID(),
            childName: "Emma",
            rewardId: UUID(),
            rewardName: "Ice Cream Trip",
            rewardIcon: "cup.and.saucer.fill"
        ),
        onDismiss: {}
    )
}
