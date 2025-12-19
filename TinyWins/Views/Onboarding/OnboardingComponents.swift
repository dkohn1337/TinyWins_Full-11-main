import SwiftUI

// MARK: - Onboarding Flow View (Multi-step)

struct OnboardingFlowView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var contentViewModel: ContentViewModel
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @State private var currentStep: OnboardingStep = .welcome
    @State private var newChild: Child?
    @State private var newReward: Reward?
    @State private var selectedBehaviors: Set<UUID> = []
    @State private var authService: (any AuthService)?

    enum OnboardingStep {
        case welcome
        case signIn  // New step for Firebase mode
        case addChild
        case createGoal
        case selectBehaviors
        case summary
    }

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .welcome:
                    welcomeStep
                case .signIn:
                    signInStep
                case .addChild:
                    addChildStep
                case .createGoal:
                    if let child = newChild {
                        createGoalStep(for: child)
                    }
                case .selectBehaviors:
                    if let child = newChild {
                        selectBehaviorsStep(for: child)
                    }
                case .summary:
                    if let child = newChild {
                        OnboardingSummaryView(
                            child: child,
                            reward: newReward,
                            onComplete: {
                                // Set the newly created child as the selected child for Today screen
                                UserDefaults.standard.set(child.id.uuidString, forKey: "today_selected_child_id")
                                // Mark onboarding complete
                                contentViewModel.completeOnboarding()
                            },
                            onEditChild: {
                                // Go back to edit child
                                withAnimation {
                                    currentStep = .addChild
                                }
                            },
                            onEditGoal: {
                                // Go back to edit goal
                                withAnimation {
                                    currentStep = .createGoal
                                }
                            },
                            onBack: {
                                // Go back to behaviors step
                                withAnimation {
                                    currentStep = .selectBehaviors
                                }
                            }
                        )
                    }
                }
            }
            // Force view recreation when step changes to reset scroll position
            .id(currentStep)
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Hero star illustration
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .shadow(color: .orange.opacity(0.4), radius: 20)

                    Image(systemName: "star.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                VStack(spacing: 12) {
                    Text("Welcome to Tiny Wins")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Notice the good in your child and watch small moments become big progress.")
                        .font(.title3)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                // Features with icon, title, and subtitle
                VStack(alignment: .leading, spacing: 20) {
                    OnboardingFeatureCard(
                        icon: "hand.thumbsup.fill",
                        color: .green,
                        title: "Catch the good stuff",
                        subtitle: "A kind word, a shared laugh, a task done without asking."
                    )

                    OnboardingFeatureCard(
                        icon: "gift.fill",
                        color: .purple,
                        title: "Set simple goals together",
                        subtitle: "Stars add up to rewards that feel earned, not expected."
                    )

                    OnboardingFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue,
                        title: "See progress over time",
                        subtitle: "Patterns emerge. Confidence grows. You will both feel it."
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 16)

                // Privacy reassurance
                Text("Everything stays private to your family.")
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)

                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            // If Firebase is enabled, show sign-in step first
                            if AppConfiguration.isFirebaseEnabled {
                                currentStep = .signIn
                            } else {
                                currentStep = .addChild
                            }
                        }
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Text("Setup takes about a minute.")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            // Initialize auth service for Firebase mode
            if AppConfiguration.isFirebaseEnabled {
                authService = AppConfiguration.createAuthService()
            }
        }
    }

    // MARK: - Sign In Step (Firebase mode only)

    private var signInStep: some View {
        OnboardingSignInView(
            authService: authService ?? LocalAuthService(),
            onSignedIn: { user in
                #if DEBUG
                print("[Onboarding] User signed in: \(user.id)")
                #endif
                withAnimation { currentStep = .addChild }
            },
            onSkip: {
                #if DEBUG
                print("[Onboarding] User skipped sign-in")
                #endif
                withAnimation { currentStep = .addChild }
            }
        )
    }

    // MARK: - Add Child Step

    private var addChildStep: some View {
        AddChildOnboardingView(
            onComplete: { child in
                // If editing existing child, update instead of add
                if let existingChild = newChild {
                    // Create new child with existing ID
                    let updatedChild = Child(
                        id: existingChild.id,
                        name: child.name,
                        age: child.age,
                        colorTag: child.colorTag,
                        activeRewardId: existingChild.activeRewardId,
                        totalPoints: existingChild.totalPoints
                    )
                    childrenStore.updateChild(updatedChild)
                    newChild = updatedChild
                } else {
                    newChild = child
                    childrenStore.addChild(child)
                }
                withAnimation { currentStep = .createGoal }
            },
            onBack: AppConfiguration.isFirebaseEnabled ? {
                withAnimation { currentStep = .signIn }
            } : {
                withAnimation { currentStep = .welcome }
            },
            existingChild: newChild
        )
    }

    // MARK: - Create Goal Step

    private func createGoalStep(for child: Child) -> some View {
        CreateFirstGoalView(
            child: child,
            onComplete: { reward in
                // If editing existing reward, update instead of add
                if let existingReward = newReward, let reward = reward {
                    // Create new reward with existing ID
                    let updatedReward = Reward(
                        id: existingReward.id,
                        childId: child.id,
                        name: reward.name,
                        targetPoints: reward.targetPoints,
                        imageName: reward.imageName,
                        isRedeemed: existingReward.isRedeemed,
                        createdDate: existingReward.createdDate,
                        dueDate: reward.dueDate
                    )
                    rewardsStore.updateReward(updatedReward)
                    newReward = updatedReward
                } else if let reward = reward {
                    rewardsStore.addReward(reward)
                    newReward = reward
                }
                withAnimation { currentStep = .selectBehaviors }
            },
            onBack: {
                withAnimation { currentStep = .addChild }
            },
            existingReward: newReward
        )
    }

    // MARK: - Select Behaviors Step

    private func selectBehaviorsStep(for child: Child) -> some View {
        SelectBehaviorsOnboardingView(
            child: child,
            onComplete: {
                withAnimation { currentStep = .summary }
            },
            onBack: {
                withAnimation { currentStep = .createGoal }
            }
        )
    }
}

