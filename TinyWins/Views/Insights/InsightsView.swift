import SwiftUI

// ============================================================================
// DEPRECATED: This file is no longer used in the main app navigation.
// The app now uses:
//   - FamilyInsightsView.swift for the bottom nav Insights tab
//   - ChildInsightsView.swift for per-child insights in ChildDetailView
//
// This file is kept temporarily for:
//   - SuggestionCard (used by ChildDetailView)
//   - InsightPeriod enum (used by analytics views)
//   - Various helper structs that may still be referenced
//
// TODO: Extract still-used components to shared files and remove this file.
// ============================================================================

// MARK: - Insight Types

enum InsightCardType: String, CaseIterable {
 case positivityBalance
 case biggestWin
 case toughestMoments
 case goalProgress
 case tooManyRules
 case sharingAttention
 case longTermProgress
 
 var priority: Int {
 switch self {
 case .positivityBalance: return 1
 case .biggestWin: return 2
 case .toughestMoments: return 3
 case .goalProgress: return 4
 case .tooManyRules: return 5
 case .sharingAttention: return 6
 case .longTermProgress: return 7
 }
 }
}

// MARK: - Insight Data Models (Legacy - renamed to avoid conflict with InsightCard.swift)

struct LegacyInsightCard: Identifiable {
 let id = UUID()
 let type: InsightCardType
 let title: String
 let line1: String
 let line2: String
 let visualData: LegacyInsightVisualData?
 var tapAction: (() -> Void)? = nil
}

enum LegacyInsightVisualData {
 case positivityBar(positive: Int, negative: Int)
 case behaviorIcon(iconName: String, color: Color)
 case timeOfDayBars(morning: Int, afternoon: Int, evening: Int)
 case progressBar(progress: Double, color: Color)
 case avatars(children: [(Child, Int)])
 case beforeAfter(before: Double, after: Double)
 case bulletList(items: [String])
}

// MARK: - Time Period

enum InsightPeriod: String, CaseIterable {
 case thisWeek = "This Week"
 case lastWeek = "Last Week"
 case last30Days = "30 Days"
 case last90Days = "90 Days"
 case last6Months = "6 Months"
 
 var label: String {
 switch self {
 case .thisWeek: return "week"
 case .lastWeek: return "week"
 case .last30Days: return "month"
 case .last90Days: return "quarter"
 case .last6Months: return "6 months"
 }
 }

 var shortLabel: String {
 switch self {
 case .thisWeek: return "Week"
 case .lastWeek: return "Last Week"
 case .last30Days: return "Month"
 case .last90Days: return "90 Days"
 case .last6Months: return "6 Months"
 }
 }
 
 var dateRange: (start: Date, end: Date) {
 let calendar = Calendar.current
 let now = Date()
 
 switch self {
 case .thisWeek:
 let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
 return (startOfWeek, now)
 case .lastWeek:
 let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
 let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
 return (startOfLastWeek, startOfThisWeek)
 case .last30Days:
 let start = calendar.date(byAdding: .day, value: -30, to: now)!
 return (start, now)
 case .last90Days:
 let start = calendar.date(byAdding: .day, value: -90, to: now)!
 return (start, now)
 case .last6Months:
 let start = calendar.date(byAdding: .month, value: -6, to: now)!
 return (start, now)
 }
 }
 
 /// Whether this period requires Plus subscription
 var isPremium: Bool {
 switch self {
 case .thisWeek, .lastWeek:
 return false
 case .last30Days, .last90Days, .last6Months:
 return true
 }
 }
 
 /// Free periods only
 static var freePeriods: [InsightPeriod] {
 [.thisWeek, .lastWeek]
 }
 
 /// Premium-only periods
 static var premiumPeriods: [InsightPeriod] {
 [.last30Days, .last90Days, .last6Months]
 }
}

// MARK: - Main Insights View

struct InsightsView: View {
 @EnvironmentObject private var childrenStore: ChildrenStore
 @EnvironmentObject private var behaviorsStore: BehaviorsStore
 @EnvironmentObject private var rewardsStore: RewardsStore
 @EnvironmentObject private var insightsStore: InsightsStore
 @EnvironmentObject private var progressionStore: ProgressionStore
 @EnvironmentObject private var subscriptionManager: SubscriptionManager
 @Environment(\.theme) private var theme
 @State private var selectedChild: Child?
 @State private var selectedPeriod: InsightPeriod = .thisWeek
 @State private var showingPaywall = false

 // Optional: When set, shows insights only for this child (no child selector)
 var focusedChild: Child? = nil

 // Auto-select if only one child, or use focused child
 private var effectiveSelectedChild: Child? {
 if let focused = focusedChild {
 return focused
 }
 if childrenStore.children.count == 1 {
 return childrenStore.children.first
 }
 return selectedChild
 }

