import SwiftUI

// MARK: - Enhanced Onboarding Components
// Emotional, engaging first-time user experience

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let animation: OnboardingAnimation

    enum OnboardingAnimation {
        case pulse
        case float
        case glow
        case rotate
    }
}

// MARK: - Welcome Screen

/// First screen with emotional hook
struct OnboardingWelcomeScreen: View {
    let onContinue: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var buttonOpacity: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated illustration
            ZStack {
                // Glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.purple.opacity(0.1 - Double(index) * 0.03), lineWidth: 2)
                        .frame(width: CGFloat(200 + index * 60), height: CGFloat(200 + index * 60))
                        .scaleEffect(pulseScale)
                }

                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 20)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
            }

            Spacer()
                .frame(height: 48)

            // Text content
            VStack(spacing: 16) {
                Text("Small Moments.")
                    .font(.system(size: 36, weight: .bold))

                Text("Big Impact.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Transform your parenting with the power of attention")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
            .opacity(textOpacity)

            Spacer()

            // CTA Button
            Button(action: {
                HapticManager.shared.success()
                onContinue()
            }) {
                Text("Start Your Journey")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.4), radius: 20, y: 10)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(buttonOpacity)
        }
        .onAppear {
            // Animate in sequence
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                buttonOpacity = 1.0
            }

            // Continuous pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1.5)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Value Proposition Screen

/// Screen explaining the core value proposition
struct OnboardingValueScreen: View {
    let onContinue: () -> Void

    @State private var visibleItems: Set<Int> = []

    private let benefits = [
        ("eye.fill", "Notice more positive moments", Color.green),
        ("chart.line.uptrend.xyaxis.fill", "Track progress over time", Color.blue),
        ("gift.fill", "Celebrate achievements together", Color.purple),
        ("heart.fill", "Strengthen your connection", Color.pink)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("What You'll Discover")
                    .font(.system(size: 32, weight: .bold))

                Text("TinyWins helps you focus on what matters most")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 48)

            // Benefits list
            VStack(spacing: 20) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitRow(
                        icon: benefit.0,
                        text: benefit.1,
                        color: benefit.2,
                        isVisible: visibleItems.contains(index)
                    )
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.15)) {
                            visibleItems.insert(index)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA Button
            Button(action: {
                HapticManager.shared.medium()
                onContinue()
            }) {
                Text("Show Me How")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.4), radius: 20, y: 10)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

/// Individual benefit row
struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
                .opacity(isVisible ? 1 : 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -50)
    }
}

// MARK: - Interactive Demo Screen

/// Try-it-now screen for first moment
struct OnboardingDemoScreen: View {
    let onComplete: () -> Void

    @State private var hasLogged = false
    @State private var showCelebration = false
    @State private var momentText = ""
    @State private var showInput = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                if !hasLogged {
                    // Pre-log state
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.green.opacity(0.2), .green.opacity(0.05), .clear],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 160, height: 160)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.4), radius: 16)
                        }

                        VStack(spacing: 12) {
                            Text("Try It Now")
                                .font(.system(size: 32, weight: .bold))

                            Text("Think of one small positive moment from today. It can be anything.")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        // Quick options
                        VStack(spacing: 12) {
                            QuickMomentButton(text: "Smiled at me", emoji: "😊") {
                                logMoment("Smiled at me")
                            }
                            QuickMomentButton(text: "Said please", emoji: "🙏") {
                                logMoment("Said please")
                            }
                            QuickMomentButton(text: "Shared a toy", emoji: "🧸") {
                                logMoment("Shared a toy")
                            }
                            QuickMomentButton(text: "Gave a hug", emoji: "🤗") {
                                logMoment("Gave a hug")
                            }
                        }
                        .padding(.top, 16)
                    }
                } else {
                    // Post-log state
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.4), radius: 16)

                        VStack(spacing: 12) {
                            Text("That's It!")
                                .font(.system(size: 32, weight: .bold))

                            Text("You just changed your brain chemistry. Noticing the positive literally rewires how you see your child.")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                }

                Spacer()

                // Continue button (after logging)
                if hasLogged {
                    Button(action: {
                        HapticManager.shared.success()
                        onComplete()
                    }) {
                        Text("Continue to Setup")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.4), radius: 20, y: 10)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            // Celebration overlay
            if showCelebration {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
    }

    private func logMoment(_ text: String) {
        HapticManager.shared.success()

        // Show celebration
        withAnimation(.spring()) {
            showCelebration = true
        }

        // Transition to completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                hasLogged = true
                showCelebration = false
            }
        }
    }
}

/// Quick moment selection button
struct QuickMomentButton: View {
    let text: String
    let emoji: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 24))

                Text(text)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isPressed ? 0.12 : 0.06), radius: isPressed ? 6 : 10, y: isPressed ? 3 : 5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 32)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Add Child Screen

