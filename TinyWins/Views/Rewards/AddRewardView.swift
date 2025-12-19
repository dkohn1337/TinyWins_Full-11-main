import SwiftUI

struct AddRewardView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var rewardsStore: RewardsStore
    @Environment(\.dismiss) private var dismiss

    let child: Child
    var editingReward: Reward? = nil

    // MARK: - State

    @State private var name: String = ""
    @State private var targetPoints: Int = 10
    @State private var selectedIcon: String = "gift.fill"
    @State private var hasDeadline: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var showingDeleteConfirmation = false
    @State private var showIconPicker = false
    @FocusState private var isNameFocused: Bool

    private var isEditing: Bool {
        editingReward != nil
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetPoints > 0
    }

    // Dynamic estimate based on ~2-3 stars per day
    private var timeEstimate: String {
        let starsPerDay = 2.5
        let days = Double(targetPoints) / starsPerDay

        if days < 1 {
            return "Same day"
        } else if days < 2 {
            return "~1 day"
        } else if days < 7 {
            return "~\(Int(round(days))) days"
        } else if days < 14 {
            return "~1 week"
        } else if days < 21 {
            return "~2 weeks"
        } else if days < 35 {
            return "~1 month"
        } else {
            return "~\(Int(round(days / 7))) weeks"
        }
    }

    init(child: Child, editingReward: Reward? = nil, template: RewardTemplate? = nil) {
        self.child = child
        self.editingReward = editingReward

        if let reward = editingReward {
            _name = State(initialValue: reward.name)
            _targetPoints = State(initialValue: reward.targetPoints)
            _selectedIcon = State(initialValue: reward.imageName ?? "gift.fill")
            if let deadline = reward.dueDate {
                _hasDeadline = State(initialValue: true)
                _dueDate = State(initialValue: deadline)
            } else {
                _hasDeadline = State(initialValue: false)
            }
        } else if let template = template {
            _name = State(initialValue: template.name)
            _targetPoints = State(initialValue: template.defaultPoints)
            _selectedIcon = State(initialValue: template.icon)
            if template.defaultDurationDays > 0 {
                _hasDeadline = State(initialValue: true)
                _dueDate = State(initialValue: Calendar.current.date(byAdding: .day, value: template.defaultDurationDays, to: Date()) ?? Date())
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Live Preview Card at top
                    livePreviewCard
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Main content
                    VStack(spacing: 24) {
                        // Step 1: Name & Icon
                        nameAndIconSection

                        // Step 2: Stars
                        starsSection

                        // Step 3: Timeline (optional)
                        timelineSection

                        // Delete button for editing
                        if isEditing {
                            deleteSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Space for save button
                }
            }
            .background(theme.bg1)
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerSheet(selectedIcon: $selectedIcon, childColor: child.colorTag.color)
            }
            .alert("Delete Reward?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let reward = editingReward {
                        rewardsStore.deleteReward(id: reward.id)
                        dismiss()
                    }
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    // MARK: - Live Preview Card

    private var livePreviewCard: some View {
        VStack(spacing: 16) {
            // Icon and name
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [child.colorTag.color.opacity(0.2), child.colorTag.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: selectedIcon)
                        .font(.system(size: 28))
                        .foregroundColor(child.colorTag.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Your goal name..." : name)
                        .font(.headline)
                        .foregroundColor(name.isEmpty ? theme.textSecondary : theme.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        // Stars badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(targetPoints) stars")
                                .font(.caption.weight(.medium))
                                .foregroundColor(theme.textSecondary)
                        }

                        // Time estimate badge
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            Text(timeEstimate)
                                .font(.caption.weight(.medium))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }

                Spacer()
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.borderSoft)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 0, height: 10)
                }

                HStack {
                    Text("0 / \(targetPoints) stars")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)

                    Spacer()

                    if hasDeadline {
                        Text("Due \(dueDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text("No deadline")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .background(theme.surface1)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Name & Icon Section

    private var nameAndIconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What's the reward?", systemImage: "pencil")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textSecondary)

            HStack(spacing: 12) {
                // Icon button
                Button {
                    showIconPicker = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(child.colorTag.color.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: selectedIcon)
                            .font(.system(size: 24))
                            .foregroundColor(child.colorTag.color)

                        // Edit indicator
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(child.colorTag.color)
                            .background(theme.surface1.clipShape(Circle()))
                            .offset(x: 20, y: 20)
                    }
                }
                .buttonStyle(.plain)

                // Name field
                TextField("Movie night, park trip, ice cream...", text: $name)
                    .font(.body)
                    .padding(14)
                    .background(theme.surface1)
                    .cornerRadius(14)
                    .focused($isNameFocused)
            }
        }
    }

    // MARK: - Stars Section

    private var starsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How many stars?", systemImage: "star.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textSecondary)

            // Use shared GoalSizeSelector for consistency across the app
            VStack(spacing: 16) {
                GoalSizeSelector(
                    starCount: $targetPoints,
                    childColor: child.colorTag.color,
                    showPresets: true,
                    showHelperText: true
                )

                // Additional time estimate
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("Typical: \(GoalSizeCategory.from(stars: targetPoints).timeframeHint)")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(16)
            .background(theme.surface1)
            .cornerRadius(16)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Deadline (optional)", systemImage: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textSecondary)

            VStack(spacing: 0) {
                // No deadline toggle
                Toggle(isOn: $hasDeadline) {
                    Text(hasDeadline ? "Has a due date" : "No deadline")
                        .font(.subheadline)
                }
                .tint(child.colorTag.color)
                .padding(16)

                // Date picker (only shown when hasDeadline is true)
                if hasDeadline {
                    Divider()
                        .padding(.horizontal, 16)

                    DatePicker(
                        "Due date",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(child.colorTag.color)
                    .padding(16)
                }
            }
            .background(theme.surface1)
            .cornerRadius(16)
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Goal")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(theme.surface1)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(isEditing ? "Save Changes" : "Create Goal")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isValid
                        ? LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                        : LinearGradient(
                            colors: [theme.borderStrong, theme.borderStrong],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                )
                .cornerRadius(16)
        }
        .disabled(!isValid)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(theme.surface1)
    }

    // MARK: - Save

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, targetPoints > 0 else { return }

        let reward = Reward(
            id: editingReward?.id ?? UUID(),
            childId: child.id,
            name: trimmedName,
            targetPoints: targetPoints,
            imageName: selectedIcon,
            isRedeemed: editingReward?.isRedeemed ?? false,
            redeemedDate: editingReward?.redeemedDate,
            createdDate: editingReward?.createdDate ?? Date(),
            startDate: editingReward?.startDate ?? Date(),
            dueDate: hasDeadline ? dueDate : nil,
            autoResetOnExpire: false,
            progressReductionFactor: editingReward?.progressReductionFactor ?? 1.0
        )

        if isEditing {
            rewardsStore.updateReward(reward)
        } else {
            rewardsStore.addReward(reward)
        }

        dismiss()
    }
}

// MARK: - Icon Picker Sheet

private struct IconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Binding var selectedIcon: String
    let childColor: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Reward.availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        selectedIcon == icon
                                            ? childColor
                                            : theme.surface2
                                    )
                                    .frame(width: 52, height: 52)

                                Image(systemName: icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(
                                        selectedIcon == icon ? .white : theme.textPrimary
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Corner Radius Extension

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview("Add") {
    AddRewardView(child: Child(name: "Emma", age: 8, colorTag: .purple, totalPoints: 45))
        .environmentObject(RewardsStore(repository: Repository.preview))
}

#Preview("Edit") {
    let child = Child(name: "Emma", age: 8, colorTag: .purple, totalPoints: 45)
    let reward = Reward(
        childId: child.id,
        name: "Movie Night",
        targetPoints: 50,
        dueDate: Date().addingTimeInterval(3 * 24 * 60 * 60)
    )

    AddRewardView(child: child, editingReward: reward)
        .environmentObject(RewardsStore(repository: Repository.preview))
}