 // Whether to show comparative family insights
 private var showFamilyInsights: Bool {
 focusedChild == nil && selectedChild == nil && childrenStore.children.count > 1
 }
 
 private var isPlusSubscriber: Bool {
 subscriptionManager.effectiveIsPlusSubscriber
 }
 
 var body: some View {
 Group {
 if focusedChild != nil {
 // Embedded in ChildDetailView - no NavigationStack needed
 insightsContent
 } else {
 // Standalone view - needs NavigationStack
 NavigationStack {
 insightsContent
 .navigationTitle("Insights")
 }
 }
 }
 .sheet(isPresented: $showingPaywall) {
 PlusPaywallView(context: .extendedHistory)
 }
 }
 
 private var insightsContent: some View {
 ScrollView {
 VStack(spacing: 20) {
 // Child Selector - hide if only one child OR if focused on specific child
 if childrenStore.children.count > 1 && focusedChild == nil {
 childSelector
 }
 
 // Time Range Chips
 timeRangeChips
 
 // Insight Cards
 if let child = effectiveSelectedChild {
 childInsightsSection(for: child)
 } else {
 allKidsInsightsSection
 }
 
 // Parent Coach Level (subtle, at bottom) - only show in main insights view
 if focusedChild == nil {
 parentCoachLevelSection
 }
 }
 .padding()
.tabBarBottomPadding()
 }
 .background(theme.bg0)
 }
 
 // MARK: - Parent Coach Level (Deprecated)

 private var parentCoachLevelSection: some View {
 EmptyView()
 }

 // MARK: - Child Selector
 
 private var childSelector: some View {
 ScrollView(.horizontal, showsIndicators: false) {
 HStack(spacing: 12) {
 ChildFilterChip(
 title:"All Kids",
 isSelected: selectedChild == nil
 ) {
 withAnimation { selectedChild = nil }
 }

 ForEach(childrenStore.children) { child in
 ChildFilterChip(
 title: child.name,
 color: child.colorTag.color,
 isSelected: selectedChild?.id == child.id
 ) {
 withAnimation { selectedChild = child }
 }
 }
 }
 .padding(.horizontal, 16)
 }
 }
 
 // MARK: - Time Range Chips
 
 private var timeRangeChips: some View {
 ScrollView(.horizontal, showsIndicators: false) {
 HStack(spacing: 8) {
 ForEach(InsightPeriod.allCases, id: \.self) { period in
 let isLocked = period.isPremium && !isPlusSubscriber
 
 Button(action: {
 if isLocked {
 showingPaywall = true
 } else {
 withAnimation { selectedPeriod = period }
 }
 }) {
 HStack(spacing: 4) {
 Text(period.rawValue)
 .font(.subheadline)
 .fontWeight(selectedPeriod == period ? .semibold : .regular)
 
 if isLocked {
 Image(systemName:"lock.fill")
 .font(.caption2)
 }
 }
 .padding(.horizontal, 14)
 .padding(.vertical, 8)
 .background(
 selectedPeriod == period ? AppColors.primary :
 isLocked ? Color.purple.opacity(0.15) : theme.accentMuted
 )
 .foregroundColor(
 selectedPeriod == period ? .white :
 isLocked ? .purple : theme.textPrimary
 )
 .cornerRadius(20)
 }
 }
 }
 .padding(.horizontal, 16)
 }
 }

 // MARK: - Child Insights Section
 
 private func childInsightsSection(for child: Child) -> some View {
 let cards = generateInsightCards(for: child, period: selectedPeriod)

 return VStack(spacing: 16) {
 if cards.isEmpty {
 emptyInsightsState(childName: child.name)
 } else {
 ForEach(cards) { card in
 LegacyInsightCardView(card: card)
 }
 }
 }
 }
 
 // MARK: - All Kids Insights Section
 
 private var allKidsInsightsSection: some View {
 let cards = generateAllKidsInsightCards(period: selectedPeriod)
 
 return VStack(spacing: 16) {
 // Show clickable child cards
 ForEach(childrenStore.children) { child in
 ChildInsightSummaryCard(
 child: child,
 period: selectedPeriod,
 onTap: { selectedChild = child }
 )
 }
 
 // Show sharing attention card if applicable
 ForEach(cards) { card in
 LegacyInsightCardView(card: card)
 }
 }
 }
 
 // MARK: - Empty State
 
 private func emptyInsightsState(childName: String) -> some View {
 VStack(spacing: 16) {
 StyledIcon(systemName:"sparkles", color: theme.textSecondary, size: 32, backgroundSize: 64, isCircle: true)

 Text("Insights will appear here")
 .font(.headline)

 Text("As you log moments, you will start to see patterns: what is working, what is improving, and how far you have come together.")
 .font(.subheadline)
 .foregroundColor(theme.textSecondary)
 .multilineTextAlignment(.center)
 .fixedSize(horizontal: false, vertical: true)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 40)
 .padding(.horizontal)
 .background(theme.surface1)
 .cornerRadius(AppStyles.cardCornerRadius)
 }
 
