import SwiftUI

// MARK: - Cached Formatters

private enum HistorySheetFormatterCache {
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

// MARK: - Event Detail Sheet (Behavior Events)

/// Detail sheet for viewing and managing a behavior event
struct EventDetailSheet: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var progressionStore: ProgressionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingEditMoment = false

    let event: BehaviorEvent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    if let behavior = behaviorsStore.behaviorType(id: event.behaviorTypeId) {
                        VStack(spacing: 12) {
                            StyledIcon(
                                systemName: behavior.iconName,
                                color: event.pointsApplied >= 0 ? AppColors.positive : AppColors.challenge,
                                size: 32,
                                backgroundSize: 72,
                                isCircle: true
                            )

                            Text(behavior.name)
                                .font(.title2.weight(.semibold))

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(theme.textSecondary)
                                Text(event.pointsApplied >= 0 ? "+\(event.pointsApplied)" : "\(event.pointsApplied)")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(event.pointsApplied >= 0 ? AppColors.positive : AppColors.challenge)
                            }
                        }
                        .padding()
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        // Child
                        if let child = childrenStore.child(id: event.childId) {
                            DetailRow(icon: "person.fill", label: "Child", value: child.name, color: child.colorTag.color)
                        }

                        // Reward (if assigned)
                        if let rewardId = event.rewardId,
                           let reward = rewardsStore.rewards.first(where: { $0.id == rewardId }) {
                            DetailRow(icon: "gift.fill", label: "Applied to", value: reward.name, color: .purple)
                        } else if event.pointsApplied > 0 {
                            DetailRow(icon: "gift.fill", label: "Applied to", value: "Primary reward", color: theme.textSecondary)
                        }

                        // Date & Time
                        DetailRow(icon: "calendar", label: "Date", value: formatDate(event.timestamp), color: theme.textSecondary)
                        DetailRow(icon: "clock.fill", label: "Time", value: formatTime(event.timestamp), color: theme.textSecondary)

                        // Note
                        if let note = event.note, !note.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Note", systemImage: "note.text")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)

                                Text(note)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(theme.surface2)
                                    .cornerRadius(12)
                            }
                        }

                        // Attachments
                        if event.hasMedia {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("\(event.mediaAttachments.count) Attachment\(event.mediaAttachments.count > 1 ? "s" : "")", systemImage: "photo.fill")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(event.mediaAttachments) { attachment in
                                            if let image = MediaManager.shared.loadImage(from: attachment) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(12)
                                                    .clipped()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: { showingEditMoment = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Moment")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.primary.opacity(0.1))
                                .foregroundColor(AppColors.primary)
                                .cornerRadius(12)
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Moment")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .background(theme.bg1)
            .navigationTitle("Moment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: toggleSpecial) {
                        Image(systemName: progressionStore.isSpecialMoment(event.id) ? "heart.fill" : "heart")
                            .foregroundColor(progressionStore.isSpecialMoment(event.id) ? .pink : theme.textSecondary)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete this moment?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    behaviorsStore.deleteEvent(id: event.id)
                    dismiss()
                }
            } message: {
                Text("This removes the moment from your history and adjusts the star count.")
            }
            .sheet(isPresented: $showingEditMoment) {
                EditMomentView(event: event)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggleSpecial() {
        if progressionStore.isSpecialMoment(event.id) {
            progressionStore.unmarkAsSpecial(eventId: event.id)
        } else {
            progressionStore.markAsSpecial(event: event)
        }
    }

    private func formatDate(_ date: Date) -> String {
        HistorySheetFormatterCache.mediumDateFormatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        HistorySheetFormatterCache.shortTimeFormatter.string(from: date)
    }
}

// MARK: - Reward Event Detail Sheet

/// Detail sheet for viewing reward history events
struct RewardEventDetailSheet: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore
    @Environment(\.dismiss) private var dismiss

    let event: RewardHistoryEvent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(eventColor.opacity(0.15))
                                .frame(width: 72, height: 72)

                            Image(systemName: event.rewardIcon ?? "gift.fill")
                                .font(.system(size: 32))
                                .foregroundColor(eventColor)
                        }

                        Text(event.rewardName)
                            .font(.title2.weight(.semibold))

                        // Event type badge
                        Text(event.eventType.displayName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(eventColor.opacity(0.15))
                            .foregroundColor(eventColor)
                            .cornerRadius(12)
                    }
                    .padding()

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        // Child
                        if let child = childrenStore.child(id: event.childId) {
                            DetailRow(icon: "person.fill", label: "Child", value: child.name, color: child.colorTag.color)
                        }

                        // Date & Time
                        DetailRow(icon: "calendar", label: "Date", value: formatDate(event.timestamp), color: theme.textSecondary)
                        DetailRow(icon: "clock.fill", label: "Time", value: formatTime(event.timestamp), color: theme.textSecondary)

                        // Stars
                        DetailRow(icon: "star.fill", label: "Stars Required", value: "\(event.starsRequired)", color: theme.textSecondary)
                        DetailRow(icon: "star.circle.fill", label: "Stars at Event", value: "\(event.starsEarnedAtEvent)", color: eventColor)

                        // Additional info based on type
                        if event.eventType == .expired {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .frame(width: 24)

                                Text("The deadline passed before the goal was reached.")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .background(theme.bg1)
            .navigationTitle("Reward Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var eventColor: Color {
        switch event.eventType {
        case .earned: return .purple
        case .given: return AppColors.positive
        case .expired: return .orange
        }
    }

    private func formatDate(_ date: Date) -> String {
        HistorySheetFormatterCache.mediumDateFormatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        HistorySheetFormatterCache.shortTimeFormatter.string(from: date)
    }
}

// MARK: - Filter Bottom Sheet

/// Bottom sheet for advanced filter options
struct FilterBottomSheet: View {
    @Environment(\.theme) private var theme
    @Binding var selectedPeriod: TimePeriod
    @Binding var selectedChildId: UUID?
    @Binding var selectedTypeFilter: HistoryTypeFilter
    let children: [Child]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Time Period
                Section("Time Period") {
                    ForEach([TimePeriod.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .allTime], id: \.self) { period in
                        Button(action: { selectedPeriod = period }) {
                            HStack {
                                Text(period.displayName)
                                Spacer()
                                if selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(theme.textPrimary)
                    }
                }

                // Who
                Section("Who") {
                    Button(action: { selectedChildId = nil }) {
                        HStack {
                            Text("All Kids")
                            Spacer()
                            if selectedChildId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(theme.textPrimary)

                    ForEach(children) { child in
                        Button(action: { selectedChildId = child.id }) {
                            HStack {
                                Circle()
                                    .fill(child.colorTag.color)
                                    .frame(width: 12, height: 12)
                                Text(child.name)
                                Spacer()
                                if selectedChildId == child.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(theme.textPrimary)
                    }
                }

                // What
                Section("What") {
                    ForEach(HistoryTypeFilter.allCases, id: \.self) { filter in
                        Button(action: { selectedTypeFilter = filter }) {
                            HStack {
                                if let icon = filter.icon {
                                    Image(systemName: icon)
                                        .foregroundColor(theme.textSecondary)
                                }
                                Text(filter.rawValue)
                                Spacer()
                                if selectedTypeFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(theme.textPrimary)
                    }
                }
            }
            .navigationTitle("Filter History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
