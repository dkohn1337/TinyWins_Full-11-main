import SwiftUI

/// View showing parent reflection history with calendar and list modes
struct ReflectionHistoryView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayMode: DisplayMode = .calendar
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingDayDetail: Date?
    @State private var showingPremiumPaywall = false

    private let calendar = Calendar.current

    private var maxHistoryDays: Int {
        subscriptionManager.maxReflectionHistoryDays()
    }

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    private var earliestAccessibleDate: Date {
        calendar.date(byAdding: .day, value: -maxHistoryDays, to: Date()) ?? Date()
    }

    private var reflectionStreak: Int {
        repository.appData.calculateReflectionStreak()
    }

    enum DisplayMode: String, CaseIterable {
        case calendar = "Calendar"
        case list = "List"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Streak badge header
                streakHeader

                // Mode picker
                Picker("Display Mode", selection: $displayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content based on mode
                switch displayMode {
                case .calendar:
                    calendarView
                case .list:
                    listView
                }
            }
            .background(theme.bg1)
            .navigationTitle("Reflection History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $showingDayDetail) { date in
                ReflectionDayDetailView(date: date)
            }
            .sheet(isPresented: $showingPremiumPaywall) {
                PlusPaywallView(context: .reflectionHistory)
            }
        }
    }

    // MARK: - Reflection Header

    private var streakHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(reflectionStreak) day\(reflectionStreak == 1 ? "" : "s") of reflection")
                    .font(.headline)
                Text(reflectionStreak == 0 ? "Start your journey today" : "Keep reflecting daily")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(theme.bg0)
    }

    // MARK: - Calendar View

    private var calendarView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month navigation
                monthNavigator

                // Calendar grid
                calendarGrid

                // Legend
                calendarLegend

                // Premium banner if on free tier
                if !isPlusSubscriber {
                    premiumBanner
                }
            }
            .padding()
            .tabBarBottomPadding()
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.accentColor)
            }

            Spacer()

            Text(monthYearString(for: currentMonth))
                .font(.headline)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.medium))
                    .foregroundColor(canGoToNextMonth ? .accentColor : .secondary)
            }
            .disabled(!canGoToNextMonth)
        }
        .padding(.horizontal, 8)
    }

    private var canGoToNextMonth: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        return nextMonth <= Date()
    }

    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextMonth() {
        guard canGoToNextMonth else { return }
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var calendarGrid: some View {
        let days = daysInMonth(for: currentMonth)
        let daysWithReflections = repository.getDaysWithReflections(
            from: calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!,
            to: calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!)!
        )

        return VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        CalendarDayCell(
                            date: day,
                            hasReflection: daysWithReflections.contains(calendar.startOfDay(for: day)),
                            isAccessible: isDateAccessible(day),
                            isToday: calendar.isDateInToday(day),
                            isFuture: day > Date()
                        ) {
                            handleDayTap(day)
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(theme.bg0)
        .cornerRadius(16)
    }

    private func daysInMonth(for date: Date) -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    private func isDateAccessible(_ date: Date) -> Bool {
        if isPlusSubscriber { return true }
        return date >= earliestAccessibleDate
    }

    private func handleDayTap(_ date: Date) {
        if date > Date() { return } // Future dates not tappable

        if !isDateAccessible(date) {
            showingPremiumPaywall = true
            return
        }

        showingDayDetail = date
    }

    private var calendarLegend: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                Text("Reflected")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            if !isPlusSubscriber {
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.textDisabled.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Plus only")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    // MARK: - List View

    private var listView: some View {
        let allNotes = repository.getParentNotes()
        let groupedNotes = Dictionary(grouping: allNotes) { note in
            calendar.startOfDay(for: note.date)
        }
        let sortedDates = groupedNotes.keys.sorted().reversed()

        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(sortedDates), id: \.self) { date in
                    let isAccessible = isDateAccessible(date)

                    ReflectionListDayCard(
                        date: date,
                        notes: groupedNotes[date] ?? [],
                        isAccessible: isAccessible
                    ) {
                        if isAccessible {
                            showingDayDetail = date
                        } else {
                            showingPremiumPaywall = true
                        }
                    }
                }

                // Premium banner at bottom of list
                if !isPlusSubscriber {
                    premiumBanner
                }
            }
            .padding()
            .tabBarBottomPadding()
        }
    }

    // MARK: - Premium Banner

    private var premiumBanner: some View {
        Button(action: { showingPremiumPaywall = true }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Full History")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    Text("See all your reflections with TinyWins Plus")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    @Environment(\.theme) private var theme
    let date: Date
    let hasReflection: Bool
    let isAccessible: Bool
    let isToday: Bool
    let isFuture: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundColor(textColor)

                // Dot indicator
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .opacity(hasReflection ? 1 : 0)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    private var textColor: Color {
        if isFuture { return theme.textDisabled }
        if !isAccessible { return theme.textDisabled }
        return theme.textPrimary
    }

    private var backgroundColor: Color {
        if hasReflection && isAccessible {
            return Color.purple.opacity(0.1)
        }
        return Color.clear
    }

    private var dotColor: Color {
        if !isAccessible { return theme.textDisabled.opacity(0.3) }
        return .purple
    }
}

// MARK: - Reflection List Day Card

private struct ReflectionListDayCard: View {
    let date: Date
    let notes: [ParentNote]
    let isAccessible: Bool
    let onTap: () -> Void
    @Environment(\.theme) private var theme

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private var parentWins: [ParentNote] {
        notes.filter { $0.noteType == .parentWin }
    }

    private var reflections: [ParentNote] {
        notes.filter { $0.noteType == .reflection || $0.noteType == .goodMoment }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Date header
                HStack {
                    Text(dateString)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isAccessible ? theme.textPrimary : theme.textSecondary)

                    Spacer()

                    if !isAccessible {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                if isAccessible {
                    // Summary
                    HStack(spacing: 16) {
                        if !parentWins.isEmpty {
                            Label("\(parentWins.count) win\(parentWins.count == 1 ? "" : "s")", systemImage: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                        }

                        if !reflections.isEmpty {
                            Label("\(reflections.count) note\(reflections.count == 1 ? "" : "s")", systemImage: "note.text")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }

                    // Preview of first note
                    if let firstReflection = reflections.first {
                        Text(firstReflection.content)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    } else if let firstWin = parentWins.first {
                        Text(firstWin.content)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                } else {
                    // Blurred preview
                    Text("Upgrade to TinyWins Plus to see this reflection")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .italic()
                }
            }
            .padding()
            .background(theme.bg0)
            .cornerRadius(12)
            .opacity(isAccessible ? 1 : 0.7)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Date Extension for Sheet Binding

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    ReflectionHistoryView()
        .environmentObject(repository)
        .environmentObject(SubscriptionManager.shared)
}