 // MARK: - Card Generation
 
 private func generateInsightCards(for child: Child, period: InsightPeriod) -> [LegacyInsightCard] {
 var availableCards: [LegacyInsightCard] = []
 let range = period.dateRange
 
 let events = behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id &&
 $0.timestamp >= range.start &&
 $0.timestamp <= range.end
 }
 
 let positiveEvents = events.filter { $0.pointsApplied > 0 }
 let challengeEvents = events.filter { $0.pointsApplied < 0 }
 
 // 1) Positivity Balance
 if let card = generatePositivityCard(
 childName: child.name,
 positiveCount: positiveEvents.count,
 challengeCount: challengeEvents.count,
 periodLabel: period.label
 ) {
 availableCards.append(card)
 }
 
 // 2) Biggest Win
 if let card = generateBiggestWinCard(
 childName: child.name,
 positiveEvents: positiveEvents,
 periodLabel: period.label
 ) {
 availableCards.append(card)
 }
 
 // 3) Toughest Moments
 if let card = generateToughestMomentsCard(
 childName: child.name,
 challengeEvents: challengeEvents,
 periodLabel: period.label
 ) {
 availableCards.append(card)
 }
 
 // 4) Goal Progress
 if let card = generateGoalProgressCard(for: child) {
 availableCards.append(card)
 }
 
 // 5) Too Many Rules
 if let card = generateTooManyRulesCard(for: child) {
 availableCards.append(card)
 }
 
 // 7) Long Term Progress
 if let card = generateLongTermProgressCard(for: child) {
 availableCards.append(card)
 }
 
