import SwiftUI

// MARK: - Win Category (File-Private)

/// Win categories with expanded options for parent reflections
fileprivate enum WinCategory: String, CaseIterable {
    case emotional = "Emotional Regulation"
    case communication = "Communication"
    case connection = "Connection"
    case selfCare = "Self-Care"
    case growth = "Growth Mindset"

    var icon: String {
        switch self {
        case .emotional: return "brain.head.profile"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .connection: return "heart.fill"
        case .selfCare: return "leaf.fill"
        case .growth: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .emotional: return .blue
        case .communication: return .purple
        case .connection: return .pink
        case .selfCare: return .green
        case .growth: return .orange
        }
    }

    var wins: [String] {
        switch self {
        case .emotional:
            return [
                "I stayed calm during a difficult moment",
                "I took a breather when I needed one",
                "I was patient when things were hard",
                "I managed my frustration well"
            ]
        case .communication:
            return [
                "I listened without interrupting",
                "I used a calm voice",
                "I asked questions instead of assuming",
                "I explained rather than just said no"
            ]
        case .connection:
            return [
                "I gave a genuine hug today",
                "I had quality one-on-one time",
                "I played together without distractions",
                "I said 'I love you' today"
            ]
        case .selfCare:
            return [
                "I took a moment for myself",
                "I asked for help when I needed it",
                "I didn't compare myself to others",
                "I forgave myself for a mistake"
            ]
        case .growth:
            return [
                "I praised effort instead of just results",
                "I apologized when I was wrong",
                "I celebrated a small win",
                "I tried something new with my child"
            ]
        }
    }
}

