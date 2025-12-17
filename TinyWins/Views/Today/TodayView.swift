import SwiftUI

// MARK: - Cached Formatters (performance optimization)
private enum DateFormatterCache {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct TodayView: View {
 let logBehaviorUseCase: LogBehaviorUseCase

 @EnvironmentObject private var childrenStore: ChildrenStore
 @EnvironmentObject private var behaviorsStore: BehaviorsStore
 @EnvironmentObject private var rewardsStore: RewardsStore
 @EnvironmentObject private var progressionStore: ProgressionStore
 @EnvironmentObject private var prefs: UserPreferencesStore
 @EnvironmentObject private var coordinator: AppCoordinator
 @EnvironmentObject private var coachMarkManager: CoachMarkManager
 @EnvironmentObject private var themeProvider: ThemeProvider
 @EnvironmentObject private var repository: Repository
 @State private var selectedChildForLogging: Child?
 @State private var showBehaviorManagement = false
 @State private var showingToast = false
 @State private var toastMessage = ""
 @State private var toastCategory: ToastCategory = .positive

 // First 48 hours coaching
 @State private var showingFirst48Coaching = false
 @State private var first48Message: (title: String, message: String)?

 // Parent reinforcement tracking
 @State private var showingFirstPositiveBanner = false
 @State private var showingWeeklyParentRecap = false
 @State private var showingConsistencyBanner = false
 @State private var showingReturnBanner = false
 @State private var dismissedRepairChildren: Set<UUID> = []
 @State private var dismissedFocusToday = false

 // Feedback prompt
 @EnvironmentObject private var feedbackManager: FeedbackManager
 @State private var showingFeedbackPrompt = false

 // Navigation state
 @State private var navigateToHistory = false

 // Evening reflection
 @State private var showingDailyCheckIn = false

 // Refresh state for pull-to-refresh
 @State private var isRefreshing = false

 // New Today Experience state
 @AppStorage("today_selected_child_id") private var selectedChildIdString: String = ""
 @State private var isFocusExpanded = false
 @State private var todayOpenedTime: Date?

 // Computed selected child ID (persisted via AppStorage)
 private var selectedChildId: Binding<UUID?> {
     Binding(
         get: {
             guard !selectedChildIdString.isEmpty else {
                 return childrenStore.activeChildren.first?.id
             }
             return UUID(uuidString: selectedChildIdString) ?? childrenStore.activeChildren.first?.id
         },
         set: { newValue in
             selectedChildIdString = newValue?.uuidString ?? ""
         }
     )
 }

 private var hasMomentsToday: Bool {
 !behaviorsStore.todayEvents.isEmpty
 }

 /// Yesterday's positive moment count for comparison
 private var yesterdayPositiveCount: Int {
     let calendar = Calendar.current
     guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
     let startOfYesterday = calendar.startOfDay(for: yesterday)
     guard let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday) else { return 0 }

     return behaviorsStore.behaviorEvents.filter { event in
         event.timestamp >= startOfYesterday &&
         event.timestamp < endOfYesterday &&
         event.pointsApplied > 0
     }.count
 }

 /// Children who have reached their goal target today
 private var childrenWithGoalsReached: [String] {
     childrenStore.activeChildren.compactMap { child in
         guard let goal = rewardsStore.activeReward(forChild: child.id) else { return nil }
         let earned = goal.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
         return earned >= goal.targetPoints ? child.name : nil
     }
 }

 private var shouldShowEveningReflection: Bool {
     EveningReflectionCard.shouldShow(repository: repository)
 }

 // MARK: - Refresh Data

 @MainActor
 private func refreshData() async {
 // Haptic feedback
 let generator = UIImpactFeedbackGenerator(style: .medium)
 generator.impactOccurred()

 isRefreshing = true

 // Simulate refresh delay for smooth animation
 try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds

 // Success haptic
 let successGenerator = UINotificationFeedbackGenerator()
 successGenerator.notificationOccurred(.success)

 isRefreshing = false
 }

 // MARK: - First 48 Hours Logic

 private var isInFirst48Hours: Bool {
     guard let completedDate = prefs.onboardingCompletedDate else { return false }
     let hoursSince = Date().timeIntervalSince(completedDate) / 3600
     return hoursSince <= 48
 }

 private var first48DayNumber: Int {
     guard let completedDate = prefs.onboardingCompletedDate else { return 0 }
     let daysSince = Calendar.current.dateComponents([.day], from: completedDate, to: Date()).day ?? 0
     return daysSince + 1
 }

 private func checkFirst48Coaching() {
     guard isInFirst48Hours else { return }

     if first48DayNumber == 1 && !prefs.first48Day1Shown {
         first48Message = (
             title: "Your first day!",
             message: "Just try noticing one good moment today. It could be something tiny: a smile, a thank you, a task done without asking."
         )
         withAnimation { showingFirst48Coaching = true }
         prefs.first48Day1Shown = true
     } else if first48DayNumber == 2 && !prefs.first48Day2Shown {
         first48Message = (
             title: "Day 2, you are building a habit!",
             message: "Keep going. Small wins really do add up. Look for one moment that made you proud of your child today."
         )
         withAnimation { showingFirst48Coaching = true }
         prefs.first48Day2Shown = true
     }
 }
 
 // Check if it's Sunday evening (for weekly recap)
 private var shouldShowWeeklyRecap: Bool {
 let calendar = Calendar.current
 let now = Date()
 let weekday = calendar.component(.weekday, from: now)
 let hour = calendar.component(.hour, from: now)
 return weekday == 1 && hour >= 17
 }
 
 // MARK: - Parent Reinforcement Conditions
 
 private var todayDateString: String {
 DateFormatterCache.dayFormatter.string(from: Date())
 }

 private var thisWeekString: String {
 let calendar = Calendar.current
 let weekOfYear = calendar.component(.weekOfYear, from: Date())
 let year = calendar.component(.year, from: Date())
 return "\(year)-\(weekOfYear)"
 }

 private var shouldShowFirstPositiveBanner: Bool {
 let todayString = DateFormatterCache.dayFormatter.string(from: Date())
 let lastString = prefs.lastFirstPositiveBannerDate.map { DateFormatterCache.dayFormatter.string(from: $0) } ?? ""
 guard lastString != todayString else { return false }
 return progressionStore.isFirstPositiveTodayForFamily(
  behaviorEvents: behaviorsStore.behaviorEvents,
  behaviorTypes: behaviorsStore.behaviorTypes
 )
 }

 private var shouldShowWeeklyParentRecap: Bool {
 let lastString = prefs.lastWeeklyRecapDate.map { thisWeekString(from: $0) } ?? ""
 guard lastString != thisWeekString else { return false }
 let calendar = Calendar.current
 let weekday = calendar.component(.weekday, from: Date())
 return weekday == 1
 }

 private var shouldShowConsistencyBanner: Bool {
 let lastString = prefs.lastConsistencyBannerDate.map { thisWeekString(from: $0) } ?? ""
 guard lastString != thisWeekString else { return false }
 let metrics = progressionStore.weeklyParentMetrics(
  children: childrenStore.children,
  behaviorEvents: behaviorsStore.behaviorEvents,
  behaviorTypes: behaviorsStore.behaviorTypes,
  rewards: rewardsStore.rewards
 )
 return metrics.daysActive >= 3
 }

