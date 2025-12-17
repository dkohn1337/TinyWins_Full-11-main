import SwiftUI

// MARK: - Enhanced Add Reward Components
// Visual, delightful reward creation experience

// MARK: - Reward Category Selector

/// Step 1: Category selection with visual cards
struct RewardCategorySelector: View {
    @Binding var selectedCategory: RewardCategory?

    struct RewardCategory: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let emoji: String
        let color: Color
        let examples: [String]

        static func == (lhs: RewardCategory, rhs: RewardCategory) -> Bool {
            lhs.id == rhs.id
        }
    }

    static let defaultCategories: [RewardCategory] = [
        .init(name: "Treats", emoji: "🍦", color: .pink, examples: ["Ice cream", "Candy", "Special snack"]),
        .init(name: "Activities", emoji: "🎨", color: .purple, examples: ["Park trip", "Movie", "Game time"]),
        .init(name: "Privileges", emoji: "⭐", color: .blue, examples: ["Stay up late", "Pick dinner", "Screen time"]),
        .init(name: "Toys", emoji: "🎁", color: .green, examples: ["New toy", "Book", "Game"]),
        .init(name: "Experiences", emoji: "🎪", color: .orange, examples: ["Zoo", "Museum", "Adventure"])
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("What kind of reward?")
                    .font(.system(size: 28, weight: .bold))

                Text("Choose a category to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            // Category grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Self.defaultCategories) { category in
                    RewardCategoryCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
        }
        .padding(20)
    }
}

/// Individual category card
struct RewardCategoryCard: View {
    let category: RewardCategorySelector.RewardCategory
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Emoji with background
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [category.color.opacity(0.3), category.color.opacity(0.1)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)

                    Text(category.emoji)
                        .font(.system(size: 44))
                }

                // Name
                Text(category.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                // Examples
                Text(category.examples.joined(separator: ", "))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color.opacity(0.15) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                isSelected ? category.color : Color(.systemGray5),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                    .shadow(color: isSelected ? category.color.opacity(0.2) : .black.opacity(0.06), radius: isSelected ? 12 : 8, y: isSelected ? 6 : 4)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Emoji Picker

/// Large visual emoji picker for reward icon
struct RewardEmojiPicker: View {
    @Binding var selectedEmoji: String
    let categoryColor: Color
    @State private var showFullPicker = false

    private let popularEmojis = [
        "🍦", "🎮", "📱", "🎬", "🎁", "🧸", "🎨", "⚽",
        "🎪", "🏊", "🎢", "🍕", "🎂", "🌟", "👑", "🎵",
        "📚", "🚲", "🎯", "🏆", "💎", "🌈", "🎈", "🍿"
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Selected emoji display
            Button(action: { showFullPicker = true }) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [categoryColor.opacity(0.4), categoryColor.opacity(0.1)],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)

                    Text(selectedEmoji)
                        .font(.system(size: 88))

                    // Edit badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(categoryColor)
                                    .frame(width: 40, height: 40)

                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -10, y: -10)
                        }
                    }
                    .frame(width: 160, height: 160)
                }
            }
            .buttonStyle(.plain)

            Text("Tap to change icon")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // Quick emoji grid
            VStack(spacing: 12) {
                Text("Popular choices")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                    ForEach(popularEmojis, id: \.self) { emoji in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedEmoji = emoji
                            }
                            HapticManager.shared.light()
                        }) {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? categoryColor.opacity(0.2) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Reward Name Input

/// Styled text input for reward name
struct RewardNameInput: View {
    @Binding var name: String
    let categoryColor: Color
    let placeholder: String

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reward name")
                .font(.system(size: 18, weight: .semibold))

            TextField(placeholder, text: $name)
                .font(.system(size: 22, weight: .semibold))
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(isFocused ? categoryColor : Color.clear, lineWidth: 2)
                        )
                )
                .focused($isFocused)

            if !name.isEmpty {
                Text("\(name.count)/50 characters")
                    .font(.system(size: 12))
                    .foregroundColor(name.count > 40 ? .orange : .secondary)
            }
        }
    }
}

// MARK: - Star Count Selector (Visual)

/// Visual star count selector with goal size categories
/// Uses GoalSizeSelector from GoalSizeHelper for consistent UI across the app
struct RewardStarSelector: View {
    @Binding var starCount: Int
    let childColor: Color

