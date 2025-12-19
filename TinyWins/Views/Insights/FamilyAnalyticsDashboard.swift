import SwiftUI

// MARK: - FamilyAnalyticsDashboard

/// Family-level aggregate analytics dashboard showing cross-child patterns.
/// Premium feature for Plus subscribers.
struct FamilyAnalyticsDashboard: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore

    @State private var selectedPeriod: TimePeriod = .thisWeek
    @State private var familyTotalMoments: Int = 0
    @State private var childSummaries: [ChildActivitySummary] = []
    @State private var familyPeakTimes: [FamilyPeakTime] = []
    @State private var familyInsight: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Selector
                periodSelector

                // Family Hero Card
                familyHeroCard

                // Per-Child Activity Summary
                if !childSummaries.isEmpty {
                    childActivitySection
                }

                // Attention Balance (logging distribution across kids)
                if childSummaries.count > 1 {
                    attentionBalanceSection
                }

                // Family Peak Times
                if !familyPeakTimes.isEmpty {
                    familyPeakTimesSection
                }

                // Individual Child Dashboard Links
                childDashboardLinksSection
            }
            .padding()
        }
        .background(theme.bg0.ignoresSafeArea())
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.familyAnalyticsRoot)
        .navigationTitle("Advanced Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadFamilyData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadFamilyData()
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([TimePeriod.thisWeek, .thisMonth, .last3Months], id: \.rawValue) { period in
                    Button {
                        withAnimation {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedPeriod == period ? .white : theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPeriod == period ?
                                          theme.accentPrimary : theme.accentMuted)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Family Hero Card

    private var familyHeroCard: some View {
        VStack(spacing: 16) {
            // Hero Icon
            Image(systemName: "house.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.success],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .background(theme.accentPrimary.opacity(0.1))
                .clipShape(Circle())

            // Stats
            VStack(spacing: 4) {
                Text("\(familyTotalMoments)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text("moments logged \(selectedPeriod.displayName.lowercased())")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)

                Text("across \(childrenStore.activeChildren.count) \(childrenStore.activeChildren.count == 1 ? "child" : "children")")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            // Insight Message
            if !familyInsight.isEmpty {
                Text(familyInsight)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    // MARK: - Child Activity Section

    private var childActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Each Child's Activity")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            VStack(spacing: 12) {
                ForEach(childSummaries) { summary in
                    childActivityRow(summary)
                }
            }
            .padding()
            .background(theme.surface1)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
        }
    }

    private func childActivityRow(_ summary: ChildActivitySummary) -> some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(summary.colorTag.color)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(summary.initials)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )

            // Name and Stats
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)

                Text("\(summary.totalMoments) moments")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            // Positive/Challenge breakdown as mini bar
            HStack(spacing: 4) {
                // Positive indicator
                HStack(spacing: 2) {
                    Circle()
                        .fill(theme.success)
                        .frame(width: 6, height: 6)
                    Text("\(summary.positiveMoments)")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                }

                // Challenge indicator
                HStack(spacing: 2) {
                    Circle()
                        .fill(theme.danger)
                        .frame(width: 6, height: 6)
                    Text("\(summary.challengeMoments)")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Attention Balance Section

    private var attentionBalanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Logging Attention")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Text("How moments are distributed across kids")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            // Attention bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(childSummaries) { summary in
                        let percentage = familyTotalMoments > 0 ? CGFloat(summary.totalMoments) / CGFloat(familyTotalMoments) : 0

                        Rectangle()
                            .fill(summary.colorTag.color)
                            .frame(width: geometry.size.width * percentage)
                    }
                }
            }
            .frame(height: 24)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.borderSoft, lineWidth: 1)
            )

            // Legend
            HStack(spacing: 16) {
                ForEach(childSummaries) { summary in
                    let percentage = familyTotalMoments > 0 ? Int((Double(summary.totalMoments) / Double(familyTotalMoments)) * 100) : 0

                    HStack(spacing: 4) {
                        Circle()
                            .fill(summary.colorTag.color)
                            .frame(width: 8, height: 8)

                        Text("\(summary.name) \(percentage)%")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    // MARK: - Family Peak Times Section

    private var familyPeakTimesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Family's Best Times")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Text("When positive moments happen most")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(familyPeakTimes.prefix(5)) { peak in
                        VStack(spacing: 8) {
                            Text(peak.dayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)

                            ZStack {
                                Circle()
                                    .fill(theme.success.opacity(peak.intensity))
                                    .frame(width: 50, height: 50)

                                Text(peak.timeString)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(peak.intensity > 0.5 ? .white : theme.textPrimary)
                            }

                            Text("\(peak.eventCount) wins")
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(theme.surface1)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
        }
    }

    // MARK: - Child Dashboard Links Section

    private var childDashboardLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("See Individual Patterns")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            VStack(spacing: 8) {
                ForEach(childrenStore.activeChildren) { child in
                    NavigationLink(destination: PremiumAnalyticsDashboard(child: child)) {
                        HStack(spacing: 12) {
                            // Avatar
                            Circle()
                                .fill(child.colorTag.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(child.initials)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                )

                            Text("\(child.name)'s Patterns")
                                .font(.subheadline)
                                .foregroundColor(theme.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding()
                        .background(theme.surface1)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadFamilyData() {
        isLoading = true

        let events = repository.appData.behaviorEvents
        let range = selectedPeriod.dateRange
        let children = childrenStore.activeChildren

        // Filter events for period
        let periodEvents = events.filter {
            $0.timestamp >= range.start && $0.timestamp <= range.end
        }

        // Calculate family total
        familyTotalMoments = periodEvents.count

        // Calculate per-child summaries
        childSummaries = children.map { child in
            let childEvents = periodEvents.filter { $0.childId == child.id }
            let positive = childEvents.filter { $0.pointsApplied > 0 }.count
            let challenge = childEvents.filter { $0.pointsApplied < 0 }.count

            return ChildActivitySummary(
                id: child.id,
                name: child.name,
                initials: child.initials,
                colorTag: child.colorTag,
                totalMoments: childEvents.count,
                positiveMoments: positive,
                challengeMoments: challenge
            )
        }

        // Calculate family peak times
        familyPeakTimes = calculateFamilyPeakTimes(events: periodEvents)

        // Generate family insight
        familyInsight = generateFamilyInsight()

        isLoading = false
    }

    private func calculateFamilyPeakTimes(events: [BehaviorEvent]) -> [FamilyPeakTime] {
        let positiveEvents = events.filter { $0.pointsApplied > 0 }

        // Group by day of week and hour
        var dayHourCounts: [Int: [Int: Int]] = [:]
        for event in positiveEvents {
            let weekday = Calendar.current.component(.weekday, from: event.timestamp)
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            dayHourCounts[weekday, default: [:]][hour, default: 0] += 1
        }

        // Find peak hour for each day
        var peaks: [FamilyPeakTime] = []
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for (weekday, hourCounts) in dayHourCounts.sorted(by: { $0.key < $1.key }) {
            if let (peakHour, count) = hourCounts.max(by: { $0.value < $1.value }), count > 0 {
                let maxCount = hourCounts.values.max() ?? 1
                let intensity = Double(count) / Double(max(maxCount, 1))

                peaks.append(FamilyPeakTime(
                    id: UUID(),
                    dayName: dayNames[weekday],
                    hour: peakHour,
                    eventCount: count,
                    intensity: min(intensity, 1.0)
                ))
            }
        }

        return peaks.sorted { $0.eventCount > $1.eventCount }
    }

    private func generateFamilyInsight() -> String {
        let totalChildren = childrenStore.activeChildren.count

        if familyTotalMoments == 0 {
            return "Start logging moments to see patterns across your family."
        }

        let avgPerChild = familyTotalMoments / max(totalChildren, 1)

        if avgPerChild >= 5 {
            return "You're capturing a healthy picture of your family's moments."
        } else if avgPerChild >= 2 {
            return "Keep logging to reveal more patterns over time."
        } else {
            return "A few more moments each day will help build a clearer picture."
        }
    }
}

// MARK: - Supporting Types

struct ChildActivitySummary: Identifiable {
    let id: UUID
    let name: String
    let initials: String
    let colorTag: ColorTag
    let totalMoments: Int
    let positiveMoments: Int
    let challengeMoments: Int
}

struct FamilyPeakTime: Identifiable {
    let id: UUID
    let dayName: String
    let hour: Int
    let eventCount: Int
    let intensity: Double

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    NavigationStack {
        FamilyAnalyticsDashboard()
    }
    .environmentObject(repository)
    .environmentObject(ChildrenStore(repository: repository))
    .withTheme(Theme())
}
