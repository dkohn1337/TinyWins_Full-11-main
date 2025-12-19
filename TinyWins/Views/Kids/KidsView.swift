import SwiftUI

struct KidsView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var viewModel: KidsViewModel
    @EnvironmentObject private var userPreferences: UserPreferencesStore
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.theme) private var theme
    @State private var showingAddChild = false
    @State private var showingArchivedChildren = false
    @State private var showingPaywall = false
    @State private var showingSecondChildCoachMark = false

    private var canAddChild: Bool {
        viewModel.state.canAddChild
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if childrenStore.children.isEmpty {
                    emptyState
                } else {
                    kidsList
                }
            }
            .navigationTitle("Kids")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Simplified: Just settings icon for consistency across all tabs
                    // Add child is available via the empty state or "Add another child" in the list
                    Button(action: { coordinator.presentSheet(.settings) }) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingAddChild) {
                AddEditChildView(mode: .add) { child in
                    childrenStore.addChild(child)
                    // Check if this is the second child and show light coach mark
                    checkForSecondChildCoachMark()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PlusPaywallView(context: .addChild)
            }
            .alert("Tracking multiple children", isPresented: $showingSecondChildCoachMark) {
                Button("Got it!") {
                    userPreferences.hasSeenSecondChildCoachMark = true
                }
            } message: {
                Text("You can track wins separately for each child. Swipe to switch between them on the Today and Goals tabs. Each child has their own goals and progress.")
            }
            .onAppear {
                // PHASE 3C: Visibility gate
                viewModel.setVisible(true)
                checkForSecondChildCoachMark()
            }
            .onDisappear {
                // PHASE 3C: Visibility gate
                viewModel.setVisible(false)
            }
            .themedNavigationBar(theme)
            .trackScreen("KidsView")
        }
    }
    
    private func handleAddChildTap() {
        if canAddChild {
            showingAddChild = true
        } else {
            showingPaywall = true
        }
    }

    /// Check if we should show the second child coach mark.
    /// Shows light, contextual guidance after adding a second child (not full onboarding).
    private func checkForSecondChildCoachMark() {
        // Only show if:
        // 1. Haven't seen it before
        // 2. User has completed initial onboarding
        // 3. Now have exactly 2 active children
        guard !userPreferences.hasSeenSecondChildCoachMark,
              userPreferences.hasCompletedOnboarding,
              childrenStore.activeChildren.count == 2 else {
            return
        }

        // H2 FIX: Show after 2.5 second delay to let user see the new child in the list
        // before showing guidance. This prevents the alert from feeling like an interruption.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showingSecondChildCoachMark = true
        }
    }
    
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.primary.opacity(0.2), AppColors.primary.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary.opacity(0.15), AppColors.primary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "figure.2.and.child.holdinghands")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                VStack(spacing: 12) {
                    Text("Let's get started")
                        .font(.system(size: 24, weight: .bold))

                    Text("Add your first child to begin noticing the small moments that make a big difference.")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)

                Button(action: { showingAddChild = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add a Child")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 8)
            }
            .padding(24)
            .padding(.top, 16)
            .tabBarBottomPadding()
        }
        .background(theme.bg0)
    }

    private var kidsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Active children - using precomputed row data
                    ForEach(viewModel.state.activeChildrenData) { rowData in
                        NavigationLink(destination: ChildDetailView(child: rowData.child)) {
                            EnhancedKidRowView(rowData: rowData) {
                                // Navigate to Goals tab with this child selected
                                coordinator.selectChild(rowData.child.id)
                                coordinator.selectedTab = .rewards
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Add child upsell (if at limit)
                    if !canAddChild {
                        PlusUpsellCard(context: .addChild) {
                            showingPaywall = true
                        }
                        .padding(.horizontal, 16)
                    }

                    // Archived children section - using precomputed row data
                    let archivedData = viewModel.state.archivedChildrenData
                    if !archivedData.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if showingArchivedChildren {
                                ForEach(archivedData) { rowData in
                                    NavigationLink(destination: ChildDetailView(child: rowData.child)) {
                                        HStack {
                                            EnhancedKidRowView(rowData: rowData) {
                                                coordinator.selectChild(rowData.child.id)
                                                coordinator.selectedTab = .rewards
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .id("archived-\(rowData.child.id)")
                                }
                            }

                            Button(action: {
                                let wasHidden = !showingArchivedChildren
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingArchivedChildren.toggle()
                                }
                                // Scroll to first archived child when expanding
                                if wasHidden, let firstArchived = archivedData.first {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            proxy.scrollTo("archived-\(firstArchived.child.id)", anchor: .top)
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: showingArchivedChildren ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                        .font(.system(size: 16))
                                    Text(showingArchivedChildren ? "Hide archived children" : "Show \(archivedData.count) archived \(archivedData.count == 1 ? "child" : "children")")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(theme.textSecondary)
                                .padding(.vertical, 12)
                            }
                            .accessibilityLabel(showingArchivedChildren ? "Hide archived children" : "Show \(archivedData.count) archived children")
                            .accessibilityHint("Double tap to \(showingArchivedChildren ? "collapse" : "expand") archived children section")
                        }
                        .id("archived-section")
                    }
                }
                .padding()
                .tabBarBottomPadding()
            }
        }
        .background(theme.bg0)
    }

    private func deleteActiveChildren(at offsets: IndexSet) {
        for index in offsets {
            let child = childrenStore.activeChildren[index]
            childrenStore.deleteChild(id: child.id)
        }
    }
}

// MARK: - Enhanced Kid Row View