 private var shouldShowReturnBanner: Bool {
 let lastString = prefs.lastReturnBannerDate.map { thisWeekString(from: $0) } ?? ""
 guard lastString != thisWeekString else { return false }
 guard let daysSinceLast = progressionStore.daysSinceLastActivity(
  behaviorEvents: behaviorsStore.behaviorEvents
 ) else { return false }
 return daysSinceLast >= 7
 }

 private func thisWeekString(from date: Date) -> String {
 let calendar = Calendar.current
 let weekOfYear = calendar.component(.weekOfYear, from: date)
 let year = calendar.component(.year, from: date)
 return "\(year)-\(weekOfYear)"
 }
 
 // MARK: - Week Progress Computation
 
 private var daysIntoWeek: Int {
 let calendar = Calendar.current
 let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
 let daysFromStart = calendar.dateComponents([.day], from: startOfWeek, to: Date()).day ?? 0
 return daysFromStart + 1
 }
 
 private var weekProgressMessage: String {
 let metrics = progressionStore.weeklyParentMetrics(
  children: childrenStore.children,
  behaviorEvents: behaviorsStore.behaviorEvents,
  behaviorTypes: behaviorsStore.behaviorTypes,
  rewards: rewardsStore.rewards
 )

 let daysActive = metrics.daysActive
 let dayText = daysActive == 1 ? "day" : "days"

 if daysActive == 0 {
 return "Every time you open TinyWins, you are building a habit that helps your kids."
 } else if daysActive == 1 {
 return "You have shown up on 1 day this week. Every moment you log matters."
 } else {
 return "You have shown up on \(daysActive) \(dayText) this week. You're building something lasting."
 }
 }

 // MARK: - New Today Experience Helpers

 /// Get today's data-driven focus
 private var todayFocus: TodayFocus {
     TodayFocusGenerator.shared.generateTodayFocus(
         children: childrenStore.activeChildren,
         behaviorEvents: behaviorsStore.behaviorEvents,
         behaviorTypes: behaviorsStore.behaviorTypes
     )
 }

 private func focusCollapsedSummary(_ focus: TodayFocus) -> String {
     // For data-driven focus, show child name if specific
     if let childName = focus.relatedChildName {
         return "For \(childName)"
     }

     // Extract a shorter version of the tip for collapsed state
     let tip = focus.primaryTip.lowercased()
     if tip.contains("sharing") { return "Notice sharing" }
     if tip.contains("effort") { return "Notice effort" }
     if tip.contains("appreciate") { return "Appreciate quietly" }
     if tip.contains("struggle") { return "Support struggles" }
     if tip.contains("patient") { return "Notice patience" }
     if tip.contains("curiosity") { return "Celebrate curiosity" }
     if tip.contains("frustration") { return "Support tough moments" }
     if tip.contains("kindness") { return "Notice kindness" }
     if tip.contains("strength") { return "Build strength" }
     if tip.contains("routine") { return "Build routine" }
     if tip.contains("balance") { return "Find balance" }
     return "Today's tip"
 }

 // Legacy property for backwards compatibility
 private var todayFocusTip: (String, String) {
     let focus = todayFocus
     return (focus.primaryTip, focus.actionTip)
 }

 /// Icon for data-driven focus based on source type
 private func focusIcon(for focus: TodayFocus) -> String {
     switch focus.source {
     case .challengePattern:
         return "eye.fill"
     case .strengthBuilding:
         return "star.fill"
     case .streakCelebration:
         return "flame.fill"
     case .recoveryCelebration:
         return "arrow.up.heart.fill"
     case .balanceNeeded:
         return "scale.3d"
     case .routineSupport:
         return "clock.fill"
     case .genericTip:
         return "lightbulb.fill"
     }
 }

 /// Icon color for data-driven focus based on source type
 private func focusIconColor(for focus: TodayFocus) -> Color {
     switch focus.source {
     case .challengePattern:
         return themeProvider.challengeColor
     case .strengthBuilding:
         return themeProvider.positiveColor
     case .streakCelebration:
         return .orange
     case .recoveryCelebration:
         return themeProvider.positiveColor
     case .balanceNeeded:
         return themeProvider.plusColor
     case .routineSupport:
         return themeProvider.routineColor
     case .genericTip:
         return themeProvider.starColor
     }
 }

 /// Title for data-driven focus based on source type
 private func focusTitle(for focus: TodayFocus) -> String {
     switch focus.source {
     case .challengePattern:
         return "Watch For"
     case .strengthBuilding:
         return "Reinforce"
     case .streakCelebration:
         return "Streak"
     case .recoveryCelebration:
         return "Bounce Back"
     case .balanceNeeded:
         return "Balance Tip"
     case .routineSupport:
         return "Routine Win"
     case .genericTip:
         return "Today's Focus"
     }
 }

