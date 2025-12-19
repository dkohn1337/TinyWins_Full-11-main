import SwiftUI

enum ChildDetailTab: String, CaseIterable {
    case overview = "Overview"
    case kidView = "Progress"
    case agreement = "Our Plan"
}

struct ChildDetailView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var progressionStore: ProgressionStore
    @EnvironmentObject private var celebrationStore: CelebrationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    private var logBehaviorUseCase: LogBehaviorUseCase {
        LogBehaviorUseCase(
            behaviorsStore: behaviorsStore,
            childrenStore: childrenStore,
            rewardsStore: rewardsStore,
            progressionStore: progressionStore,
            celebrationStore: celebrationStore
        )
    }

    let child: Child

    @State private var selectedTab: ChildDetailTab = .overview
    @State private var showingEditChild = false
    @State private var showingAddReward = false
    @State private var showingTemplatePicker = false
    @State private var selectedRewardTemplate: RewardTemplate? = nil
    @State private var showingLogBehavior = false
    @State private var showingDeleteConfirmation = false
    @State private var showingArchiveConfirmation = false
    @State private var showingKidView = false
    @State private var showingFamilyAgreement = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastCategory: ToastCategory = .positive

    // Get the latest child data from childrenStore
    private var currentChild: Child {
        childrenStore.child(id: child.id) ?? child
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with avatar and segmented control
            childHeaderWithTabs
            
            // Tab Content (Insights consolidated to main Insights tab)
            TabView(selection: $selectedTab) {
                overviewTab
                    .tag(ChildDetailTab.overview)

                KidView(child: currentChild)
                    .tag(ChildDetailTab.kidView)

                FamilyPlanView(child: currentChild)
                    .tag(ChildDetailTab.agreement)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(theme.bg1)
        .navigationTitle(currentChild.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingEditChild = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    if currentChild.isArchived {
                        Button(action: {
                            childrenStore.unarchiveChild(id: child.id)
                            toastMessage = "\(currentChild.name) is now active"
                            toastCategory = .positive
                            showingToast = true
                        }) {
                            Label("Unarchive", systemImage: "tray.and.arrow.up")
                        }
                    } else {
                        Button(role: .destructive, action: { showingArchiveConfirmation = true }) {
                            Label("Archive", systemImage: "archivebox")
                        }
                    }

                    Divider()

                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditChild) {
            AddEditChildView(mode: .edit(currentChild)) { updatedChild in
                childrenStore.updateChild(updatedChild)
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            RewardTemplatePickerView(
                child: currentChild,
                onTemplateSelected: { template in
                    selectedRewardTemplate = template
                    // Small delay to allow sheet to dismiss before presenting new one
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAddReward = true
                    }
                },
                onCreateCustom: {
                    selectedRewardTemplate = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAddReward = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddReward) {
            AddRewardView(child: currentChild, template: selectedRewardTemplate)
        }
        .sheet(isPresented: $showingLogBehavior) {
            LogBehaviorSheet(
                child: currentChild,
                onBehaviorSelected: { behaviorTypeId, note, attachments, rewardId in
                    logBehaviorUseCase.execute(childId: currentChild.id, behaviorTypeId: behaviorTypeId, note: note)
                },
                onQuickAdd: { message, category in
                    toastMessage = message
                    toastCategory = category
                    withAnimation {
                        showingToast = true
                    }
                }
            )
        }
        .toast(isShowing: $showingToast, message: toastMessage, category: toastCategory)
        .alert("Delete \(currentChild.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                childrenStore.deleteChild(id: child.id)
                dismiss()
            }
        } message: {
            Text("This removes \(currentChild.name) and all their stars and history from this device.")
        }
        .alert("Archive \(currentChild.name)?", isPresented: $showingArchiveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Archive", role: .destructive) {
                childrenStore.archiveChild(id: child.id)
                dismiss()
            }
        } message: {
            Text("\(currentChild.name) will be hidden but their history stays safe. You can bring them back anytime.")
        }
    }
    
    // MARK: - Header with Tabs
    
    private var childHeaderWithTabs: some View {
        VStack(spacing: 16) {
            // Avatar and name
            HStack(spacing: 16) {
                ChildAvatar(child: currentChild, size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentChild.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let age = currentChild.age {
                        Text("\(age) \(age == 1 ? "year" : "years") old")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Segmented Control
            Picker("Tab", selection: $selectedTab) {
                ForEach(ChildDetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(theme.surface1)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Agreement needs review banner (if applicable)
                if hasGoalsNeedingAgreement {
                    agreementNeedsReviewBanner
                }
                
                // Points & Reward Section
                pointsAndRewardSection
                
                // Skill Badges (if any)
                badgesSection
                
                // Quick Log Button
                quickLogButton
                
                // Suggestions (if any)
                suggestionsSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
    }
    
    private var agreementCoverageStatus: AgreementCoverageStatus {
        rewardsStore.agreementCoverageStatus(forChild: currentChild.id)
    }

    private var hasActiveRewards: Bool {
        !rewardsStore.rewards(forChild: currentChild.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .isEmpty
    }
    
    private var hasGoalsNeedingAgreement: Bool {
        // Only show banner if there are active rewards AND agreement status isn't current
        hasActiveRewards && agreementCoverageStatus != .signedCurrent
    }
    
    private var agreementNeedsReviewBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.orange)
                Text(agreementCoverageStatus == .neverSigned ? "Check In Together" : "Time to Refresh")
                    .font(.subheadline.weight(.semibold))
            }

            Text(agreementCoverageStatus == .neverSigned ?
                 "Review your plan together so you're both on the same page." :
                 "Your goals have changed. Take a moment to check in together.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            Button(action: { selectedTab = .agreement }) {
                Text("View Our Plan")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Badges Section

    private var badgesSection: some View {
        let badges = progressionStore.badges(forChild: currentChild.id)
        
        return Group {
            if !badges.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "medal.fill")
                            .foregroundColor(.yellow)
                        Text("Skill Badges")
                            .font(.headline)
                        
                        Spacer()


                        Text("\(badges.count)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    // Show badges in a horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(badges.prefix(10)) { badge in
                                SkillBadgeView(badge: badge)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding()
                .background(theme.surface1)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Points & Reward Section
    
    private var activeRewards: [Reward] {
        rewardsStore.rewards(forChild: currentChild.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
    }
    
    private var pointsAndRewardSection: some View {
        VStack(spacing: 16) {
            // Current Balance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Balance")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("\(currentChild.totalPoints)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(currentChild.colorTag.color)
                }
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow.opacity(0.8))
            }
            .padding()
            .background(theme.surface1)
            .cornerRadius(12)
            
            // All Active Rewards
            if !activeRewards.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(activeRewards.enumerated()), id: \.element.id) { index, reward in
                        RewardProgressCard(
                            reward: reward,
                            colorTag: currentChild.colorTag,
                            showActiveLabel: index == 0,
                            isPrimary: index == 0
                        )
                    }
                }
            } else {
                // No active reward - show button to add
                Button(action: { showingTemplatePicker = true }) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Set a Reward Goal")
                                .font(.headline)
                            Text("Pick something exciting to work toward")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .padding()
                    .background(currentChild.colorTag.color.opacity(0.1))
                    .foregroundColor(currentChild.colorTag.color)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Quick Log Button
    
    private var starTargetReward: Reward? {
        rewardsStore.defaultStarTarget(forChild: currentChild.id, behaviorEvents: behaviorsStore.behaviorEvents)
    }
    
    private var quickLogButton: some View {
        VStack(spacing: 8) {
            Button(action: { showingLogBehavior = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Moment")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(currentChild.colorTag.color)
                .foregroundColor(.white)
                .cornerRadius(AppStyles.buttonCornerRadius)
            }
            
            // Star routing helper text
            HStack(spacing: 4) {
                if let reward = starTargetReward {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(theme.star)
                    Text("New stars go toward:")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(reward.name)
                        .font(.caption.weight(.medium))
                        .foregroundColor(currentChild.colorTag.color)
                } else {
                    Image(systemName: "star")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                    Text("Stars aren't linked to a goal yet")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title3)
                .fontWeight(.semibold)

            let events = behaviorsStore.recentEvents(forChild: currentChild.id)
            
            if events.isEmpty {
                Text("Nothing logged yet. Add a moment!")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background(theme.surface1)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 1) {
                    ForEach(events) { event in
                        ChildEventRow(event: event)
                    }
                }
                .background(theme.surface1)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        let suggestions = improvementSuggestions()

        return Group {
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Suggestions")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    ForEach(suggestions.prefix(2)) { suggestion in
                        let state = routineState(for: suggestion)
                        let buttonLabel = buttonLabelForState(state, suggestionType: suggestion.type)
                        let isDisabled = state == .alreadyActive
                        
                        SuggestionCard(
                            suggestion: suggestion,
                            buttonLabel: buttonLabel,
                            isDisabled: isDisabled,
                            onAction: {
                                handleSuggestionAction(suggestion)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods

    private func improvementSuggestions() -> [ImprovementSuggestion] {
        let allSuggestions = AnalyticsService.improvementSuggestions(
            events: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes,
            child: currentChild
        )

        // Filter out suggestions for behaviors that are already active routines
        return allSuggestions.filter { suggestion in
            if suggestion.type == .reduceNegative {
                return true
            }

            let state = routineState(for: suggestion)
            return state != .alreadyActive
        }
    }

    private func routineState(for suggestion: ImprovementSuggestion) -> RoutineState {
        // Find existing behavior by name (case-insensitive)
        let existingBehavior = behaviorsStore.behaviorTypes.first {
            $0.name.lowercased() == suggestion.behaviorType.name.lowercased()
        }

        guard let existing = existingBehavior else {
            return .notCreated
        }

        return existing.isActive ? .alreadyActive : .existsNotActive
    }

    /// Determine the appropriate button label based on routine state
    private func buttonLabelForState(_ state: RoutineState, suggestionType: ImprovementSuggestion.SuggestionType) -> String {
        switch state {
        case .notCreated:
            return "Add as routine"
        case .existsNotActive:
            return "Start tracking this"
        case .alreadyActive:
            // This shouldn't happen since we filter these out, but just in case
            return "Already tracking"
        }
    }

    private func handleSuggestionAction(_ suggestion: ImprovementSuggestion) {
        let childName = currentChild.name
        let behaviorName = suggestion.behaviorType.name

        // Use the centralized state detection
        let state = routineState(for: suggestion)

        switch state {
        case .notCreated:
            // Create new behavior and mark it as active routine
            let newBehavior = BehaviorType(
                name: suggestion.behaviorType.name,
                category: .routinePositive,
                defaultPoints: suggestion.behaviorType.defaultPoints,
                isActive: true,
                iconName: suggestion.behaviorType.iconName,
                suggestedAgeRange: suggestion.behaviorType.suggestedAgeRange,
                difficultyScore: suggestion.behaviorType.difficultyScore
            )
            behaviorsStore.addBehaviorType(newBehavior)
            toastMessage = "Nice choice! \"\(behaviorName)\" is now a daily check-in for \(childName)."
            toastCategory = .positive

        case .existsNotActive:
            // Activate the existing behavior
            if let existingBehavior = behaviorsStore.behaviorTypes.first(where: {
                $0.name.lowercased() == behaviorName.lowercased()
            }) {
                var updated = existingBehavior
                updated.isActive = true
                behaviorsStore.updateBehaviorType(updated)
                toastMessage = "Great! \"\(behaviorName)\" is back on \(childName)'s list."
                toastCategory = .positive
            }

        case .alreadyActive:
            // Race condition fallback - behavior became active between render and tap
            // Show a helpful message that doesn't feel like an error
            toastMessage = "You're already tracking \"\(behaviorName)\". Keep it up!"
            toastCategory = .positive
        }
        
        withAnimation { showingToast = true }
        
        // Log analytics event
        AnalyticsService.shared.log(.custom("suggestion_action", [
            "type": String(describing: suggestion.type),
            "state": String(describing: state),
            "behavior": behaviorName
        ]))
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)


                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.surface1)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reward Progress Card

struct RewardProgressCard: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.theme) private var theme
    let reward: Reward
    let colorTag: ColorTag
    var showActiveLabel: Bool = false
    var isPrimary: Bool = true
    var onTapReady: (() -> Void)? = nil

    private var progress: Double {
        reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    private var pointsEarned: Int {
        reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    private var rewardStatus: Reward.RewardStatus {
        reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }
    
    var body: some View {
        Group {
            if rewardStatus == .readyToRedeem, let onTap = onTapReady {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reward ready: \(reward.name)")
                .accessibilityHint("Double tap to mark as given")
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reward.imageName ?? "gift.fill")
                    .font(.title2)
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(headerText)
                        .font(.caption)
                        .foregroundColor(headerColor)
                    Text(reward.name)
                        .font(.headline)
                        .foregroundColor(rewardStatus == .completed ? theme.textSecondary : theme.textPrimary)
                }

                Spacer()

                // Status badge based on state
                statusBadge

                // Chevron for ready-to-redeem state
                if rewardStatus == .readyToRedeem && onTapReady != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green.opacity(0.6))
                }
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.borderSoft)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressBarColor)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    progressText

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(percentColor)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        // No colored border - ready state indicated by badge only
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var headerText: String {
        switch rewardStatus {
        case .readyToRedeem: return "" // Badge shows "Reward ready", no header needed
        case .completed: return "Given"
        case .expired: return "Expired"
        case .active, .activeWithDeadline: return isPrimary ? "Working toward" : "Queued"
        }
    }


    private var headerColor: Color {
        // Use secondary for all states - badge indicates ready state
        return theme.textSecondary
    }

    private var iconColor: Color {
        switch rewardStatus {
        case .readyToRedeem: return colorTag.color // Keep child identity
        case .completed: return theme.textSecondary
        case .expired: return theme.danger.opacity(0.6)
        case .active, .activeWithDeadline: return colorTag.color
        }
    }

    private var progressBarColor: Color {
        switch rewardStatus {
        case .readyToRedeem: return colorTag.color // Keep child identity
        case .completed: return theme.textDisabled
        case .expired: return theme.danger.opacity(0.5)
        case .active, .activeWithDeadline: return colorTag.color
        }
    }

    private var percentColor: Color {
        switch rewardStatus {
        case .readyToRedeem: return colorTag.color // Keep child identity
        case .completed, .expired: return theme.textSecondary
        case .active, .activeWithDeadline: return colorTag.color
        }
    }

    private var cardBackgroundColor: Color {
        // Neutral backgrounds - ready state indicated by badge only
        switch rewardStatus {
        case .readyToRedeem: return theme.surface1
        case .completed: return theme.surface1.opacity(0.7)
        case .expired: return theme.danger.opacity(0.03)
        case .active, .activeWithDeadline: return theme.surface1
        }
    }
    
    @ViewBuilder
    private var progressText: some View {
        switch rewardStatus {
        case .readyToRedeem:
            Text("When you give it, mark it as given in Rewards.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        case .completed:
            if let dateString = reward.redeemedDateString {
                Text("Given on \(dateString)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                Text("\(pointsEarned) / \(reward.targetPoints) points")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        case .expired:
            Text("Goal not reached")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        case .active, .activeWithDeadline:
            Text("\(pointsEarned) / \(reward.targetPoints) points")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
    
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
            .modifier(PulsingBadgeModifier())
            .accessibilityLabel("Goal Reached")
            .accessibilityHint("Tap to celebrate this achievement")

        case .completed:
            if showActiveLabel {
                Text("Achieved")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(achievementGold.opacity(0.15))
                    .foregroundColor(achievementGold)
                    .cornerRadius(4)
            }
            
        case .expired:
            Text("Expired")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.15))
                .foregroundColor(.red)
                .cornerRadius(4)
            
        case .active, .activeWithDeadline:
            if showActiveLabel {
                Text("Active")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorTag.color.opacity(0.15))
                    .foregroundColor(colorTag.color)
                    .cornerRadius(6)
            } else if reward.hasDeadline, let days = reward.daysRemaining {
                Text("\(days)d left")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Child Event Row

struct ChildEventRow: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.theme) private var theme
    let event: BehaviorEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date/Time
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
            .frame(width: 60, alignment: .leading)

            // Behavior name
            if let behaviorType = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
                Text(behaviorType.name)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Points
            Text(pointsText)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(event.isPositive ? .green : .red.opacity(0.8))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(event.timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(event.timestamp) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: event.timestamp)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.timestamp)
    }
    
    private var pointsText: String {
        if event.pointsApplied >= 0 {
            return "+\(event.pointsApplied)"
        } else {
            return "\(event.pointsApplied)"
        }
    }
}

// MARK: - Skill Badge View

struct SkillBadgeView: View {
    @Environment(\.theme) private var theme
    let badge: SkillBadge

    private var badgeColor: Color {
        switch badge.type.color {
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        case "blue": return .blue
        case "indigo": return .indigo
        case "orange": return .orange
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "yellow": return .yellow
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: badge.type.icon)
                    .font(.title2)
                    .foregroundColor(badgeColor)
                
                // Level indicator
                if badge.level > 1 {
                    Text("\(badge.level)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(badgeColor)
                        .clipShape(Circle())
                        .offset(x: 18, y: -18)
                }
            }


            Text(badge.type.rawValue)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    NavigationStack {
        ChildDetailView(child: Child(name: "Emma", age: 8, colorTag: .purple, totalPoints: 45))
    }
    .environmentObject(repository)
    .environmentObject(ChildrenStore(repository: repository))
    .environmentObject(BehaviorsStore(repository: repository))
    .environmentObject(RewardsStore(repository: repository))
    .environmentObject(ProgressionStore())
    .environmentObject(CelebrationStore())
}