 // Sort by priority and take top 3
 return Array(availableCards.sorted { $0.type.priority < $1.type.priority }.prefix(3))
 }
 
 private func generateAllKidsInsightCards(period: InsightPeriod) -> [LegacyInsightCard] {
 var cards: [LegacyInsightCard] = []
 
 // 6) Sharing Star Attention (only for multi-child families)
 if let card = generateSharingAttentionCard(period: period) {
 cards.append(card)
 }
 
 return cards
 }
 
 // MARK: - Individual Card Generators
 
 private func generatePositivityCard(childName: String, positiveCount: Int, challengeCount: Int, periodLabel: String) -> LegacyInsightCard? {
 guard positiveCount + challengeCount >= 3 else { return nil }
 
 let line2: String
 if positiveCount >= 2 * max(1, challengeCount) {
 line2 = "Most of what you are recording is positive. Keep noticing those small wins."
 } else {
 line2 = "You are noticing more challenges than positives right now. That awareness is valuable. Try catching one extra positive moment tomorrow."
 }
 
 // Add target guidance
 let targetLine = " Many parents find a 3-to-1 ratio of positives to challenges works well."
 
 return LegacyInsightCard(
 type: .positivityBalance,
 title:"Positivity balance",
 line1:"This \(periodLabel) you logged \(positiveCount) positive moment\(positiveCount == 1 ? "" : "s") and \(challengeCount) challenge\(challengeCount == 1 ? "" : "s") for \(childName).",
 line2:"\(line2)\n\n\(targetLine)",
 visualData: .positivityBar(positive: positiveCount, negative: challengeCount)
 )
 }
 
 private func generateBiggestWinCard(childName: String, positiveEvents: [BehaviorEvent], periodLabel: String) -> LegacyInsightCard? {
 var behaviorCounts: [UUID: Int] = [:]
 for event in positiveEvents {
 behaviorCounts[event.behaviorTypeId, default: 0] += 1
 }
 
 guard let topBehaviorId = behaviorCounts.max(by: { $0.value < $1.value })?.key,
 let topBehavior = behaviorsStore.behaviorType(id: topBehaviorId),
 let count = behaviorCounts[topBehaviorId],
 count >= 3 else { return nil }
 
 return LegacyInsightCard(
 type: .biggestWin,
 title:"Biggest win this \(periodLabel)",
 line1:"Top strength for \(childName): \"\(topBehavior.name)\" (\(count) times).",
 line2:"This is a strength worth celebrating out loud, not just with stars.",
 visualData: .behaviorIcon(iconName: topBehavior.iconName, color: AppColors.positive)
 )
 }
 
 private func generateToughestMomentsCard(childName: String, challengeEvents: [BehaviorEvent], periodLabel: String) -> LegacyInsightCard? {
 guard !challengeEvents.isEmpty else { return nil }
 
 var behaviorCounts: [UUID: Int] = [:]
 var timeOfDayCounts: [String: Int] = ["Morning": 0,"Afternoon": 0,"Evening": 0]
 
 for event in challengeEvents {
 behaviorCounts[event.behaviorTypeId, default: 0] += 1
 
 let hour = Calendar.current.component(.hour, from: event.timestamp)
 if hour < 12 {
 timeOfDayCounts["Morning", default: 0] += 1
 } else if hour < 17 {
 timeOfDayCounts["Afternoon", default: 0] += 1
 } else {
 timeOfDayCounts["Evening", default: 0] += 1
 }
 }
 
 guard let topBehaviorId = behaviorCounts.max(by: { $0.value < $1.value })?.key,
 let topBehavior = behaviorsStore.behaviorType(id: topBehaviorId),
 let count = behaviorCounts[topBehaviorId] else { return nil }
 
 // Find dominant time of day
 let sortedTimes = timeOfDayCounts.sorted { $0.value > $1.value }
 let topTime = sortedTimes.first
 let secondTime = sortedTimes.dropFirst().first
 
 let line2: String
 if let top = topTime, let second = secondTime, top.value > second.value + 1 {
 line2 = "This tends to happen in the \(top.key.lowercased()). A calmer transition or heads-up before that time might help."
 } else {
 line2 = "Notice when this tends to happen, then try adjusting the routine around those times."
 }
 
 return LegacyInsightCard(
 type: .toughestMoments,
 title:"Toughest moments",
 line1:"The hardest behavior this \(periodLabel) was \"\(topBehavior.name)\" (\(count) time\(count == 1 ? "" : "s")).",
 line2: line2,
 visualData: .timeOfDayBars(
 morning: timeOfDayCounts["Morning"] ?? 0,
 afternoon: timeOfDayCounts["Afternoon"] ?? 0,
 evening: timeOfDayCounts["Evening"] ?? 0
 )
 )
 }
 
 private func generateGoalProgressCard(for child: Child) -> LegacyInsightCard? {
 guard let reward = rewardsStore.activeReward(forChild: child.id) else { return nil }
 
 let earned = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
 let target = reward.targetPoints
 let daysLeft = reward.daysRemaining ?? 30
 
 // Calculate average stars per day over last 7 days
 let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
 let recentEvents = behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id &&
 $0.timestamp >= sevenDaysAgo &&
 $0.pointsApplied > 0
 }
 let recentPoints = recentEvents.reduce(0) { $0 + $1.pointsApplied }
 let avgPerDay = max(1, Double(recentPoints) / 7.0)
 
 let remaining = target - earned
 let projectedDays = Int(ceil(Double(remaining) / avgPerDay))
 
 let isOnTrack = projectedDays <= daysLeft + 1
 
 let line1: String
 let line2: String
 
 if isOnTrack {
 line1 = "\(child.name) is on track to reach \"\(reward.name)\"."
 line2 = "At this pace, you will likely reach the goal in about \(projectedDays) day\(projectedDays == 1 ? "" : "s")."
 } else {
 line1 = "This goal might need more time to feel achievable."
 line2 = "You can adjust the stars needed or extend the deadline. Goals should feel motivating, not stressful."
 }
 
 return LegacyInsightCard(
 type: .goalProgress,
 title:"Goal progress",
 line1: line1,
 line2: line2,
 visualData: .progressBar(progress: reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: true), color: .purple)
 )
 }
 
 private func generateTooManyRulesCard(for child: Child) -> LegacyInsightCard? {
 let allBehaviors = behaviorsStore.behaviorTypes
 let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
 
 let recentEvents = behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id && $0.timestamp >= thirtyDaysAgo
 }
 
 let usedBehaviorIds = Set(recentEvents.map { $0.behaviorTypeId })
 let unusedBehaviors = allBehaviors.filter { !usedBehaviorIds.contains($0.id) && $0.isActive }
 
 guard unusedBehaviors.count > 2 else { return nil }
 
 let behaviorNames = unusedBehaviors.prefix(3).map { $0.name }
 let listText = behaviorNames.joined(separator: ", ")
 
 return LegacyInsightCard(
 type: .tooManyRules,
 title: "Unused behaviors",
 line1: "These behaviors have not been logged in the past month: \(listText).",
 line2: "Consider removing ones that no longer fit, so the list stays manageable.",
 visualData: .bulletList(items: Array(behaviorNames))
 )
 }
 
 private func generateSharingAttentionCard(period: InsightPeriod) -> LegacyInsightCard? {
 guard childrenStore.children.count >= 2 else { return nil }
 
 let range = period.dateRange
 var childPositiveCounts: [(Child, Int)] = []
 var totalPositive = 0
 
 for child in childrenStore.children {
 let count = behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id &&
 $0.timestamp >= range.start &&
 $0.timestamp <= range.end &&
 $0.pointsApplied > 0
 }.count
 childPositiveCounts.append((child, count))
 totalPositive += count
 }
 
 guard totalPositive > 0 else { return nil }
 
 let sorted = childPositiveCounts.sorted { $0.1 > $1.1 }
 guard let dominant = sorted.first,
 let other = sorted.dropFirst().first else { return nil }
 
 let dominantShare = Double(dominant.1) / Double(totalPositive)
 
 guard dominantShare > 0.6 && other.1 < dominant.1 / 2 else { return nil }
 
 return LegacyInsightCard(
 type: .sharingAttention,
 title:"Sharing star attention",
 line1:"Most stars this \(period.label) went to \(dominant.0.name).",
 line2:"That is perfectly fine. You might also look for small chances to notice positive moments for \(other.0.name).",
 visualData: .avatars(children: childPositiveCounts)
 )
 }
 
 private func generateLongTermProgressCard(for child: Child) -> LegacyInsightCard? {
 let eightWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -8, to: Date())!
 let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date())!
 
 let oldEvents = behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id &&
 $0.timestamp >= eightWeeksAgo &&
 $0.timestamp < fourWeeksAgo &&
 $0.pointsApplied > 0
 }
 
 let newEvents = behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id &&
 $0.timestamp >= fourWeeksAgo &&
 $0.pointsApplied > 0
 }
 
 // Need at least some data in both periods
 guard oldEvents.count >= 5 && newEvents.count >= 5 else { return nil }
 
 let oldAvg = Double(oldEvents.count) / 4.0
 let newAvg = Double(newEvents.count) / 4.0
 
 return LegacyInsightCard(
 type: .longTermProgress,
 title:"Long-term progress",
 line1:"Since you started using Tiny Wins, weekly positive moments went from about \(Int(round(oldAvg))) to about \(Int(round(newAvg))).",
 line2:"You and \(child.name) are building new habits together. Keep going at your own pace.",
 visualData: .beforeAfter(before: oldAvg, after: newAvg)
 )
 }
}

