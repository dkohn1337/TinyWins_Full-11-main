import SwiftUI

// MARK: - Enhanced Goal Selection Components
// Gamified "reward store" experience for kid goal selection

// MARK: - Goal Store Header

/// Header for the goal selection screen with child context
struct GoalStoreHeader: View {
    let childName: String
    let childColor: Color
    let childEmoji: String

    var body: some View {
        VStack(spacing: 16) {
            // Child avatar with glow
            ZStack {
                Circle()
                    .fill(childColor.opacity(0.2))
                    .frame(width: 88, height: 88)
                    .blur(radius: 12)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [childColor, childColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(childEmoji)
                            .font(.system(size: 40))
                    )
                    .shadow(color: childColor.opacity(0.4), radius: 12)
            }

            VStack(spacing: 8) {
                Text("Choose \(childName)'s Next Goal")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Pick something exciting to work toward together")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Category Filter Pills

/// Horizontal scrolling category filters
struct GoalCategoryFilter: View {
    let categories: [GoalCategory]
    @Binding var selectedCategory: GoalCategory?

    struct GoalCategory: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color

        static func == (lhs: GoalCategory, rhs: GoalCategory) -> Bool {
            lhs.id == rhs.id
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All category
                CategoryPill(
                    name: "All",
                    icon: "square.grid.2x2.fill",
                    color: .purple,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                    HapticManager.shared.selection()
                }

                ForEach(categories) { category in
                    CategoryPill(
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

/// Individual category pill
struct CategoryPill: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.12))
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Store Card (Gamified)

/// Individual goal card with game-store styling
struct GoalStoreCard: View {
    let goal: GoalTemplate
    let childColor: Color
    let onSelect: () -> Void

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -100

    struct GoalTemplate: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let description: String
        let defaultStars: Int
        let difficulty: Difficulty
        let isPremium: Bool
        let category: String

        enum Difficulty: String {
            case easy = "Easy"
            case medium = "Medium"
            case challenging = "Challenging"
            case epic = "Epic"

            var color: Color {
                switch self {
                case .easy: return .green
                case .medium: return .blue
                case .challenging: return .orange
                case .epic: return .purple
                }
            }

            var stars: Int {
                switch self {
                case .easy: return 1
                case .medium: return 2
                case .challenging: return 3
                case .epic: return 4
                }
            }
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.medium()
            onSelect()
        }) {
            VStack(spacing: 12) {
                // Premium badge
                if goal.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("PREMIUM")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, -4)
                } else {
                    Spacer()
                        .frame(height: 20)
                }

                // Emoji/Icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [childColor.opacity(0.3), childColor.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)

                    Text(goal.emoji)
                        .font(.system(size: 52))
                        .shadow(color: childColor.opacity(0.3), radius: 8)
                }

                // Name
                Text(goal.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 44)

                // Stars required
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text("\(goal.defaultStars)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("stars")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Difficulty badge
                HStack(spacing: 4) {
                    ForEach(0..<goal.difficulty.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(goal.difficulty.color)
                    }
                    ForEach(0..<(4 - goal.difficulty.stars), id: \.self) { _ in
                        Image(systemName: "star")
                            .font(.system(size: 8))
                            .foregroundColor(Color(.systemGray4))
                    }

                    Text(goal.difficulty.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(goal.difficulty.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(goal.difficulty.color.opacity(0.12))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                goal.isPremium ?
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray5)], startPoint: .top, endPoint: .bottom),
                                lineWidth: goal.isPremium ? 2 : 1
                            )
                    )
                    .shadow(color: .black.opacity(isPressed ? 0.12 : 0.06), radius: isPressed ? 8 : 16, y: isPressed ? 4 : 8)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .overlay(
                // Shimmer for premium
                goal.isPremium ?
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.2), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 20))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false).delay(Double.random(in: 0...1))) {
                                shimmerOffset = 200
                            }
                        }
                    : nil
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Goal Detail Modal

/// Full-screen modal when a goal is selected
struct GoalDetailModal: View {
    let goal: GoalStoreCard.GoalTemplate
    let childName: String
    let childColor: Color
    @Binding var isPresented: Bool
    @State private var selectedStars: Int
    let onConfirm: (Int) -> Void