 var body: some View {
 NavigationStack {
 ZStack {
 ScrollView {
 VStack(spacing: AppSpacing.md) {
 // 1. Parent greeting (time-of-day summary with goal celebration)
 ParentGreetingView(
 totalPositiveToday: behaviorsStore.todayPositiveCount,
 totalChallengesToday: behaviorsStore.todayNegativeCount,
 yesterdayPositive: yesterdayPositiveCount,
 childrenWithGoalsReached: childrenWithGoalsReached
 )

 // 2. Quick Add Section - PRIMARY ACTION AREA
 // Uses compact child picker + big Add Moment button
 QuickAddSection(
     selectedChildId: selectedChildId,
     onAddMoment: { child in
         // Track analytics
         let childIndex = childrenStore.activeChildren.firstIndex(where: { $0.id == child.id }) ?? 0
         let hasActiveGoal = rewardsStore.activeReward(forChild: child.id) != nil
         TodayAnalyticsTracker.shared.trackAddMomentTapped(
             source: "primary_button",
             selectedChildIndex: childIndex,
             hasActiveGoal: hasActiveGoal
         )
         selectedChildForLogging = child
     }
 )
 .padding(.horizontal, -16) // Counter outer padding for full-width
 .padding(.horizontal, 16)

 // Note: LatestTodayCard removed - redundant with Today's Activity section below

 // 4. Collapsible rows - progressive disclosure (compact)
 VStack(spacing: 8) {
     // Data-driven focus row (collapsed by default)
     if !dismissedFocusToday {
         let focus = todayFocus
         CollapsibleRow(
             icon: focusIcon(for: focus),
             iconColor: focusIconColor(for: focus),
             title: focusTitle(for: focus),
             subtitle: focusCollapsedSummary(focus),
             isExpanded: $isFocusExpanded,
             collapsedContent: {
                 HStack(spacing: 4) {
                     // Show confidence indicator for data-driven tips
                     if focus.source != .genericTip {
                         Image(systemName: "sparkles")
                             .font(.system(size: 8))
                             .foregroundColor(themeProvider.plusColor.opacity(0.6))
                     }
                     Image(systemName: "chevron.right")
                         .font(.system(size: 10, weight: .medium))
                         .foregroundColor(themeProvider.secondaryText.opacity(0.5))
                 }
             },
             expandedContent: {
                 FocusRowContent(focusTip: focus.primaryTip, actionTip: focus.actionTip)
             }
         )
         .onChange(of: isFocusExpanded) { _, expanded in
             if expanded {
                 TodayAnalyticsTracker.shared.trackRowExpanded(rowType: "focus")
             }
         }
     }

     // Evening reflection shortcut (simple link, main home is Insights > You)
     if shouldShowEveningReflection {
         Button(action: {
             showingDailyCheckIn = true
             TodayAnalyticsTracker.shared.trackReflectionOpened(trigger: "shortcut_tap")
         }) {
             HStack(spacing: 10) {
                 Image(systemName: "moon.stars.fill")
                     .font(.system(size: 14, weight: .medium))
                     .foregroundColor(themeProvider.plusColor)

                 Text("Reflect on today")
                     .font(.system(size: 13, weight: .medium))
                     .foregroundColor(themeProvider.primaryText)

                 Spacer()

                 Image(systemName: "chevron.right")
                     .font(.system(size: 10, weight: .semibold))
                     .foregroundColor(themeProvider.secondaryText.opacity(0.5))
             }
             .padding(.horizontal, 12)
             .padding(.vertical, 10)
             .background(
                 RoundedRectangle(cornerRadius: 10)
                     .fill(themeProvider.plusColor.opacity(0.08))
             )
         }
         .buttonStyle(.plain)
         .accessibilityLabel("Reflect on today")
         .accessibilityHint("Opens evening reflection")
     }
 }

 // 5. Goal progress mini-view (shows active reward progress)
 goalProgressMiniView

 // 6. Parent coaching strip (when present)
 parentCoachingStrip

 // 7. Today's Activity section (full detail)
 todaysActivitySection
 }
 .padding()
 .tabBarBottomPadding()
 }
 .background(themeProvider.backgroundColor)
 .refreshable {
 await refreshData()
 }

 // Coach marks are now handled by CoachMarkOverlay in ContentView
 }
 .navigationBarTitleDisplayMode(.inline)
 .themedNavigationBar(themeProvider)
 .toolbar {
 ToolbarItem(placement: .principal) {
     VStack(spacing: 0) {
         Text("Today")
             .font(.headline)
             .foregroundColor(themeProvider.primaryText)
         Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
             .font(.caption)
             .foregroundColor(themeProvider.secondaryText)
     }
     .accessibilityElement(children: .combine)
     .accessibilityLabel("Today, \(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))")
 }
 ToolbarItem(placement: .primaryAction) {
 // Simplified: Just settings icon for consistency across all tabs
 Button(action: { coordinator.presentSheet(.settings) }) {
 Image(systemName: "gearshape")
 }
 .accessibilityLabel("Settings")
 }
 }
 .sheet(item: $selectedChildForLogging) { child in
 LogBehaviorSheet(
 child: child,
 onBehaviorSelected: { behaviorTypeId, note, mediaAttachments, rewardId in
 logBehaviorUseCase.execute(
 childId: child.id,
 behaviorTypeId: behaviorTypeId,
 note: note
 )

 // Check for first positive of the day
 if shouldShowFirstPositiveBanner {
 prefs.lastFirstPositiveBannerDate = Date()
 DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
 withAnimation { showingFirstPositiveBanner = true }
 }
 DispatchQueue.main.asyncAfter(deadline: .now() + 5.3) {
 withAnimation { showingFirstPositiveBanner = false }
 }
 }
 },
 onQuickAdd: { message, category in
 toastMessage = message
 toastCategory = category
 withAnimation {
 showingToast = true
 }

 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
 if shouldShowFirstPositiveBanner {
 prefs.lastFirstPositiveBannerDate = Date()
 withAnimation { showingFirstPositiveBanner = true }
 DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
 withAnimation { showingFirstPositiveBanner = false }
 }
 }
 }
 }
 )
 }
 .toast(isShowing: $showingToast, message: toastMessage, icon: "checkmark.circle.fill", category: toastCategory)
 .onAppear {
 progressionStore.refreshDailyPromptIfNeeded()
 checkParentReinforcementConditions()
 checkFeedbackPromptEligibility()
 checkFirst48Coaching()

 // Track Today opened for analytics
 todayOpenedTime = Date()
 let selectedIndex = selectedChildId.wrappedValue.flatMap { id in
     childrenStore.activeChildren.firstIndex(where: { $0.id == id })
 }
 TodayAnalyticsTracker.shared.trackTodayOpened(
     childCount: childrenStore.activeChildren.count,
     hasActivityToday: hasMomentsToday,
     selectedChildIndex: selectedIndex
 )

 // Trigger new post-onboarding coach mark sequence
 if childrenStore.hasChildren {
     coachMarkManager.startSequenceIfNeeded(.today)
 }
 }
 .sheet(isPresented: $showingFeedbackPrompt) {
 FeedbackPromptView()
 .presentationDetents([.medium])
 }
 .sheet(isPresented: $showingDailyCheckIn) {
     DailyCheckInView()
 }
 .navigationDestination(isPresented: $navigateToHistory) {
 HistoryView()
 }
 }
 }
 
 // MARK: - Parent Reinforcement Logic
 
 private func checkParentReinforcementConditions() {
 if shouldShowReturnBanner && !showingReturnBanner {
 prefs.lastReturnBannerDate = Date()
 withAnimation { showingReturnBanner = true }
 } else if shouldShowConsistencyBanner && !showingConsistencyBanner {
 prefs.lastConsistencyBannerDate = Date()
 withAnimation { showingConsistencyBanner = true }
 }

 if shouldShowWeeklyParentRecap && !showingWeeklyParentRecap {
 withAnimation { showingWeeklyParentRecap = true }
 }
 }
 
 // MARK: - Feedback Prompt Logic
 
 private func checkFeedbackPromptEligibility() {
 // Check eligibility based on total moments logged
 let totalMoments = behaviorsStore.behaviorEvents.count
 feedbackManager.checkPromptEligibility(totalMomentsLogged: totalMoments)
 
 // Show prompt if eligible (with slight delay to not interrupt other UX)
 if feedbackManager.shouldShowPrompt {
 DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {  // L1 FIX: Increased delay
 // Only show if no other modals are open
 if !coachMarkManager.isShowingCoachMark && !showingWeeklyParentRecap && selectedChildForLogging == nil {
 showingFeedbackPrompt = true
 }
 }
 }
 }
 
 // MARK: - 2. Week Progress Strip - Enhanced with Streak System

 @State private var streakAnimating = false

 private var weekProgressStrip: some View {
 let activeDays = progressionStore.parentActivity.activeDaysThisWeek
 let streakColor = activeDays >= 5 ? themeProvider.streakHotColor : themeProvider.streakActiveColor
 let inactiveColor = themeProvider.streakInactiveColor

 return VStack(spacing: 0) {
 ElevatedCard(elevation: .medium, padding: AppSpacing.lg) {
 VStack(spacing: AppSpacing.md) {
 // Top row: Streak flame + message
 HStack(spacing: AppSpacing.md) {
 // Animated streak flame
 ZStack {
 // Glow effect
 Circle()
 .fill(
 RadialGradient(
 colors: [
 streakColor.opacity(themeProvider.isDarkMode ? 0.5 : 0.4),
 Color.clear
 ],
 center: .center,
 startRadius: 0,
 endRadius: 40
 )
 )
 .frame(width: 80, height: 80)
 .blur(radius: 8)
 .scaleEffect(streakAnimating ? 1.1 : 1.0)

 // Main circle
 Circle()
 .fill(
 LinearGradient(
 colors: activeDays >= 5
 ? [themeProvider.streakHotColor, themeProvider.challengeColor]
 : (activeDays >= 3 ? [themeProvider.streakActiveColor, themeProvider.positiveColor] : [inactiveColor, inactiveColor.opacity(0.8)]),
 startPoint: .topLeading,
 endPoint: .bottomTrailing
 )
 )
 .frame(width: 64, height: 64)
 .shadow(color: streakColor.opacity(themeProvider.isDarkMode ? 0.6 : 0.4), radius: 12, y: 4)

 // Flame or number
 VStack(spacing: 0) {
 if activeDays >= 3 {
 Image(systemName: "flame.fill")
 .font(.system(size: 24, weight: .bold))
 .foregroundColor(.white)
 .scaleEffect(streakAnimating ? 1.15 : 1.0)
 }
 Text("\(activeDays)")
 .font(.system(size: activeDays >= 3 ? 16 : 28, weight: .black, design: .rounded))
 .foregroundColor(activeDays >= 3 ? .white : themeProvider.primaryText)
 }
 }
 .coachMarkTarget(.streakBadge)

 VStack(alignment: .leading, spacing: AppSpacing.xs) {
 // Streak title (with minimumScaleFactor for long localized strings)
 HStack(spacing: 6) {
 Text(streakTitle(for: activeDays))
 .font(.system(size: 18, weight: .bold))
 .foregroundColor(themeProvider.primaryText)
 .minimumScaleFactor(0.7)
 .lineLimit(1)

 if activeDays >= 5 {
 Text("🔥")
 .font(.system(size: 16))
 }
 }

 Text(weekProgressMessage)
 .font(.system(size: 14))
 .foregroundColor(themeProvider.secondaryText)
 .fixedSize(horizontal: false, vertical: true)
 }

 Spacer()
 }

 // Day indicator pills (locale-aware weekday symbols)
 HStack(spacing: 6) {
 ForEach(0..<7, id: \.self) { day in
 let calendar = Calendar.current
 let weekdaySymbols = calendar.veryShortWeekdaySymbols
 // Adjust for locale's first weekday (Sunday = 1, Monday = 2, etc.)
 let adjustedIndex = (day + calendar.firstWeekday - 1) % 7
 let dayName = weekdaySymbols[adjustedIndex]
 let isActive = day < activeDays
 let isToday = day == Calendar.current.component(.weekday, from: Date()) - 1

 VStack(spacing: 4) {
 ZStack {
 Circle()
 .fill(
 isActive
 ? LinearGradient(colors: [themeProvider.streakActiveColor, themeProvider.positiveColor], startPoint: .top, endPoint: .bottom)
 : LinearGradient(colors: [inactiveColor], startPoint: .top, endPoint: .bottom)
 )
 .frame(width: 32, height: 32)

 if isActive {
 Image(systemName: "checkmark")
 .font(.system(size: 12, weight: .bold))
 .foregroundColor(.white)
 } else if isToday {
 Circle()
 .strokeBorder(themeProvider.streakActiveColor, lineWidth: 2)
 .frame(width: 32, height: 32)
 }
 }

 Text(dayName)
 .font(.system(size: 10, weight: .medium))
 .foregroundColor(isActive ? themeProvider.streakActiveColor : themeProvider.secondaryText)
 }
 }
 }

 // Today's progress mini-bar
 if hasMomentsToday {
 HStack(spacing: AppSpacing.sm) {
 Image(systemName: "sparkles")
 .font(.system(size: 12))
 .foregroundColor(themeProvider.starColor)

 let momentText = behaviorsStore.todayPositiveCount == 1 ? "moment" : "moments"
 Text("\(behaviorsStore.todayPositiveCount) positive \(momentText) logged today")
 .font(.system(size: 13, weight: .medium))
 .foregroundColor(themeProvider.primaryText)

 Spacer()

 Image(systemName: "checkmark.circle.fill")
 .font(.system(size: 14))
 .foregroundColor(themeProvider.positiveColor)
 }
 .padding(12)
 .background(
 RoundedRectangle(cornerRadius: 12)
 .fill(themeProvider.bannerPositiveBackground)
 )
 }
 }
 }
 }
 .onAppear {
 if activeDays >= 3 {
 withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
 streakAnimating = true
 }
 }
 }
 }

 private func streakTitle(for days: Int) -> String {
 // Calm, agency-forward messaging - celebrates consistency without pressure
 switch days {
 case 0: return "Your Week"
 case 1: return "1 Day This Week"
 case 2: return "2 Days Active"
 case 3: return "3 Days Active"
 case 4: return "4 Days Active"
 case 5: return "5 Days Active"
 case 6: return "6 Days Active"
 case 7: return "Full Week!"
 default: return "\(days) Days Active"
 }
 }

 // MARK: - 3.25 Goal Progress Mini-View

 @ViewBuilder
 private var goalProgressMiniView: some View {
     // Get the selected child or first active child
     let selectedChild: Child? = {
         if let selectedId = coordinator.selectedChildId,
            let child = childrenStore.activeChildren.first(where: { $0.id == selectedId }) {
             return child
         }
         return childrenStore.activeChildren.first
     }()

     if let child = selectedChild,
        let reward = rewardsStore.activeReward(forChild: child.id) {
         let progress = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
         let target = reward.targetPoints
         let progressPercent = min(Double(progress) / Double(target), 1.0)
         let isComplete = progress >= target

         Button(action: {
             coordinator.selectChild(child.id)
             coordinator.selectedTab = .rewards
         }) {
             HStack(spacing: 12) {
                 // Child avatar (small)
                 ChildAvatar(child: child, size: 36)

                 // Goal progress info
                 VStack(alignment: .leading, spacing: 4) {
                     HStack(spacing: 4) {
                         Text(child.name)
                             .font(.system(size: 13, weight: .semibold))
                             .foregroundColor(themeProvider.primaryText)
                         if isComplete {
                             Image(systemName: "party.popper.fill")
                                 .font(.system(size: 10))
                                 .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.1))
                         }
                     }

                     HStack(spacing: 4) {
                         Image(systemName: "flag.fill")
                             .font(.system(size: 10))
                             .foregroundColor(child.colorTag.color.opacity(0.7))
                         Text(isComplete ? "Goal Reached!" : reward.name)
                             .font(.system(size: 12))
                             .foregroundColor(isComplete ? Color(red: 0.85, green: 0.55, blue: 0.1) : themeProvider.secondaryText)
                             .lineLimit(1)
                     }
                 }

                 Spacer()

                 // Progress indicator
                 VStack(alignment: .trailing, spacing: 2) {
                     Text("\(progress)/\(target)")
                         .font(.system(size: 12, weight: .medium))
                         .foregroundColor(themeProvider.secondaryText)

                     // Mini progress bar
                     GeometryReader { geo in
                         ZStack(alignment: .leading) {
                             Capsule()
                                 .fill(Color(.systemGray5))
                                 .frame(height: 4)

                             Capsule()
                                 .fill(
                                     isComplete ?
                                     LinearGradient(colors: [Color(red: 0.95, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.85, blue: 0.4)], startPoint: .leading, endPoint: .trailing) :
                                     LinearGradient(colors: [child.colorTag.color, child.colorTag.color.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                 )
                                 .frame(width: geo.size.width * progressPercent, height: 4)
                         }
                     }
                     .frame(width: 60, height: 4)
                 }

                 Image(systemName: "chevron.right")
                     .font(.system(size: 12))
                     .foregroundColor(themeProvider.secondaryText)
             }
             .padding(12)
             .background(
                 RoundedRectangle(cornerRadius: 12)
                     .fill(themeProvider.cardBackground)
                     .shadow(color: themeProvider.cardShadow, radius: 4, y: 2)
             )
         }
         .buttonStyle(.plain)
     }
 }

 // MARK: - 3. Today's Focus Card (Merged)

 private var todayFocusCard: some View {
 let tips = [
 ("Try to catch one sharing moment today.", "Say \"I see you working hard on that.\""),
 ("Notice one moment of effort today.", "Tell them what you loved about how they tried."),
 ("Look for a chance to appreciate without commenting.", "Just watch and enjoy one moment."),
 ("When they struggle, try \"That looks hard\" first.", "See if they ask for help before offering."),
 ("Catch them being patient today.", "Notice kindness with a sibling or friend."),
 ("Look for a moment of curiosity or wonder.", "Celebrate their questions today."),
 ("Notice when they handle frustration.", "See how they manage a tough moment."),
 ("Watch for acts of kindness today.", "Notice when they think of others.")
 ]
 
 let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
 let (primaryFocus, tinyGoal) = tips[dayOfYear % tips.count]
 
 return ElevatedCard(elevation: .medium, padding: AppSpacing.lg) {
 HStack(spacing: AppSpacing.md) {
 // Glowing lightbulb icon
 ZStack {
 Circle()
 .fill(LinearGradient(
 colors: [themeProvider.starColor.opacity(themeProvider.isDarkMode ? 0.4 : 0.3), themeProvider.challengeColor.opacity(themeProvider.isDarkMode ? 0.3 : 0.2)],
 startPoint: .topLeading,
 endPoint: .bottomTrailing
 ))
 .frame(width: 64, height: 64)
 .shadow(color: themeProvider.starColor.opacity(themeProvider.isDarkMode ? 0.4 : 0.3), radius: 12)

 Image(systemName: "lightbulb.fill")
 .font(.system(size: 28))
 .foregroundColor(themeProvider.starColor)
 }

 VStack(alignment: .leading, spacing: AppSpacing.xs) {
 Text("Today's Focus")
 .font(AppTypography.title3)
 .foregroundColor(themeProvider.primaryText)
 .fontWeight(.bold)

 Text(primaryFocus)
 .font(AppTypography.bodyLarge)
 .foregroundColor(themeProvider.primaryText)
 .fixedSize(horizontal: false, vertical: true)

 Divider()
 .padding(.vertical, AppSpacing.xxs)

 HStack(spacing: AppSpacing.xxs) {
 Image(systemName: "target")
 .font(.caption)
 .foregroundColor(themeProvider.challengeColor)
 Text(tinyGoal)
 .font(AppTypography.bodySmall)
 .foregroundColor(themeProvider.secondaryText)
 .fixedSize(horizontal: false, vertical: true)
 }
 }

 Spacer()

 VStack {
 Button(action: {
 withAnimation(.spring(response: 0.3)) { dismissedFocusToday = true }
 }) {
 Image(systemName: "xmark.circle.fill")
 .font(.title3)
 .foregroundColor(themeProvider.secondaryText)
 }
 Spacer()
 }
 }
 }
 .coachMarkTarget(.dailyFocusCard)
 .background(
 LinearGradient(
 colors: [themeProvider.bannerFocusBackground, themeProvider.bannerChallengeBackground.opacity(0.5)],
 startPoint: .topLeading,
 endPoint: .bottomTrailing
 )
 .cornerRadius(20)
 )
 }
 
 // MARK: - 4. Today Summary Row (Tappable)
 
 private var todaySummaryRow: some View {
 Button(action: { navigateToHistory = true }) {
 HStack {
 Text("Today:")
 .font(.subheadline)
 .foregroundColor(themeProvider.secondaryText)

 HStack(spacing: 12) {
 if behaviorsStore.todayPositiveCount > 0 {
 HStack(spacing: 4) {
 Image(systemName: "hand.thumbsup.fill")
 .font(.caption)
 .foregroundColor(themeProvider.positiveColor)
 Text("\(behaviorsStore.todayPositiveCount) positive")
 .font(.subheadline)
 .foregroundColor(themeProvider.primaryText)
 }
 }

 if behaviorsStore.todayNegativeCount > 0 {
 HStack(spacing: 4) {
 Image(systemName: "exclamationmark.triangle.fill")
 .font(.caption)
 .foregroundColor(themeProvider.challengeColor)
 Text("\(behaviorsStore.todayNegativeCount) challenges")
 .font(.subheadline)
 .foregroundColor(themeProvider.primaryText)
 }
 }

 if behaviorsStore.todayPositiveCount == 0 && behaviorsStore.todayNegativeCount == 0 {
 Text("No moments yet")
 .font(.subheadline)
 .foregroundColor(themeProvider.secondaryText)
 }
 }

 Spacer()

 Image(systemName: "chevron.right")
 .font(.caption)
 .foregroundColor(themeProvider.secondaryText)
 }
 .padding(.horizontal, 12)
 .padding(.vertical, 10)
 .background(themeProvider.cardBackground)
 .cornerRadius(10)
 }
 .buttonStyle(.plain)
 }
 
 // MARK: - 5. Quick Add Section

 private var quickAddSection: some View {
 VStack(alignment: .leading, spacing: AppSpacing.sm) {
 Text("Quick Add")
 .font(AppTypography.title2)
 .foregroundColor(themeProvider.primaryText)
 .padding(.horizontal, 4)

 if childrenStore.activeChildren.isEmpty {
 noChildrenEmptyState
 } else {
 ForEach(Array(childrenStore.activeChildren.enumerated()), id: \.element.id) { index, child in
 ChildQuickLogCard(
 child: child,
 todayPoints: behaviorsStore.todayPoints(forChild: child.id),
 lastEvent: behaviorsStore.lastEvent(forChild: child.id),
 onLogTapped: {
 selectedChildForLogging = child
 },
 onRepeatLast: {
 handleRepeatLast(for: child)
 }
 )
 // Add coach mark target to first child card only
 .modifier(ConditionalCoachMarkTarget(target: .kidCard, condition: index == 0))
 }
 }
 }
 }
 
 private func handleRepeatLast(for child: Child) {
 if let lastEvent = behaviorsStore.lastEvent(forChild: child.id),
 let behaviorType = behaviorsStore.behaviorType(id: lastEvent.behaviorTypeId) {
 _ = lastEvent.rewardId ?? rewardsStore.activeReward(forChild: child.id)?.id
 logBehaviorUseCase.execute(
 childId: child.id,
 behaviorTypeId: lastEvent.behaviorTypeId,
 note: nil
 )
 
 let category: ToastCategory
 let verb: String
 switch behaviorType.category {
 case .routinePositive:
 category = .routine
 verb = "Added"
 case .positive:
 category = .positive
 verb = "Added"
 case .negative:
 category = .challenge
 verb = "Noted"
 }
 
 let pointsText = behaviorType.defaultPoints >= 0 ? "+\(behaviorType.defaultPoints)" : "\(behaviorType.defaultPoints)"
 toastMessage = "\(verb) \"\(behaviorType.name)\" (\(pointsText) stars)"
 toastCategory = category
 withAnimation {
 showingToast = true
 }
 }
 }
 
 // MARK: - 6. Parent Coaching Strip
 
 private var parentCoachingStrip: some View {
 VStack(spacing: 8) {
 // First 48 hours coaching (highest priority for new users)
 if showingFirst48Coaching, let msg = first48Message {
 coachingBanner(
 icon: "graduationcap.fill",
 iconColor: themeProvider.plusColor,
 title: msg.title,
 message: msg.message,
 backgroundColor: themeProvider.bannerSpecialBackground,
 onDismiss: { withAnimation { showingFirst48Coaching = false } }
 )
 }

 // Return after gap (highest priority)
 if showingReturnBanner && !showingFirst48Coaching {
 coachingBanner(
 icon: "heart.fill",
 iconColor: Color.pink,
 title: "You're back. That matters.",
 message: "Kids don't need perfect. They need you to come back and try again.",
 backgroundColor: themeProvider.bannerPinkBackground,
 onDismiss: { withAnimation { showingReturnBanner = false } }
 )
 }

 // Consistency banner
 if showingConsistencyBanner && !showingReturnBanner && !showingFirst48Coaching {
 let metrics = progressionStore.weeklyParentMetrics(
  children: childrenStore.children,
  behaviorEvents: behaviorsStore.behaviorEvents,
  behaviorTypes: behaviorsStore.behaviorTypes,
  rewards: rewardsStore.rewards
 )
 coachingBanner(
 icon: "star.fill",
 iconColor: themeProvider.routineColor,
 title: "You kept a small promise.",
 message: "You showed up here on \(metrics.daysActive) days this week. Kids remember that.",
 backgroundColor: themeProvider.bannerInfoBackground,
 onDismiss: { withAnimation { showingConsistencyBanner = false } }
 )
 }

 // Weekly parent recap
 if showingWeeklyParentRecap || shouldShowWeeklyParentRecap {
 weeklyParentRecapStrip
 }

 // First positive banner
 if showingFirstPositiveBanner {
 coachingBanner(
 icon: "sparkles",
 iconColor: themeProvider.challengeColor,
 title: "You turned a moment into a Tiny Win.",
 message: "Catching small good things is what changes the pattern.",
 backgroundColor: themeProvider.bannerChallengeBackground,
 onDismiss: { withAnimation { showingFirstPositiveBanner = false } }
 )
 }

 // Repair pattern cards per child
 ForEach(childrenStore.activeChildren) { child in
 if progressionStore.hasRepairPatternToday(forChild: child.id, behaviorEvents: behaviorsStore.behaviorEvents, behaviorTypes: behaviorsStore.behaviorTypes) && !dismissedRepairChildren.contains(child.id) {
 repairPatternStrip(for: child)
 }
 }
 }
 }
 
 private func coachingBanner(icon: String, iconColor: Color, title: String, message: String, backgroundColor: Color, onDismiss: @escaping () -> Void) -> some View {
 HStack(alignment: .top, spacing: 10) {
 Image(systemName: icon)
 .font(.subheadline)
 .foregroundColor(iconColor)

 VStack(alignment: .leading, spacing: 2) {
 Text(title)
 .font(.caption.weight(.semibold))
 .foregroundColor(themeProvider.primaryText)
 .fixedSize(horizontal: false, vertical: true)

 Text(message)
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 .fixedSize(horizontal: false, vertical: true)
 .multilineTextAlignment(.leading)
 }

 Spacer()

 Button(action: onDismiss) {
 Image(systemName: "xmark")
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 }
 }
 .padding(10)
 .background(backgroundColor)
 .cornerRadius(10)
 .transition(.move(edge: .top).combined(with: .opacity))
 }
 
 private var weeklyParentRecapStrip: some View {
 let metrics = progressionStore.weeklyParentMetrics(
  children: childrenStore.children,
  behaviorEvents: behaviorsStore.behaviorEvents,
  behaviorTypes: behaviorsStore.behaviorTypes,
  rewards: rewardsStore.rewards
 )

 return HStack(spacing: 10) {
 Image(systemName: "heart.text.square.fill")
 .font(.subheadline)
 .foregroundColor(themeProvider.positiveColor)

 VStack(alignment: .leading, spacing: 2) {
 Text("What you did well this week")
 .font(.caption.weight(.semibold))
 .foregroundColor(themeProvider.primaryText)

 HStack(spacing: 8) {
 if metrics.daysWithPositiveMoments > 0 {
 Text("\(metrics.daysWithPositiveMoments) days with positives")
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 }
 if metrics.uniqueGoalsWorkedOn > 0 {
 Text("· \(metrics.uniqueGoalsWorkedOn) goals")
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 }
 }
 }

 Spacer()

 Button(action: {
 prefs.lastWeeklyRecapDate = Date()
 withAnimation { showingWeeklyParentRecap = false }
 }) {
 Image(systemName: "xmark")
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 }
 }
 .padding(10)
 .background(themeProvider.bannerPositiveBackground.opacity(0.8))
 .cornerRadius(10)
 }

 private func repairPatternStrip(for child: Child) -> some View {
 HStack(spacing: 10) {
 Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
 .font(.subheadline)
 .foregroundColor(themeProvider.plusColor)

 VStack(alignment: .leading, spacing: 2) {
 Text("You did something powerful today.")
 .font(.caption.weight(.semibold))
 .foregroundColor(themeProvider.primaryText)

 Text("You named a hard moment and a win for \(child.name). That helps them learn.")
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 }

 Spacer()

 Button(action: {
 withAnimation {
 _ = dismissedRepairChildren.insert(child.id)
 }
 }) {
 Image(systemName: "xmark")
 .font(.caption2)
 .foregroundColor(themeProvider.secondaryText)
 }
 }
 .padding(10)
 .background(themeProvider.bannerSpecialBackground.opacity(0.8))
 .cornerRadius(10)
 }
 
 // MARK: - 7. Today's Activity Section

 private var todaysActivitySection: some View {
 VStack(alignment: .leading, spacing: AppSpacing.sm) {
 // Compact section header
 HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
 Text("Today's Activity")
 .font(.system(size: 17, weight: .bold))
 .foregroundColor(themeProvider.primaryText)

 Spacer()

 if !behaviorsStore.todayEvents.isEmpty {
 Text("\(behaviorsStore.todayEvents.count)")
 .font(.system(size: 15, weight: .bold, design: .rounded))
 .foregroundColor(themeProvider.accentColor)
 }
 }

 if behaviorsStore.todayEvents.isEmpty {
 emptyActivityState
 } else {
 // Compact activity list - no outer card wrapper
 VStack(alignment: .leading, spacing: 6) {
 // Grouped events by child
 groupedEventsList
 }
 }
 }
 }
 
 private var activitySummaryLine: some View {
 let childMoments = childrenStore.activeChildren.map { child in
 let count = behaviorsStore.todayEvents.filter { $0.childId == child.id }.count
 return (child: child, count: count)
 }.filter { $0.count > 0 }

 return HStack(spacing: 12) {
 ForEach(childMoments, id: \.child.id) { item in
 HStack(spacing: 4) {
 Circle()
 .fill(item.child.colorTag.color)
 .frame(width: 8, height: 8)
 Text("\(item.child.name) has \(item.count) moment\(item.count == 1 ? "" : "s")")
 .font(.caption)
 .foregroundColor(themeProvider.secondaryText)
 }
 }
 }
 .padding(.bottom, 4)
 }

 private var groupedEventsList: some View {
 let eventsGroupedByChild = Dictionary(grouping: behaviorsStore.todayEvents) { $0.childId }

 return VStack(spacing: 12) {
 ForEach(childrenStore.activeChildren) { child in
 if let childEvents = eventsGroupedByChild[child.id], !childEvents.isEmpty {
 VStack(alignment: .leading, spacing: 6) {
 // Child header - prominent and clear
 if childrenStore.activeChildren.count > 1 {
 HStack(spacing: 8) {
 // Child avatar (small)
 ChildAvatar(child: child, size: 24)

 Text(child.name)
 .font(.system(size: 15, weight: .semibold))
 .foregroundColor(themeProvider.primaryText)

 Spacer()

 // Event count badge
 Text("\(childEvents.count)")
 .font(.system(size: 12, weight: .bold, design: .rounded))
 .foregroundColor(child.colorTag.color)
 .padding(.horizontal, 8)
 .padding(.vertical, 2)
 .background(
 Capsule()
 .fill(child.colorTag.color.opacity(0.15))
 )
 }
 .padding(.vertical, 6)
 .padding(.horizontal, 4)
 }

 // Events for this child
 ForEach(childEvents.sorted { $0.timestamp > $1.timestamp }) { event in
 // Don't show child name in rows since we have section headers
 EventRow(event: event, showChildName: false)
 }
 }
 }
 }
 }
 }
 
 private var emptyActivityState: some View {
 VStack(spacing: 12) {
 StyledIcon(systemName: "sun.max.fill", color: themeProvider.secondaryText, size: 32, backgroundSize: 64, isCircle: true)

 Text("No moments yet today")
 .font(.subheadline)
 .foregroundColor(themeProvider.secondaryText)

 Text("You can always start with one small moment.")
 .font(.caption)
 .foregroundColor(themeProvider.secondaryText)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 32)
 .background(themeProvider.cardBackground)
 .cornerRadius(AppStyles.cardCornerRadius)
 .shadow(color: themeProvider.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
 }

 // MARK: - No Children Empty State

 private var noChildrenEmptyState: some View {
 VStack(spacing: 16) {
 Image(systemName: "figure.2.and.child.holdinghands")
 .font(.system(size: 48))
 .foregroundColor(themeProvider.secondaryText)

 Text("Add your child to begin")
 .font(.headline)
 .foregroundColor(themeProvider.primaryText)

 Text("Let's set up your first child so you can start noticing the good moments.")
 .font(.subheadline)
 .foregroundColor(themeProvider.secondaryText)
 .multilineTextAlignment(.center)
 .fixedSize(horizontal: false, vertical: true)
 .padding(.horizontal, 16)

 // Actionable CTA button that navigates to Kids tab and opens Add Child
 PrimaryButton(title: "Add your first child") {
     coordinator.selectTab(.kids)
     // Small delay to let tab transition complete
     DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
         coordinator.showAddChild()
     }
 }
 .padding(.top, AppSpacing.xxs)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 40)
 .padding(.horizontal, 16)
 .background(themeProvider.cardBackground)
 .cornerRadius(AppStyles.cardCornerRadius)
 }
 
}

