import SwiftUI

struct BehaviorManagementView: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @State private var showingAddBehavior = false
    @State private var editingBehavior: BehaviorType?
    @State private var selectedCategory: BehaviorCategory = .routinePositive
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Helper text for new users
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("The defaults work well for most families. Tweak points or add your own whenever you like.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(BehaviorCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Behaviors List
                List {
                    ForEach(behaviorsForCategory) { behavior in
                        BehaviorRow(behavior: behavior)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingBehavior = behavior
                            }
                    }
                    .onDelete(perform: deleteBehaviors)
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Manage Behaviors")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddBehavior = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBehavior) {
                AddEditBehaviorView(mode: .add(category: selectedCategory))
            }
            .sheet(item: $editingBehavior) { behavior in
                AddEditBehaviorView(mode: .edit(behavior))
            }
        }
    }
    
    private var behaviorsForCategory: [BehaviorType] {
        behaviorsStore.behaviorTypes.filter { $0.category == selectedCategory }
    }

    private func deleteBehaviors(at offsets: IndexSet) {
        for index in offsets {
            let behavior = behaviorsForCategory[index]
            behaviorsStore.deleteBehaviorType(id: behavior.id)
        }
    }
}

// MARK: - Behavior Row

struct BehaviorRow: View {
    let behavior: BehaviorType
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon in styled container
            StyledIcon(
                systemName: behavior.iconName,
                color: iconColor,
                size: 18,
                backgroundSize: 40
            )
            
            // Main info - left aligned
            VStack(alignment: .leading, spacing: 4) {
                // Name and badges
                HStack(spacing: 6) {
                    Text(behavior.name)
                        .font(.body)
                        .lineLimit(2)
                    
                    if !behavior.isActive {
                        BadgeLabel(text: "Inactive", color: .gray)
                    }
                    
                    if behavior.isCustom {
                        BadgeLabel(text: "Custom", color: .blue)
                    }
                }
                
                // Points
                Text(pointsText)
                    .font(.subheadline)
                    .foregroundColor(pointsColor)
            }
            
            Spacer()
            