// MARK: - Child Filter Chip

struct ChildFilterChip: View {
 @Environment(\.theme) private var theme
 let title: String
 var color: Color = .primary
 let isSelected: Bool
 let action: () -> Void

 var body: some View {
 Button(action: action) {
 HStack(spacing: 6) {
 if color != .primary && isSelected {
 Circle()
 .fill(color)
 .frame(width: 8, height: 8)
 }
 Text(title)
 .font(.subheadline)
 .fontWeight(isSelected ? .semibold : .regular)
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 8)
 .background(isSelected ? color.opacity(0.15) : theme.accentMuted)
 .foregroundColor(isSelected ? color : theme.textPrimary)
 .cornerRadius(20)
 }
 }
}

// MARK: - Legacy Insight Card View

struct LegacyInsightCardView: View {
 @Environment(\.theme) private var theme
 let card: LegacyInsightCard

 // Cards that require Plus subscription
 private var isPlusFeature: Bool {
 card.type == .toughestMoments || card.type == .sharingAttention
 }
 
 var body: some View {
 Button(action: { card.tapAction?() }) {
 VStack(alignment: .leading, spacing: 12) {
 // Title with Plus badge if applicable
 HStack {
 Text(card.title)
 .font(.headline)
 .foregroundColor(titleColor)
 .fixedSize(horizontal: false, vertical: true)
 
 if isPlusFeature {
 PlusBadge()
 }
 
 Spacer()
 }
 
 // Visual (if present)
 if let visualData = card.visualData {
 insightVisual(visualData)
 }
 
 // Line 1 - Data sentence
 Text(card.line1)
 .font(.subheadline)
 .foregroundColor(theme.textPrimary)
 .fixedSize(horizontal: false, vertical: true)
 .multilineTextAlignment(.leading)

 // Line 2 - Suggestion
 Text(card.line2)
 .font(.subheadline)
 .foregroundColor(theme.textSecondary)
 .fixedSize(horizontal: false, vertical: true)
 .multilineTextAlignment(.leading)
 }
 .frame(maxWidth: .infinity, alignment: .leading)
 .padding()
 .background(theme.surface1)
 .cornerRadius(AppStyles.cardCornerRadius)
 .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
 }
 .buttonStyle(.plain)
 }

 private var titleColor: Color {
 switch card.type {
 case .positivityBalance: return AppColors.primary
 case .biggestWin: return AppColors.positive
 case .toughestMoments: return AppColors.challenge
 case .goalProgress: return .purple
 case .tooManyRules: return .orange
 case .sharingAttention: return AppColors.primary
 case .longTermProgress: return AppColors.positive
 }
 }
 
 @ViewBuilder
 private func insightVisual(_ data: LegacyInsightVisualData) -> some View {
 switch data {
 case .positivityBar(let positive, let negative):
 positivityBarView(positive: positive, negative: negative)
 
 case .behaviorIcon(let iconName, let color):
 HStack {
 StyledIcon(systemName: iconName, color: color, size: 20, backgroundSize: 44, isCircle: true)
 Spacer()
 }
 
 case .timeOfDayBars(let morning, let afternoon, let evening):
 timeOfDayBarsView(morning: morning, afternoon: afternoon, evening: evening)
 
 case .progressBar(let progress, let color):
 progressBarView(progress: progress, color: color)
 
 case .avatars(let children):
 avatarsView(children: children)
 
 case .beforeAfter(let before, let after):
 beforeAfterView(before: before, after: after)
 
 case .bulletList(let items):
 bulletListView(items: items)
 }
 }
 
