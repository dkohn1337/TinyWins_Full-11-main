import SwiftUI

/// Child-friendly view showing progress toward reward
/// No negative numbers, no detailed history, no configuration
/// Uses "stars" terminology for child-friendly language
struct KidView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var progressionStore: ProgressionStore
    @EnvironmentObject private var prefs: UserPreferencesStore
    @EnvironmentObject private var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss

    let child: Child
    var activeReward: Reward? // Optional - if nil, will look up from rewardsStore

    @State private var showingFireworks = false
    @State private var showingThemePicker = false

    private var selectedTheme: KidViewTheme {
        KidViewTheme(rawValue: prefs.kidViewTheme(forChildId: child.id)) ?? .classic
    }

    private var unlockedThemes: [KidViewTheme] {
        KidViewTheme.unlockedThemes(goalsCompleted: rewardsStore.goalsCompleted(forChild: child.id))
    }

    // Get the reward to display
    private var displayReward: Reward? {
        activeReward ?? rewardsStore.activeReward(forChild: child.id)
    }
    
    private var themeGradient: LinearGradient {
        switch selectedTheme {
        case .classic:
            return LinearGradient(
                colors: [child.colorTag.color.opacity(0.3), child.colorTag.color.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .space:
            return LinearGradient(
                colors: [Color.indigo.opacity(0.6), Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .ocean:
            return LinearGradient(
                colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .forest:
            return LinearGradient(
                colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .rainbow:
            return LinearGradient(
                colors: [Color.red.opacity(0.2), Color.orange.opacity(0.2), Color.yellow.opacity(0.2), Color.green.opacity(0.2), Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient based on theme
            themeGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with theme picker and close button
                    HStack {
                        // Theme picker (only show if more than one theme unlocked)
                        if unlockedThemes.count > 1 {
                            Button(action: { showingThemePicker = true }) {
                                Image(systemName: selectedTheme.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44) // Larger tap area
                        .contentShape(Rectangle())
                    }
                    .padding(.horizontal)
                    
                    // Big avatar and name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(child.colorTag.color)
                                .frame(width: 120, height: 120)
                                .shadow(color: child.colorTag.color.opacity(0.5), radius: 20)
                            
                            Text(child.initials)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(child.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    // Reward progress
                    if let reward = displayReward {
                        rewardProgressCard(reward: reward)
                    } else {
                        noRewardCard
                    }
                    
                    // Badges / Achievements
                    achievementBadges
                    
                    // Today's stars (positive behaviors only)
                    todayStars
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            
            // Fireworks overlay
            if showingFireworks {
                FireworksView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerSheet(
                child: child,
                unlockedThemes: unlockedThemes,
                totalGoalsCompleted: rewardsStore.goalsCompleted(forChild: child.id)
            )
            .environmentObject(prefs)
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Reward Progress Card
    
    private func rewardProgressCard(reward: Reward) -> some View {
        // Check if this is the primary reward
        let isPrimary = (displayReward?.id == reward.id)
        let rewardStatus = reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
        let progress = reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
        let earned = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)

        return ElevatedCard(elevation: .high, padding: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                // Content varies by status
                switch rewardStatus {
                case .readyToRedeem:
                    // Celebration view - goal reached!
                    rewardEarnedView(reward: reward, earned: earned)

                case .completed:
                    // Already given view
                    rewardCompletedView(reward: reward, earned: earned)

                case .expired:
                    // Expired view with gentle messaging
                    rewardExpiredView(reward: reward, earned: earned)

                case .active, .activeWithDeadline:
                    // Working toward view
                    rewardActiveView(reward: reward, progress: progress, earned: earned)
                }
            }
        }
    }
    
    // MARK: - Active Reward View (Working toward)
    
    @ViewBuilder
    private func rewardActiveView(reward: Reward, progress: Double, earned: Int) -> some View {
        // Reward header with GIANT glowing icon - use theme star color
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeProvider.starColor.opacity(0.3), themeProvider.starColor.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeProvider.starColor.opacity(0.3), themeProvider.starColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: reward.imageName ?? "gift.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(themeProvider.starColor)
                    .shadow(color: themeProvider.starColor.opacity(0.5), radius: 16)
            }
            .padding(.top, AppSpacing.md)

            VStack(spacing: AppSpacing.xxs) {
                Text("Working toward:")
                    .font(AppTypography.label)
                    .foregroundColor(.secondary)

                Text(reward.name)
                    .font(AppTypography.displayLarge)
                    .fontWeight(.black)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }

        // MASSIVE progress ring with milestone markers
        ZStack {
            // Use shared large progress ring component
            LargeProgressRingView(
                progress: progress,
                color: child.colorTag.color,
                milestones: reward.milestones,
                targetPoints: reward.targetPoints,
                currentPoints: earned
            )

            // GIANT center stats
            VStack(spacing: AppSpacing.xs) {
                // Stars earned - fraction style with HUGE numbers
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(earned)")
                        .font(.system(size: 88, weight: .black, design: .rounded))
                        .foregroundColor(child.colorTag.color)

                    Text("/")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("\(reward.targetPoints)")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                // Label with star icon - use theme star color
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(AppTypography.title3)
                        .foregroundColor(themeProvider.starColor)
                    Text("stars")
                        .font(AppTypography.title3)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, AppSpacing.xl)

        // Encouragement message
        encouragementMessage(progress: progress)

        // Days remaining if applicable
        if let days = reward.daysRemaining, days > 0 {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock.fill")
                    .foregroundColor(child.colorTag.color)
                Text("\(days) day\(days == 1 ? "" : "s") left")
                    .fontWeight(.semibold)
            }
            .font(AppTypography.bodyLarge)
            .foregroundColor(.secondary)
            .padding(.top, AppSpacing.xxs)
        }
    }
    
    // MARK: - Earned Reward View (Ready to redeem)
    
    @ViewBuilder
    private func rewardEarnedView(reward: Reward, earned: Int) -> some View {
        // Trophy celebration
        ZStack {
            Circle()
                .fill(themeProvider.positiveColor.opacity(0.15))
                .frame(width: 120, height: 120)

            Circle()
                .fill(themeProvider.positiveColor.opacity(0.25))
                .frame(width: 90, height: 90)

            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(themeProvider.starColor)
                .shadow(color: themeProvider.starColor.opacity(0.5), radius: 10)
        }
        .onAppear {
            showingFireworks = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showingFireworks = false
            }
        }
        
        // "You earned:" label
        Text("You earned:")
            .font(.headline)
            .foregroundColor(themeProvider.positiveColor)

        Text(reward.name)
            .font(.largeTitle)
            .fontWeight(.bold)

        // Celebration message
        VStack(spacing: 8) {
            Text("Amazing job!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeProvider.positiveColor)
            
            Text("You collected all \(reward.targetPoints) stars!")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Ask your parent to give you your reward!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Completed Reward View (Already given)

    @ViewBuilder
    private func rewardCompletedView(reward: Reward, earned: Int) -> some View {
        // Checkmark with reward icon
        ZStack {
            Circle()
                .fill(themeProvider.streakInactiveColor)
                .frame(width: 100, height: 100)

            Image(systemName: reward.imageName ?? "gift.fill")
                .font(.system(size: 40))
                .foregroundColor(themeProvider.secondaryText)

            // Checkmark badge
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(themeProvider.positiveColor)
                .background(themeProvider.cardBackground.clipShape(Circle()))
                .offset(x: 35, y: 35)
        }
        
        // "You got:" label
        Text("You got:")
            .font(.headline)
            .foregroundColor(.secondary)
        
        Text(reward.name)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
        
        // Completion info
        VStack(spacing: 8) {
            Text("Great job! ")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let dateString = reward.redeemedDateString {
                Text("Given on \(dateString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("You collected \(earned) stars for this reward!")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Expired Reward View

    @ViewBuilder
    private func rewardExpiredView(reward: Reward, earned: Int) -> some View {
        // Soft expired icon
        ZStack {
            Circle()
                .fill(themeProvider.streakInactiveColor)
                .frame(width: 100, height: 100)

            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 44))
                .foregroundColor(themeProvider.secondaryText)
        }
        
        Text(reward.name)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
        
        // Gentle message
        VStack(spacing: 8) {
            Text("This goal has finished")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("You collected \(earned) of \(reward.targetPoints) stars")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("You can pick a new goal together!")
                .font(.body)
                .foregroundColor(.primary)
                .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func encouragementMessage(progress: Double) -> some View {
        // Note: 100% progress is handled by rewardEarnedView, not shown here
        if progress >= 0.75 {
            VStack(spacing: 4) {
                Text("Almost there!")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("You're getting so close!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else if progress >= 0.5 {
            VStack(spacing: 4) {
                Text("Halfway there!")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Great job, keep going!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else if progress >= 0.25 {
            VStack(spacing: 4) {
                Text("Nice progress!")
                    .font(.headline)
                    .foregroundColor(themeProvider.positiveColor)
                Text("You're on your way!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else if progress > 0 {
            VStack(spacing: 4) {
                Text("Good start!")
                    .font(.headline)
                    .foregroundColor(themeProvider.positiveColor)
                Text("You can do it!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - No Reward Card
    
    private var noRewardCard: some View {
        ElevatedCard(elevation: .high, padding: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "star.circle")
                    .font(.system(size: 60))
                    .foregroundColor(themeProvider.starColor)

                Text("Keep being awesome!")
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Text("You have")
                        .font(.title3)
                    Text("\(child.totalPoints)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(child.colorTag.color)
                    Text("stars!")
                        .font(.title3)
                }
            }
        }
    }
    
    // MARK: - Achievement Badges

    private var achievementBadges: some View {
        let recentBadges = getRecentBadges()
        let allBadges = getAllBadges()

        return Group {
            if !allBadges.isEmpty {
                ElevatedCard(elevation: .medium, padding: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Text("Your Journey")
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()

                            if allBadges.count > recentBadges.count {
                                NavigationLink(destination: AllBadgesView(child: child, badges: allBadges)) {
                                    HStack(spacing: 4) {
                                        Text("See all")
                                            .font(.subheadline.weight(.medium))
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                    }
                                    .foregroundColor(child.colorTag.color)
                                }
                            }
                        }

                        // Show recent/most important badges
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.md) {
                                ForEach(recentBadges, id: \.id) { badge in
                                    BadgeView(
                                        icon: badge.icon,
                                        title: badge.title,
                                        subtitle: badge.subtitle,
                                        color: badge.color
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(child.colorTag.color.opacity(0.1))
                )
            }
        }
    }

    // Computed property for recent/important badges (3-5 badges)
    private func getRecentBadges() -> [BadgeInfo] {
        let allBadges = getAllBadges()
        return Array(allBadges.prefix(5))
    }

    // Computed property for all badges
    private func getAllBadges() -> [BadgeInfo] {
        var badges: [BadgeInfo] = []

        // Skill badges from progression system (most recent first)
        let skillBadges = progressionStore.badges(forChild: child.id)
        for skillBadge in skillBadges {
            let color = badgeColor(from: skillBadge.type.color)
            badges.append(BadgeInfo(
                id: skillBadge.id.uuidString,
                icon: skillBadge.type.icon,
                title: skillBadge.type.rawValue,
                subtitle: "Level \(skillBadge.level)",
                color: color
            ))
        }

        // Routine activity badges (weekly, not consecutive)
        let routines = calculateRoutineActivity()
        for routine in routines {
            badges.append(BadgeInfo(
                id: routine.name,
                icon: routine.icon,
                title: routine.name,
                subtitle: "\(routine.count) this week",
                color: routine.color
            ))
        }

        // Achievement badges
        let achievements = calculateAchievements()
        for achievement in achievements {
            badges.append(BadgeInfo(
                id: achievement.name,
                icon: achievement.icon,
                title: achievement.name,
                subtitle: achievement.subtitle,
                color: achievement.color
            ))
        }

        return badges
    }

    private func badgeColor(from colorName: String) -> Color {
        switch colorName {
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

    // Badge info structure for unified badge handling
    struct BadgeInfo: Identifiable {
        let id: String
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
    }
    
    // MARK: - Today's Stars

    private var todayStars: some View {
        let todayPositive = behaviorsStore.todayEvents
            .filter { $0.childId == child.id && $0.pointsApplied > 0 }

        return Group {
            if !todayPositive.isEmpty {
                ElevatedCard(elevation: .medium, padding: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // GIANT header with star count
                        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                                Text("Today's Stars")
                                    .font(AppTypography.displayLarge)
                                    .fontWeight(.black)
                                    .foregroundColor(.primary)

                                HStack(spacing: AppSpacing.xxs) {
                                    Image(systemName: "star.fill")
                                        .font(AppTypography.title2)
                                        .foregroundColor(themeProvider.starColor)
                                    Text("\(todayPositive.count) earned today")
                                        .font(AppTypography.bodyLarge)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.semibold)
                                }
                            }

                            Spacer()

                            // Giant number badge - use theme star color
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [themeProvider.starColor.opacity(0.3), themeProvider.starColor.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)

                                Text("\(todayPositive.count)")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(themeProvider.starColor)
                            }
                        }

                        // Star events with premium styling
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(todayPositive) { event in
                                if let behavior = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
                                    HStack(spacing: AppSpacing.md) {
                                        // Icon with gradient background - use theme star color
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [themeProvider.starColor.opacity(0.2), themeProvider.starColor.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 52, height: 52)

                                            Image(systemName: behavior.iconName)
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(themeProvider.starColor)
                                        }

                                        Text(behavior.name)
                                            .font(AppTypography.bodyLarge)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        // Points badge
                                        Text("+\(event.pointsApplied)")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(themeProvider.positiveColor)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, AppSpacing.xxs)
                                            .background(themeProvider.bannerPositiveBackground)
                                            .cornerRadius(8)
                                    }
                                    .padding(AppSpacing.md)
                                    .background(themeProvider.cardBackground)
                                    .cornerRadius(16)
                                    .shadow(color: themeProvider.cardShadow, radius: 4, y: 2)
                                }
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [themeProvider.starColor.opacity(0.08), themeProvider.starColor.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Renamed from StreakInfo to RoutineInfo - shows weekly activity, not consecutive days
    private struct RoutineInfo {
        let name: String
        let icon: String
        let count: Int  // Times this week (not consecutive)
        let color: Color
    }
    
    private struct AchievementInfo {
        let name: String
        let icon: String
        let subtitle: String
        let color: Color
    }
    
    // Calculate weekly routine activity (not consecutive streaks)
    private func calculateRoutineActivity() -> [RoutineInfo] {
        var routines: [RoutineInfo] = []
        
        // Check morning routine activity this week
        if let count = calculateRoutineThisWeek(containing: "morning"), count > 0 {
            routines.append(RoutineInfo(
                name: "Morning Hero",
                icon: "sun.horizon.fill",
                count: count,
                color: .orange
            ))
        }
        
        // Check bedtime routine activity this week
        if let count = calculateRoutineThisWeek(containing: "bedtime"), count > 0 {
            routines.append(RoutineInfo(
                name: "Bedtime Champ",
                icon: "moon.stars.fill",
                count: count,
                color: .purple
            ))
        }
        
        return routines
    }
    
    // Count routine completions this week (non-consecutive)
    private func calculateRoutineThisWeek(containing keyword: String) -> Int? {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        // Find matching behavior types
        let matchingBehaviors = behaviorsStore.behaviorTypes.filter {
            $0.name.lowercased().contains(keyword.lowercased()) &&
            $0.category == .routinePositive
        }

        guard !matchingBehaviors.isEmpty else { return nil }
        let behaviorIds = Set(matchingBehaviors.map { $0.id })

        // Get events for this child with matching behaviors this week
        let events = behaviorsStore.behaviorEvents.filter {
            $0.childId == child.id && 
            behaviorIds.contains($0.behaviorTypeId) &&
            $0.timestamp >= startOfWeek
        }
        
        // Count unique days with this routine (not consecutive)
        let uniqueDays = Set(events.map { calendar.startOfDay(for: $0.timestamp) })
        
        return uniqueDays.count > 0 ? uniqueDays.count : nil
    }
    
    private func calculateAchievements() -> [AchievementInfo] {
        var achievements: [AchievementInfo] = []

        // Count helping behaviors
        let helpingEvents = behaviorsStore.behaviorEvents.filter {
            $0.childId == child.id &&
            behaviorsStore.behaviorType(id: $0.behaviorTypeId)?.name.lowercased().contains("help") == true
        }
        
        if helpingEvents.count >= 5 {
            achievements.append(AchievementInfo(
                name: "Kindness Star",
                icon: "heart.fill",
                subtitle: "Helped \(helpingEvents.count) times",
                color: .pink
            ))
        }
        
        // Check total points milestones
        if child.totalPoints >= 100 {
            achievements.append(AchievementInfo(
                name: "Century Star",
                icon: "star.circle.fill",
                subtitle: "100+ points!",
                color: .yellow
            ))
        }
        
        if child.totalPoints >= 50 {
            achievements.append(AchievementInfo(
                name: "Rising Star",
                icon: "star.fill",
                subtitle: "50+ points!",
                color: .blue
            ))
        }
        
        return achievements
    }
}

// MARK: - Badge View - Enhanced with animations and gradients

struct BadgeView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Main badge circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Inner highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.3), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 4)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 90, height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: color.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Fireworks View

struct FireworksView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var color: Color
        var scale: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 12, height: 12)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(particle.position)
                }
            }
            .onAppear {
                createFireworks(in: geometry.size)
            }
        }
    }
    
    private func createFireworks(in size: CGSize) {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green]
        
        for _ in 0..<3 {
            let center = CGPoint(
                x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                y: CGFloat.random(in: size.height * 0.2...size.height * 0.5)
            )
            
            for i in 0..<20 {
                let angle = Double(i) * (360.0 / 20.0) * .pi / 180
                let distance = CGFloat.random(in: 50...150)
                
                let particle = Particle(
                    position: center,
                    color: colors.randomElement()!,
                    scale: 1,
                    opacity: 1
                )
                
                particles.append(particle)
                
                let index = particles.count - 1
                
                withAnimation(.easeOut(duration: 1.5).delay(Double.random(in: 0...0.5))) {
                    if index < particles.count {
                        particles[index].position = CGPoint(
                            x: center.x + cos(angle) * distance,
                            y: center.y + sin(angle) * distance
                        )
                        particles[index].scale = 0.1
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

// MARK: - Skill Badge Card (for Kid View)

struct SkillBadgeCard: View {
    let badge: SkillBadge
    @EnvironmentObject private var themeProvider: ThemeProvider

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
                    .frame(width: 60, height: 60)
                
                Image(systemName: badge.type.icon)
                    .font(.title)
                    .foregroundColor(badgeColor)
                
                // Level stars
                if badge.level > 1 {
                    HStack(spacing: 2) {
                        ForEach(0..<badge.level, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(themeProvider.starColor)
                        }
                    }
                    .offset(y: 35)
                }
            }
            
            Text(badge.type.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Level \(badge.level)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 90)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
    }
}

// MARK: - Theme Picker Sheet

struct ThemePickerSheet: View {
    @EnvironmentObject private var prefs: UserPreferencesStore
    let child: Child
    let unlockedThemes: [KidViewTheme]
    let totalGoalsCompleted: Int
    @Environment(\.dismiss) private var dismiss

    private var selectedTheme: String {
        prefs.kidViewTheme(forChildId: child.id)
    }

    // Premium themes require Plus
    private func isPlusTheme(_ theme: KidViewTheme) -> Bool {
        theme != .classic
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(KidViewTheme.allCases) { theme in
                        let isUnlocked = unlockedThemes.contains(theme)

                        Button(action: {
                            if isUnlocked {
                                prefs.setKidViewTheme(theme.rawValue, forChildId: child.id)
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: theme.icon)
                                    .font(.title2)
                                    .foregroundColor(isUnlocked ? themeColor(theme) : .secondary)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(theme.rawValue)
                                            .font(.headline)
                                            .foregroundColor(isUnlocked ? .primary : .secondary)
                                        
                                        if isPlusTheme(theme) {
                                            PlusBadge()
                                        }
                                    }
                                    
                                    if !isUnlocked {
                                        Text(unlockRequirement(theme))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedTheme == theme.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else if !isUnlocked {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(!isUnlocked)
                    }
                } header: {
                    Text("Choose a theme for Kid View")
                } footer: {
                    Text("Complete goals to unlock more themes!")
                }
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func themeColor(_ theme: KidViewTheme) -> Color {
        switch theme {
        case .classic: return .blue
        case .space: return .indigo
        case .ocean: return .cyan
        case .forest: return .green
        case .rainbow: return .purple
        }
    }
    
    private func unlockRequirement(_ theme: KidViewTheme) -> String {
        switch theme {
        case .classic: return "Available"
        case .ocean: return "Complete 3 goals"
        case .forest: return "Complete 5 goals"
        case .space: return "Complete 8 goals"
        case .rainbow: return "Complete 12 goals"
        }
    }
}

// MARK: - Kid Goal Selection View (Kid Participation)

/// A child-friendly view where kids can browse goals by category
/// Presented as big, tappable cards organized by category with horizontal scrolling
struct KidGoalSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    enum Context {
        case afterReward    // Shown after completing a goal
        case addingGoal     // Shown when adding a new goal from Goals tab

        var title: String {
            switch self {
            case .afterReward: return "Pick your next adventure!"
            case .addingGoal: return "What should we work toward?"
            }
        }

        var subtitle: String {
            switch self {
            case .afterReward: return "What excites you most?"
            case .addingGoal: return "Pick together with your kid!"
            }
        }
    }

    let child: Child
    let suggestions: [KidGoalOption]
    let onGoalSelected: (KidGoalOption) -> Void
    var onManageRewards: (() -> Void)? = nil
    var context: Context = .addingGoal
    var recentGoals: [KidGoalOption] = []  // Recently used goals from past rewards

    @State private var selectedOption: KidGoalOption?
    @State private var selectedCategory: KidGoalOption.KidGoalCategory? = nil
    @State private var isConfirming = false
    @State private var showContent = false
    @State private var starPulse = false
    @State private var searchText = ""

    // Search-filtered suggestions
    private var searchFilteredSuggestions: [KidGoalOption] {
        guard !searchText.isEmpty else { return suggestions }
        return suggestions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // Group suggestions by category (respecting search filter)
    private var suggestionsByCategory: [(category: KidGoalOption.KidGoalCategory, options: [KidGoalOption])] {
        let filtered = searchFilteredSuggestions
        let grouped = Dictionary(grouping: filtered) { $0.category }
        return KidGoalOption.KidGoalCategory.allCases.compactMap { category in
            guard let options = grouped[category], !options.isEmpty else { return nil }
            return (category, options)
        }
    }

    // Filtered options based on selected category (and search)
    private var filteredOptions: [KidGoalOption] {
        let base = searchFilteredSuggestions
        if let category = selectedCategory {
            return base.filter { $0.category == category }
        }
        return base
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedMeshBackground(baseColor: child.colorTag.color)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Compact header with animated star
                compactHeader
                    .padding(.top, 50)
                    .padding(.bottom, 16)

                // Category filter chips
                categoryChips
                    .padding(.bottom, 12)

                // Search bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Goal options organized by category OR filtered list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Recently used section (if any, no category filter, and not searching)
                        if !recentGoals.isEmpty && selectedCategory == nil && searchText.isEmpty {
                            recentGoalsSection
                        }

                        if selectedCategory == nil {
                            // Show all categories with horizontal scrolling
                            categorizedGoalsList
                        } else {
                            // Show filtered list for selected category
                            filteredGoalsList
                        }

                        // Completeness footer
                        completenessFooter
                            .padding(.top, 8)
                    }
                }

                // Bottom section with confirm button
                bottomSection
                    .padding(.bottom, 36)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .onAppear {
            withAnimation { starPulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5)) { showContent = true }
            }
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow rings (smaller) - use theme star color
                ForEach(0..<2) { i in
                    Circle()
                        .stroke(themeProvider.starColor.opacity(0.15 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: 50 + CGFloat(i) * 15, height: 50 + CGFloat(i) * 15)
                        .scaleEffect(starPulse ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: starPulse)
                }

                // Main star (smaller) - use theme star color
                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient(colors: [themeProvider.starColor, themeProvider.starColor.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: themeProvider.starColor.opacity(0.5), radius: 8, y: 3)
                    .scaleEffect(starPulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: starPulse)
            }
            .frame(height: 70)

            Text(context.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(context.subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Category Filter Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" chip
                CategoryChip(
                    title: "All",
                    icon: "sparkles",
                    color: child.colorTag.color,
                    isSelected: selectedCategory == nil,
                    count: suggestions.count
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }

                // Category chips
                ForEach(suggestionsByCategory, id: \.category) { item in
                    CategoryChip(
                        title: item.category.rawValue,
                        icon: item.category.icon,
                        color: item.category.color,
                        isSelected: selectedCategory == item.category,
                        count: item.options.count
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = item.category
                            selectedOption = nil // Clear selection when changing category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            TextField("Search goals...", text: $searchText)
                .font(.system(size: 16, design: .rounded))
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Completeness Footer

    private var completenessFooter: some View {
        let ageText = child.age.map { "age \($0)" } ?? "all ages"

        return HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text("Showing all \(suggestions.count) goals for \(ageText)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Recently Used Goals Section

    private var recentGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.purple)

                Text("Recently Used")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(recentGoals.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            // Horizontal scroll of recent goal cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(recentGoals.prefix(5).enumerated()), id: \.element.id) { index, option in
                        CompactGoalCard(
                            option: option,
                            isSelected: selectedOption?.id == option.id,
                            categoryColor: option.category.color
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedOption = option
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .overlay(alignment: .topLeading) {
                            // "Used before" badge
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                Text("Used")
                                    .font(.system(size: 8, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .cornerRadius(6)
                            .offset(x: -4, y: -4)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Categorized Goals List (All Categories View)

    private var categorizedGoalsList: some View {
        VStack(spacing: 24) {
            ForEach(Array(suggestionsByCategory.enumerated()), id: \.element.category) { categoryIndex, item in
                VStack(alignment: .leading, spacing: 12) {
                    // Category header
                    HStack(spacing: 8) {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(item.category.color)

                        Text(item.category.rawValue)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(item.options.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)

                    // Horizontal scroll of goal cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(item.options.enumerated()), id: \.element.id) { index, option in
                                CompactGoalCard(
                                    option: option,
                                    isSelected: selectedOption?.id == option.id,
                                    categoryColor: item.category.color
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        selectedOption = option
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                .offset(x: showContent ? 0 : 100)
                                .opacity(showContent ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(categoryIndex) * 0.1 + Double(index) * 0.05),
                                    value: showContent
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Filtered Goals List (Single Category View)

    private var filteredGoalsList: some View {
        VStack(spacing: 14) {
            ForEach(Array(filteredOptions.enumerated()), id: \.element.id) { index, option in
                KidGoalOptionCard(
                    option: option,
                    isSelected: selectedOption?.id == option.id,
                    childColor: child.colorTag.color,
                    iconGradient: [selectedCategory?.color ?? child.colorTag.color, (selectedCategory?.color ?? child.colorTag.color).opacity(0.7)]
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedOption = option
                    }
                }
                .offset(x: showContent ? 0 : UIScreen.main.bounds.width)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * 0.08),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Primary Confirm Button
            if let selected = selectedOption {
                Button(action: {
                    AnalyticsService.shared.log(.custom("goal_picker_confirmed", [
                        "goal_name": selected.name,
                        "category": selected.category.rawValue,
                        "child_id": child.id.uuidString
                    ]))

                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.spring(response: 0.3)) {
                        isConfirming = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onGoalSelected(selected)
                        dismiss()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                        Text("Let's go!")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: child.colorTag.color.opacity(0.4), radius: 12, y: 6)
                }
                .scaleEffect(isConfirming ? 0.95 : 1.0)
                .opacity(isConfirming ? 0.5 : 1)
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }

            // Secondary action - navigate to create custom goal
            if onManageRewards != nil {
                Button(action: {
                    AnalyticsService.shared.log(.custom("goal_picker_custom_goal_tapped", [
                        "child_id": child.id.uuidString
                    ]))
                    onManageRewards?()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 13))
                        Text("Create custom goal")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    .cornerRadius(8)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Goal Card (for horizontal scroll)

private struct CompactGoalCard: View {
    let option: KidGoalOption
    let isSelected: Bool
    let categoryColor: Color
    let onTap: () -> Void
    @EnvironmentObject private var themeProvider: ThemeProvider

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Icon with badge
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor.opacity(0.25), categoryColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: option.icon)
                            .font(.system(size: 26))
                            .foregroundColor(categoryColor)
                    }

                    // Popular/Quick Win badge
                    if option.isPopular || option.isQuickWin {
                        HStack(spacing: 2) {
                            Image(systemName: option.isPopular ? "heart.fill" : "bolt.fill")
                                .font(.system(size: 7))
                            Text(option.isPopular ? "Popular" : "Quick")
                                .font(.system(size: 7, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(option.isPopular ? Color.pink : Color.orange)
                        .cornerRadius(5)
                        .offset(x: 6, y: -4)
                    }
                }

                // Name
                Text(option.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 36)

                // Stats
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(themeProvider.starColor)
                    Text("\(option.stars)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(Color(.systemGray4))

                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("\(option.days)d")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 110)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? categoryColor.opacity(0.3) : .black.opacity(0.08), radius: isSelected ? 8 : 6, y: 3)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Animated Mesh Background
private struct AnimatedMeshBackground: View {
    let baseColor: Color
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme

    private var bgColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(.systemBackground)
    }

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    bgColor,
                    baseColor.opacity(colorScheme == .dark ? 0.25 : 0.15),
                    Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.1),
                    bgColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Floating orbs
            GeometryReader { geo in
                ForEach(0..<4) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    [baseColor, .purple, .blue, .pink][i % 4].opacity(colorScheme == .dark ? 0.3 : 0.2),
                                    [baseColor, .purple, .blue, .pink][i % 4].opacity(colorScheme == .dark ? 0.1 : 0.05)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .offset(
                            x: animate ? CGFloat.random(in: -50...50) : 0,
                            y: animate ? CGFloat.random(in: -30...30) : 0
                        )
                        .position(
                            x: geo.size.width * [0.2, 0.8, 0.3, 0.7][i % 4],
                            y: geo.size.height * [0.2, 0.4, 0.7, 0.9][i % 4]
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct KidGoalOptionCard: View {
    let option: KidGoalOption
    let isSelected: Bool
    let childColor: Color
    let iconGradient: [Color]
    let onTap: () -> Void
    @EnvironmentObject private var themeProvider: ThemeProvider

    @State private var isPressed = false
    @State private var iconBounce = false
    @State private var shimmer = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Vibrant icon with gradient background
                ZStack {
                    // Outer glow (always visible, brighter when selected)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    iconGradient[0].opacity(isSelected ? 0.5 : 0.25),
                                    iconGradient[1].opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: isSelected ? 8 : 4)

                    // Main circle with vibrant gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 66, height: 66)
                        .shadow(color: iconGradient[0].opacity(0.4), radius: 8, y: 4)

                    // Shimmer overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(shimmer ? 0.4 : 0.2),
                                    .clear,
                                    .white.opacity(shimmer ? 0.1 : 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 66, height: 66)

                    // Icon
                    Image(systemName: option.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .scaleEffect(iconBounce ? 1.2 : 1.0)
                }

                // Text content
                VStack(alignment: .leading, spacing: 8) {
                    Text(option.name)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        // Stars badge
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeProvider.starColor, themeProvider.starColor.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("\(option.stars)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeProvider.starColor.opacity(0.15))
                        )

                        // Days badge
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text("\(option.days) days")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? childColor : (colorScheme == .dark ? Color(white: 0.35) : Color(.systemGray4)),
                            lineWidth: isSelected ? 0 : 2
                        )
                        .frame(width: 30, height: 30)

                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [childColor, childColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                            .shadow(color: childColor.opacity(0.4), radius: 4, y: 2)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color(.systemBackground))
                    .shadow(
                        color: isSelected ? childColor.opacity(colorScheme == .dark ? 0.4 : 0.2) : Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                        radius: isSelected ? 16 : 10,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [childColor.opacity(0.6), childColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2.5
                    )
            )
            .scaleEffect(isPressed ? 0.97 : (isSelected ? 1.01 : 1.0))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in isPressed = false }
        )
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    iconBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.3)) {
                        iconBounce = false
                    }
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    KidView(child: Child(name: "Emma", age: 8, colorTag: .purple, totalPoints: 45))
        .environmentObject(ChildrenStore(repository: Repository.preview))
        .environmentObject(BehaviorsStore(repository: Repository.preview))
        .environmentObject(RewardsStore(repository: Repository.preview))
        .environmentObject(ProgressionStore())
        .environmentObject(UserPreferencesStore())
}

// MARK: - All Badges View

struct AllBadgesView: View {
    let child: Child
    let badges: [KidView.BadgeInfo]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(badges, id: \.id) { badge in
                    BadgeView(
                        icon: badge.icon,
                        title: badge.title,
                        subtitle: badge.subtitle,
                        color: badge.color
                    )
                }
            }
            .padding()
        }
        .navigationTitle("All Badges")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [
                    child.colorTag.color.opacity(colorScheme == .dark ? 0.2 : 0.1),
                    colorScheme == .dark ? Color(white: 0.1) : Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview("Goal Selection") {
    KidGoalSelectionView(
        child: Child(name: "Emma", age: 8, colorTag: .purple),
        suggestions: [
            KidGoalOption(name: "Park Adventure", icon: "leaf.fill", stars: 20, days: 7),
            KidGoalOption(name: "Movie Night Quest", icon: "tv.fill", stars: 25, days: 10),
            KidGoalOption(name: "Pizza Party", icon: "fork.knife", stars: 15, days: 5)
        ],
        onGoalSelected: { selected in
            print("Selected: \(selected.name)")
        }
    )
}