// MARK: - Child Quick Log Card (Simplified)

struct ChildQuickLogCard: View {
 @EnvironmentObject private var childrenStore: ChildrenStore
 @EnvironmentObject private var behaviorsStore: BehaviorsStore
 @EnvironmentObject private var rewardsStore: RewardsStore
 @EnvironmentObject private var prefs: UserPreferencesStore
 @EnvironmentObject private var themeProvider: ThemeProvider

 let child: Child
 let todayPoints: Int
 let lastEvent: BehaviorEvent?
 let onLogTapped: () -> Void
 let onRepeatLast: () -> Void

 @State private var showingCreateGoal = false
 @State private var showingKidView = false
 @State private var showingEditGoal = false
 @State private var showingTooltip = false
 @State private var isPressed = false

 private var hasSeenGoalTooltip: Bool {
 prefs.hasSeenGoalTooltip(forChildId: child.id)
 }
 
 private var activeGoal: Reward? {
 rewardsStore.activeReward(forChild: child.id)
 }

 private var hasNoGoal: Bool {
 activeGoal == nil
 }

 private var goalProgress: Double {
 guard let goal = activeGoal else { return 0 }
 return goal.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
 }

 private var starsEarned: Int {
 guard let goal = activeGoal else { return 0 }
 return goal.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
 }