/// Screen for adding first child
struct OnboardingAddChildScreen: View {
    @Binding var childName: String
    @Binding var selectedColor: ChildColorTag
    @Binding var selectedEmoji: String
    let onContinue: () -> Void

    enum ChildColorTag: String, CaseIterable {
        case blue, purple, pink, green, orange, red

        var color: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .green: return .green
            case .orange: return .orange
            case .red: return .red
            }
        }
    }

    private let emojis = ["👦", "👧", "🧒", "👶", "🧒🏻", "👦🏽", "👧🏾", "🧒🏿"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Add Your Child")
                        .font(.system(size: 32, weight: .bold))

                    Text("Let's set up their profile")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // Avatar preview
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [selectedColor.color, selectedColor.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: selectedColor.color.opacity(0.4), radius: 16)

                    Text(selectedEmoji)
                        .font(.system(size: 64))
                }

                // Name input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Name")
                        .font(.system(size: 18, weight: .semibold))

                    TextField("Enter name", text: $childName)
                        .font(.system(size: 22, weight: .semibold))
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding(.horizontal, 32)

                // Emoji selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Avatar")
                        .font(.system(size: 18, weight: .semibold))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedEmoji = emoji
                                }
                                HapticManager.shared.light()
                            }) {
                                Text(emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 64, height: 64)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ? selectedColor.color.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(selectedEmoji == emoji ? selectedColor.color : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 32)

                // Color selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.system(size: 18, weight: .semibold))

                    HStack(spacing: 16) {
                        ForEach(ChildColorTag.allCases, id: \.self) { colorTag in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedColor = colorTag
                                }
                                HapticManager.shared.light()
                            }) {
                                Circle()
                                    .fill(colorTag.color)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: selectedColor == colorTag ? 3 : 0)
                                    )
                                    .shadow(color: selectedColor == colorTag ? colorTag.color.opacity(0.5) : .clear, radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 32)

                // Continue button
                Button(action: {
                    HapticManager.shared.success()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            childName.isEmpty ?
                                LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [selectedColor.color, selectedColor.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: childName.isEmpty ? .clear : selectedColor.color.opacity(0.4), radius: 20, y: 10)
                }
                .disabled(childName.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Page Indicator

/// Onboarding progress dots
struct OnboardingPageIndicator: View {
    let totalPages: Int
    let currentPage: Int
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? accentColor : Color(.systemGray4))
                    .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

// MARK: - Complete Onboarding Flow

/// Full onboarding experience
struct EnhancedOnboardingFlow: View {
    @State private var currentPage = 0
    @State private var childName = ""
    @State private var selectedColor: OnboardingAddChildScreen.ChildColorTag = .purple
    @State private var selectedEmoji = "👦"

    let onComplete: (String, String, Color) -> Void

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // Content
            TabView(selection: $currentPage) {
                OnboardingWelcomeScreen {
                    withAnimation { currentPage = 1 }
                }
                .tag(0)

                OnboardingValueScreen {
                    withAnimation { currentPage = 2 }
                }
                .tag(1)

                OnboardingDemoScreen {
                    withAnimation { currentPage = 3 }
                }
                .tag(2)

                OnboardingAddChildScreen(
                    childName: $childName,
                    selectedColor: $selectedColor,
                    selectedEmoji: $selectedEmoji
                ) {
                    onComplete(childName, selectedEmoji, selectedColor.color)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            VStack {
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation { currentPage -= 1 }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    Spacer()
                }

                Spacer()

                OnboardingPageIndicator(
                    totalPages: 4,
                    currentPage: currentPage,
                    accentColor: .purple
                )
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Simple Confetti View (placeholder - use EnhancedConfetti in production)

struct ConfettiView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50, id: \.self) { _ in
                    ConfettiPiece()
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

struct ConfettiPiece: View {
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        Rectangle()
            .fill(colors.randomElement()!)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .offset(y: yOffset)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4))) {
                    yOffset = 800
                    rotation = Double.random(in: 360...720)
                }
            }
    }
}

// MARK: - Previews

#Preview("Welcome Screen") {
    OnboardingWelcomeScreen {}
}

#Preview("Value Screen") {
    OnboardingValueScreen {}
}

#Preview("Demo Screen") {
    OnboardingDemoScreen {}
}

#Preview("Add Child Screen") {
    OnboardingAddChildScreen(
        childName: .constant(""),
        selectedColor: .constant(.purple),
        selectedEmoji: .constant("👦")
    ) {}
}

#Preview("Full Onboarding") {
    EnhancedOnboardingFlow { _, _, _ in }
}
