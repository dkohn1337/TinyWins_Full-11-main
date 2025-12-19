import SwiftUI

// MARK: - Cached Formatters (performance optimization)
private enum HistoryDateFormatterCache {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - History View with Enhanced Filtering

struct HistoryView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var coordinator: AppCoordinator

    // Filter state with explicit structure
    @State private var selectedPeriod: TimePeriod = .thisWeek
    @State private var selectedChildId: UUID? = nil
    @State private var hasInitializedFromCoordinator = false
    @State private var selectedTypeFilter: HistoryTypeFilter = .positiveOnly
    
    // Sheet presentation
    @State private var selectedBehaviorEvent: BehaviorEvent?
    @State private var selectedRewardEvent: RewardHistoryEvent?
    @State private var showingFilterSheet = false
    
    // Computed filtered items
    private var filteredItems: [HistoryItem] {
        let range = selectedPeriod.dateRange
        let events = behaviorsStore.behaviorEvents
        let rewards = rewardsStore.rewardHistoryEvents

        var items: [HistoryItem] = []

        switch selectedTypeFilter {
        case .allMoments:
            let behaviorItems = events
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                    return matchesTime && matchesChild
                }
                .map { HistoryItem.behavior($0) }

            let rewardItems = rewards
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                    return matchesTime && matchesChild
                }
                .map { HistoryItem.reward($0) }

            items = behaviorItems + rewardItems