 private func positivityBarView(positive: Int, negative: Int) -> some View {
 let total = max(1, positive + negative)
 let positiveRatio = CGFloat(positive) / CGFloat(total)
 
 return GeometryReader { geometry in
 HStack(spacing: 2) {
 RoundedRectangle(cornerRadius: 4)
 .fill(AppColors.positive)
 .frame(width: geometry.size.width * positiveRatio)
 
 RoundedRectangle(cornerRadius: 4)
 .fill(AppColors.challenge)
 .frame(width: geometry.size.width * (1 - positiveRatio))
 }
 }
 .frame(height: 12)
 }
 
 private func timeOfDayBarsView(morning: Int, afternoon: Int, evening: Int) -> some View {
 let maxVal = max(1, max(morning, max(afternoon, evening)))
 
 return HStack(spacing: 8) {
 ForEach([("AM", morning), ("PM", afternoon), ("Eve", evening)], id: \.0) { label, value in
 VStack(spacing: 4) {
 ZStack(alignment: .bottom) {
 RoundedRectangle(cornerRadius: 2)
 .fill(theme.accentMuted)
 .frame(width: 24, height: 40)

 RoundedRectangle(cornerRadius: 2)
 .fill(AppColors.challenge)
 .frame(width: 24, height: CGFloat(value) / CGFloat(maxVal) * 40)
 }
 Text(label)
 .font(.caption2)
 .foregroundColor(theme.textSecondary)
 }
 }
 Spacer()
 }
 }
 
 private func progressBarView(progress: Double, color: Color) -> some View {
 GeometryReader { geometry in
 ZStack(alignment: .leading) {
 RoundedRectangle(cornerRadius: 6)
 .fill(theme.accentMuted)

 RoundedRectangle(cornerRadius: 6)
 .fill(color)
 .frame(width: geometry.size.width * progress)
 }
 }
 .frame(height: 12)
 }
 
 private func avatarsView(children: [(Child, Int)]) -> some View {
 HStack(spacing: 16) {
 ForEach(children, id: \.0.id) { child, count in
 VStack(spacing: 4) {
 ChildAvatar(child: child, size: 32)
 Text("\(count)")
 .font(.caption)
 .fontWeight(.semibold)
 .foregroundColor(child.colorTag.color)
 }
 }
 Spacer()
 }
 }
 
 private func beforeAfterView(before: Double, after: Double) -> some View {
 let maxVal = max(before, after, 1)

 return HStack(spacing: 16) {
 VStack(spacing: 4) {
 ZStack(alignment: .bottom) {
 RoundedRectangle(cornerRadius: 4)
 .fill(theme.accentMuted)
 .frame(width: 40, height: 50)

 RoundedRectangle(cornerRadius: 4)
 .fill(theme.textSecondary)
 .frame(width: 40, height: CGFloat(before / maxVal) * 50)
 }
 Text("Before")
 .font(.caption2)
 .foregroundColor(theme.textSecondary)
 }

 VStack(spacing: 4) {
 ZStack(alignment: .bottom) {
 RoundedRectangle(cornerRadius: 4)
 .fill(theme.accentMuted)
 .frame(width: 40, height: 50)

 RoundedRectangle(cornerRadius: 4)
 .fill(AppColors.positive)
 .frame(width: 40, height: CGFloat(after / maxVal) * 50)
 }
 Text("Now")
 .font(.caption2)
 .foregroundColor(theme.textSecondary)
 }

 Spacer()
 }
 }
 
 private func bulletListView(items: [String]) -> some View {
 VStack(alignment: .leading, spacing: 4) {
 ForEach(items, id: \.self) { item in
 HStack(spacing: 8) {
 Circle()
 .fill(AppColors.challenge)
 .frame(width: 6, height: 6)
 Text(item)
 .font(.caption)
 .foregroundColor(theme.textSecondary)
 }
 }
 }
 }
}

// MARK: - Child Insight Summary Card (for All Kids view)

struct ChildInsightSummaryCard: View {
 @EnvironmentObject private var behaviorsStore: BehaviorsStore
 @Environment(\.theme) private var theme
 let child: Child
 let period: InsightPeriod
 let onTap: () -> Void

 private var periodEvents: [BehaviorEvent] {
 let range = period.dateRange
 return behaviorsStore.behaviorEvents.filter {
 $0.childId == child.id &&
 $0.timestamp >= range.start &&
 $0.timestamp <= range.end
 }
 }
 