            // Right side metadata - vertically stacked
            VStack(alignment: .trailing, spacing: 4) {
                // Age range (if not default)
                if behavior.suggestedAgeRange.minAge != 2 || behavior.suggestedAgeRange.maxAge != 18 {
                    Text(behavior.suggestedAgeRange.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Allowance indicator
                if behavior.isMonetized {
                    HStack(spacing: 2) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                        Text("Allowance")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
                
                // Difficulty dots
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= behavior.difficultyScore ? categoryColor : Color.gray.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .opacity(behavior.isActive ? 1 : 0.6)
    }
    
    private var iconColor: Color {
        switch behavior.category {
        case .routinePositive: return AppColors.routine
        case .positive: return AppColors.positive
        case .negative: return AppColors.challenge
        }
    }
    
    private var categoryColor: Color {
        iconColor
    }
    
    private var pointsText: String {
        if behavior.defaultPoints >= 0 {
            return "+\(behavior.defaultPoints) points"
        } else {
            return "\(behavior.defaultPoints) points"
        }
    }
    
    private var pointsColor: Color {
        behavior.defaultPoints >= 0 ? AppColors.positive : AppColors.challenge
    }
}

// Small badge label component
struct BadgeLabel: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Add/Edit Behavior View

struct AddEditBehaviorView: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.dismiss) private var dismiss
    
    enum Mode {
        case add(category: BehaviorCategory)
        case edit(BehaviorType)
        
        var title: String {
            switch self {
            case .add: return "Add Behavior"
            case .edit: return "Edit Behavior"
            }
        }
        
        var category: BehaviorCategory {
            switch self {
            case .add(let category): return category
            case .edit(let behavior): return behavior.category
            }
        }
    }
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var points: Int = 3
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedCategory: BehaviorCategory
    @State private var isActive: Bool = true
    @State private var minAge: Int = 2
    @State private var maxAge: Int = 18
    @State private var difficultyScore: Int = 3
    @State private var isMonetized: Bool = false
    @State private var showingDeleteConfirmation = false
    
    init(mode: Mode) {
        self.mode = mode
        _selectedCategory = State(initialValue: mode.category)
        
        if case .edit(let behavior) = mode {
            _name = State(initialValue: behavior.name)
            _points = State(initialValue: behavior.defaultPoints)
            _selectedIcon = State(initialValue: behavior.iconName)
            _selectedCategory = State(initialValue: behavior.category)
            _isActive = State(initialValue: behavior.isActive)
            _minAge = State(initialValue: behavior.suggestedAgeRange.minAge)
            _maxAge = State(initialValue: behavior.suggestedAgeRange.maxAge)
            _difficultyScore = State(initialValue: behavior.difficultyScore)
            _isMonetized = State(initialValue: behavior.isMonetized)
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Behavior Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(BehaviorCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory) { _, newValue in
                        // Adjust points to match category
                        let range = BehaviorType.suggestedPointRange(for: newValue)
                        if !range.contains(points) {
                            points = newValue == .negative ? range.upperBound : range.lowerBound
                        }
                    }
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section("Points") {
                    HStack {
                        Text("Points:")
                        Spacer()
                        Text(pointsDisplayText)
                            .foregroundColor(points >= 0 ? .green : .red)
                            .fontWeight(.semibold)
                    }
                    
                    Stepper("Adjust points", value: $points, in: selectedCategory == .negative ? -10...(-1) : 1...10)
                        .labelsHidden()
                    
                    Text(pointsHelpText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Icon") {
                    iconPicker
                }
                
                Section("Age Range") {
                    HStack {
                        Text("Min Age:")
                        Picker("", selection: $minAge) {
                            ForEach(2..<19, id: \.self) { age in
                                Text("\(age)").tag(age)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                        
                        Text("Max Age:")
                        Picker("", selection: $maxAge) {
                            ForEach(2..<19, id: \.self) { age in
                                Text("\(age)").tag(age)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .onChange(of: minAge) { _, newValue in
                        if maxAge < newValue {
                            maxAge = newValue
                        }
                    }
                }
                
                Section("Difficulty") {
                    Picker("Difficulty", selection: $difficultyScore) {
                        ForEach(DifficultyLevel.allCases) { level in
                            Text(level.displayName).tag(level.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text("Suggested points: \(DifficultyLevel(rawValue: difficultyScore)?.suggestedPointRange.description ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if selectedCategory != .negative {
                    Section("Allowance") {
                        Toggle("Counts toward allowance", isOn: $isMonetized)
                        
                        if isMonetized {
                            Text("This behavior will earn money when allowance is enabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if case .edit(let behavior) = mode, behavior.isCustom {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Behavior")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .alert("Delete Behavior?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if case .edit(let behavior) = mode {
                        behaviorsStore.deleteBehaviorType(id: behavior.id)
                        dismiss()
                    }
                }
            } message: {
                Text("This will also delete all logged events for this behavior.")
            }
        }
    }
    
    private var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(BehaviorType.availableIcons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                        .frame(width: 40, height: 40)
                        .background(selectedIcon == icon ? categoryColor : Color(.systemGray5))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var categoryColor: Color {
        switch selectedCategory {
        case .routinePositive: return .blue
        case .positive: return .green
        case .negative: return .orange
        }
    }
    
    private var pointsDisplayText: String {
        if points >= 0 {
            return "+\(points)"
        }
        return "\(points)"
    }
    
    private var pointsHelpText: String {
        switch selectedCategory {
        case .routinePositive: return "Routine tasks typically earn 3-10 points"
        case .positive: return "Positive behaviors typically earn 1-5 points"
        case .negative: return "Challenges typically deduct 1-10 points"
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let behavior: BehaviorType

        switch mode {
        case .add:
            behavior = BehaviorType(
                name: trimmedName,
                category: selectedCategory,
                defaultPoints: points,
                isActive: isActive,
                iconName: selectedIcon,
                suggestedAgeRange: AgeRange(minAge: minAge, maxAge: maxAge),
                difficultyScore: difficultyScore,
                isMonetized: isMonetized && selectedCategory != .negative,
                isCustom: true
            )
            behaviorsStore.addBehaviorType(behavior)

        case .edit(let existingBehavior):
            behavior = BehaviorType(
                id: existingBehavior.id,
                name: trimmedName,
                category: selectedCategory,
                defaultPoints: points,
                isActive: isActive,
                iconName: selectedIcon,
                suggestedAgeRange: AgeRange(minAge: minAge, maxAge: maxAge),
                difficultyScore: difficultyScore,
                isMonetized: isMonetized && selectedCategory != .negative,
                isCustom: existingBehavior.isCustom
            )
            behaviorsStore.updateBehaviorType(behavior)
        }

        dismiss()
    }
}

// MARK: - Previews

#Preview {
    let repository = Repository.preview
    let behaviorsStore = BehaviorsStore(repository: repository)

    BehaviorManagementView()
        .environmentObject(behaviorsStore)
}
