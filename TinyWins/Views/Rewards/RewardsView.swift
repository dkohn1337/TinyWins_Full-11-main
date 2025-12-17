import SwiftUI

// MARK: - Cached Formatters (performance optimization)
private enum RewardsDateFormatterCache {
    static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
}

struct RewardsView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var celebrationStore: CelebrationStore
    @EnvironmentObject private var prefs: UserPreferencesStore
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var showingTemplatePickerForChild: Child?
    @State private var selectedTemplateForChild: (child: Child, template: RewardTemplate?)?
    @State private var celebratingReward: (reward: Reward, child: Child)?
    @State private var kidGoalSelectionChild: Child?
    @State private var goalSelectionContext: KidGoalSelectionView.Context = .addingGoal
    @State private var showingCompletionToast = false

    // Child selection state - synced via coordinator
    @State private var hasInitializedSelection = false

    // Computed selected child - uses coordinator's shared selection
    private var selectedChildId: UUID? {
        coordinator.selectedChildId
    }

    private var selectedChild: Child? {
        if let id = selectedChildId {
            return childrenStore.child(id: id)
        }
        return nil
    }

    // Get the effective selected child (handles edge cases)
    private var effectiveSelectedChild: Child? {
        // If we have a valid selection from coordinator, use it
        if let child = selectedChild {
            return child
        }
        // Fall back to first child
        return childrenStore.activeChildren.first
    }


    // Check if any child has an active goal
    private var hasAnyActiveGoal: Bool {
        childrenStore.activeChildren.contains { child in
            rewardsStore.activeReward(forChild: child.id) != nil
        }
    }

    // Check if a child has a ready-to-redeem reward
    private func hasReadyReward(for child: Child) -> Bool {
        let rewards = rewardsStore.rewards(forChild: child.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }

        guard let primaryReward = rewards.first else { return false }
        return primaryReward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: true) == .readyToRedeem
    }

    // Get the first child with a ready reward
    private var firstChildWithReadyReward: Child? {
        childrenStore.activeChildren.first { hasReadyReward(for: $0) }
    }

    // Summary for child pill
    private func summaryText(for child: Child) -> String {
        let points = child.totalPoints
        let goalCount = rewardsStore.rewards(forChild: child.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .count

        if goalCount == 0 {
            return "\(points) stars · No goals yet"
        } else {
            return "\(points) stars \u{00B7} \(goalCount) goal\(goalCount == 1 ? "" : "s")"
        }
    }

    private var completionToastMessage: String {
        guard let notification = celebrationStore.rewardCompletedNotification else {
            return ""
        }
        if notification.hasNextReward {
            return NSLocalizedString("goals_completion_has_next", value: "A new goal keeps them excited to keep going.", comment: "Toast message when reward is complete and there's a next goal")
        } else {
            return NSLocalizedString("goals_completion_no_next", value: "You can add a new goal to keep the momentum going.", comment: "Toast message when reward is complete and there's no next goal")
        }
    }

    /// Get recently used goals for a child based on their past rewards
    private func recentGoalsForChild(_ child: Child) -> [KidGoalOption] {
        // Get all rewards for this child (completed/redeemed ones)
        let pastRewards = rewardsStore.rewards(forChild: child.id)
            .filter { $0.isRedeemed }
            .sorted { ($0.redeemedDate ?? .distantPast) > ($1.redeemedDate ?? .distantPast) }

        // Get all available goal options
        let allOptions = rewardsStore.generateKidGoalOptions(forChild: child)

        // Match past rewards to goal options by name
        var recentOptions: [KidGoalOption] = []
        var seenNames: Set<String> = []

        for reward in pastRewards.prefix(10) {
            // Find matching option by name (case-insensitive)
            if let matchingOption = allOptions.first(where: {
                $0.name.lowercased() == reward.name.lowercased()
            }), !seenNames.contains(matchingOption.name.lowercased()) {
                recentOptions.append(matchingOption)
                seenNames.insert(matchingOption.name.lowercased())
            }
        }

        return recentOptions
    }

    var body: some View {
        NavigationStack {
            Group {
                if childrenStore.activeChildren.isEmpty {
                    noChildrenState
                } else if !hasAnyActiveGoal {
                    noGoalsEmptyState
                } else {
                    rewardsContent
                }
            }
            .navigationTitle(effectiveSelectedChild.map { "\($0.name)'s Goals" } ?? "Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Simplified: Just settings icon for consistency across all tabs
                    // Allowance is accessible from Settings or child detail
                    Button(action: { coordinator.presentSheet(.settings) }) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .onAppear {
                // Check for expired timed rewards
                rewardsStore.checkExpiredRewards(behaviorEvents: behaviorsStore.behaviorEvents)

                // Initialize selection if needed
                initializeChildSelection()

                // Check for pending celebration from Kids tab
                if let pending = coordinator.pendingGoalCelebration {
                    celebratingReward = (pending.reward, pending.child)
                    coordinator.clearPendingGoalCelebration()
                }
            }
            .onChange(of: coordinator.pendingGoalCelebration?.reward.id) { _, newValue in
                // Handle pending celebration when navigating from Kids tab
                if let pending = coordinator.pendingGoalCelebration {
                    celebratingReward = (pending.reward, pending.child)
                    coordinator.clearPendingGoalCelebration()
                }
            }
            .onChange(of: celebrationStore.rewardCompletedNotification) { _, newValue in
                if newValue != nil {
                    showingCompletionToast = true
                    // Auto-dismiss after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        showingCompletionToast = false
                        celebrationStore.dismissRewardCompletedNotification()
                    }
                }
            }
            .toast(
                isShowing: $showingCompletionToast,
                message: celebrationStore.rewardCompletedNotification.map { "\($0.childName) earned \($0.rewardName)!" } ?? "",
                icon: "party.popper.fill",
                category: .positive
            )
            // Template picker sheet
            .sheet(item: $showingTemplatePickerForChild) { child in
                RewardTemplatePickerView(
                    child: child,
                    onTemplateSelected: { template in
                        // Open AddRewardView pre-filled with template
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedTemplateForChild = (child, template)
                        }
                    },
                    onCreateCustom: {
                        // Open AddRewardView blank
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedTemplateForChild = (child, nil)
                        }
                    }
                )
            }
            // Add reward sheet (with or without template)
            .sheet(item: Binding(
                get: { selectedTemplateForChild.map { TemplateSelection(child: $0.child, template: $0.template) } },
                set: { selectedTemplateForChild = $0.map { ($0.child, $0.template) } }
            )) { selection in
                if let template = selection.template {
                    AddRewardView(child: selection.child, template: template)
                } else {
                    AddRewardView(child: selection.child)
                }
            }
            .fullScreenCover(item: Binding(
                get: { celebratingReward.map { CelebrationData(reward: $0.reward, child: $0.child) } },
                set: { celebratingReward = $0.map { ($0.reward, $0.child) } }
            )) { data in
                GoalCompletionCelebration(
                    reward: data.reward,
                    child: data.child,
                    onMarkGiven: {
                        completeReward(id: data.reward.id, childName: data.child.name)
                        celebratingReward = nil
                    },
                    onSetNextGoal: {
                        completeReward(id: data.reward.id, childName: data.child.name)
                        celebratingReward = nil
                        // Show template picker for this child
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingTemplatePickerForChild = data.child
                        }
                    },
                    onLetKidChoose: {
                        completeReward(id: data.reward.id, childName: data.child.name)
                        celebratingReward = nil
                        // Show kid goal selection with afterReward context
                        goalSelectionContext = .afterReward
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            kidGoalSelectionChild = data.child
                        }
                    },
                    onDismiss: {
                        celebratingReward = nil
                    }
                )
            }
            .fullScreenCover(item: $kidGoalSelectionChild) { child in
                KidGoalSelectionView(
                    child: child,
                    suggestions: rewardsStore.generateKidGoalOptions(forChild: child),
                    onGoalSelected: { selectedOption in
                        // Create the reward from the selected option
                        let reward = Reward(
                            childId: child.id,
                            name: selectedOption.name,
                            targetPoints: selectedOption.stars,
                            imageName: selectedOption.icon,
                            priority: rewardsStore.rewards(forChild: child.id).filter { !$0.isRedeemed }.count,
                            dueDate: Calendar.current.date(byAdding: .day, value: selectedOption.days, to: Date())
                        )
                        rewardsStore.addReward(reward)
                    },
                    onManageRewards: {
                        // Dismiss picker and open custom goal creation
                        let childToAdd = child
                        kidGoalSelectionChild = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.presentSheet(.addReward(child: childToAdd))
                        }
                    },
                    context: goalSelectionContext,
                    recentGoals: recentGoalsForChild(child)
                )
            }
            .themedNavigationBar(themeProvider)
        }
    }
    
    private var noChildrenState: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No children added yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a child to start setting goals together.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var noGoalsEmptyState: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Enhanced illustration with animation
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.3), .purple.opacity(0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Main circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.25), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Inner highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.3), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 16)

                VStack(spacing: 12) {
                    Text("Pick a goal to work toward")
                        .font(.system(size: 26, weight: .bold))

                    Text("Choose something they will enjoy earning: time together, a fun outing, or a small treat.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }

                // Enhanced goal buttons for each child
                VStack(spacing: 12) {
                    ForEach(childrenStore.activeChildren) { child in
                        Button(action: {
                            goalSelectionContext = .addingGoal
                            kidGoalSelectionChild = child
                        }) {
                            HStack(spacing: 14) {
                                // Avatar with ring
                                ZStack {
                                    Circle()
                                        .stroke(child.colorTag.color.opacity(0.3), lineWidth: 3)
                                        .frame(width: 48, height: 48)
                                    ChildAvatar(child: child, size: 40)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pick a goal for \(child.name)")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Start working toward something...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(child.colorTag.color)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(child.colorTag.color.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(child.colorTag.color.opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .padding(.bottom, 120) // Space for floating tab bar
        }
        .background(themeProvider.backgroundColor)
    }

    // MARK: - Child Selection Initialization

    private func initializeChildSelection() {
        guard !hasInitializedSelection else { return }
        hasInitializedSelection = true

        // Priority 1: Child with ready reward
        if let readyChild = firstChildWithReadyReward {
            coordinator.selectChild(readyChild.id)
            return
        }

        // Priority 2: Previously selected child (already in coordinator)
        if let id = selectedChildId, childrenStore.child(id: id) != nil {
            return // Keep current selection
        }

        // Priority 3: First child
        if let firstChild = childrenStore.activeChildren.first {
            coordinator.selectChild(firstChild.id)
        }
    }

    private func selectChild(_ child: Child) {
        withAnimation(.easeInOut(duration: 0.2)) {
            coordinator.selectChild(child.id)
        }
    }

    // MARK: - Helper Methods

    private func completeReward(id: UUID, childName: String) {
        if let result = rewardsStore.completeReward(id: id, childName: childName) {
            celebrationStore.triggerRewardCompletedNotification(
                rewardName: result.rewardName,
                childName: childName,
                hasNextReward: result.hasNextReward
            )
        }
    }
    
    // MARK: - Main Rewards Content
    
    private var rewardsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Child Switcher (only show when 2+ children)
                if childrenStore.activeChildren.count > 1 {
                    childSwitcher
                        .padding(.horizontal)
                }

                // Selected Child's Rewards
                if let child = effectiveSelectedChild {
                    ChildRewardSection(
                        child: child,
                        onCelebrate: { reward in
                            celebratingReward = (reward, child)
                        },
                        onAddGoal: { child in
                            goalSelectionContext = .addingGoal
                            kidGoalSelectionChild = child
                        }
                    )
                    .id(child.id) // For animation when switching
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .padding(.horizontal)
                }
            }
            .padding(.top, 16)
            .tabBarBottomPadding()
        }
        .background(themeProvider.backgroundColor)
        .animation(.easeInOut(duration: 0.25), value: coordinator.selectedChildId)
    }

    // MARK: - Child Switcher

    private var childSwitcher: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(childrenStore.activeChildren) { child in
                        ChildSwitcherPill(
                            child: child,
                            isSelected: selectedChildId == child.id,
                            summaryText: summaryText(for: child),
                            hasReadyReward: hasReadyReward(for: child),
                            onTap: {
                                selectChild(child)
                            }
                        )
                        .id(child.id)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
            }
            .onChange(of: selectedChildId) { _, newId in
                if let id = newId {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let id = selectedChildId {
                    // Slight delay to ensure layout is complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Child Switcher Pill (Premium/App Store Ready Design)

private struct ChildSwitcherPill: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    let child: Child
    let isSelected: Bool
    let summaryText: String
    let hasReadyReward: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            // Haptic feedback on selection
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Enhanced Avatar with contrast ring
                ZStack {
                    // Outer glow for selected state
                    if isSelected {
                        Circle()
                            .fill(child.colorTag.color.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .blur(radius: 4)
                    }

                    // White background circle for contrast
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)

                    // Colored border ring
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? child.colorTag.color
                                : child.colorTag.color.opacity(0.4),
                            lineWidth: isSelected ? 3 : 2
                        )
                        .frame(width: 40, height: 40)

                    // Avatar content
                    ChildAvatar(child: child, size: 32)
                }

                // Name and summary with better typography
                VStack(alignment: .leading, spacing: 3) {
                    Text(child.name)
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(summaryText)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(1)
                }

                // Goal reached badge with glow - richer amber gold
                if hasReadyReward && !isSelected {
                    HStack(spacing: 3) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 8))
                        Text("🎉")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.85, green: 0.55, blue: 0.1), Color(red: 0.95, green: 0.7, blue: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .modifier(PulsingBadgeModifier())
                    .accessibilityLabel("Goal Reached")
                    .accessibilityHint("Tap to celebrate this achievement")
                }
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Selected state: gradient background
                    if isSelected {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        child.colorTag.color,
                                        child.colorTag.color.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Inner highlight for depth
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    } else {
                        // Unselected: theme-aware background
                        RoundedRectangle(cornerRadius: 24)
                            .fill(themeProvider.resolved.cardBackground)

                        // Subtle border
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth > 0 ? themeProvider.resolved.cardBorderWidth : 1)
                    }
                }
            )
            // Shadow for elevation
            .shadow(
                color: isSelected
                    ? child.colorTag.color.opacity(0.35)
                    : Color.black.opacity(0.06),
                radius: isSelected ? 12 : 4,
                y: isSelected ? 6 : 2
            )
            // Scale animation on selection change
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PillPressButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Select \(child.name), \(summaryText)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to view \(child.name)'s goals")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Pill Press Button Style (handles press animation properly)