 var body: some View {
 Button(action: onTap) {
 HStack(spacing: 16) {
 ChildAvatar(child: child, size: 50)
 
 VStack(alignment: .leading, spacing: 4) {
 Text(child.name)
 .font(.headline)
 .foregroundColor(theme.textPrimary)

 let positive = periodEvents.filter { $0.pointsApplied > 0 }.count
 let challenges = periodEvents.filter { $0.pointsApplied < 0 }.count
 
 HStack(spacing: 12) {
 Label("\(positive)", systemImage:"hand.thumbsup.fill")
 .font(.caption)
 .foregroundColor(AppColors.positive)
 
 Label("\(challenges)", systemImage:"exclamationmark.triangle.fill")
 .font(.caption)
 .foregroundColor(AppColors.challenge)
 }
 }
 
 Spacer()

 Image(systemName:"chevron.right")
 .font(.subheadline)
 .foregroundColor(theme.textSecondary)
 }
 .padding()
 .background(theme.surface1)
 .cornerRadius(AppStyles.cardCornerRadius)
 .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
 }
 .buttonStyle(.plain)
 }
}

// MARK: - Suggestion Card (used in ChildDetailView)

struct SuggestionCard: View {
 @Environment(\.theme) private var theme
 let suggestion: ImprovementSuggestion
 var buttonLabel: String? = nil  // Custom button label, nil uses default
 var isDisabled: Bool = false    // Show as already tracked
 var onAction: (() -> Void)? = nil
 
 var body: some View {
 VStack(alignment: .leading, spacing: 12) {
 HStack(alignment: .top, spacing: 12) {
 Image(systemName: suggestion.type.iconName)
 .font(.title2)
 .foregroundColor(suggestionColor)
 .frame(width: 32)
 
 VStack(alignment: .leading, spacing: 4) {
 Text(suggestion.type.title)
 .font(.subheadline)
 .fontWeight(.semibold)
 .foregroundColor(suggestionColor)
 .fixedSize(horizontal: false, vertical: true)
 
 Text(suggestion.message)
 .font(.subheadline)
 .foregroundColor(theme.textSecondary)
 .fixedSize(horizontal: false, vertical: true)
 .multilineTextAlignment(.leading)
 }

 Spacer()
 }
 
 // Action button (only for actionable suggestion types)
 if suggestion.type == .tryNew || suggestion.type == .increaseRoutine {
 if isDisabled {
 // Already tracking - show as a non-interactive badge
 HStack {
 Image(systemName: "checkmark.circle.fill")
 Text("Already tracking")
 }
 .font(.subheadline)
 .fontWeight(.medium)
 .frame(maxWidth: .infinity)
 .padding(.vertical, 8)
 .background(theme.accentMuted)
 .foregroundColor(theme.textSecondary)
 .cornerRadius(8)
 } else {
 Button(action: { onAction?() }) {
 HStack {
 Image(systemName: "plus.circle.fill")
 Text(resolvedButtonLabel)
 }
 .font(.subheadline)
 .fontWeight(.medium)
 .frame(maxWidth: .infinity)
 .padding(.vertical, 8)
 .background(suggestionColor)
 .foregroundColor(.white)
 .cornerRadius(8)
 }
 }
 }
 }
 .padding()
 .background(suggestionColor.opacity(0.1))
 .cornerRadius(AppStyles.cardCornerRadius)
 }
 
 /// Resolved button label - uses custom label if provided, otherwise defaults based on type
 private var resolvedButtonLabel: String {
 if let customLabel = buttonLabel {
 return customLabel
 }
 return suggestion.type == .increaseRoutine ? "Start tracking this" : "Add as routine"
 }
 
 private var suggestionColor: Color {
 switch suggestion.type {
 case .reduceNegative: return AppColors.challenge
 case .increaseRoutine: return AppColors.routine
 case .tryNew: return AppColors.positive
 }
 }
}

// MARK: - Yearly Summary Card

struct YearlySummaryCard: View {
 @Environment(\.theme) private var theme
 let summary: YearlySummary
 let childName: String
 let color: Color
 
