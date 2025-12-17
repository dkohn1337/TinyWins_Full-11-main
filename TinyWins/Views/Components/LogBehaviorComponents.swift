import SwiftUI

// MARK: - Log Behavior Child Header

/// Header showing child info in the log behavior sheet
struct LogBehaviorChildHeader: View {
    let child: Child

    var body: some View {
        HStack(spacing: 12) {
            ChildAvatar(child: child, size: 40)

            VStack(alignment: .leading) {
                Text("Add moment for")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(child.name)
                    .font(.headline)
            }

            Spacer()

            if let age = child.age {
                Text("\(age) \(age == 1 ? "year" : "years") old")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(child.colorTag.color.opacity(0.15))
                    .foregroundColor(child.colorTag.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(child.colorTag.color.opacity(0.1))
        .cornerRadius(AppStyles.cardCornerRadius)
    }
}

// MARK: - Goal Prompt Banner

/// Banner prompting user to create a goal for their child
struct GoalPromptBanner: View {
    let childName: String
    let onPickGoal: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Give these stars a home")
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Pick a reward so \(childName) has something exciting to work toward.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button(action: onPickGoal) {
                Text("Pick a goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Age Suggestion Banner

/// Banner showing age-appropriate behavior suggestions
struct AgeSuggestionBanner: View {
    let age: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            StyledIcon(systemName: "lightbulb.fill", color: .yellow, size: 14, backgroundSize: 28)

            Text("Showing behaviors suggested for \(age)-year-olds. You can add your own in Manage Behaviors.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Star Target Selector Pill

/// Pill showing current star target with dropdown option
struct StarTargetSelectorPill: View {
    let selectedRewardId: UUID?
    let currentTargetName: String
    let childColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)

                if selectedRewardId != nil {
                    Text("Stars will count toward:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currentTargetName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(childColor)
                } else {
                    Text("Stars will not count toward a reward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Behavior Chip

/// Chip for quick-adding recent behaviors
struct RecentBehaviorChip: View {
    let behavior: BehaviorType
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: behavior.iconName)
                    .font(.caption)

                Text(behavior.name)
                    .font(.caption)
                    .lineLimit(1)

                PointsBadge(points: behavior.defaultPoints, useStars: true, size: .caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.1))
            .foregroundColor(.primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress?()
                }
        )
    }
}

// MARK: - Behavior Tile

/// Tile for selecting a behavior to log
struct BehaviorTile: View {
    let behavior: BehaviorType
    let category: BehaviorCategory
    var isPopular: Bool = false
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil
    @EnvironmentObject private var themeProvider: ThemeProvider

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Icon with gradient background and popular badge
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [iconColor.opacity(0.25), iconColor.opacity(0.05)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 28
                                )
                            )
                            .frame(width: 52, height: 52)

                        // Main circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        // Inner highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: behavior.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [iconColor, iconColor.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    // Popular badge
                    if isPopular {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 6))
                            Text("Popular")
                                .font(.system(size: 7, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.pink)
                        .cornerRadius(5)
                        .offset(x: 4, y: -4)
                    }
                }

                Text(behavior.name)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.primary)

                // Enhanced points badge
                HStack(spacing: 3) {
                    Text(behavior.defaultPoints >= 0 ? "+\(behavior.defaultPoints)" : "\(behavior.defaultPoints)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(behavior.defaultPoints >= 0 ? themeProvider.positiveColor : themeProvider.challengeColor)
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(themeProvider.starColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(behavior.defaultPoints >= 0 ? themeProvider.positiveColor.opacity(0.1) : themeProvider.challengeColor.opacity(0.1))
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: iconColor.opacity(isPressed ? 0.1 : 0.15), radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(iconColor.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isPressed)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onLongPress?()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var iconColor: Color {
        switch category {
        case .routinePositive: return AppColors.routine
        case .positive: return AppColors.positive
        case .negative: return AppColors.challenge
        }
    }
}

// Keep BehaviorButton for backward compatibility
typealias BehaviorButton = BehaviorTile

// MARK: - Reward Picker Option

/// Option row in reward picker
struct RewardPickerOption: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    let reward: Reward
    let isSelected: Bool
    let onTap: () -> Void

    private var progress: Double {
        reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: reward.priority == 0)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .secondary)
                    .font(.title3)

                // Reward icon
                Image(systemName: reward.imageName ?? "gift.fill")
                    .font(.subheadline)
                    .foregroundColor(.purple)

                // Reward name and progress
                VStack(alignment: .leading, spacing: 2) {
                    Text(reward.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray4))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.purple)
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                Spacer()

                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Media Thumbnail

/// Thumbnail for media attachments
struct MediaThumbnail: View {
    let attachment: MediaAttachment
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if attachment.mediaType == .image,
                   let image = MediaManager.shared.loadImage(from: attachment) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if attachment.mediaType == .video,
                          let thumbnail = MediaManager.shared.loadThumbnail(from: attachment) {
                    ZStack {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()

                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                } else {
                    Color.gray
                        .overlay {
                            Image(systemName: attachment.mediaType == .video ? "video.fill" : "photo.fill")
                                .foregroundColor(.white)
                        }
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            .clipped()

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Star Chip Button

/// Chip button for selecting star amount
struct StarChipButton: View {
    let amount: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
                Text(amount >= 0 ? "+\(amount)" : "\(amount)")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .yellow)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? (amount >= 0 ? AppColors.positive : AppColors.challenge) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? (amount >= 0 ? AppColors.positive : AppColors.challenge) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Goal Interception Sheet

/// Sheet shown to prompt goal creation before logging
struct GoalInterceptionSheet: View {
    let child: Child
    let onChooseGoal: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.purple)
                .padding(.top, 8)

            // Title and body
            VStack(spacing: 8) {
                Text("Pick a goal first?")
                    .font(.title3.weight(.semibold))

                Text("Stars feel more exciting when they're building toward something special.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }

            // Buttons
            VStack(spacing: 12) {
                Button(action: onChooseGoal) {
                    Text("Pick a goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                }

                Button(action: onNotNow) {
                    Text("Choose later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Previews

#Preview("Child Header") {
    LogBehaviorChildHeader(child: Child(name: "Emma", age: 7, colorTag: .purple))
        .padding()
}

#Preview("Goal Prompt") {
    GoalPromptBanner(childName: "Emma", onPickGoal: {})
        .padding()
}

#Preview("Behavior Tile") {
    let behavior = BehaviorType(
        name: "Shared toys",
        category: .positive,
        defaultPoints: 2,
        iconName: "heart.fill"
    )
    BehaviorTile(behavior: behavior, category: .positive, onTap: {})
        .frame(width: 160)
        .padding()
}