private struct PillPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Celebration Data (for Identifiable binding)
struct CelebrationData: Identifiable {
    let id = UUID()
    let reward: Reward
    let child: Child
}

// MARK: - Template Selection (for Identifiable binding)
struct TemplateSelection: Identifiable {
    let id = UUID()
    let child: Child
    let template: RewardTemplate?
}

// MARK: - Goal Completion Celebration - Enhanced with dramatic animations

struct GoalCompletionCelebration: View {
    let reward: Reward
    let child: Child
    let onMarkGiven: () -> Void
    let onSetNextGoal: () -> Void
    let onLetKidChoose: (() -> Void)?  // Optional kid participation callback
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var trophyScale: CGFloat = 0.3
    @State private var trophyRotation: Double = -15
    @State private var glowPulse = false
    @State private var textAppeared = false
    @State private var buttonsAppeared = false
    @Environment(\.colorScheme) private var colorScheme

    init(reward: Reward, child: Child, onMarkGiven: @escaping () -> Void, onSetNextGoal: @escaping () -> Void, onLetKidChoose: (() -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.reward = reward
        self.child = child
        self.onMarkGiven = onMarkGiven
        self.onSetNextGoal = onSetNextGoal
        self.onLetKidChoose = onLetKidChoose
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: [
                    child.colorTag.color.opacity(0.4),
                    Color.purple.opacity(0.3),
                    Color.yellow.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Radial burst effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.yellow.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: showConfetti ? 400 : 50
                    )
                )
                .frame(width: 800, height: 800)
                .offset(y: -100)

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }

            // X button for dismissal (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.8), .black.opacity(0.2))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                Spacer()
            }

            VStack(spacing: 32) {
                Spacer()

                // Enhanced trophy with glow and animation
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.yellow.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: CGFloat(160 + i * 40), height: CGFloat(160 + i * 40))
                            .scaleEffect(glowPulse ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: glowPulse
                            )
                    }

                    // Glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.5), Color.orange.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(glowPulse ? 1.15 : 1.0)

                    // Trophy
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.8), radius: 20)
                        .shadow(color: .yellow.opacity(0.5), radius: 40)
                }
                .scaleEffect(trophyScale)
                .rotationEffect(.degrees(trophyRotation))

                // Content with staggered animation
                VStack(spacing: 20) {
                    Text("🎉 Goal Reached! 🎉")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, child.colorTag.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("\(child.name) worked hard for this!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)

                    // Reward card with gradient
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [child.colorTag.color.opacity(0.3), child.colorTag.color.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: reward.imageName ?? "gift.fill")
                                .font(.system(size: 28))
                                .foregroundColor(child.colorTag.color)
                        }

                        Text(reward.name)
                            .font(.system(size: 22, weight: .bold))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill((colorScheme == .dark ? Color(white: 0.15) : Color(.systemBackground)).opacity(0.95))
                            .shadow(color: child.colorTag.color.opacity(0.3), radius: 16, y: 8)
                    )
                }
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 30)

                Spacer()

                // Action buttons with staggered animation
                VStack(spacing: 14) {
                    // Primary action: Celebrate together - uses child's color
                    Button(action: onMarkGiven) {
                        HStack(spacing: 10) {
                            Image(systemName: "hands.clap.fill")
                                .font(.system(size: 20))
                            Text("Go Celebrate!")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: child.colorTag.color.opacity(0.4), radius: 12, y: 6)
                    }

                    // Kid participation option
                    if let kidChoose = onLetKidChoose {
                        Button(action: kidChoose) {
                            HStack(spacing: 10) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 20))
                                Text("Let \(child.name) Pick Next!")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(child.colorTag.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colorScheme == .dark ? Color(white: 0.15) : Color(.systemBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(child.colorTag.color.opacity(0.3), lineWidth: 2)
                            )
                        }
                    }

                    Button(action: onSetNextGoal) {
                        HStack(spacing: 10) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 18))
                            Text("Choose Next Goal")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colorScheme == .dark ? Color(white: 0.15) : Color(.systemBackground).opacity(0.8))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(buttonsAppeared ? 1 : 0)
                .offset(y: buttonsAppeared ? 0 : 40)
            }
        }
        .onAppear {
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            // Trophy entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                trophyScale = 1.0
                trophyRotation = 0
            }

            // Start confetti
            withAnimation(.easeOut(duration: 0.3)) {
                showConfetti = true
            }

            // Start glow pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                glowPulse = true
            }

            // Staggered text animation
            withAnimation(.spring(response: 0.5).delay(0.3)) {
                textAppeared = true
            }

            // Staggered buttons animation
            withAnimation(.spring(response: 0.5).delay(0.5)) {
                buttonsAppeared = true
            }
        }
    }
}