 var body: some View {
 VStack(alignment: .leading, spacing: 16) {
 // Header
 HStack {
 Image(systemName:"calendar.badge.checkmark")
 .font(.title2)
 .foregroundColor(color)
 
 VStack(alignment: .leading, spacing: 2) {
 HStack(spacing: 6) {
 Text("\(String(summary.year)) Year in Review")
 .font(.headline)
 PlusBadge()
 }
 Text(childName)
 .font(.subheadline)
 .foregroundColor(theme.textSecondary)
 }

 Spacer()
 }
 
 // Stats Row
 HStack(spacing: 20) {
 StatBubble(value:"\(summary.totalPositiveMoments)", label:"Moments", icon:"star.fill", color: theme.star)
 StatBubble(value:"\(summary.goalsCompleted)", label:"Goals", icon:"gift.fill", color: .purple)
 if summary.specialMomentsCount > 0 {
 StatBubble(value:"\(summary.specialMomentsCount)", label:"Special", icon:"heart.fill", color: .pink)
 }
 }
 
 // Top Strengths
 if !summary.topStrengths.isEmpty {
 VStack(alignment: .leading, spacing: 8) {
 Text("Top Strengths")
 .font(.subheadline)
 .fontWeight(.semibold)
 
 HStack(spacing: 8) {
 ForEach(summary.topStrengths, id: \.self) { strength in
 Text(strength)
 .font(.caption)
 .padding(.horizontal, 10)
 .padding(.vertical, 6)
 .background(color.opacity(0.15))
 .foregroundColor(color)
 .cornerRadius(12)
 }
 }
 }
 }
 
 // Narrative Summary
 Text(summary.summaryText)
 .font(.subheadline)
 .foregroundColor(theme.textSecondary)
 .fixedSize(horizontal: false, vertical: true)
 }
 .padding()
 .background(theme.surface1)
 .cornerRadius(AppStyles.cardCornerRadius)
 .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
 }
}

struct StatBubble: View {
 @Environment(\.theme) private var theme
 let value: String
 let label: String
 let icon: String
 let color: Color

 var body: some View {
 VStack(spacing: 4) {
 HStack(spacing: 4) {
 Image(systemName: icon)
 .font(.caption)
 .foregroundColor(color)
 Text(value)
 .font(.title3.bold())
 }
 Text(label)
 .font(.caption2)
 .foregroundColor(theme.textSecondary)
 }
 }
}

// MARK: - Special Moments Timeline

struct SpecialMomentsTimeline: View {
 @Environment(\.theme) private var theme
 let moments: [SpecialMoment]

 var body: some View {
 VStack(alignment: .leading, spacing: 12) {
 HStack {
 Image(systemName:"heart.text.square.fill")
 .foregroundColor(.pink)
 Text("Special Moments")
 .font(.headline)

 Spacer()

 Text("\(moments.count)")
 .font(.caption)
 .foregroundColor(theme.textSecondary)
 }

 // Timeline scroll
 ScrollView(.horizontal, showsIndicators: false) {
 HStack(spacing: 16) {
 ForEach(moments.prefix(10)) { moment in
 SpecialMomentCard(moment: moment)
 }
 }
 }
 }
 .padding()
 .background(theme.surface1)
 .cornerRadius(AppStyles.cardCornerRadius)
 }
}

struct SpecialMomentCard: View {
 @EnvironmentObject private var behaviorsStore: BehaviorsStore
 @Environment(\.theme) private var theme
 let moment: SpecialMoment

 private var event: BehaviorEvent? {
 behaviorsStore.behaviorEvents.first { $0.id == moment.eventId }
 }

 private var behavior: BehaviorType? {
 guard let event = event else { return nil }
 return behaviorsStore.behaviorType(id: event.behaviorTypeId)
 }

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 // Date
 Text(formatDate(moment.markedDate))
 .font(.caption2)
 .foregroundColor(theme.textSecondary)

 // Icon or thumbnail
 if let event = event, !event.mediaAttachments.isEmpty {
 // Show thumbnail if available
 RoundedRectangle(cornerRadius: 8)
 .fill(theme.accentMuted)
 .frame(width: 80, height: 60)
 .overlay(
 Image(systemName:"photo.fill")
 .foregroundColor(theme.textSecondary)
 )
 } else if let behavior = behavior {
 ZStack {
 RoundedRectangle(cornerRadius: 8)
 .fill(behavior.defaultPoints > 0 ? theme.success.opacity(0.2) : theme.danger.opacity(0.2))
 .frame(width: 80, height: 60)

 Image(systemName: behavior.iconName)
 .font(.title2)
 .foregroundColor(behavior.defaultPoints > 0 ? theme.success : theme.danger)
 }
 }
 
 // Caption or behavior name
 if let caption = moment.caption, !caption.isEmpty {
 Text(caption)
 .font(.caption)
 .lineLimit(2)
 .frame(width: 80, alignment: .leading)
 } else if let behavior = behavior {
 Text(behavior.name)
 .font(.caption)
 .lineLimit(2)
 .frame(width: 80, alignment: .leading)
 }
 }
 }
 
 private func formatDate(_ date: Date) -> String {
 let formatter = DateFormatter()
 formatter.dateFormat = "MMM d"
 return formatter.string(from: date)
 }
}

// MARK: - Preview

#Preview {
 let repository = Repository.preview
    InsightsView()
 .environmentObject(ChildrenStore(repository: repository))
 .environmentObject(BehaviorsStore(repository: repository))
 .environmentObject(RewardsStore(repository: repository))
 .environmentObject(InsightsStore(repository: repository))
 .environmentObject(ProgressionStore())
}
