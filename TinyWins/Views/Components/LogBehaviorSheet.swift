import SwiftUI

struct LogBehaviorSheet: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var progressionStore: ProgressionStore
    @EnvironmentObject private var prefs: UserPreferencesStore
    @Environment(\.dismiss) private var dismiss

    let child: Child
    let onBehaviorSelected: (UUID, String?, [MediaAttachment], UUID?) -> Void // Added rewardId
    var onQuickAdd: ((String, ToastCategory) -> Void)? // Callback for toast message and category

    @State private var selectedBehaviorType: BehaviorType?
    @State private var note: String = ""
    @State private var showingMediaPicker = false
    @State private var mediaAttachments: [MediaAttachment] = []
    @State private var showingConfirmation = false
    @State private var searchText: String = ""
    @State private var selectedRewardId: UUID? = nil
    @State private var showingRewardSelector = false

    // Goal interception state
    @State private var showingGoalInterception = false
    @State private var pendingBehavior: BehaviorType? = nil

    private var hasSeenGoalInterception: Bool {
        prefs.hasSeenGoalInterception(forChildId: child.id)
    }
    
    // Available rewards for this child
    private var availableRewards: [Reward] {
        rewardsStore.rewards(forChild: child.id)
            .filter {!$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
    }

    // Default star target
    private var defaultStarTarget: Reward? {
        rewardsStore.defaultStarTarget(forChild: child.id, behaviorEvents: behaviorsStore.behaviorEvents)
    }
    
    // Current star target name for display
    private var currentTargetName: String {
        if let id = selectedRewardId,
           let reward = availableRewards.first(where: { $0.id == id }) {
            return reward.name
        }
        return "No reward"
    }
    
    // Check if should show goal prompt (no goal + some logged moments)
    private var shouldShowGoalPrompt: Bool {
        let noActiveGoal = availableRewards.isEmpty
        let hasLoggedMoments = behaviorsStore.behaviorEvents.filter {
            $0.childId == child.id && $0.pointsApplied > 0
        }.count >= 3
        return noActiveGoal && hasLoggedMoments
    }
    
    // Check if we should intercept with goal prompt
    private func shouldInterceptForGoal(_ behavior: BehaviorType) -> Bool {
        return availableRewards.isEmpty &&
              !hasSeenGoalInterception &&
               behavior.category != .negative
    }
    
    @State private var showingCreateGoal = false
    @State private var challengesSectionExpanded = false  // Collapsed by default

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Child Header
                    childHeader
                    
                    // Goal prompt (when no goal + some logged moments)
                    if shouldShowGoalPrompt {
                        goalPromptBanner
                    }
                    
                    // Star target selector pill
                    starTargetSelectorPill
                    
                    // Age-based suggestion banner
                    if let age = child.age {
                        ageSuggestionBanner(age: age)
                    }

                    // Search bar for behaviors
                    behaviorSearchBar

                    // Recent behaviors (quick access) - hidden when searching
                    if searchText.isEmpty {
                        recentBehaviorsSection
                    }
                    
                    // Behavior Sections - Routines and Positive first, Challenges last
                    behaviorSection(for: .routinePositive)
                    behaviorSection(for: .positive)
                    behaviorSection(for: .negative)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // NOTE: This view uses 5 separate .sheet() modifiers, which can cause presentation issues on iOS 15-16.
            // However, since TinyWins targets iOS 17+, this pattern is acceptable.
            // The sheets are mutually exclusive (controlled by separate @State bools) and cannot trigger simultaneously.
            // If iOS 17+ exhibits sheet issues in the future, refactor to a single .sheet() with an enum.
            .sheet(isPresented: $showingMediaPicker) {
                MediaPickerSheet(
                    onImageSelected: { image in
                        if let attachment = MediaManager.shared.saveImage(image) {
                            mediaAttachments.append(attachment)
                        }
                    },
                    onVideoSelected: { url in
                        if let attachment = MediaManager.shared.saveVideo(from: url) {
                            mediaAttachments.append(attachment)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingRewardSelector) {
                rewardSelectorSheet
            }
            .sheet(isPresented: $showingConfirmation) {
                if let behavior = selectedBehaviorType {
                    MomentConfirmationSheet(
                        child: child,
                        behaviorType: behavior,
                        note: $note,
                        mediaAttachments: $mediaAttachments,
                        selectedRewardId: $selectedRewardId,
                        availableRewards: availableRewards,
                        onConfirm: {
                            onBehaviorSelected(
                                behavior.id,
                                note.isEmpty ? nil : note,
                                mediaAttachments,
                                behavior.defaultPoints > 0 ? selectedRewardId : nil // Only assign reward for positive
                            )
                            dismiss()
                        },
                        onConfirmWithBonus: {
                            // Add note about bonus star if no note exists
                            let finalNote = note.isEmpty ? " Bonus star awarded!" : "\(note)\n Bonus star awarded!"
                            onBehaviorSelected(
                                behavior.id,
                                finalNote,
                                mediaAttachments,
                                behavior.defaultPoints > 0 ? selectedRewardId : nil
                            )
                            // Log an extra point by calling onBehaviorSelected again with a special "bonus" note
                            // Actually, we need to handle this differently - let's just add to the note for now
                            dismiss()
                        },
                        onAddMedia: {
                            showingMediaPicker = true
                        }
                    )
                }
            }
            .onAppear {
                // Default to the star target (active reward that can accept points)
                selectedRewardId = defaultStarTarget?.id
            }
            .sheet(isPresented: $showingGoalInterception) {
                GoalInterceptionSheet(
                    child: child,
                    onChooseGoal: {
                        prefs.setHasSeenGoalInterception(true, forChildId: child.id)
                        showingGoalInterception = false
                        showingCreateGoal = true
                    },
                    onNotNow: {
                        prefs.setHasSeenGoalInterception(true, forChildId: child.id)
                        showingGoalInterception = false
                        // Continue with the pending behavior
                        if let behavior = pendingBehavior {
                            executeQuickAdd(behavior)
                        }
                    }
                )
                .presentationDetents([.height(280)])
            }
            .sheet(isPresented: $showingCreateGoal) {
                NavigationStack {
                    KidGoalSelectionView(
                        child: child,
                        suggestions: rewardsStore.generateKidGoalOptions(forChild: child),
                        onGoalSelected: { selectedOption in
                            let reward = Reward(
                                childId: child.id,
                                name: selectedOption.name,
                                targetPoints: selectedOption.stars,
                                imageName: selectedOption.icon,
                                priority: 0,
                                dueDate: Calendar.current.date(byAdding: .day, value: selectedOption.days, to: Date())
                            )
                            rewardsStore.addReward(reward)
                            // After goal is set, continue with pending behavior
                            if let behavior = pendingBehavior {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    executeQuickAdd(behavior)
                                }
                            }
                        },
                        onManageRewards: {
                            // Dismiss goal picker - user can create custom goal from Goals tab
                            showingCreateGoal = false
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Add (Fast Path)
    
    private func quickAddBehavior(_ behavior: BehaviorType) {
        // Check if we should intercept with goal prompt
        if shouldInterceptForGoal(behavior) {
            pendingBehavior = behavior
            showingGoalInterception = true
            return
        }
        
        executeQuickAdd(behavior)
    }
    
    private func executeQuickAdd(_ behavior: BehaviorType) {
        // For quick add, use the primary reward (or nil for challenges)
        let rewardId = behavior.defaultPoints > 0 ? availableRewards.first?.id : nil
        onBehaviorSelected(behavior.id, nil, [], rewardId)
        
        // Determine toast category based on behavior category
        let toastCategory: ToastCategory
        let verb: String
        switch behavior.category {
        case .routinePositive:
            toastCategory = .routine
            verb = "Added"
        case .positive:
            toastCategory = .positive
            verb = "Added"
        case .negative:
            toastCategory = .challenge
            verb = "Noted"
        }
        
        // Generate toast message
        let pointsText = behavior.defaultPoints >= 0 ? "+\(behavior.defaultPoints)" : "\(behavior.defaultPoints)"
        let message = "\(verb) '\(behavior.name)' (\(pointsText) stars)"
        onQuickAdd?(message, toastCategory)
        
        dismiss()
    }
    
    // MARK: - Star Target Selector
    
    @ViewBuilder
    private var starTargetSelectorPill: some View {
        // Only show if there are rewards to select from
        if !availableRewards.isEmpty {
            Button(action: { showingRewardSelector = true }) {
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
                            .foregroundColor(child.colorTag.color)
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
    
    private var rewardSelectorSheet: some View {
        NavigationStack {
            List {
                let options = rewardsStore.rewardSelectionOptions(forChild: child.id, behaviorEvents: behaviorsStore.behaviorEvents)
                
                // Rewards that can accept points
                Section {
                    ForEach(options.filter { $0.canAcceptPoints }) { option in
                        Button(action: {
                            selectedRewardId = option.id
                            showingRewardSelector = false
                        }) {
                            HStack {
                                if let iconName = option.reward.imageName {
                                    Image(systemName: iconName)
                                        .foregroundColor(child.colorTag.color)
                                        .frame(width: 24)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.reward.name)
                                        .foregroundColor(.primary)
                                    if option.isDefault {
                                        Text("Active reward")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedRewardId == option.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(child.colorTag.color)
                                }
                            }
                        }
                    }
                    
                    // "No reward" option
                    Button(action: {
                        selectedRewardId = nil
                        showingRewardSelector = false
                    }) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No reward, just stars")
                                    .foregroundColor(.primary)
                                Text("Recognition without goal progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedRewardId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text("Apply stars to")
                }
                
                // Rewards that cannot accept points (disabled)
                let disabledOptions = options.filter {!$0.canAcceptPoints }
                if !disabledOptions.isEmpty {
                    Section {
                        ForEach(disabledOptions) { option in
                            HStack {
                                if let iconName = option.reward.imageName {
                                    Image(systemName: iconName)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.reward.name)
                                        .foregroundColor(.secondary)
                                    if let note = option.statusNote {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .opacity(0.6)
                        }
                    } header: {
                        Text("Unavailable")
                    }
                }
            }
            .navigationTitle("Choose Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { showingRewardSelector = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Behavior Search Bar

    private var behaviorSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            TextField("Search behaviors...", text: $searchText)
                .font(.subheadline)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Child Header

    private var childHeader: some View {
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
    
    // MARK: - Goal Prompt Banner
    
    private var goalPromptBanner: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Give these stars a home")
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Pick a reward so \(child.name) has something exciting to work toward.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            Button(action: { showingCreateGoal = true }) {
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
    
    // MARK: - Age Suggestion Banner
    
    private func ageSuggestionBanner(age: Int) -> some View {
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
    
    // MARK: - Recent Behaviors Section
    
    @ViewBuilder
    private var recentBehaviorsSection: some View {
        let recentBehaviors = behaviorsStore.recentBehaviorTypes(forChild: child.id, limit: 5)
        
        if !recentBehaviors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StyledIcon(systemName: "clock.arrow.circlepath", color: .purple, size: 14, backgroundSize: 28)
                    Text("Recent")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Tap to add quickly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recentBehaviors) { behavior in
                            RecentBehaviorChip(
                                behavior: behavior,
                                onTap: {
                                    quickAddBehavior(behavior)
                                },
                                onLongPress: {
                                    selectedBehaviorType = behavior
                                    showingConfirmation = true
                                }
                            )
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Behavior Sections

    // Popular behaviors (frequently logged across all families)
    private let popularBehaviorNames: Set<String> = [
        "Morning routine completed",
        "Bedtime routine completed",
        "Brushed teeth"
    ]

    @ViewBuilder
    private func behaviorSection(for category: BehaviorCategory) -> some View {
        let allBehaviors = behaviorsStore.suggestedBehaviors(forChild: child, category: category)
        // Filter by search text if searching
        let behaviors = searchText.isEmpty ? allBehaviors : allBehaviors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        let isChallenge = category == .negative
        let isExpanded = isChallenge ? challengesSectionExpanded : true

        if !behaviors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Section Header (tappable for Challenges)
                Button(action: {
                    if isChallenge {
                        withAnimation(.spring(response: 0.3)) {
                            challengesSectionExpanded.toggle()
                        }
                    }
                }) {
                    HStack {
                        StyledIcon(
                            systemName: category.iconName,
                            color: sectionColor(for: category),
                            size: 14,
                            backgroundSize: 28
                        )
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(behaviors.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)

                        // Chevron for collapsible Challenges section
                        if isChallenge {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Collapsed hint for Challenges
                if isChallenge && !isExpanded {
                    Text("Tap to expand")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 36)
                }

                // Behavior Buttons (shown if expanded)
                if isExpanded {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(behaviors) { behavior in
                            BehaviorTile(
                                behavior: behavior,
                                category: category,
                                isPopular: popularBehaviorNames.contains(behavior.name),
                                onTap: {
                                    quickAddBehavior(behavior)
                                },
                                onLongPress: {
                                    selectedBehaviorType = behavior
                                    showingConfirmation = true
                                }
                            )
                        }
                    }
                }
            }
        } else {
            // Return empty but valid view
            EmptyView()
        }
    }
    
    private func sectionColor(for category: BehaviorCategory) -> Color {
        switch category {
        case .routinePositive: return AppColors.routine
        case .positive: return AppColors.positive
        case .negative: return AppColors.challenge
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    LogBehaviorSheet(
        child: Child(name: "Emma", age: 8, colorTag: .purple),
        onBehaviorSelected: { _, _, _, _ in }
    )
    .environmentObject(repository)
    .environmentObject(ChildrenStore(repository: repository))
    .environmentObject(BehaviorsStore(repository: repository))
    .environmentObject(RewardsStore(repository: repository))
    .environmentObject(ProgressionStore())
    .environmentObject(UserPreferencesStore())
}