 private var lastPositiveMoment: BehaviorEvent? {
 behaviorsStore.behaviorEvents
 .filter { $0.childId == child.id && $0.pointsApplied > 0 }
 .sorted { $0.timestamp > $1.timestamp }
 .first
 }
 
 var body: some View {
 ElevatedCard(elevation: .medium, padding: AppSpacing.md) {
 VStack(spacing: AppSpacing.sm) {
 // Header row
 HStack(spacing: AppSpacing.sm) {
 ChildAvatar(child: child, size: 52)

 VStack(alignment: .leading, spacing: AppSpacing.xxs) {
 Text(child.name)
 .font(AppTypography.title3)
 .foregroundColor(themeProvider.primaryText)

 // Goal info or no goal prompt
 if let goal = activeGoal {
 Button(action: { showingKidView = true }) {
 HStack(spacing: 4) {
 Text("\(goal.name) · \(starsEarned) of \(goal.targetPoints) stars")
 .font(AppTypography.caption)
 .lineLimit(1)
 Image(systemName: "chevron.right")
 .font(.system(size: 9, weight: .semibold))
 .opacity(0.6)
 }
 .foregroundColor(themeProvider.secondaryText)
 }
 .buttonStyle(.plain)
 .contextMenu {
 Button(action: { showingKidView = true }) {
 Label("Show Progress", systemImage: "star.circle.fill")
 }
 Button(action: { showingEditGoal = true }) {
 Label("Edit Goal", systemImage: "pencil")
 }
 }
 } else {
 Button(action: {
 showingTooltip = false
 prefs.setHasSeenGoalTooltip(true, forChildId: child.id)
 showingCreateGoal = true
 }) {
 HStack(spacing: AppSpacing.xxs) {
 Image(systemName: "gift.fill")
 .font(AppTypography.caption)
 Text("Pick a goal together")
 .font(AppTypography.caption)
 .fontWeight(.medium)
 }
 .foregroundColor(themeProvider.plusColor)
 }
 }
 }

 Spacer()

 // Add button - always filled with child's color for consistency
 Button(action: onLogTapped) {
 HStack(spacing: AppSpacing.xxs) {
 Image(systemName: "plus.circle.fill")
 Text("Add")
 }
 .font(AppTypography.button)
 .padding(.horizontal, AppSpacing.sm)
 .padding(.vertical, AppSpacing.xs)
 .background(child.colorTag.color)
 .foregroundColor(.white)
 .cornerRadius(20)
 }
 }

 // Secondary stats line (simplified)
 HStack(spacing: AppSpacing.sm) {
 // Today's points + last activity combined
 let statsText = buildStatsText()
 Text(statsText)
 .font(AppTypography.bodySmall)
 .foregroundColor(themeProvider.secondaryText)

 Spacer()

 // Quick repeat
 if let lastEvent = lastEvent,
 let behaviorType = behaviorsStore.behaviorType(id: lastEvent.behaviorTypeId) {
 Button(action: onRepeatLast) {
 HStack(spacing: AppSpacing.xxs) {
 Image(systemName: "arrow.counterclockwise")
 .font(AppTypography.caption)
 Text(behaviorType.name)
 .font(AppTypography.caption)
 .lineLimit(1)
 }
 .foregroundColor(child.colorTag.color)
 }
 }
 }
 }
 }
 .scaleEffect(isPressed ? 0.97 : 1.0)
 .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
 .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
 isPressed = pressing
 if pressing {
 let generator = UIImpactFeedbackGenerator(style: .light)
 generator.impactOccurred()
 }
 }, perform: {})
 .sheet(isPresented: $showingCreateGoal) {
 AddRewardView(child: child)
 }
 .sheet(isPresented: $showingEditGoal) {
 if let goal = activeGoal {
 AddRewardView(child: child, editingReward: goal)
 }
 }
 .fullScreenCover(isPresented: $showingKidView) {
 KidView(child: child)
 }
 .onAppear {
 if hasNoGoal && !hasSeenGoalTooltip {
 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
 withAnimation {
 showingTooltip = true
 }
 }
 }
 }
 }
 
 private func buildStatsText() -> String {
 var parts: [String] = []
 
 // Today's points
 let pointsStr = todayPoints >= 0 ? "+\(todayPoints)" : "\(todayPoints)"
 parts.append("\(pointsStr) stars today")
 
 // Last moment time
 if let lastPos = lastPositiveMoment {
 parts.append("last moment \(timeAgoString(from: lastPos.timestamp))")
 }
 
 return parts.joined(separator: " · ")
 }
 
 private func timeAgoString(from date: Date) -> String {
 let now = Date()
 let interval = now.timeIntervalSince(date)
 
 if interval < 60 {
 return "just now"
 } else if interval < 3600 {
 let minutes = Int(interval / 60)
 return "\(minutes)m ago"
 } else if interval < 86400 {
 let hours = Int(interval / 3600)
 return "\(hours)h ago"
 } else {
 let days = Int(interval / 86400)
 return "\(days)d ago"
 }
 }
}