// MARK: - Child Reward Section

struct ChildRewardSection: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingTemplatePicker = false
    @State private var showingAddReward = false
    @State private var selectedTemplate: RewardTemplate?
    @State private var showingCompleteConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingKidView = false
    @State private var showingPaywall = false
    @State private var rewardToEdit: Reward?
    @State private var rewardToDelete: Reward?
    @State private var rewardToComplete: Reward?
    @State private var showingRewardHistory = false
    @State private var popularChipsCollapsed = false

    let child: Child
    var onCelebrate: ((Reward) -> Void)? = nil
    var onAddGoal: ((Child) -> Void)? = nil

    // Get the latest child data from childrenStore
    private var currentChild: Child {
        childrenStore.child(id: child.id) ?? child
    }

    // All active (not completed, not expired) rewards, sorted by priority
    private var activeRewards: [Reward] {
        rewardsStore.rewards(forChild: currentChild.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
    }

    // The primary active reward (first one)
    private var primaryReward: Reward? {
        activeRewards.first
    }

    // Whether user can add another goal
    private var canAddGoal: Bool {
        subscriptionManager.canAddActiveGoal(currentActiveCount: activeRewards.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Child Header with Add Button
            HStack(spacing: 12) {
                ChildAvatar(child: currentChild, size: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentChild.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // Summary line: points - active goals
                    let goalCount = activeRewards.count
                    HStack(spacing: 4) {
                        Text("\(currentChild.totalPoints) points")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\u{00B7}")
                            .foregroundColor(.secondary)
                        
                        if goalCount == 0 {
                            Text("No goals yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(goalCount) goal\(goalCount == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()

                // Add Goal Button - only show when child already has goals
                // (empty state card provides the CTA when no goals exist)
                if !activeRewards.isEmpty {
                    Button(action: handleAddTap) {
                        HStack(spacing: 4) {
                            Image(systemName: canAddGoal ? "plus.circle.fill" : "star.fill")
                            Text(canAddGoal ? "Add goal" : "Get Plus")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(canAddGoal ? currentChild.colorTag.color : .purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((canAddGoal ? currentChild.colorTag.color : Color.purple).opacity(0.12))
                        .cornerRadius(20)
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PlusPaywallView(context: .additionalGoals)
            }

            // Inline upgrade message when at goal limit
            if !canAddGoal {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.purple)
                        Text("Free goal limit reached")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text("TinyWins Plus lets you add more goals for \(currentChild.name).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(12)
                .padding(.top, 8)
            }
            
            // Active Rewards List
            if activeRewards.isEmpty {
                // No rewards - show prompt
                addRewardPrompt
            } else {
                // Show all active rewards with section headers
                ForEach(Array(activeRewards.enumerated()), id: \.element.id) { index, reward in
                    // Section header for first (main) and second (upcoming) rewards
                    if index == 0 && activeRewards.count == 1 {
                        // Just one goal - no header needed
                        EmptyView()
                    } else if index == 0 {
                        // Main goal header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Focus")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("This is the main reward they're working toward now.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 4)
                    } else if index == 1 {
                        // Upcoming goals header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upcoming Goals")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("These become active when the main goal is completed.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                    }

                    RewardCard(
                        reward: reward,
                        child: currentChild,
                        isPrimary: index == 0,
                        onMarkReceived: {
                            // If redeemable, trigger celebration; otherwise just confirm
                            if reward.isRedeemable(from: behaviorsStore.behaviorEvents, isPrimaryReward: index == 0) {
                                if let celebrate = onCelebrate {
                                    celebrate(reward)
                                } else {
                                    rewardToComplete = reward
                                    showingCompleteConfirmation = true
                                }
                            } else {
                                rewardToComplete = reward
                                showingCompleteConfirmation = true
                            }
                        },
                        onEdit: {
                            rewardToEdit = reward
                        },
                        onDelete: {
                            // Capture reward and delay slightly to ensure Menu dismisses first
                            let toDelete = reward
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                rewardToDelete = toDelete
                                showingDeleteConfirmation = true
                            }
                        },
                        onShowKidView: {
                            showingKidView = true
                        },
                        onSetAsPrimary: {
                            rewardsStore.setRewardAsPrimary(reward.id, forChild: currentChild.id)
                        }
                    )
                }
            }
            
            // Expired Rewards (if any)
            let expiredRewards = rewardsStore.rewards(forChild: currentChild.id).filter { $0.isExpired && !$0.isRedeemed }
            if !expiredRewards.isEmpty {
                expiredRewardsSection(expiredRewards)
            }

            // Completed Rewards (Achievements)
            let completedRewards = rewardsStore.rewards(forChild: currentChild.id).filter { $0.isRedeemed }
            if !completedRewards.isEmpty {
                pastRewardsSection(completedRewards)
            }

            // Encouragement footer to fill dead space
            encouragementFooter
        }
        .cardStyle(elevation: .medium)
        .sheet(isPresented: $showingTemplatePicker) {
            RewardTemplatePickerView(
                child: currentChild,
                onTemplateSelected: { template in
                    selectedTemplate = template
                    showingAddReward = true
                },
                onCreateCustom: {
                    selectedTemplate = nil
                    showingAddReward = true
                }
            )
        }
        .sheet(isPresented: $showingAddReward) {
            AddRewardView(child: currentChild, template: selectedTemplate)
        }
        .sheet(item: $rewardToEdit) { reward in
            AddRewardView(child: currentChild, editingReward: reward)
        }
        .sheet(isPresented: $showingRewardHistory) {
            RewardHistorySheet(
                child: currentChild,
                rewards: rewardsStore.rewards(forChild: currentChild.id).filter { $0.isRedeemed }
            )
            .environmentObject(themeProvider)
        }
        .fullScreenCover(isPresented: $showingKidView) {
            if let reward = primaryReward {
                KidView(child: currentChild, activeReward: reward)
            } else {
                KidView(child: currentChild, activeReward: nil)
            }
        }
        .alert("Delete Reward?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let reward = rewardToDelete {
                    rewardsStore.deleteReward(id: reward.id)
                }
            }
        } message: {
            if let reward = rewardToDelete {
                let earnedPoints = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
                if earnedPoints > 0 {
                    Text("Delete \"\(reward.name)\"? \(earnedPoints) of \(reward.targetPoints) stars of progress will be lost.")
                } else {
                    Text("Delete \"\(reward.name)\"? This cannot be undone.")
                }
            } else {
                Text("This will permanently delete this reward goal.")
            }
        }
        .alert("Mark as Complete?", isPresented: $showingCompleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, Complete!") {
                if let reward = rewardToComplete {
                    _ = rewardsStore.completeReward(id: reward.id, childName: currentChild.name)
                }
            }
        } message: {
            if let reward = rewardToComplete {
                Text("\(currentChild.name) achieved \"\(reward.name)\"!")
            }
        }
    }

    // Check if child has any completed rewards (to show different copy)
    private var hasCompletedRewards: Bool {
        !rewardsStore.rewards(forChild: currentChild.id).filter { $0.isRedeemed }.isEmpty
    }
    
    private func handleAddTap() {
        if canAddGoal {
            // Use callback to open playful picker if provided, fallback to template picker
            if let onAddGoal = onAddGoal {
                onAddGoal(currentChild)
            } else {
                showingTemplatePicker = true
            }
        } else {
            showingPaywall = true
        }
    }
    
    private var addRewardPrompt: some View {
        VStack(spacing: 12) {
            Button(action: handleAddTap) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasCompletedRewards ? "Set a New Goal" : "Add a Goal")
                            .font(.headline)

                        Text(hasCompletedRewards ? "You can add another goal to keep the momentum going." : "Pick something to work toward together")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(currentChild.colorTag.color.opacity(0.1))
                .foregroundColor(currentChild.colorTag.color)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Popular goals suggestion
            popularGoalsSuggestion
        }
    }

    /// Shows popular goal suggestions as quick-tap chips (collapsible)
    @ViewBuilder
    private var popularGoalsSuggestion: some View {
        let popularTemplates = RewardTemplate.templates(forAge: currentChild.age)
            .filter { $0.isPopular }
            .prefix(3)

        if !popularTemplates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Tappable header to expand/collapse
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        popularChipsCollapsed.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                        Text("Quick picks")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Image(systemName: popularChipsCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if !popularChipsCollapsed {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(popularTemplates), id: \.id) { template in
                                Button(action: {
                                    // Quick-select this popular goal
                                    selectedTemplate = template
                                    showingAddReward = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: template.icon)
                                            .font(.caption)
                                        Text(template.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                        HStack(spacing: 2) {
                                            Text("\(template.defaultPoints)")
                                                .font(.caption2.weight(.semibold))
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 8))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(currentChild.colorTag.color.opacity(0.08))
                                    .foregroundColor(currentChild.colorTag.color)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(currentChild.colorTag.color.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func expiredRewardsSection(_ rewards: [Reward]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.xmark.fill")
                    .foregroundColor(.red)
                Text("Expired")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            ForEach(rewards) { reward in
                HStack {
                    Image(systemName: reward.imageName ?? "gift.fill")
                        .foregroundColor(.gray)

                    Text(reward.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(role: .destructive) {
                        rewardsStore.deleteReward(id: reward.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Encouragement Footer

    /// Footer section that fills dead space with encouraging content
    /// Hidden when goal is reached (card already has Celebrate button)
    @ViewBuilder
    private var encouragementFooter: some View {
        VStack(spacing: 16) {
            // Progress encouragement based on state
            if let primaryReward = primaryReward {
                let progress = primaryReward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
                let target = primaryReward.targetPoints

                if progress >= target {
                    // Goal reached - NO encouragement card (button is already there)
                    // Just show the tip of the day
                    EmptyView()
                } else if progress >= target / 2 {
                    // Past halfway
                    encouragementCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "More than halfway there!",
                        message: "Keep noticing the good moments. Every star counts toward the goal."
                    )
                } else if progress > 0 {
                    // Making progress
                    encouragementCard(
                        icon: "leaf.fill",
                        iconColor: .green,
                        title: "Building momentum",
                        message: "Small steps lead to big achievements. \(currentChild.name) is on the way!"
                    )
                } else {
                    // Just getting started
                    encouragementCard(
                        icon: "sparkles",
                        iconColor: currentChild.colorTag.color,
                        title: "The journey begins",
                        message: "Log positive moments to earn stars toward \(primaryReward.name)."
                    )
                }
            } else if !hasCompletedRewards {
                // No goals set yet
                encouragementCard(
                    icon: "gift.fill",
                    iconColor: currentChild.colorTag.color,
                    title: "Set a goal together",
                    message: "Goals give kids something to work toward. Pick one above to get started!"
                )
            } else {
                // Has completed goals but no active ones
                encouragementCard(
                    icon: "trophy.fill",
                    iconColor: Color(red: 0.85, green: 0.65, blue: 0.1),
                    title: "Ready for the next adventure?",
                    message: "Set a new goal to keep the momentum going!"
                )
            }

            // Tip of the day (rotating based on day)
            tipOfTheDay
        }
        .padding(.top, 16)
    }

    private func encouragementCard(icon: String, iconColor: Color, title: String, message: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.05))
        )
    }

    private var tipOfTheDay: some View {
        let tips = [
            "Celebrate effort over outcome. \"I noticed how hard you tried\" builds resilience.",
            "Goals work best when kids help choose them. Ownership drives motivation.",
            "Small, achievable goals build confidence for bigger ones.",
            "The journey matters as much as the destination. Enjoy the progress together!",
            "Recognition is powerful. A simple \"I see you\" can change a child's day.",
            "Kids remember how we celebrated, not just what we celebrated.",
            "One goal at a time keeps focus sharp. Quality over quantity."
        ]

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let tipIndex = dayOfYear % tips.count
        let tip = tips[tipIndex]

        return HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)

            Text(tip)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.yellow.opacity(0.08))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func pastRewardsSection(_ rewards: [Reward]) -> some View {
        let sortedRewards = rewards.sorted(by: { ($0.redeemedDate ?? .distantPast) > ($1.redeemedDate ?? .distantPast) })
        let totalCount = sortedRewards.count

        VStack(alignment: .leading, spacing: 8) {
            // Header with count badge
            HStack {
                Text("Achievements")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Count badge
                Text("\(totalCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.85, green: 0.65, blue: 0.1))
                    )

                Spacer()

                // "View all" link - always visible
                Button(action: { showingRewardHistory = true }) {
                    HStack(spacing: 4) {
                        Text(totalCount > 3 ? "View all" : "View history")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.1))
                }
            }

            // Show first 3 completed rewards
            ForEach(sortedRewards.prefix(3)) { reward in
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.1))

                    Text(reward.name)
                        .font(.subheadline)

                    Spacer()

                    if let date = reward.redeemedDate {
                        Text("Achieved \(formattedDate(date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Celebration message for milestone completion counts
            if totalCount >= 5 {
                HStack(spacing: 6) {
                    Image(systemName: totalCount >= 10 ? "star.fill" : "sparkles")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(milestoneMessage(for: totalCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }

    /// Generate celebration message based on completed rewards count
    private func milestoneMessage(for count: Int) -> String {
        if count >= 25 {
            return "25+ goals achieved! \(currentChild.name) is a superstar!"
        } else if count >= 10 {
            return "10+ goals completed! Amazing consistency!"
        } else if count >= 5 {
            return "5 goals down! Building great habits!"
        }
        return ""
    }
    
    private func formattedDate(_ date: Date) -> String {
        RewardsDateFormatterCache.dayMonthFormatter.string(from: date)
    }
}

// MARK: - Reward Card (supports primary and secondary states) - Enhanced with game psychology

struct RewardCard: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var themeProvider: ThemeProvider

    let reward: Reward
    let child: Child
    let isPrimary: Bool
    let onMarkReceived: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onShowKidView: (() -> Void)? = nil
    var onSetAsPrimary: (() -> Void)? = nil

    @State private var animateProgress = false
    @State private var pulseIcon = false

    private var progress: Double {
        reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    private var pointsEarned: Int {
        reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    private var pointsRemaining: Int {
        reward.pointsRemaining(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    private var rewardStatus: Reward.RewardStatus {
        reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    /// Whether this reward is ready to celebrate (goal reached)
    private var isReadyToRedeem: Bool {
        rewardStatus == .readyToRedeem
    }

    /// Whether this reward is in a terminal state (completed or expired)
    private var isTerminal: Bool {
        rewardStatus.isTerminal
    }

    var body: some View {
        VStack(spacing: isPrimary ? 20 : 12) {
            // Primary reward gets enhanced hero layout
            if isPrimary && !isTerminal {
                enhancedPrimaryLayout
            } else {
                standardLayout
            }
        }
        .padding(isPrimary ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: isPrimary ? 24 : 16)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: isPrimary ? 16 : 8, y: isPrimary ? 8 : 4)
        )
        .opacity(isTerminal ? 0.85 : 1.0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateProgress = true
            }
            if isReadyToRedeem {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseIcon = true
                }
            }
        }
    }

    // MARK: - Enhanced Primary Layout (Compact Management Card)

    private var enhancedPrimaryLayout: some View {
        VStack(spacing: AppSpacing.md) {
            // Header row with status badge and menu
            HStack {
                statusBadge
                Spacer()
                menuButton
            }

            // Main content: Icon + Goal info
            HStack(spacing: 16) {
                // Goal icon with glow for ready state
                ZStack {
                    if isReadyToRedeem {
                        Circle()
                            .fill(themeProvider.positiveColor.opacity(0.2))
                            .frame(width: 72, height: 72)
                            .scaleEffect(pulseIcon ? 1.15 : 1.0)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isReadyToRedeem
                                    ? [themeProvider.positiveColor, themeProvider.positiveColor.opacity(0.7)]
                                    : [child.colorTag.color.opacity(0.15), child.colorTag.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: reward.imageName ?? "gift.fill")
                        .font(.system(size: 26))
                        .foregroundColor(isReadyToRedeem ? .white : child.colorTag.color)
                }

                // Goal details
                VStack(alignment: .leading, spacing: 6) {
                    Text(reward.name)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(2)

                    // Stars progress
                    HStack(spacing: 4) {
                        Text("\(pointsEarned)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(child.colorTag.color)

                        Text("/ \(reward.targetPoints)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)

                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeProvider.starColor)
                    }

                    // Timer display for deadlines (inline)
                    if reward.hasDeadline, let remaining = reward.timeRemainingString {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(remaining)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(timeRemainingColor)
                    }
                }

                Spacer()
            }

            // Horizontal progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeProvider.streakInactiveColor)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: progressBarColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (animateProgress ? progress : 0), height: 10)
                        .animation(.spring(response: 0.6), value: animateProgress)

                    // Milestone markers
                    ForEach(reward.milestones, id: \.self) { milestone in
                        let position = CGFloat(milestone) / CGFloat(reward.targetPoints)
                        let reached = pointsEarned >= milestone

                        Circle()
                            .fill(reached ? child.colorTag.color : Color(.systemGray5))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(reached ? child.colorTag.color.opacity(0.6) : Color(.systemGray4), lineWidth: 2)
                            )
                            .offset(x: geometry.size.width * position - 4)
                    }
                }
            }
            .frame(height: 10)

            // Progress helper text
            HStack {
                progressHelperText
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(progressPercentColor)
            }

            // Action button - changes based on reward status
            if isReadyToRedeem {
                // Celebrate button when goal is reached - uses child's color
                Button(action: onMarkReceived) {
                    HStack(spacing: 8) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 18))
                        Text("Celebrate!")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: child.colorTag.color.opacity(0.4), radius: 8, y: 4)
                }
            } else if let onShowKidView = onShowKidView {
                // Show child button when still in progress
                Button(action: onShowKidView) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 18))
                        Text("Show \(child.name)'s Progress")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: child.colorTag.color.opacity(0.4), radius: 8, y: 4)
                }
            }
        }
    }

    // MARK: - Standard Layout (Secondary/Terminal)

    private var standardLayout: some View {
        VStack(spacing: isPrimary ? 16 : 12) {
            // Reward Info
            HStack(spacing: 12) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconBackgroundColor.opacity(isTerminal ? 0.08 : 0.2), iconBackgroundColor.opacity(isTerminal ? 0.04 : 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isPrimary ? 56 : 48, height: isPrimary ? 56 : 48)

                    Image(systemName: reward.imageName ?? "gift.fill")
                        .font(isPrimary ? .title2 : .title3)
                        .foregroundColor(iconBackgroundColor.opacity(isTerminal ? 0.5 : 1.0))
                }

                VStack(alignment: .leading, spacing: 4) {
                    statusBadge

                    Text(reward.name)
                        .font(isPrimary ? .headline : .subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isTerminal ? .secondary : .primary)

                    // Points display
                    if rewardStatus == .completed {
                        if let dateString = reward.redeemedDateString {
                            Text("Given on \(dateString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(pointsEarned) of \(reward.targetPoints) stars")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if rewardStatus == .expired {
                        Text("Deadline passed")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    } else {
                        HStack(spacing: 4) {
                            Text("\(pointsEarned)/\(reward.targetPoints)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(child.colorTag.color)
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }

                    // Timer
                    if !isTerminal && reward.hasDeadline, let remaining = reward.timeRemainingString {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(remaining)
                                .font(.caption2)
                        }
                        .foregroundColor(timeRemainingColor)
                    }
                }

                Spacer()

                menuButton
            }

            // Progress Bar with gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeProvider.streakInactiveColor)
                        .frame(height: isPrimary ? 12 : 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: progressBarColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (animateProgress ? progress : 0), height: isPrimary ? 12 : 8)
                        .animation(.spring(response: 0.6), value: animateProgress)

                    // Milestone markers - use child color for reached (consistent with progress bar)
                    if isPrimary && !isTerminal {
                        ForEach(reward.milestones, id: \.self) { milestone in
                            let position = CGFloat(milestone) / CGFloat(reward.targetPoints)
                            let reached = pointsEarned >= milestone

                            Circle()
                                .fill(reached ? child.colorTag.color : Color(.systemGray5))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(reached ? child.colorTag.color.opacity(0.6) : Color(.systemGray4), lineWidth: 2)
                                )
                                .offset(x: geometry.size.width * position - 4)
                        }
                    }
                }
            }
            .frame(height: isPrimary ? 12 : 8)

            // Progress Text
            HStack {
                progressHelperText
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(progressPercentColor)
            }

            // Kid View button for primary
            if isPrimary && !isTerminal {
                if let onShowKidView = onShowKidView {
                    Button(action: onShowKidView) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.circle.fill")
                            Text("Show Progress")
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(child.colorTag.color.opacity(0.12))
                        .foregroundColor(child.colorTag.color)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Menu Button

    private var menuButton: some View {
        Menu {
            if !isTerminal && !isPrimary, let onSetAsPrimary = onSetAsPrimary {
                Button(action: onSetAsPrimary) {
                    Label("Make main goal", systemImage: "star.fill")
                }
            }

            if !isTerminal, let onEdit = onEdit {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }

            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(isPrimary ? .title2 : .title3)
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
    
    // MARK: - Status Badge
    
    /// Richer amber gold for achievement badges
    private let achievementGold = Color(red: 0.85, green: 0.55, blue: 0.1)

    @ViewBuilder
    private var statusBadge: some View {
        switch rewardStatus {
        case .readyToRedeem:
            HStack(spacing: 4) {
                Image(systemName: "party.popper.fill")
                    .font(.caption2)
                Text("Goal Reached!")
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [achievementGold, Color(red: 0.95, green: 0.7, blue: 0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(6)

        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.caption2)
                Text("Achieved")
            }
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(achievementGold.opacity(0.15))
            .foregroundColor(achievementGold)
            .cornerRadius(4)
            
        case .active, .activeWithDeadline:
            if isPrimary {
                Text("Main goal")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(child.colorTag.color.opacity(0.15))
                    .foregroundColor(child.colorTag.color)
                    .cornerRadius(4)
            } else {
                Text("Upcoming")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(themeProvider.streakInactiveColor)
                    .foregroundColor(themeProvider.secondaryText)
                    .cornerRadius(4)
            }
            
        case .expired:
            HStack(spacing: 4) {
                Image(systemName: "clock.badge.xmark")
                    .font(.caption2)
                Text("Expired")
            }
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.15))
            .foregroundColor(.red)
            .cornerRadius(4)
        }
    }
    
    // MARK: - Progress Helper Text
    
    @ViewBuilder
    private var progressHelperText: some View {
        switch rewardStatus {
        case .readyToRedeem:
            // Simple "Ready!" text - celebration is on the button
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                Text("Ready!")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(child.colorTag.color)

        case .completed:
            Label("Achieved", systemImage: "trophy.fill")
                .font(.caption)
                .foregroundColor(achievementGold)

        case .expired:
            Text("Goal not reached in time")
                .font(.caption)
                .foregroundColor(.secondary)

        case .active, .activeWithDeadline:
            Text("\(pointsRemaining) more points to go")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Colors
    
    private var iconBackgroundColor: Color {
        switch rewardStatus {
        case .readyToRedeem: return child.colorTag.color  // Use child's color when goal reached
        case .completed: return achievementGold
        case .expired: return themeProvider.challengeColor
        case .active, .activeWithDeadline: return child.colorTag.color
        }
    }

    private var progressBarColors: [Color] {
        switch rewardStatus {
        case .readyToRedeem:
            // Use child's color for progress bar when goal reached
            return [child.colorTag.color, child.colorTag.color.opacity(0.8)]
        case .completed:
            return [achievementGold.opacity(0.5), achievementGold.opacity(0.3)]
        case .expired:
            let color = themeProvider.challengeColor
            return [color.opacity(0.5), color.opacity(0.3)]
        case .active, .activeWithDeadline:
            return [child.colorTag.color, child.colorTag.color.opacity(0.7)]
        }
    }

    private var progressPercentColor: Color {
        switch rewardStatus {
        case .readyToRedeem: return child.colorTag.color  // Use child's color
        case .completed: return achievementGold
        case .expired: return themeProvider.challengeColor.opacity(0.7)
        case .active, .activeWithDeadline: return child.colorTag.color
        }
    }

    private var cardBackgroundColor: Color {
        // Use neutral backgrounds to avoid competing with child identity color
        // Ready-to-redeem indicated via badge only, not background tint or border
        switch rewardStatus {
        case .readyToRedeem:
            // Neutral background - the "Earned" badge indicates ready state
            return themeProvider.resolved.cardBackground
        case .completed: return themeProvider.resolved.cardBackground.opacity(0.6)
        case .expired: return themeProvider.challengeColor.opacity(0.05)
        case .active, .activeWithDeadline:
            // Neutral background to not compete with child identity color
            return themeProvider.resolved.cardBackground
        }
    }

    private var cardBorderColor: Color {
        // No colored borders - they compete with child identity color
        // Ready-to-redeem state is indicated by the "Earned" badge
        return .clear
    }
    
    private var timeRemainingColor: Color {
        guard let remaining = reward.timeRemaining else { return .secondary }
        if remaining < 24 * 60 * 60 { // Less than 1 day - urgent
            return themeProvider.challengeColor
        } else if remaining < 3 * 24 * 60 * 60 { // Less than 3 days - attention
            return themeProvider.starColor
        }
        // Normal time remaining - neutral, not colored (reduces visual noise)
        return .secondary
    }
}

// MARK: - Reward History Sheet

/// Sheet showing all completed rewards for a child
struct RewardHistorySheet: View {
    let child: Child
    let rewards: [Reward]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    private var sortedRewards: [Reward] {
        rewards.sorted { ($0.redeemedDate ?? .distantPast) > ($1.redeemedDate ?? .distantPast) }
    }

    private var groupedByMonth: [(key: String, rewards: [Reward])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped: [String: [Reward]] = [:]
        var monthOrder: [String] = []

        for reward in sortedRewards {
            let key = formatter.string(from: reward.redeemedDate ?? Date())
            if grouped[key] == nil {
                grouped[key] = []
                monthOrder.append(key)
            }
            grouped[key]?.append(reward)
        }

        return monthOrder.map { (key: $0, rewards: grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 56, height: 56)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.1))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(rewards.count) Goals Achieved")
                                .font(.title2.weight(.bold))
                            Text("\(child.name)'s achievements")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Grouped by month
                    ForEach(groupedByMonth, id: \.key) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.key)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(group.rewards) { reward in
                                    rewardRow(reward)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(themeProvider.resolved.backgroundColor)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func rewardRow(_ reward: Reward) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.1))

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.subheadline.weight(.medium))

                if let date = reward.redeemedDate {
                    Text(formattedDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Points badge
            Text("\(reward.targetPoints) pts")
                .font(.caption.weight(.medium))
                .foregroundColor(themeProvider.positiveColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeProvider.positiveColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(12)
        .background(themeProvider.resolved.cardBackground)
        .cornerRadius(12)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    RewardsView()
        .environmentObject(repository)
        .environmentObject(RewardsStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(CelebrationStore())
}

#Preview("Empty") {
    let repository = Repository()
    RewardsView()
        .environmentObject(repository)
        .environmentObject(RewardsStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(CelebrationStore())
}