// MARK: - Onboarding Progress Bar

/// Consistent progress bar used across all onboarding steps
struct OnboardingProgressBar: View {
    @Environment(\.theme) private var theme
    let currentStep: Int // 0-indexed: 0=Child, 1=Goal, 2=Behaviors, 3=Done
    let steps = ["Child", "Goal", "Behaviors", "Done"]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep ? Color.accentColor : Theme().borderStrong)
                        .frame(height: 4)
                }
            }

            HStack(spacing: 8) {
                ForEach(steps, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Onboarding Feature Card (with title and subtitle)

struct OnboardingFeatureCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Onboarding Feature Row (simple version for other uses)

struct OnboardingFeatureRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Add Child Onboarding View

struct AddChildOnboardingView: View {
    @Environment(\.theme) private var theme
    let onComplete: (Child) -> Void
    var onBack: (() -> Void)?
    var existingChild: Child?

    @State private var name: String = ""
    @State private var selectedAge: Int? = nil
    @State private var selectedColor: ColorTag = .blue
    @State private var showingAgePicker = false
    @FocusState private var isNameFocused: Bool

    // Age options for the picker
    private let ageOptions: [Int?] = [nil] + Array(1...17).map { Optional($0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress indicator
                OnboardingProgressBar(currentStep: 0)

                Text("Add your first child")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Who are you cheering on?")
                    .font(.body)
                    .foregroundColor(theme.textSecondary)

                Text("You can update this anytime. Everything stays private on your device.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                // Form card with avatar and fields
                VStack(spacing: 20) {
                    // Preview avatar with animation
                    ZStack {
                        Circle()
                            .fill(selectedColor.color)
                            .frame(width: 100, height: 100)
                            .shadow(color: selectedColor.color.opacity(0.4), radius: 8, y: 4)

                        if name.isEmpty {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text(String(name.prefix(2)).uppercased())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                    .padding(.top, 8)

                    // Divider
                    Rectangle()
                        .fill(theme.borderSoft)
                        .frame(height: 1)
                        .padding(.horizontal)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)

                        TextField("First name or nickname", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .textInputAutocapitalization(.words)
                            .focused($isNameFocused)
                            .onChange(of: name) { _, newValue in
                                // Sanitize: only allow letters, spaces, hyphens, apostrophes
                                let sanitized = newValue.filter { char in
                                    char.isLetter || char == " " || char == "-" || char == "'"
                                }
                                // Limit to 20 characters
                                let limited = String(sanitized.prefix(20))
                                if limited != newValue {
                                    name = limited
                                }
                            }

                        // Character count
                        HStack {
                            Spacer()
                            Text("\(name.count)/20")
                                .font(.caption2)
                                .foregroundColor(name.count >= 18 ? .orange : theme.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // Age picker field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age (optional)")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)

                        Button {
                            isNameFocused = false
                            showingAgePicker = true
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            HStack {
                                Text(ageDisplayText)
                                    .foregroundColor(selectedAge == nil ? theme.textSecondary : theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding()
                            .background(theme.surface1)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.borderStrong, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)

                        // Two rows of colors, centered
                        let selectableColors = ColorTag.selectableColors
                        VStack(spacing: 16) {
                            HStack(spacing: 20) {
                                ForEach(Array(selectableColors.prefix(4)), id: \.self) { color in
                                    colorCircle(for: color)
                                }
                            }
                            HStack(spacing: 20) {
                                ForEach(Array(selectableColors.suffix(4)), id: \.self) { color in
                                    colorCircle(for: color)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)  // Center the color grid

                        // Selected color name with checkmark
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(selectedColor.color)
                            Text("\(selectedColor.displayName) selected")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .padding(.vertical, 16)
                .background(theme.surface1)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button(action: {
                    let child = Child(
                        name: name.trimmingCharacters(in: .whitespaces),
                        age: selectedAge,
                        colorTag: selectedColor
                    )
                    onComplete(child)
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty ? theme.borderStrong : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(name.isEmpty)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(theme.bg1)
            }
        }
        .background(theme.bg1)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if onBack != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onBack?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAgePicker) {
            AgePickerSheet(selectedAge: $selectedAge, ageOptions: ageOptions)
                .presentationDetents([.height(300)])
        }
        .onAppear {
            // Initialize from existing child if editing
            if let child = existingChild {
                name = child.name
                selectedAge = child.age
                selectedColor = child.colorTag
            }
            // Autofocus the name field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }

    private var ageDisplayText: String {
        guard let age = selectedAge else {
            return "Select age"
        }
        return age == 1 ? "1 year" : "\(age) years"
    }

    @ViewBuilder
    private func colorCircle(for color: ColorTag) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedColor = color
            }
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 48, height: 48)

                // Checkmark for selected color
                if selectedColor == color {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(theme.textPrimary.opacity(0.3), lineWidth: selectedColor == color ? 3 : 0)
                    .padding(-2)
            )
            .scaleEffect(selectedColor == color ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.displayName) color")
        .accessibilityHint(selectedColor == color ? "Selected" : "Double tap to select")
        .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
    }
}

// MARK: - Age Picker Sheet

struct AgePickerSheet: View {
    @Environment(\.theme) private var theme
    @Binding var selectedAge: Int?
    let ageOptions: [Int?]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Age", selection: $selectedAge) {
                    Text("Not specified").tag(nil as Int?)
                    ForEach(1..<18, id: \.self) { age in
                        Text(age == 1 ? "1 year" : "\(age) years").tag(age as Int?)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 200)
            }
            .navigationTitle("Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Create First Goal View

struct CreateFirstGoalView: View {
    @Environment(\.theme) private var theme
    let child: Child
    let onComplete: (Reward?) -> Void
    var onBack: (() -> Void)?
    var existingReward: Reward?

    @State private var selectedSuggestion: GoalSuggestion?
    @State private var customName: String = ""
    @State private var customStars: Int = 15
    @State private var customDays: Int = 7
    @State private var showingCustom = false
    @FocusState private var isCustomNameFocused: Bool

    // Goal categories for better organization
    private enum GoalCategory: String, CaseIterable {
        case quickWin = "Quick Wins"
        case weekly = "This Week"
        case bigger = "Bigger Goals"

        var subtitle: String {
            switch self {
            case .quickWin: return "2-4 days"
            case .weekly: return "5-7 days"
            case .bigger: return "10-14 days"
            }
        }

        var icon: String {
            switch self {
            case .quickWin: return "bolt.fill"
            case .weekly: return "calendar"
            case .bigger: return "trophy.fill"
            }
        }

        var color: Color {
            switch self {
            case .quickWin: return .green
            case .weekly: return .blue
            case .bigger: return .purple
            }
        }
    }

    // Categorized goal suggestions
    private var categorizedSuggestions: [(category: GoalCategory, goals: [GoalSuggestion])] {
        let age = child.age ?? 7

        // Toddlers & Preschoolers (2-5 years)
        if age <= 5 {
            return [
                (.quickWin, [
                    GoalSuggestion(name: "Sticker Surprise", icon: "star.circle.fill", stars: 5, days: 2),
                    GoalSuggestion(name: "Ice Cream Treat", icon: "cup.and.saucer.fill", stars: 8, days: 3),
                ]),
                (.weekly, [
                    GoalSuggestion(name: "Park Playdate", icon: "leaf.fill", stars: 12, days: 5),
                    GoalSuggestion(name: "Movie Night", icon: "tv.fill", stars: 15, days: 7),
                ]),
                (.bigger, [
                    GoalSuggestion(name: "New Toy Adventure", icon: "teddybear.fill", stars: 20, days: 10),
                ]),
            ]
        }
        // Early Elementary (6-8 years)
        else if age <= 8 {
            return [
                (.quickWin, [
                    GoalSuggestion(name: "Dessert Pick", icon: "birthday.cake.fill", stars: 8, days: 3),
                    GoalSuggestion(name: "Extra Screen Time", icon: "gamecontroller.fill", stars: 10, days: 3),
                ]),
                (.weekly, [
                    GoalSuggestion(name: "Pizza Night", icon: "fork.knife", stars: 15, days: 5),
                    GoalSuggestion(name: "Movie Choice", icon: "film.fill", stars: 18, days: 7),
                ]),
                (.bigger, [
                    GoalSuggestion(name: "Friend Playdate", icon: "person.2.fill", stars: 25, days: 10),
                ]),
            ]
        }
        // Late Elementary (9-11 years)
        else if age <= 11 {
            return [
                (.quickWin, [
                    GoalSuggestion(name: "Favorite Snack Run", icon: "cart.fill", stars: 10, days: 3),
                    GoalSuggestion(name: "Game Time Bonus", icon: "gamecontroller.fill", stars: 12, days: 4),
                ]),
                (.weekly, [
                    GoalSuggestion(name: "Outing of Choice", icon: "ticket.fill", stars: 20, days: 7),
                    GoalSuggestion(name: "Sleepover Night", icon: "moon.stars.fill", stars: 25, days: 7),
                ]),
                (.bigger, [
                    GoalSuggestion(name: "Special Purchase", icon: "bag.fill", stars: 35, days: 14),
                ]),
            ]
        }
        // Tweens & Teens (12+)
        else {
            return [
                (.quickWin, [
                    GoalSuggestion(name: "Skip a Chore", icon: "checkmark.circle.fill", stars: 10, days: 3),
                    GoalSuggestion(name: "Later Bedtime", icon: "moon.fill", stars: 12, days: 4),
                ]),
                (.weekly, [
                    GoalSuggestion(name: "Movie & Snacks", icon: "popcorn.fill", stars: 18, days: 5),
                    GoalSuggestion(name: "Friend Hangout", icon: "person.2.fill", stars: 20, days: 7),
                ]),
                (.bigger, [
                    GoalSuggestion(name: "Shopping Trip", icon: "bag.fill", stars: 40, days: 14),
                ]),
            ]
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            OnboardingProgressBar(currentStep: 1)

            // Header
            VStack(spacing: 6) {
                Text("Pick a goal for \(child.name)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Here are some ideas to get you started")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }

            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Recommended badge for first goal
                        if selectedSuggestion == nil && !showingCustom {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("Quick wins help build momentum early on")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Categorized goals
                        ForEach(categorizedSuggestions, id: \.category.rawValue) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            // Section header
                            HStack(spacing: 8) {
                                Image(systemName: section.category.icon)
                                    .font(.caption)
                                    .foregroundColor(section.category.color)

                                Text(section.category.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.textPrimary)

                                Text("• \(section.category.subtitle)")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)

                                Spacer()
                            }
                            .padding(.leading, 4)

                            // Goals in this category
                            ForEach(section.goals) { suggestion in
                                GoalSuggestionCard(
                                    suggestion: suggestion,
                                    isSelected: selectedSuggestion?.id == suggestion.id,
                                    childColor: child.colorTag.color,
                                    categoryColor: section.category.color
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedSuggestion = suggestion
                                        showingCustom = false
                                    }
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }
                    }

                    // Divider before custom
                    HStack {
                        Rectangle()
                            .fill(theme.borderStrong)
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(theme.borderStrong)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    // Custom goal option
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingCustom.toggle()
                                if showingCustom {
                                    selectedSuggestion = nil
                                    // Scroll to custom section after animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scrollProxy.scrollTo("customGoalSection", anchor: .top)
                                        }
                                    }
                                    // Focus the text field after scroll
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        isCustomNameFocused = true
                                    }
                                }
                            }
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(child.colorTag.color.opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: showingCustom ? "pencil" : "plus")
                                        .font(.title3)
                                        .foregroundColor(child.colorTag.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create your own")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(theme.textPrimary)
                                    Text("Something special for \(child.name)")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: showingCustom ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(showingCustom ? child.colorTag.color.opacity(0.08) : theme.surface1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showingCustom ? child.colorTag.color : theme.borderStrong, lineWidth: showingCustom ? 2 : 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Custom goal fields (expanded)
                        if showingCustom {
                            VStack(spacing: 16) {
                                // Goal name
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("What's the reward?")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)

                                    TextField("e.g., Trip to the zoo", text: $customName)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isCustomNameFocused)
                                }

                                // Stars to earn with goal size presets
                                GoalSizeSelector(
                                    starCount: $customStars,
                                    childColor: child.colorTag.color,
                                    showPresets: true,
                                    showHelperText: true
                                )

                                // Timeframe selector with warm labels
                                TimeframeSelector(
                                    days: $customDays,
                                    childColor: child.colorTag.color,
                                    showHelperText: true
                                )
                            }
                            .padding()
                            .background(theme.surface2)
                            .cornerRadius(12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .id("customGoalSection")
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }

            // Bottom section
            VStack(spacing: 12) {
                // Skip option
                Button {
                    onComplete(nil)
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 4)

                // Continue button
                Button {
                    // Haptic on confirm
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)

                    if let suggestion = selectedSuggestion {
                        let deadline = Calendar.current.date(byAdding: .day, value: suggestion.days, to: Date())
                        let reward = Reward(
                            childId: child.id,
                            name: suggestion.name,
                            targetPoints: suggestion.stars,
                            imageName: suggestion.icon,
                            dueDate: deadline
                        )
                        onComplete(reward)
                    } else if showingCustom && !customName.isEmpty {
                        let deadline = Calendar.current.date(byAdding: .day, value: customDays, to: Date())
                        let reward = Reward(
                            childId: child.id,
                            name: customName,
                            targetPoints: customStars,
                            imageName: "gift.fill",
                            dueDate: deadline
                        )
                        onComplete(reward)
                    }
                    // Note: Button is disabled when no goal selected, so users must use "Skip for now"
                } label: {
                    HStack(spacing: 8) {
                        if selectedSuggestion != nil || (showingCustom && !customName.isEmpty) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                        }
                        Text(selectedSuggestion != nil || (showingCustom && !customName.isEmpty) ? "Set This Goal" : "Continue")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((selectedSuggestion != nil || (showingCustom && !customName.isEmpty)) ? Color.accentColor : theme.borderStrong)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(selectedSuggestion == nil && (!showingCustom || customName.isEmpty))
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if onBack != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onBack?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Goal Suggestion

struct GoalSuggestion: Identifiable, Equatable {
    let id: String  // Use stable string ID instead of UUID to prevent re-renders
    let name: String
    let icon: String
    let stars: Int
    let days: Int

    init(name: String, icon: String, stars: Int, days: Int) {
        // Create stable ID from content
        self.id = "\(name)-\(stars)-\(days)"
        self.name = name
        self.icon = icon
        self.stars = stars
        self.days = days
    }
}

struct GoalSuggestionCard: View {
    @Environment(\.theme) private var theme
    let suggestion: GoalSuggestion
    let isSelected: Bool
    let childColor: Color
    var categoryColor: Color = .gray
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                // Icon with category color accent
                ZStack {
                    Circle()
                        .fill(childColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: suggestion.icon)
                        .font(.system(size: 20))
                        .foregroundColor(childColor)
                }

                // Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        // Stars badge
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("\(suggestion.stars)")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(theme.textSecondary)

                        // Days badge
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(suggestion.days)d")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? childColor : theme.borderStrong)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? childColor.opacity(0.08) : theme.surface1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? childColor : theme.borderStrong, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(suggestion.name), \(suggestion.stars) stars, \(suggestion.days) days")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select this goal")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Custom button style with scale animation for better feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Select Behaviors Onboarding

struct SelectBehaviorsOnboardingView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    let child: Child
    let onComplete: () -> Void
    var onBack: (() -> Void)?

    @State private var selectedBehaviors: Set<UUID> = []

    // Suggested behaviors for quick selection
    private var suggestedBehaviors: [BehaviorType] {
        behaviorsStore.suggestedBehaviors(forChild: child, category: .positive)
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            OnboardingProgressBar(currentStep: 2)

            VStack(spacing: 8) {
                Text("What positive moments will you notice?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tap to log these moments and your child earns stars toward their goal.")
                    .font(.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(suggestedBehaviors) { behavior in
                        BehaviorChip(
                            behavior: behavior,
                            isSelected: selectedBehaviors.contains(behavior.id)
                        ) {
                            if selectedBehaviors.contains(behavior.id) {
                                selectedBehaviors.remove(behavior.id)
                            } else {
                                selectedBehaviors.insert(behavior.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Text("Start with a few. You can add or change these later.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            Button(action: {
                // Activate selected behaviors
                for behaviorId in selectedBehaviors {
                    if var behavior = behaviorsStore.behaviorTypes.first(where: { $0.id == behaviorId }) {
                        behavior.isActive = true
                        behaviorsStore.updateBehaviorType(behavior)
                    }
                }
                onComplete()
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if onBack != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onBack?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .onAppear {
            // Pre-select a few behaviors by default (first 3)
            let defaultSelection = suggestedBehaviors.prefix(3).map { $0.id }
            selectedBehaviors = Set(defaultSelection)
        }
    }
}

struct BehaviorChip: View {
    @Environment(\.theme) private var theme
    let behavior: BehaviorType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: behavior.iconName)
                    .font(.subheadline)

                Text(behavior.name)
                    .font(.caption)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44) // Accessibility: minimum tap target
            .background(isSelected ? AppColors.positive.opacity(0.15) : theme.surface2)
            .foregroundColor(isSelected ? AppColors.positive : theme.textPrimary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? AppColors.positive : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(behavior.name). \(isSelected ? "Selected" : "Not selected")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }
}

// MARK: - Onboarding Summary View

struct OnboardingSummaryView: View {
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var notificationService: NotificationService
    @Environment(\.theme) private var theme
    let child: Child
    let reward: Reward?
    let onComplete: () -> Void
    var onEditChild: (() -> Void)?
    var onEditGoal: (() -> Void)?
    var onBack: (() -> Void)?

    @State private var notificationsRequested = false

    // Get top behaviors from the active behavior types
    private var topBehaviors: [BehaviorType] {
        behaviorsStore.behaviorTypes
            .filter { $0.isActive && $0.category == .positive }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Progress indicator - all complete
            OnboardingProgressBar(currentStep: 3)

            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Here is your plan with \(child.name).")
                    .font(.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }

            // Summary card
            VStack(spacing: 16) {
                // Child info - tappable to edit
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onEditChild?()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(child.colorTag.color)
                                .frame(width: 50, height: 50)

                            Text(String(child.name.prefix(2)).uppercased())
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.name)
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)

                            if let age = child.age {
                                Text("\(age) years old")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }

                        Spacer()

                        if onEditChild != nil {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.textSecondary.opacity(0.5))
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(onEditChild == nil)

                Divider()

                // Goal info - tappable to edit
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onEditGoal?()
                } label: {
                    if let reward = reward {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: reward.imageName ?? "gift.fill")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Goal: \(reward.name)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textPrimary)

                                if let dueDate = reward.dueDate {
                                    let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
                                    Text("\(reward.targetPoints) stars in \(max(1, days)) days")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                } else {
                                    Text("\(reward.targetPoints) stars")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                            }

                            Spacer()

                            if onEditGoal != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.textSecondary.opacity(0.5))
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "gift.fill")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }

                            Text("Tap to add a goal")
                                .font(.subheadline)
                                .foregroundColor(theme.accentPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            if onEditGoal != nil {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.accentPrimary.opacity(0.7))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(onEditGoal == nil)

                Divider()

                // Behaviors
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(child.name) earns stars for:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(topBehaviors) { behavior in
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)

                                Text(behavior.name)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(theme.surface1)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10)
            .padding(.horizontal)

            Spacer()

            // Notification permission prompt (only show if not yet requested)
            if !notificationService.hasRequestedPermission && !notificationsRequested {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Get a daily reminder")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("A gentle nudge to notice something good.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button(action: requestNotifications) {
                            Text("Enable")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            // Helper text
            Text("You can change any of this later in Settings.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            Button {
                // Haptic feedback for completion
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                onComplete()
            } label: {
                Text("Start noticing")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 32)
        }
        .background(theme.bg1)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if onBack != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onBack?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }

    private func requestNotifications() {
        notificationsRequested = true
        notificationService.requestAuthorization { _ in }
    }
}

// MARK: - Goal Prompt Sheet (shown after recording moments without a goal)

struct GoalPromptSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    let child: Child

    @State private var showingCreateGoal = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Illustration
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                }

                VStack(spacing: 12) {
                    Text("Turn these stars into something special")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)

                    Text("You've been catching great moments for \(child.name). Pick a reward so those stars feel even more meaningful!")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: { showingCreateGoal = true }) {
                        Text("Pick a Goal")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button(action: { dismiss() }) {
                        Text("Maybe later")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showingCreateGoal) {
                AddRewardView(child: child)
                    .onDisappear { dismiss() }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    let dependencies = DependencyContainer()
    OnboardingFlowView()
        .environmentObject(dependencies.contentViewModel)
        .environmentObject(dependencies.childrenStore)
        .environmentObject(dependencies.behaviorsStore)
        .environmentObject(dependencies.rewardsStore)
}

#Preview("Add Child") {
    AddChildOnboardingView { child in
        print("Created: \(child.name)")
    }
}