// MARK: - Event Row (Compact)

struct EventRow: View {
 @EnvironmentObject private var childrenStore: ChildrenStore
 @EnvironmentObject private var behaviorsStore: BehaviorsStore
 @EnvironmentObject private var themeProvider: ThemeProvider

 let event: BehaviorEvent
 var showChildName: Bool = false

 var body: some View {
 HStack(spacing: 10) {
     // Compact timeline dot
     Circle()
         .fill(event.isPositive ? themeProvider.positiveColor : themeProvider.challengeColor)
         .frame(width: 8, height: 8)

     // Compact icon
     ZStack {
         RoundedRectangle(cornerRadius: 8)
             .fill(
                 (event.isPositive ? themeProvider.positiveColor : themeProvider.challengeColor)
                     .opacity(0.12)
             )
             .frame(width: 32, height: 32)

         if let behaviorType = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
             Image(systemName: behaviorType.iconName)
                 .font(.system(size: 14, weight: .semibold))
                 .foregroundColor(event.isPositive ? themeProvider.positiveColor : themeProvider.challengeColor)
         }
     }

     // Behavior name and time only (child name removed - shown in section header)
     VStack(alignment: .leading, spacing: 2) {
         if let behaviorType = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
             Text(behaviorType.name)
                 .font(.system(size: 14, weight: .semibold))
                 .foregroundColor(themeProvider.primaryText)
                 .lineLimit(1)
         }

         Text(timeString)
             .font(.system(size: 11))
             .foregroundColor(themeProvider.secondaryText)
     }

