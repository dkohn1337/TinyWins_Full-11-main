import SwiftUI

struct AddEditChildView: View {
    @Environment(\.dismiss) private var dismiss
    
    enum Mode {
        case add
        case edit(Child)
        
        var title: String {
            switch self {
            case .add: return "Add Child"
            case .edit: return "Edit Child"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .add: return "Add"
            case .edit: return "Save"
            }
        }
    }
    
    let mode: Mode
    let onSave: (Child) -> Void
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedColor: ColorTag = .blue
    
    private var existingChild: Child? {
        if case .edit(let child) = mode {
            return child
        }
        return nil
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Age (optional)", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section("Color") {
                    colorPicker
                }
                
                Section {
                    // Preview
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Circle()
                                .fill(selectedColor.color)
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text(previewInitials)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            
                            Text(name.isEmpty ? "Child Name" : name)
                                .font(.headline)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.buttonTitle) {
                        saveChild()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let child = existingChild {
                    name = child.name
                    age = child.age.map { String($0) } ?? ""
                    selectedColor = child.colorTag
                }
            }
        }
    }
    
    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            ForEach(ColorTag.allCases) { color in
                Button(action: { selectedColor = color }) {
                    Circle()
                        .fill(color.color)
                        .frame(width: 44, height: 44)
                        .overlay {
                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(color.rawValue.capitalized) color")
                .accessibilityHint(selectedColor == color ? "Selected" : "Double tap to select")
                .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color picker")
    }
    
    private var previewInitials: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "?"
        }
        let components = trimmedName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(trimmedName.prefix(2)).uppercased()
    }
    
    private func saveChild() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let parsedAge = Int(age)
        
        let child: Child
        if let existing = existingChild {
            child = Child(
                id: existing.id,
                name: trimmedName,
                age: parsedAge,
                colorTag: selectedColor,
                activeRewardId: existing.activeRewardId,
                totalPoints: existing.totalPoints
            )
        } else {
            child = Child(
                name: trimmedName,
                age: parsedAge,
                colorTag: selectedColor
            )
        }
        
        onSave(child)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add") {
    AddEditChildView(mode: .add) { _ in }
}

#Preview("Edit") {
    AddEditChildView(mode: .edit(Child(name: "Emma", age: 8, colorTag: .purple))) { _ in }
}