    var body: some View {
        VStack(spacing: 16) {
            Text("How many stars to earn it?")
                .font(.system(size: 18, weight: .semibold))

            // Use the shared GoalSizeSelector for consistency
            GoalSizeSelector(
                starCount: $starCount,
                childColor: childColor,
                showPresets: true,
                showHelperText: true
            )

            // Timeframe hint
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Typical: \(GoalSizeCategory.from(stars: starCount).timeframeHint)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Reward Preview Card

/// Live preview of the reward being created
struct RewardPreviewCard: View {
    let emoji: String
    let name: String
    let starCount: Int
    let categoryColor: Color

    var body: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                                center: .center,
                                startRadius: 15,
                                endRadius: 40
                            )
                        )
                        .frame(width: 72, height: 72)

                    Text(emoji)
                        .font(.system(size: 40))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(name.isEmpty ? "Reward Name" : name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(name.isEmpty ? .secondary : .primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        Text("\(starCount) stars to earn")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
            )
        }
    }
}

// MARK: - Deadline Selector (Optional)

/// Optional deadline picker with visual calendar
struct RewardDeadlineSelector: View {
    @Binding var deadline: Date?
    @Binding var hasDeadline: Bool
    let childColor: Color

    private let quickOptions: [(String, Int)] = [
        ("1 week", 7),
        ("2 weeks", 14),
        ("1 month", 30),
        ("Custom", 0)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set a deadline?")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Optional: adds urgency and excitement")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $hasDeadline)
                    .tint(childColor)
            }

            if hasDeadline {
                // Quick options
                HStack(spacing: 10) {
                    ForEach(quickOptions, id: \.1) { option in
                        Button(action: {
                            if option.1 > 0 {
                                deadline = Calendar.current.date(byAdding: .day, value: option.1, to: Date())
                            }
                            HapticManager.shared.selection()
                        }) {
                            Text(option.0)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isSelected(days: option.1) ? .white : childColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(isSelected(days: option.1) ? childColor : childColor.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Date display
                if let deadline = deadline {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(childColor)
                        Text("Due: \(formattedDate(deadline))")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Text(daysRemaining(until: deadline))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(childColor.opacity(0.08))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    private func isSelected(days: Int) -> Bool {
        guard let deadline = deadline else { return false }
        let targetDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
        return Calendar.current.isDate(deadline, inSameDayAs: targetDate ?? Date())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func daysRemaining(until date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return "\(days) days"
    }
}

// MARK: - Complete Add Reward Form

/// Assembled add reward form with all steps
struct EnhancedAddRewardForm: View {
    let childName: String
    let childColor: Color
    @Binding var selectedCategory: RewardCategorySelector.RewardCategory?
    @Binding var selectedEmoji: String
    @Binding var rewardName: String
    @Binding var starCount: Int
    @Binding var deadline: Date?
    @Binding var hasDeadline: Bool
    let onSave: () -> Void

    private var isValid: Bool {
        selectedCategory != nil && !rewardName.isEmpty && starCount > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Emoji picker
                RewardEmojiPicker(
                    selectedEmoji: $selectedEmoji,
                    categoryColor: selectedCategory?.color ?? childColor
                )

                // Name input
                RewardNameInput(
                    name: $rewardName,
                    categoryColor: selectedCategory?.color ?? childColor,
                    placeholder: "e.g., Ice Cream Trip"
                )
                .padding(.horizontal, 20)

                // Star selector with goal size categories
                RewardStarSelector(
                    starCount: $starCount,
                    childColor: childColor
                )
                .padding(.horizontal, 20)

                // Deadline (optional)
                RewardDeadlineSelector(
                    deadline: $deadline,
                    hasDeadline: $hasDeadline,
                    childColor: childColor
                )
                .padding(.horizontal, 20)

                // Preview
                RewardPreviewCard(
                    emoji: selectedEmoji,
                    name: rewardName,
                    starCount: starCount,
                    categoryColor: selectedCategory?.color ?? childColor
                )
                .padding(.horizontal, 20)

                // Save button
                Button(action: onSave) {
                    Text("Create Goal for \(childName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            isValid ?
                                LinearGradient(colors: [childColor, childColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: isValid ? childColor.opacity(0.3) : .clear, radius: 12, y: 6)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Previews

#Preview("Category Selector") {
    RewardCategorySelector(selectedCategory: .constant(nil))
}

#Preview("Emoji Picker") {
    RewardEmojiPicker(selectedEmoji: .constant("🍦"), categoryColor: .purple)
        .padding()
}

#Preview("Star Selector") {
    RewardStarSelector(
        starCount: .constant(10),
        childColor: .blue
    )
    .padding()
}

#Preview("Preview Card") {
    RewardPreviewCard(
        emoji: "🍦",
        name: "Ice Cream Trip",
        starCount: 10,
        categoryColor: .pink
    )
    .padding()
}
