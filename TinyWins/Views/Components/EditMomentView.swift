import SwiftUI

struct EditMomentView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let event: BehaviorEvent

    // Editable fields
    @State private var selectedBehaviorTypeId: UUID
    @State private var pointsApplied: Int
    @State private var note: String
    @State private var isPositive: Bool

    // UI state
    @State private var showingBehaviorPicker = false
    
    init(event: BehaviorEvent) {
        self.event = event
        _selectedBehaviorTypeId = State(initialValue: event.behaviorTypeId)
        _pointsApplied = State(initialValue: abs(event.pointsApplied))
        _note = State(initialValue: event.note ?? "")
        _isPositive = State(initialValue: event.pointsApplied >= 0)
    }
    
    private var selectedBehaviorType: BehaviorType? {
        behaviorsStore.behaviorType(id: selectedBehaviorTypeId)
    }

    private var child: Child? {
        childrenStore.child(id: event.childId)
    }
    
    private var effectivePoints: Int {
        isPositive ? pointsApplied : -pointsApplied
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Child (read-only)
                if let child = child {
                    Section("Child") {
                        HStack {
                            ChildAvatar(child: child, size: 32)
                            Text(child.name)
                                .font(.body)
                        }
                    }
                }
                
                // Behavior Type
                Section("Behavior") {
                    Button(action: { showingBehaviorPicker = true }) {
                        HStack {
                            if let behavior = selectedBehaviorType {
                                Image(systemName: behavior.iconName)
                                    .foregroundColor(isPositive ? AppColors.positive : AppColors.challenge)
                                Text(behavior.name)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select behavior")
                                    .foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                
                // Positive / Challenge
                Section("Type") {
                    Picker("Type", selection: $isPositive) {
                        Text("Positive").tag(true)
                        Text("Challenge").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Points
                Section("Stars") {
                    Stepper(value: $pointsApplied, in: 1...10) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(theme.textSecondary)
                            Text(isPositive ? "+\(pointsApplied)" : "-\(pointsApplied)")
                                .font(.headline)
                                .foregroundColor(isPositive ? AppColors.positive : AppColors.challenge)
                        }
                    }
                }
                
                // Note
                Section("Note") {
                    TextField("Add a note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Timestamp (read-only)
                Section("Timestamp") {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(theme.textSecondary)
                        Text(formatDateTime(event.timestamp))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Edit Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingBehaviorPicker) {
                BehaviorPickerSheet(
                    selectedBehaviorTypeId: $selectedBehaviorTypeId,
                    isPositive: $isPositive,
                    defaultPoints: $pointsApplied
                )
            }
        }
    }
    
    private func saveChanges() {
        var updatedEvent = event
        updatedEvent.note = note.isEmpty ? nil : note
        
        // Create new event with updated values (keeping original timestamp and media)
        let newEvent = BehaviorEvent(
            id: event.id,
            childId: event.childId,
            behaviorTypeId: selectedBehaviorTypeId,
            timestamp: event.timestamp,
            pointsApplied: effectivePoints,
            note: note.isEmpty ? nil : note,
            mediaAttachments: event.mediaAttachments,
            earnedAllowance: event.earnedAllowance,
            rewardId: event.rewardId
        )
        
        behaviorsStore.updateEvent(newEvent)
        dismiss()
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Behavior Picker Sheet

struct BehaviorPickerSheet: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedBehaviorTypeId: UUID
    @Binding var isPositive: Bool
    @Binding var defaultPoints: Int

    private var groupedBehaviors: [BehaviorCategory: [BehaviorType]] {
        Dictionary(grouping: behaviorsStore.behaviorTypes.filter { $0.isActive }) { $0.category }
    }
    
    private var sortedCategories: [BehaviorCategory] {
        groupedBehaviors.keys.sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCategories, id: \.self) { category in
                    Section(category.displayName) {
                        ForEach(groupedBehaviors[category] ?? []) { behavior in
                            Button(action: {
                                selectedBehaviorTypeId = behavior.id
                                isPositive = behavior.defaultPoints >= 0
                                defaultPoints = abs(behavior.defaultPoints)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: behavior.iconName)
                                        .foregroundColor(behavior.defaultPoints >= 0 ? AppColors.positive : AppColors.challenge)
                                        .frame(width: 24)
                                    
                                    Text(behavior.name)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedBehaviorTypeId == behavior.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EditMomentView(event: BehaviorEvent(
        childId: UUID(),
        behaviorTypeId: UUID(),
        pointsApplied: 2,
        note: "Test note"
    ))
    .environmentObject(Repository.preview)
}
