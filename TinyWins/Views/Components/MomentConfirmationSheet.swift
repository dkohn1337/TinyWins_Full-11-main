import SwiftUI

// MARK: - Moment Confirmation Sheet

/// Sheet for confirming and customizing a behavior log before saving
struct MomentConfirmationSheet: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var progressionStore: ProgressionStore
    @Environment(\.theme) private var theme
    let child: Child
    let behaviorType: BehaviorType
    @Binding var note: String
    @Binding var mediaAttachments: [MediaAttachment]
    @Binding var selectedRewardId: UUID?
    let availableRewards: [Reward]
    let onConfirm: () -> Void
    let onConfirmWithBonus: () -> Void
    let onAddMedia: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showBonusOffer = false
    @State private var customStarAmount: Int?
    @State private var showCustomStarInput = false

    // Only show reward picker for positive behaviors with multiple rewards
    private var showRewardPicker: Bool {
        behaviorType.defaultPoints > 0 && availableRewards.count > 1
    }

    // Check if we should offer a bonus star
    private var shouldOfferBonus: Bool {
        progressionStore.canOfferBonusStar(forChild: child.id) &&
        progressionStore.behaviorQualifiesForBonus(behaviorType)
    }

    // Get current star amount (custom or default)
    private var currentStarAmount: Int {
        customStarAmount ?? behaviorType.defaultPoints
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(theme.borderStrong)
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    // Icon
                    StyledIcon(
                        systemName: behaviorType.iconName,
                        color: categoryColor,
                        size: 32,
                        backgroundSize: 72,
                        isCircle: true
                    )

                    // Behavior name
                    Text(behaviorType.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    // Star selection chips (horizontal)
                    if behaviorType.defaultPoints != 0 {
                        starSelectionChips
                    }

                    // Reward picker (only for positive behaviors with multiple rewards)
                    if showRewardPicker {
                        rewardPickerSection
                    } else if behaviorType.defaultPoints > 0 && availableRewards.count == 1 {
                        // Single reward - just show which reward it goes to
                        if let reward = availableRewards.first {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(theme.textSecondary)
                                Text("Goes toward: \(reward.name)")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a note (optional)")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)

                        TextField("What happened?", text: $note, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
                    }

                    // Attachments
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Attachments")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)

                            Spacer()

                            Button(action: onAddMedia) {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                            }
                        }

                        if mediaAttachments.isEmpty {
                            Text("No attachments")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(theme.surface2)
                                .cornerRadius(8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(mediaAttachments) { attachment in
                                        MediaThumbnail(attachment: attachment) {
                                            mediaAttachments.removeAll { $0.id == attachment.id }
                                            MediaManager.shared.deleteMedia(attachment)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Bonus star offer (rare, once per week per child for challenging behaviors)
                    if shouldOfferBonus && !showBonusOffer {
                        Button(action: { withAnimation { showBonusOffer = true } }) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(theme.star)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("That took real effort!")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Tap to add a bonus star")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding()
                            .background(theme.star.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }

                    if showBonusOffer {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.circle.fill")
                                    .font(.title)
                                    .foregroundColor(theme.star)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Give a bonus star?")
                                        .font(.headline)
                                    Text("Tell \(child.name) why this moment stood out")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    progressionStore.recordBonusStarGiven(forChild: child.id)
                                    onConfirmWithBonus()
                                }) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                        Text("Yes, +1 bonus!")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(theme.star)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                }

                                Button(action: onConfirm) {
                                    Text("Just save")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(theme.borderSoft)
                                        .foregroundColor(theme.textPrimary)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(theme.star.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        // Primary button
                        Button(action: onConfirm) {
                            Text("Save Moment")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(child.colorTag.color)
                                .foregroundColor(.white)
                                .cornerRadius(AppStyles.buttonCornerRadius)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Star Selection Chips

    private var starSelectionChips: some View {
        VStack(spacing: 12) {
            Text("How many stars?")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            // Horizontal row of preset star options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Preset star amounts (1-5 for positive, -1 to -3 for negative)
                    ForEach(starOptions, id: \.self) { amount in
                        StarChipButton(
                            amount: amount,
                            isSelected: customStarAmount == amount || (customStarAmount == nil && amount == behaviorType.defaultPoints),
                            onTap: {
                                if customStarAmount == amount {
                                    customStarAmount = nil // Deselect if already selected
                                } else {
                                    customStarAmount = amount
                                    showCustomStarInput = false
                                }
                            }
                        )
                    }

                    // Custom option
                    Button(action: {
                        showCustomStarInput.toggle()
                        if showCustomStarInput {
                            customStarAmount = behaviorType.defaultPoints
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCustomStarInput ? "checkmark.circle.fill" : "ellipsis.circle")
                                .font(.title3)
                            Text("Custom")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(showCustomStarInput ? .white : theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(showCustomStarInput ? Color.purple : theme.surface2)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(showCustomStarInput ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }

            // Custom star input (revealed when Custom is tapped)
            if showCustomStarInput {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: {
                            if let current = customStarAmount, current > (behaviorType.defaultPoints < 0 ? -10 : 1) {
                                customStarAmount = current - 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.textSecondary)
                        }

                        HStack(spacing: 4) {
                            Text("\(customStarAmount ?? behaviorType.defaultPoints)")
                                .font(.title.weight(.bold))
                                .foregroundColor(behaviorType.defaultPoints >= 0 ? AppColors.positive : AppColors.challenge)
                                .frame(minWidth: 40)

                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundColor(theme.star)
                        }

                        Button(action: {
                            if let current = customStarAmount {
                                customStarAmount = current + 1
                            } else {
                                customStarAmount = behaviorType.defaultPoints + 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(behaviorType.defaultPoints >= 0 ? AppColors.positive : AppColors.challenge)
                        }
                    }

                    Text("Tap + or - to adjust")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
                .background(theme.surface2)
                .cornerRadius(12)
            }
        }
    }

    // Generate star options based on behavior type
    private var starOptions: [Int] {
        if behaviorType.defaultPoints >= 0 {
            // Positive: 1-5 stars
            return [1, 2, 3, 4, 5]
        } else {
            // Negative: -1 to -3 stars
            return [-1, -2, -3]
        }
    }

    // MARK: - Reward Picker Section

    private var rewardPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.purple)
                Text("Apply stars to:")
                    .font(.subheadline.weight(.medium))
            }

            // Reward options as segmented buttons
            VStack(spacing: 8) {
                ForEach(availableRewards) { reward in
                    RewardPickerOption(
                        reward: reward,
                        isSelected: selectedRewardId == reward.id,
                        onTap: { selectedRewardId = reward.id }
                    )
                }
            }
        }
        .padding()
        .background(theme.surface2)
        .cornerRadius(12)
    }

    private var categoryColor: Color {
        switch behaviorType.category {
        case .routinePositive: return AppColors.routine
        case .positive: return AppColors.positive
        case .negative: return AppColors.challenge
        }
    }

    private var pointsText: String {
        if behaviorType.defaultPoints >= 0 {
            return "+\(behaviorType.defaultPoints)"
        }
        return "\(behaviorType.defaultPoints)"
    }
}

// Keep LogConfirmationSheet as alias for backward compatibility
typealias LogConfirmationSheet = MomentConfirmationSheet

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    MomentConfirmationSheet(
        child: Child(name: "Emma", age: 8, colorTag: .purple),
        behaviorType: BehaviorType(name: "Shared toys", category: .positive, defaultPoints: 2, iconName: "heart.fill"),
        note: .constant(""),
        mediaAttachments: .constant([]),
        selectedRewardId: .constant(nil),
        availableRewards: [],
        onConfirm: {},
        onConfirmWithBonus: {},
        onAddMedia: {}
    )
    .environmentObject(BehaviorsStore(repository: repository))
    .environmentObject(ProgressionStore())
}