/// Daily check-in view for parent support and reflection
struct DailyCheckInView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var selectedWins: Set<String> = []
    @State private var customNote: String = ""
    @State private var showingSuccess = false
    @State private var animateStreak = false
    @State private var showingHistory = false
    @State private var showingMilestone = false
    @State private var milestoneStreak: Int = 0
    @State private var shareWithPartner = false

    // Calculate reflection streak from saved parent notes
    private var reflectionStreak: Int {
        repository.appData.calculateReflectionStreak()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with streak
                    headerCard

                    // Personalized prompt (Plus feature)
                    if subscriptionManager.effectiveIsPlusSubscriber {
                        PersonalizedPromptView()
                    }

                    // Parent wins - now the primary focus
                    parentWinsSection

                    // Today's highlights (collapsed, less prominent)
                    todayHighlights

                    // Custom note
                    customNoteSection

                    // Gentle guidance if needed
                    gentleGuidance

                    // Partner's shared reflections (Plus feature)
                    if subscriptionManager.effectiveIsPlusSubscriber {
                        PartnerReflectionCompactCard(date: Date())
                    }

                    // Share with partner toggle (Plus feature)
                    if subscriptionManager.effectiveIsPlusSubscriber {
                        shareWithPartnerToggle
                    }

                    // Save button
                    saveButton
                }
                .padding()
            }
            .background(theme.bg1)
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Reflection Saved! 🌙", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text(successMessage)
            }
            .sheet(isPresented: $showingHistory) {
                ReflectionHistoryView()
            }
            .fullScreenCover(isPresented: $showingMilestone) {
                StreakMilestoneView(streak: milestoneStreak) {
                    dismiss()
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.3)) {
                animateStreak = true
            }
        }
    }

    private var successMessage: String {
        let newStreak = reflectionStreak + 1
        if newStreak == 1 {
            return "You showed up for yourself today. That matters."
        } else if newStreak < 7 {
            return "That's \(newStreak) days of reflection! Keep it going."
        } else {
            return "Amazing! \(newStreak) days strong. You're building a powerful habit."
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Moon icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Title
            VStack(spacing: 4) {
                Text("You showed up today")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("What went well?")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }

            // Reflection streak badge and history button
            HStack(spacing: 12) {
                if reflectionStreak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(reflectionStreak) day\(reflectionStreak == 1 ? "" : "s") of reflection")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(20)
                    .scaleEffect(animateStreak ? 1.0 : 0.8)
                    .opacity(animateStreak ? 1.0 : 0)
                } else {
                    // Gentle prompt for first reflection (no pressure, no "streak" framing)
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Your reflection space")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(20)
                    .scaleEffect(animateStreak ? 1.0 : 0.8)
                    .opacity(animateStreak ? 1.0 : 0)
                }

                // History button
                Button(action: { showingHistory = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.12))
                    .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(theme.surface1)
        .cornerRadius(16)
    }
    
    // MARK: - Today's Highlights
    
    private var todayHighlights: some View {
        let todayStats = calculateTodayStats()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatBox(
                    value: "\(todayStats.positiveCount)",
                    label: "Good Moments",
                    color: .green,
                    icon: "hand.thumbsup.fill"
                )
                
                StatBox(
                    value: "\(todayStats.challengeCount)",
                    label: "Challenges",
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatBox(
                    value: todayStats.netPoints >= 0 ? "+\(todayStats.netPoints)" : "\(todayStats.netPoints)",
                    label: "Net Points",
                    color: todayStats.netPoints >= 0 ? .blue : .red,
                    icon: "star.fill"
                )
            }
            
            // Top behaviors today
            if !todayStats.topBehaviors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top moments today:")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                    
                    ForEach(todayStats.topBehaviors.prefix(3), id: \.0.id) { behavior, count in
                        HStack {
                            Image(systemName: behavior.iconName)
                                .foregroundColor(.green)
                            Text(behavior.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)x")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(16)
    }
    
    // MARK: - Parent Wins Section

    /// Key for storing custom wins in UserDefaults
    private static let customWinsKey = "savedCustomParentWins"

    /// Load saved custom wins
    private var savedCustomWins: [String] {
        UserDefaults.standard.stringArray(forKey: Self.customWinsKey) ?? []
    }

    /// Save a new custom win
    private func saveCustomWin(_ win: String) {
        var wins = savedCustomWins
        if !wins.contains(win) {
            wins.append(win)
            UserDefaults.standard.set(wins, forKey: Self.customWinsKey)
        }
    }

    @State private var showingAddCustomWin = false
    @State private var newCustomWin = ""
    @State private var expandedCategory: WinCategory? = nil

    private var parentWinsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Parent Wins")
                    .font(.headline)

                Spacer()

                // Count badge
                if !selectedWins.isEmpty {
                    Text("\(selectedWins.count) selected")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink.opacity(0.15))
                        .cornerRadius(10)
                }
            }

            Text("Celebrate what you did well today:")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            // Category sections
            ForEach(WinCategory.allCases, id: \.self) { category in
                CategoryWinsSection(
                    category: category,
                    selectedWins: $selectedWins,
                    isExpanded: expandedCategory == category,
                    onToggle: {
                        withAnimation(.spring(response: 0.3)) {
                            expandedCategory = expandedCategory == category ? nil : category
                        }
                    }
                )
            }

            // Custom wins section
            customWinsSection
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(16)
        .sheet(isPresented: $showingAddCustomWin) {
            addCustomWinSheet
        }
    }

    // MARK: - Custom Wins Section

    @ViewBuilder
    private var customWinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("My Custom Wins")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Button(action: { showingAddCustomWin = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.yellow)
                }
            }

            if savedCustomWins.isEmpty {
                Text("Add your own wins that matter to you")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .italic()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(savedCustomWins, id: \.self) { win in
                        ParentWinChip(
                            text: win,
                            isSelected: selectedWins.contains(win),
                            accentColor: .yellow
                        ) {
                            toggleWin(win)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Add Custom Win Sheet

    private var addCustomWinSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.yellow)

                    Text("Add Your Own Win")
                        .font(.title3.weight(.semibold))

                    Text("What's something you did well that isn't listed?")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                TextField("e.g., I read an extra book at bedtime", text: $newCustomWin, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .padding(.horizontal)

                Spacer()

                Button(action: {
                    let trimmed = newCustomWin.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        saveCustomWin(trimmed)
                        selectedWins.insert(trimmed)
                        newCustomWin = ""
                        showingAddCustomWin = false
                    }
                }) {
                    Text("Save & Select")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newCustomWin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.textDisabled : Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .disabled(newCustomWin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Custom Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newCustomWin = ""
                        showingAddCustomWin = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func toggleWin(_ win: String) {
        if selectedWins.contains(win) {
            selectedWins.remove(win)
        } else {
            selectedWins.insert(win)
        }
    }
    
    // MARK: - Custom Note
    
    private var customNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a Note (Optional)")
                .font(.headline)

            // Quick-add suggestion chips
            if customNote.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        QuickNoteChip(text: "Feeling grateful for...", icon: "heart.fill") {
                            customNote = "Feeling grateful for "
                        }
                        QuickNoteChip(text: "Today I noticed...", icon: "eye.fill") {
                            customNote = "Today I noticed "
                        }
                        QuickNoteChip(text: "I'm proud that...", icon: "star.fill") {
                            customNote = "I'm proud that "
                        }
                        QuickNoteChip(text: "Tomorrow I want to...", icon: "arrow.right.circle.fill") {
                            customNote = "Tomorrow I want to "
                        }
                    }
                }
            }

            TextField("What else would you like to remember about today?", text: $customNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(16)
    }
    
    // MARK: - Gentle Guidance
    
    @ViewBuilder
    private var gentleGuidance: some View {
        let weekStats = calculateWeekStats()
        
        if weekStats.negativeRatio > 0.5 && weekStats.totalEvents > 10 {
            // Many challenges this week
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("A Gentle Thought")
                        .font(.headline)
                }
                
                Text("It has been a week with some challenges, and that is part of the journey. Tomorrow, try noticing just one small moment that feels good, like a calm morning or a kind word.")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Tip: Noticing the good stuff often brings more of it.")
                        .font(.caption)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Save Button
    
    // MARK: - Share With Partner Toggle

    private var shareWithPartnerToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .foregroundColor(.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text("Share with Partner")
                    .font(.subheadline.weight(.medium))
                Text("Let your partner see this reflection")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $shareWithPartner)
                .labelsHidden()
                .tint(.teal)
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(16)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: saveCheckIn) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Check-in")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedWins.isEmpty && customNote.isEmpty)
        .opacity(selectedWins.isEmpty && customNote.isEmpty ? 0.6 : 1)
    }
    
    // MARK: - Helper Methods
    
    private struct TodayStats {
        let positiveCount: Int
        let challengeCount: Int
        let netPoints: Int
        let topBehaviors: [(BehaviorType, Int)]
    }
    
    private func calculateTodayStats() -> TodayStats {
        let todayEvents = behaviorsStore.todayEvents

        let positive = todayEvents.filter { $0.pointsApplied > 0 }
        let negative = todayEvents.filter { $0.pointsApplied < 0 }
        let net = todayEvents.reduce(0) { $0 + $1.pointsApplied }

        // Count behaviors
        var behaviorCounts: [UUID: Int] = [:]
        for event in positive {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }

        let topBehaviors = behaviorCounts
            .compactMap { id, count -> (BehaviorType, Int)? in
                guard let behavior = behaviorsStore.behaviorType(id: id) else { return nil }
                return (behavior, count)
            }
            .sorted { $0.1 > $1.1 }

        return TodayStats(
            positiveCount: positive.count,
            challengeCount: negative.count,
            netPoints: net,
            topBehaviors: topBehaviors
        )
    }
    
    private struct WeekStats {
        let totalEvents: Int
        let negativeRatio: Double
    }
    
    private func calculateWeekStats() -> WeekStats {
        let events = behaviorsStore.allEvents(forPeriod: .thisWeek)
        let negative = events.filter { $0.pointsApplied < 0 }.count
        let ratio = events.isEmpty ? 0 : Double(negative) / Double(events.count)

        return WeekStats(totalEvents: events.count, negativeRatio: ratio)
    }
    
    private func saveCheckIn() {
        // Get current streak before saving (to detect milestone)
        let previousStreak = reflectionStreak

        // Get current parent info for attribution
        let currentParent = repository.appData.currentParent
        let parentId = currentParent?.id ?? repository.appData.currentParentId
        let parentName = currentParent?.displayName

        // Determine if sharing is enabled
        let shouldShare = shareWithPartner && subscriptionManager.effectiveIsPlusSubscriber

        // Save parent wins as notes
        for win in selectedWins {
            let note = ParentNote(
                content: win,
                noteType: .parentWin,
                isSharedWithPartner: shouldShare,
                loggedByParentId: parentId,
                loggedByParentName: parentName
            )
            repository.addParentNote(note)
        }

        // Save custom note if present
        if !customNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let note = ParentNote(
                content: customNote,
                noteType: .reflection,
                isSharedWithPartner: shouldShare,
                loggedByParentId: parentId,
                loggedByParentName: parentName
            )
            repository.addParentNote(note)
        }

        // Check for milestone after saving
        let newStreak = repository.appData.calculateReflectionStreak()

        // Show milestone celebration if hitting a milestone
        if Milestone.celebrationMilestones.contains(newStreak) && newStreak > previousStreak {
            milestoneStreak = newStreak
            showingMilestone = true
        } else {
            showingSuccess = true
        }
    }
}

