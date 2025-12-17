import SwiftUI

/// Per-child insights view displayed within ChildDetailView
/// Shows "This week with [Child]", "Biggest Win", "Area to Work On" cards
/// Plus-gated Advanced section at the bottom (links to PremiumAnalyticsDashboard)
struct ChildInsightsView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var insightsStore: InsightsStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingPaywall = false

    let child: Child
    
    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }
    
    // Get events for this week
    private var thisWeekRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return (startOfWeek, now)
    }
    
    private var thisWeekEvents: [BehaviorEvent] {
        let range = thisWeekRange
        return behaviorsStore.behaviorEvents.filter {
            $0.childId == child.id &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }
    }
    
    private var positiveEvents: [BehaviorEvent] {
        thisWeekEvents.filter { $0.pointsApplied > 0 }
    }
    
    private var challengeEvents: [BehaviorEvent] {
        thisWeekEvents.filter { $0.pointsApplied < 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header: "This week with [Child]"
                thisWeekHeader
                
                // Biggest Win card
                biggestWinCard
                
                // Area to Work On card
                areaToWorkOnCard
                
                // Goal Progress card (if has active goal)
                if rewardsStore.activeReward(forChild: child.id) != nil {
                    goalProgressCard
                }
                
                // Plus-gated Advanced section (canonical entry point)
                advancedSection
                
            }
            .padding()
            .tabBarBottomPadding()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingPaywall) {
            PlusPaywallView(context: .advancedInsights)
        }
    }
    
    // MARK: - This Week Header
    
    private var thisWeekHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(child.colorTag.color)
                Text("This Week with \(child.name)")
                    .font(.headline)
                Spacer()
            }
            
            // Quick stats row
            HStack(spacing: 0) {
                WeekStatBox(
                    value: "\(positiveEvents.count)",
                    label: "Positive",
                    color: AppColors.positive
                )
                
                Divider()
                    .frame(height: 40)
                
                WeekStatBox(
                    value: "\(challengeEvents.count)",
                    label: "Challenges",
                    color: AppColors.negative
                )
                
                Divider()
                    .frame(height: 40)
                
                let netStars = thisWeekEvents.reduce(0) { $0 + $1.pointsApplied }
                WeekStatBox(
                    value: netStars >= 0 ? "+\(netStars)" : "\(netStars)",
                    label: "Net Stars",
                    color: netStars >= 0 ? .blue : .orange
                )
            }
            
            // Encouragement message
            Text(weekSummaryMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
    }
    
    private var weekSummaryMessage: String {
        let positive = positiveEvents.count
        let negative = challengeEvents.count
        let total = positive + negative
        
        if total == 0 {
            return "No moments logged this week yet. Start noticing the small wins!"
        } else if positive == 0 && negative > 0 {
            return "It's been a tough week. Try to catch some positive moments too."
        } else if negative == 0 && positive > 0 {
            return "All positive this week! Keep celebrating those wins."
        } else if positive >= negative * 3 {
            return "Great week! You're noticing lots of positive moments."
        } else if positive >= negative {
            return "Good balance. Keep catching those small wins!"
        } else {
            return "More challenges than positives this week. Tomorrow is a fresh start."
        }
    }
    
    // MARK: - Biggest Win Card
    
    private var biggestWinCard: some View {
        // Find the most frequent positive behavior
        var behaviorCounts: [UUID: Int] = [:]
        for event in positiveEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }

        let topBehavior = behaviorCounts.max(by: { $0.value < $1.value })
        let topBehaviorType = topBehavior.flatMap { behaviorsStore.behaviorType(id: $0.key) }
        let topCount = topBehavior?.value ?? 0
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Biggest Win")
                    .font(.headline)
                Spacer()
            }
            
            if let behavior = topBehaviorType, topCount >= 2 {
                HStack(spacing: 16) {
                    // Behavior icon
                    ZStack {
                        Circle()
                            .fill(AppColors.positive.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: behavior.iconName)
                            .font(.title2)
                            .foregroundColor(AppColors.positive)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(behavior.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("\(topCount) times this week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text("This is \(child.name)'s top strength this week. Keep praising it out loud, not just with stars!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if positiveEvents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Log some positive moments to see \(child.name)'s biggest win this week.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.positive)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(positiveEvents.count) positive moment\(positiveEvents.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Keep logging to see patterns emerge!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
    }
    
    // MARK: - Area to Work On Card
    
    private var areaToWorkOnCard: some View {
        // Find the most frequent challenge behavior
        var behaviorCounts: [UUID: Int] = [:]
        var timeOfDay: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0]
        
        for event in challengeEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
            
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            if hour < 12 {
                timeOfDay["Morning", default: 0] += 1
            } else if hour < 17 {
                timeOfDay["Afternoon", default: 0] += 1
            } else {
                timeOfDay["Evening", default: 0] += 1
            }
        }

        let topBehavior = behaviorCounts.max(by: { $0.value < $1.value })
        let topBehaviorType = topBehavior.flatMap { behaviorsStore.behaviorType(id: $0.key) }
        let topCount = topBehavior?.value ?? 0
        let topTime = timeOfDay.max(by: { $0.value < $1.value })
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("Area to Work On")
                    .font(.headline)
                Spacer()
            }
            
            if let behavior = topBehaviorType, topCount >= 2 {
                HStack(spacing: 16) {
                    // Behavior icon
                    ZStack {
                        Circle()
                            .fill(AppColors.negative.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: behavior.iconName)
                            .font(.title2)
                            .foregroundColor(AppColors.negative)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(behavior.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("\(topCount) times this week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Timing insight
                if let (time, count) = topTime, count >= 2 {
                    Text("This tends to happen in the \(time.lowercased()). A small routine adjustment around that time might help.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Notice when this happens. Understanding the pattern is the first step to shifting it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if challengeEvents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("No challenges logged this week. Great job!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(challengeEvents.count) challenge\(challengeEvents.count == 1 ? "" : "s") this week")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Keep logging. Patterns will emerge over time.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
    }
    
    // MARK: - Goal Progress Card
    
    private var goalProgressCard: some View {
        guard let reward = rewardsStore.activeReward(forChild: child.id) else {
            return AnyView(EmptyView())
        }

        let status = reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
        let progress = min(Double(reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)) / Double(reward.targetPoints), 1.0)
        let starsNeeded = max(0, reward.targetPoints - reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true))

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(child.colorTag.color)
                    Text("Goal Progress")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    // Reward icon
                    ZStack {
                        Circle()
                            .fill(child.colorTag.color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: reward.imageName ?? "gift.fill")
                            .font(.title2)
                            .foregroundColor(child.colorTag.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        // Progress bar - always use child color for identity
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray4))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(child.colorTag.color)
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 8)

                        if status == .readyToRedeem {
                            Text("Goal reached!")
                                .font(.caption)
                                .foregroundColor(child.colorTag.color)
                        } else {
                            Text("\(starsNeeded) more star\(starsNeeded == 1 ? "" : "s") to go")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(AppStyles.cardCornerRadius)
        )
    }
    
    // MARK: - Advanced Insights Section (Plus-gated, canonical entry point)

    @ViewBuilder
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.purple)
                Text("Advanced Insights")
                    .font(.headline)

                Spacer()

                Text("Plus")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(isPlusSubscriber ? 1.0 : 0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }

            Text("Patterns and progress over time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if isPlusSubscriber {
                // Plus subscriber: NavigationLink to Advanced Insights
                NavigationLink(destination: PremiumAnalyticsDashboard(child: child)) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Advanced Insights")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityLabel("Advanced Insights for \(child.name)")
                .accessibilityHint("Opens deeper patterns and trends")
            } else {
                // Free user: show paywall
                Button(action: { showingPaywall = true }) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.purple.opacity(0.7))
                        Text("Advanced Insights")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.purple.opacity(0.5))
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple.opacity(0.7))
                    .cornerRadius(8)
                }
                .accessibilityLabel("Locked. Advanced Insights")
                .accessibilityHint("Requires TinyWins Plus")
            }

            // Value examples (calm, no laundry list)
            Text("Includes Growth Rings, Activity Patterns, and week-over-week trends.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
    }
}

// MARK: - Supporting Views

private struct WeekStatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    return NavigationStack {
        ChildInsightsView(child: Child(
            name: "Emma",
            colorTag: .purple
        ))
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(RewardsStore(repository: repository))
        .environmentObject(InsightsStore(repository: repository))
    }
}