        case .positiveOnly:
            items = events
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                    return matchesTime && matchesChild && event.pointsApplied > 0
                }
                .map { HistoryItem.behavior($0) }

        case .challengesOnly:
            items = events
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                    return matchesTime && matchesChild && event.pointsApplied < 0
                }
                .map { HistoryItem.behavior($0) }

        case .goalsOnly:
            items = rewards
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                    return matchesTime && matchesChild
                }
                .map { HistoryItem.reward($0) }
        }

        return items.sorted { $0.timestamp > $1.timestamp }
    }

    // Summary counts for current filter
    private var positiveCount: Int {
        let range = selectedPeriod.dateRange
        return behaviorsStore.behaviorEvents
            .filter { event in
                let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                return matchesTime && matchesChild && event.pointsApplied > 0
            }
            .count
    }

    private var challengeCount: Int {
        let range = selectedPeriod.dateRange
        return behaviorsStore.behaviorEvents
            .filter { event in
                let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                return matchesTime && matchesChild && event.pointsApplied < 0
            }
            .count
    }

    private var netStars: Int {
        let range = selectedPeriod.dateRange
        return behaviorsStore.behaviorEvents
            .filter { event in
                let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                let matchesChild = selectedChildId == nil || event.childId == selectedChildId
                return matchesTime && matchesChild
            }
            .reduce(0) { $0 + $1.pointsApplied }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact Filter Bar - dropdowns in a single row
                compactFilterBar

                // Summary Bar with counts
                summaryBar

                // Guidance text
                guidanceText

                // Timeline or List based on data
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    timelineView
                }
            }
            .background(theme.bg1)
            .navigationTitle("History")
            .sheet(item: $selectedBehaviorEvent) { event in
                EventDetailSheet(event: event)
            }
            .sheet(item: $selectedRewardEvent) { event in
                RewardEventDetailSheet(event: event)
            }
            .onAppear {
                // Initialize filter from coordinator's shared selection (once)
                if !hasInitializedFromCoordinator {
                    hasInitializedFromCoordinator = true
                    if let coordinatorChildId = coordinator.selectedChildId {
                        selectedChildId = coordinatorChildId
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Section (3 Rows)
    
    private var filterSection: some View {
        VStack(spacing: 10) {
            // Row 1: Time chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([TimePeriod.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .allTime], id: \.self) { period in
                        FilterChip(
                            label: period.displayName,
                            isSelected: selectedPeriod == period,
                            color: AppColors.primary
                        ) {
                            withAnimation { selectedPeriod = period }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Row 2: Who chips (children)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All Kids",
                        isSelected: selectedChildId == nil,
                        color: AppColors.primary
                    ) {
                        withAnimation { selectedChildId = nil }
                    }
                    
                    ForEach(childrenStore.children) { child in
                        FilterChip(
                            label: child.name,
                            isSelected: selectedChildId == child.id,
                            color: child.colorTag.color
                        ) {
                            withAnimation { selectedChildId = child.id }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Row 3: What chips (type filter)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HistoryTypeFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            label: filter.rawValue,
                            isSelected: selectedTypeFilter == filter,
                            color: typeFilterColor(for: filter),
                            icon: filter.icon
                        ) {
                            withAnimation { selectedTypeFilter = filter }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(theme.surface1)
    }

    private func typeFilterColor(for filter: HistoryTypeFilter) -> Color {
        switch filter {
        case .allMoments: return .gray
        case .positiveOnly: return AppColors.positive
        case .challengesOnly: return AppColors.challenge
        case .goalsOnly: return AppColors.primary
        }
    }

    // MARK: - Compact Filter Bar

    private var compactFilterBar: some View {
        HStack(spacing: 10) {
            // Time Period Dropdown
            Menu {
                ForEach([TimePeriod.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .allTime], id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPeriod = period }
                    } label: {
                        if selectedPeriod == period {
                            Label(period.displayName, systemImage: "checkmark")
                        } else {
                            Text(period.displayName)
                        }
                    }
                }
            } label: {
                FilterDropdownLabel(text: selectedPeriod.shortDisplayName)
            }

            // Child Dropdown
            Menu {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedChildId = nil }
                } label: {
                    if selectedChildId == nil {
                        Label("All Kids", systemImage: "checkmark")
                    } else {
                        Text("All Kids")
                    }
                }

                ForEach(childrenStore.children) { child in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedChildId = child.id }
                    } label: {
                        if selectedChildId == child.id {
                            Label(child.name, systemImage: "checkmark")
                        } else {
                            Text(child.name)
                        }
                    }
                }
            } label: {
                FilterDropdownLabel(
                    text: selectedChildId.flatMap { id in
                        childrenStore.child(id: id)?.name
                    } ?? "All Kids",
                    accentColor: selectedChildAccentColor
                )
            }

            // Type Dropdown
            Menu {
                ForEach(HistoryTypeFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTypeFilter = filter }
                    } label: {
                        if selectedTypeFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            } label: {
                FilterDropdownLabel(
                    text: selectedTypeFilter.rawValue,
                    accentColor: typeFilterAccentColor
                )
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(theme.bg1)
    }

    /// Accent color for selected child (uses child's color tag)
    private var selectedChildAccentColor: Color? {
        guard let id = selectedChildId,
              let child = childrenStore.child(id: id) else { return nil }
        return child.colorTag.color
    }

    /// Accent color for type filter (subtle hint of filter type)
    private var typeFilterAccentColor: Color? {
        switch selectedTypeFilter {
        case .allMoments: return nil
        case .positiveOnly: return AppColors.positive
        case .challengesOnly: return AppColors.challenge
        case .goalsOnly: return AppColors.primary
        }
    }

    // MARK: - Filter Summary Line (unused)
    
    private var filterSummaryLine: some View {
        Button(action: { showingFilterSheet = true }) {
            HStack(spacing: 6) {
                Text("Showing:")
                    .foregroundColor(theme.textSecondary)

                Text(filterSummaryText)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .font(.caption)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(theme.surface2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Filter: \(filterSummaryText)")
        .accessibilityHint("Double tap to change filters")
    }
    
    private var filterSummaryText: String {
        let timePart = selectedPeriod.displayName
        let whoPart = selectedChildId.flatMap { id in
            childrenStore.child(id: id)?.name
        } ?? "All kids"
        let whatPart = selectedTypeFilter.rawValue

        return "\(timePart) · \(whoPart) · \(whatPart)"
    }
    
    // MARK: - Summary Bar
    
    private var summaryBar: some View {
        HStack(spacing: 0) {
            SummaryPill(
                icon: "hand.thumbsup.fill",
                value: "\(positiveCount)",
                label: "Positive",
                color: AppColors.positive
            )
            
            Divider()
                .frame(height: 30)
            
            SummaryPill(
                icon: "exclamationmark.triangle.fill",
                value: "\(challengeCount)",
                label: "Challenges",
                color: AppColors.challenge
            )
            
            Divider()
                .frame(height: 30)
            
            SummaryPill(
                icon: "star.fill",
                value: netStars >= 0 ? "+\(netStars)" : "\(netStars)",
                label: "Net Stars",
                color: netStars >= 0 ? AppColors.positive : .red
            )
        }
        .padding(.vertical, 12)
        .background(theme.surface1)
    }

    // MARK: - Guidance Text
    
    private var guidanceText: some View {
        Group {
            if positiveCount > 0 || challengeCount > 0 {
                Text(guidanceMessage)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var guidanceMessage: String {
        if positiveCount >= challengeCount {
            return "You're noticing more positives than challenges this period. Keep catching the good moments."
        } else {
            return "Challenges are showing up more than positives this period. Try to catch a few easy wins tomorrow."
        }
    }
    
    // MARK: - Timeline View
    
    private var timelineView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(groupedByDay.keys.sorted().reversed(), id: \.self) { date in
                    UnifiedDayRow(
                        date: date,
                        items: groupedByDay[date] ?? [],
                        onBehaviorTapped: { event in
                            selectedBehaviorEvent = event
                        },
                        onRewardTapped: { event in
                            selectedRewardEvent = event
                        }
                    )
                }
            }
            .tabBarBottomPadding()
        }
    }

    private var groupedByDay: [Date: [HistoryItem]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredItems) { item in
            calendar.startOfDay(for: item.timestamp)
        }
    }
    
    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 16) {
                StyledIcon(systemName: "clock.badge.checkmark", color: theme.textSecondary, size: 32, backgroundSize: 64, isCircle: true)

                if behaviorsStore.behaviorEvents.isEmpty && rewardsStore.rewardHistoryEvents.isEmpty {
                    Text("Your timeline will grow here")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Every moment you log becomes part of your family's story.")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                } else {
                    Text("Nothing matches this filter")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Try widening your filters to see more moments.")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    Button(action: {
                        withAnimation {
                            selectedPeriod = .allTime
                            selectedTypeFilter = .allMoments
                            selectedChildId = nil
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Show everything")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .padding(.top, 16)
            .tabBarBottomPadding()
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    HistoryView()
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(RewardsStore(repository: repository))
        .environmentObject(ProgressionStore())
}