// MARK: - Quick Note Chip

/// Tappable chip for quick note suggestions
private struct QuickNoteChip: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(text)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.purple)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Category Wins Section

/// Expandable category section for parent wins
private struct CategoryWinsSection: View {
    let category: WinCategory
    @Binding var selectedWins: Set<String>
    let isExpanded: Bool
    let onToggle: () -> Void

    @Environment(\.theme) private var theme

    /// Count of selected wins in this category
    private var selectedCount: Int {
        category.wins.filter { selectedWins.contains($0) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header (always visible)
            Button(action: onToggle) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundColor(category.color)
                        .frame(width: 20)

                    Text(category.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.textPrimary)

                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(category.color)
                            .cornerRadius(8)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            // Quick-select row (always visible) - first 2 options
            if !isExpanded {
                HStack(spacing: 8) {
                    ForEach(category.wins.prefix(2), id: \.self) { win in
                        ParentWinChip(
                            text: win,
                            isSelected: selectedWins.contains(win),
                            accentColor: category.color
                        ) {
                            toggleWin(win)
                        }
                    }
                    if category.wins.count > 2 {
                        Text("+\(category.wins.count - 2)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }

            // Expanded content
            if isExpanded {
                FlowLayout(spacing: 8) {
                    ForEach(category.wins, id: \.self) { win in
                        ParentWinChip(
                            text: win,
                            isSelected: selectedWins.contains(win),
                            accentColor: category.color
                        ) {
                            toggleWin(win)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(category.color.opacity(0.06))
        .cornerRadius(12)
    }

    private func toggleWin(_ win: String) {
        if selectedWins.contains(win) {
            selectedWins.remove(win)
        } else {
            selectedWins.insert(win)
        }
    }
}

// MARK: - Parent Win Chip

struct ParentWinChip: View {
    let text: String
    let isSelected: Bool
    var accentColor: Color = .pink
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? accentColor.opacity(0.2) : theme.surface2)
                .foregroundColor(isSelected ? accentColor : theme.textPrimary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                
                self.size.width = max(self.size.width, currentX)
            }
            
            self.size.height = currentY + lineHeight
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    DailyCheckInView()
        .environmentObject(repository)
        .environmentObject(BehaviorsStore(repository: repository))
}