    @State private var pulseScale: CGFloat = 1.0

    private let starOptions = [5, 10, 15, 20, 25]

    init(goal: GoalStoreCard.GoalTemplate, childName: String, childColor: Color, isPresented: Binding<Bool>, onConfirm: @escaping (Int) -> Void) {
        self.goal = goal
        self.childName = childName
        self.childColor = childColor
        self._isPresented = isPresented
        self._selectedStars = State(initialValue: goal.defaultStars)
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }

            // Modal content
            VStack(spacing: 28) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }

                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [childColor.opacity(0.4), childColor.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)

                    Text(goal.emoji)
                        .font(.system(size: 88))
                        .scaleEffect(pulseScale)
                        .shadow(color: childColor.opacity(0.4), radius: 16)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.08
                    }
                }

                // Goal info
                VStack(spacing: 12) {
                    Text(goal.name)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(goal.description)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Star count selector
                VStack(spacing: 16) {
                    Text("How many stars to earn it?")
                        .font(.system(size: 18, weight: .semibold))

                    HStack(spacing: 12) {
                        ForEach(starOptions, id: \.self) { count in
                            StarCountButton(
                                count: count,
                                isSelected: selectedStars == count,
                                color: childColor
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedStars = count
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }

                    // Estimated time
                    Text(estimatedTimeText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // CTA Button
                Button(action: {
                    HapticManager.shared.success()
                    onConfirm(selectedStars)
                    isPresented = false
                }) {
                    Text("Start This Goal")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [childColor, childColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: childColor.opacity(0.4), radius: 16, y: 8)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var estimatedTimeText: String {
        let daysEstimate: String
        switch selectedStars {
        case 5: daysEstimate = "~2-3 days"
        case 10: daysEstimate = "~4-5 days"
        case 15: daysEstimate = "~1 week"
        case 20: daysEstimate = "~1-2 weeks"
        default: daysEstimate = "~2+ weeks"
        }
        return "At 2-3 stars/day, this takes \(daysEstimate)"
    }
}

/// Star count selection button
struct StarCountButton: View {
    let count: Int
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : color)

                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .yellow)
            }
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Goal Entry

/// Section for creating a custom goal
struct CustomGoalEntry: View {
    let childColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [childColor.opacity(0.2), childColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(childColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Custom Goal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Design your own unique reward")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(childColor.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [childColor.opacity(0.3), childColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2,
                                antialiased: true
                            )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Store Grid

/// Complete goal store grid layout
struct GoalStoreGrid: View {
    let goals: [GoalStoreCard.GoalTemplate]
    let childColor: Color
    let onSelect: (GoalStoreCard.GoalTemplate) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(goals) { goal in
                GoalStoreCard(
                    goal: goal,
                    childColor: childColor,
                    onSelect: { onSelect(goal) }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Goal Store Card") {
    let goal = GoalStoreCard.GoalTemplate(
        name: "Ice Cream Trip",
        emoji: "🍦",
        description: "A special trip to get ice cream together",
        defaultStars: 10,
        difficulty: .medium,
        isPremium: false,
        category: "Treats"
    )

    GoalStoreCard(
        goal: goal,
        childColor: .purple,
        onSelect: {}
    )
    .frame(width: 170)
    .padding()
}

#Preview("Premium Goal Card") {
    let goal = GoalStoreCard.GoalTemplate(
        name: "Theme Park Day",
        emoji: "🎢",
        description: "An exciting day at the theme park",
        defaultStars: 25,
        difficulty: .epic,
        isPremium: true,
        category: "Experiences"
    )

    GoalStoreCard(
        goal: goal,
        childColor: .blue,
        onSelect: {}
    )
    .frame(width: 170)
    .padding()
}

#Preview("Category Filter") {
    GoalCategoryFilter(
        categories: [
            .init(name: "Treats", icon: "birthday.cake.fill", color: .pink),
            .init(name: "Activities", icon: "figure.play", color: .blue),
            .init(name: "Toys", icon: "gift.fill", color: .green),
            .init(name: "Experiences", icon: "sparkles", color: .orange)
        ],
        selectedCategory: .constant(nil)
    )
    .padding(.vertical)
}
