import SwiftUI

struct KidsView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var userPreferences: UserPreferencesStore
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var themeProvider: ThemeProvider
    @State private var showingAddChild = false
    @State private var showingArchivedChildren = false
    @State private var showingPaywall = false
    @State private var showingSecondChildCoachMark = false

    private var canAddChild: Bool {
        subscriptionManager.canAddChild(currentCount: childrenStore.activeChildren.count)
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
                checkForSecondChildCoachMark()
            }
            .themedNavigationBar(themeProvider)
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
                        .foregroundColor(.secondary)
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
        .background(themeProvider.backgroundColor)
    }

    private var kidsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Active children
                    ForEach(childrenStore.activeChildren) { child in
                        NavigationLink(destination: ChildDetailView(child: child)) {
                            EnhancedKidRowView(child: child) {
                                // Navigate to Goals tab with this child selected
                                coordinator.selectChild(child.id)
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

                    // Archived children section
                    if !childrenStore.archivedChildren.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if showingArchivedChildren {
                                ForEach(childrenStore.archivedChildren) { child in
                                    NavigationLink(destination: ChildDetailView(child: child)) {
                                        HStack {
                                            EnhancedKidRowView(child: child, isArchived: true) {
                                                coordinator.selectChild(child.id)
                                                coordinator.selectedTab = .rewards
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .id("archived-\(child.id)")
                                }
                            }

                            Button(action: {
                                let wasHidden = !showingArchivedChildren
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingArchivedChildren.toggle()
                                }
                                // Scroll to first archived child when expanding
                                if wasHidden, let firstArchived = childrenStore.archivedChildren.first {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            proxy.scrollTo("archived-\(firstArchived.id)", anchor: .top)
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: showingArchivedChildren ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                        .font(.system(size: 16))
                                    Text(showingArchivedChildren ? "Hide archived children" : "Show \(childrenStore.archivedChildren.count) archived \(childrenStore.archivedChildren.count == 1 ? "child" : "children")")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                            }
                            .accessibilityLabel(showingArchivedChildren ? "Hide archived children" : "Show \(childrenStore.archivedChildren.count) archived children")
                            .accessibilityHint("Double tap to \(showingArchivedChildren ? "collapse" : "expand") archived children section")
                        }
                        .id("archived-section")
                    }
                }
                .padding()
                .tabBarBottomPadding()
            }
        }
        .background(themeProvider.backgroundColor)
    }

    private func deleteActiveChildren(at offsets: IndexSet) {
        for index in offsets {
            let child = childrenStore.activeChildren[index]
            childrenStore.deleteChild(id: child.id)
        }
    }
}

// MARK: - Enhanced Kid Row View

struct EnhancedKidRowView: View {
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var coordinator: AppCoordinator
    let child: Child
    var isArchived: Bool = false
    var onRewardBadgeTap: (() -> Void)? = nil

    private var activeReward: Reward? {
        rewardsStore.activeReward(forChild: child.id)
    }

    private var rewardStatus: Reward.RewardStatus? {
        activeReward?.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
    }

    private var progress: Double {
        guard let reward = activeReward else { return 0 }
        let earned = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
        return min(Double(earned) / Double(reward.targetPoints), 1.0)
    }

    // MARK: - Extracted Subviews

    @ViewBuilder
    private var avatarSection: some View {
        ZStack {
            Circle()
                .stroke(themeProvider.resolved.isDark ? Color.white.opacity(0.15) : Color(.systemGray5), lineWidth: 3)
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
                    .fill(Color(.systemGray4))
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

    /// Get all queued (non-redeemed, non-expired) rewards for this child
    private var queuedRewards: [Reward] {
        rewardsStore.rewards(forChild: child.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
    }

    /// Calculate stars remaining to reach a specific goal
    private func starsRemaining(for reward: Reward, isPrimary: Bool) -> Int {
        let earned = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
        return max(0, reward.targetPoints - earned)
    }

    /// Get the next queued reward after the primary one
    private var nextQueuedReward: Reward? {
        let queued = queuedRewards
        guard queued.count > 1 else { return nil }
        return queued.dropFirst().first
    }

    /// Count of additional queued rewards (excluding primary and next)
    private var additionalQueuedCount: Int {
        max(0, queuedRewards.count - 1)
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
                            colors: [themeProvider.starColor, themeProvider.starColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("\(child.totalPoints)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Goal status
            if let reward = activeReward {
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.5))

                if rewardStatus == Reward.RewardStatus.readyToRedeem {
                    // Goal reached - show next goal or prompt
                    if let nextReward = nextQueuedReward {
                        // Has queued goals - show next one
                        let remaining = starsRemaining(for: nextReward, isPrimary: false)
                        HStack(spacing: 4) {
                            Text("Next:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("\(remaining) to")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(nextReward.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(child.colorTag.color)
                                .lineLimit(1)
                        }
                        // Show +N more if there are additional queued goals
                        if additionalQueuedCount > 1 {
                            Text("(+\(additionalQueuedCount - 1))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    } else {
                        // No queued goals - prompt to set next
                        Text("Tap to set next goal")
                            .font(.system(size: 12))
                            .foregroundColor(child.colorTag.color.opacity(0.8))
                    }
                } else {
                    // In progress - show stars remaining to primary goal
                    let remaining = starsRemaining(for: reward, isPrimary: true)
                    if remaining > 0 {
                        HStack(spacing: 4) {
                            Text("\(remaining) to")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(reward.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(child.colorTag.color)
                                .lineLimit(1)
                        }
                        // Show +N more if there are additional queued goals
                        if additionalQueuedCount > 0 {
                            Text("(+\(additionalQueuedCount))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
            } else {
                // No active goal
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No active goal")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
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
                        .foregroundColor(.primary)

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
            RoundedRectangle(cornerRadius: themeProvider.resolved.cornerRadius)
                .fill(themeProvider.resolved.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeProvider.resolved.cornerRadius)
                .strokeBorder(
                    isArchived ? Color(.systemGray4) : themeProvider.resolved.cardBorderColor,
                    lineWidth: isArchived ? 1 : themeProvider.resolved.cardBorderWidth
                )
        )
        .shadow(color: themeProvider.resolved.shadowColor.opacity(CardElevation.medium.shadowOpacity * (themeProvider.resolved.isDark ? 1.5 : 1.0)), radius: CardElevation.medium.shadowRadius, y: CardElevation.medium.shadowY)
    }
}

// MARK: - Legacy Kid Row View (kept for compatibility)

struct KidRowView: View {
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    let child: Child

    var body: some View {
        HStack(spacing: 16) {
            ChildAvatar(child: child, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("\(child.totalPoints)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let reward = rewardsStore.activeReward(forChild: child.id) {
                        let status = reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
                        Text("\u{00B7}")
                            .foregroundColor(.secondary)

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
                .foregroundColor(.secondary)
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