/// PERFORMANCE: Uses precomputed KidRowData from KidsViewModel instead of accessing stores.
/// All heavy computations (reward status, progress, queued rewards) are done via Combine,
/// not during SwiftUI body evaluation.
struct EnhancedKidRowView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var coordinator: AppCoordinator

    let rowData: KidRowData
    var onRewardBadgeTap: (() -> Void)? = nil

    // Convenience accessors from rowData
    private var child: Child { rowData.child }
    private var isArchived: Bool { rowData.isArchived }
    private var activeReward: Reward? { rowData.activeReward }
    private var rewardStatus: Reward.RewardStatus? { rowData.rewardStatus }
    private var progress: Double { rowData.progress }

    // MARK: - Extracted Subviews

    @ViewBuilder
    private var avatarSection: some View {
        ZStack {
            Circle()
                .stroke(theme.isDark ? Color.white.opacity(0.15) : theme.borderSoft, lineWidth: 3)
                .frame(width: 62, height: 62)

            if activeReward != nil {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(-90))
            }

            ChildAvatar(child: child, size: 54)

            if isArchived {
                Circle()
                    .fill(theme.borderStrong)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    )
                    .offset(x: 20, y: 20)
            }
        }
    }

    /// Richer amber gold for achievement badges
    private let achievementGold = Color(red: 0.85, green: 0.55, blue: 0.1)

    @ViewBuilder
    private var rewardBadgeButton: some View {
        Button(action: {
            // Go directly to celebration screen (no popup)
            if let reward = activeReward {
                coordinator.triggerGoalCelebration(reward: reward, child: child)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 10))
                Text("Goal Reached!")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [achievementGold, Color(red: 0.95, green: 0.7, blue: 0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .modifier(PulsingBadgeModifier())
            .microConfetti()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Goal Reached")
        .accessibilityHint("Tap to celebrate this achievement")
    }

    @ViewBuilder
    private var starsAndGoalSection: some View {
        HStack(spacing: 6) {
            // Star count
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.star, theme.star.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("\(child.totalPoints)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }

            // Goal status - using precomputed values from rowData
            if let reward = activeReward {
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDisabled)

                if rewardStatus == Reward.RewardStatus.readyToRedeem {
                    // Goal reached - show next goal or prompt
                    if let nextReward = rowData.nextQueuedReward {
                        // Has queued goals - show next one
                        HStack(spacing: 4) {
                            Text("Next:")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                            Text("\(rowData.starsRemainingForNext) to")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                            Text(nextReward.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(child.colorTag.color)
                                .lineLimit(1)
                        }
                        // Show +N more if there are additional queued goals
                        if rowData.additionalQueuedCount > 1 {
                            Text("(+\(rowData.additionalQueuedCount - 1))")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textSecondary)
                        }
                    } else {
                        // No queued goals - prompt to set next
                        Text("Tap to set next goal")
                            .font(.system(size: 12))
                            .foregroundColor(child.colorTag.color.opacity(0.8))
                    }
                } else {
                    // In progress - show stars remaining to primary goal
                    let remaining = rowData.starsRemainingForPrimary
                    if remaining > 0 {
                        HStack(spacing: 4) {
                            Text("\(remaining) to")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                            Text(reward.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(child.colorTag.color)
                                .lineLimit(1)
                        }
                        // Show +N more if there are additional queued goals
                        if rowData.additionalQueuedCount > 0 {
                            Text("(+\(rowData.additionalQueuedCount))")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            } else {
                // No active goal
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDisabled)
                Text("No active goal")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDisabled)
            }
        }
    }

    @ViewBuilder
    private var chevronSection: some View {
        ZStack {
            Circle()
                .fill(child.colorTag.color.opacity(0.1))
                .frame(width: 28, height: 28)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(child.colorTag.color)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            avatarSection

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(child.name)
                        .font(AppTypography.button)
                        .foregroundColor(theme.textPrimary)

                    if rewardStatus == Reward.RewardStatus.readyToRedeem {
                        rewardBadgeButton
                    }
                }

                starsAndGoalSection
            }

            Spacer()

            chevronSection
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(
                    isArchived ? theme.borderStrong : theme.borderSoft,
                    lineWidth: isArchived ? 1 : 1
                )
        )
        .shadow(color: theme.shadowColor.opacity(CardElevation.medium.shadowOpacity * (theme.isDark ? 1.5 : 1.0)), radius: CardElevation.medium.shadowRadius, y: CardElevation.medium.shadowY)
    }
}

// MARK: - Legacy Kid Row View (kept for compatibility)

struct KidRowView: View {
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.theme) private var theme
    let child: Child

    var body: some View {
        HStack(spacing: 16) {
            ChildAvatar(child: child, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(theme.star)
                        Text("\(child.totalPoints)")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }

                    if let reward = rewardsStore.activeReward(forChild: child.id) {
                        let status = reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
                        Text("\u{00B7}")
                            .foregroundColor(theme.textSecondary)

                        switch status {
                        case .readyToRedeem:
                            HStack(spacing: 4) {
                                Image(systemName: "gift.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("Earned \(reward.name)!")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        case .active, .activeWithDeadline:
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.caption2)
                                    .foregroundColor(child.colorTag.color)
                                Text("Working toward \(reward.name)")
                                    .font(.caption)
                                    .foregroundColor(child.colorTag.color)
                            }
                        default:
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.caption2)
                                    .foregroundColor(child.colorTag.color)
                                Text("Working toward \(reward.name)")
                                    .font(.caption)
                                    .foregroundColor(child.colorTag.color)
                            }
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    KidsView()
        .environmentObject(ChildrenStore(repository: repository))
}

#Preview("Empty") {
    let repository = Repository()
    KidsView()
        .environmentObject(ChildrenStore(repository: repository))
}