     Spacer()

     // Compact points badge
     Text(pointsText)
         .font(.system(size: 16, weight: .bold, design: .rounded))
         .foregroundColor(event.isPositive ? themeProvider.positiveColor : themeProvider.challengeColor)
 }
 .padding(.vertical, 8)
 .padding(.horizontal, 10)
 .background(themeProvider.cardBackground.opacity(0.5))
 .cornerRadius(10)
 }

 private var timeString: String {
 DateFormatterCache.timeFormatter.string(from: event.timestamp)
 }

 private var pointsText: String {
 if event.pointsApplied >= 0 {
 return "+\(event.pointsApplied)"
 } else {
 return "\(event.pointsApplied)"
 }
 }
}

// MARK: - Child Picker Sheet

/// A simple sheet for selecting which child to log a behavior for
struct ChildPickerSheet: View {
    let children: [Child]
    let onChildSelected: (Child) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    var body: some View {
        NavigationStack {
            childListContent
                .background(themeProvider.backgroundColor)
                .navigationTitle("Add a Tiny Win")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }

    private var childListContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Who is this for?")
                    .font(AppTypography.title2)
                    .padding(.top, 8)

                ForEach(children) { child in
                    childRow(for: child)
                }
            }
            .padding()
        }
    }

    private func childRow(for child: Child) -> some View {
        Button {
            onChildSelected(child)
        } label: {
            HStack(spacing: 12) {
                ChildAvatar(child: child, size: 44)

                Text(child.name)
                    .font(AppTypography.title3)
                    .foregroundColor(themeProvider.resolved.primaryTextColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .cardStyle(elevation: .low, padding: 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
 let container = DependencyContainer()
 let coordinator = AppCoordinator()
    TodayView(logBehaviorUseCase: container.logBehaviorUseCase)
 .environmentObject(container.childrenStore)
 .environmentObject(container.behaviorsStore)
 .environmentObject(container.rewardsStore)
 .environmentObject(container.progressionStore)
 .environmentObject(container.userPreferences)
 .environmentObject(container.coachMarkManager)
 .environmentObject(container.feedbackManager)
 .environmentObject(container.repository)
 .environmentObject(container.themeProvider)
 .environmentObject(coordinator)
}
