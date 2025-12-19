import SwiftUI

// MARK: - Feedback Manager

class FeedbackManager: ObservableObject {
    /// Shared singleton instance for backward compatibility.
    /// New code should use dependency injection via DependencyContainer.
    static let shared = FeedbackManager()

    // UserDefaults keys
    private let firstInstallDateKey = "FeedbackManager.firstInstallDate"
    private let lastPromptDateKey = "FeedbackManager.lastFeedbackPromptDate"
    private let lastMilestoneCountKey = "FeedbackManager.lastMilestoneCount"

    // Milestone thresholds - show prompt at these moments logged
    private let milestones = [10, 25, 50, 100, 200, 500]
    private let daysBetweenPrompts = 14
    private let minimumDaysSinceInstall = 3

    @Published var shouldShowPrompt = false
    @Published var currentMilestone: Int? = nil

    /// Creates a new FeedbackManager instance.
    init() {
        // Record first install date if not already set
        if UserDefaults.standard.object(forKey: firstInstallDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstInstallDateKey)
        }
    }

    // MARK: - Public Methods

    /// Check if feedback prompt should be shown based on milestone achievement
    func checkPromptEligibility(totalMomentsLogged: Int) {
        // Don't show if we've shown recently
        guard !hasRecentlyShownPrompt else {
            shouldShowPrompt = false
            return
        }

        // Don't show too early
        guard hasMinimumInstallTime else {
            shouldShowPrompt = false
            return
        }

        // Check if we've hit a new milestone
        let lastCount = UserDefaults.standard.integer(forKey: lastMilestoneCountKey)

        if let milestone = milestones.first(where: { totalMomentsLogged >= $0 && lastCount < $0 }) {
            currentMilestone = milestone
            shouldShowPrompt = true
        } else {
            shouldShowPrompt = false
        }
    }

    /// Call this when a milestone is reached (e.g., streak achieved, goal completed)
    func checkMilestoneReached(type: MilestoneType) {
        guard !hasRecentlyShownPrompt, hasMinimumInstallTime else {
            return
        }

        currentMilestone = nil
        shouldShowPrompt = true
    }

    /// Mark the prompt as shown (call after user interacts with prompt)
    func markPromptShown() {
        UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
        shouldShowPrompt = false
        currentMilestone = nil
    }

    /// Mark the prompt as shown and update the milestone count
    func markPromptShown(totalMomentsLogged: Int) {
        UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
        UserDefaults.standard.set(totalMomentsLogged, forKey: lastMilestoneCountKey)
        shouldShowPrompt = false
        currentMilestone = nil
    }

    // MARK: - Private Helpers

    private var firstInstallDate: Date? {
        UserDefaults.standard.object(forKey: firstInstallDateKey) as? Date
    }

    private var lastPromptDate: Date? {
        UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date
    }

    private var hasMinimumInstallTime: Bool {
        guard let installDate = firstInstallDate else { return false }
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return daysSinceInstall >= minimumDaysSinceInstall
    }

    private var hasRecentlyShownPrompt: Bool {
        guard let lastDate = lastPromptDate else {
            return false // Never shown before
        }

        let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastPrompt < daysBetweenPrompts
    }
}

// MARK: - Milestone Types

enum MilestoneType {
    case momentsLogged(Int)
    case streakAchieved(Int)
    case goalCompleted
    case weeklyReflection
}

// MARK: - Pulse Response

enum PulseResponse: String, CaseIterable {
    case loving = "loving"
    case good = "good"
    case okay = "okay"
    case struggling = "struggling"

    var emoji: String {
        switch self {
        case .loving: return "😍"
        case .good: return "😊"
        case .okay: return "😐"
        case .struggling: return "😕"
        }
    }

    var label: String {
        switch self {
        case .loving: return "Loving it"
        case .good: return "Good"
        case .okay: return "Okay"
        case .struggling: return "Struggling"
        }
    }

    var isPositive: Bool {
        self == .loving || self == .good
    }
}

// MARK: - Feedback Prompt View

struct FeedbackPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var feedbackManager: FeedbackManager

    @State private var selectedResponse: PulseResponse? = nil
    @State private var showingFollowUp = false
    @State private var showingFeedbackView = false
    @State private var showingThankYou = false

    var body: some View {
        VStack(spacing: 20) {
            // Handle / drag indicator
            Capsule()
                .fill(theme.borderStrong)
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            if showingThankYou {
                thankYouView
            } else if showingFollowUp, let response = selectedResponse {
                followUpView(response: response)
            } else {
                pulseCheckView
            }
        }
        .background(theme.surface1)
        .sheet(isPresented: $showingFeedbackView, onDismiss: {
            dismiss()
        }) {
            FeedbackView(
                prefillGoingWell: selectedResponse?.isPositive == true ? "I'm enjoying Tiny Wins because..." : nil,
                prefillConfusing: selectedResponse?.isPositive == false ? "Tiny Wins could be better if..." : nil
            )
        }
    }

    // MARK: - Pulse Check View

    private var pulseCheckView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Milestone celebration (if applicable)
            if let milestone = feedbackManager.currentMilestone {
                VStack(spacing: 8) {
                    Text("\(milestone) moments!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.primary)

                    Text("You're building great habits")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.bottom, 8)
            }

            // Question
            Text("How's it going?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            // Emoji buttons
            HStack(spacing: 16) {
                ForEach(PulseResponse.allCases, id: \.self) { response in
                    PulseButton(response: response) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedResponse = response
                            showingFollowUp = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Skip button
            Button(action: {
                feedbackManager.markPromptShown()
                dismiss()
            }) {
                Text("Not now")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Follow-up View

    private func followUpView(response: PulseResponse) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Selected emoji
            Text(response.emoji)
                .font(.system(size: 64))

            // Follow-up message
            VStack(spacing: 8) {
                if response.isPositive {
                    Text("That's great to hear!")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Would you like to share what's working well?")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Thanks for being honest")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("We'd love to hear how we can improve")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    feedbackManager.markPromptShown()
                    showingFeedbackView = true
                }) {
                    Text(response.isPositive ? "Share feedback" : "Tell us more")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(AppStyles.buttonCornerRadius)
                }

                Button(action: {
                    feedbackManager.markPromptShown()
                    recordPulseOnly(response)
                }) {
                    Text("Just the emoji is enough")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Thank You View

    private var thankYouView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)

            Text("Thanks!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your feedback helps us improve")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    // MARK: - Helper Methods

    private func recordPulseOnly(_ response: PulseResponse) {
        // Record the pulse response for analytics
        #if DEBUG
        print("[Feedback] Pulse recorded: \(response.rawValue)")
        #endif

        withAnimation {
            showingFollowUp = false
            showingThankYou = true
        }
    }
}

// MARK: - Pulse Button

private struct PulseButton: View {
    let response: PulseResponse
    let action: () -> Void

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(response.emoji)
                    .font(.system(size: 36))

                Text(response.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Micro Feedback Manager

class MicroFeedbackManager: ObservableObject {
    static let shared = MicroFeedbackManager()

    // Track when micro-feedback was last shown for each action type
    private var lastShownDates: [String: Date] = [:]
    private let cooldownInterval: TimeInterval = 60 * 60 * 24 // 24 hours

    // Probability of showing micro-feedback (10% chance)
    private let showProbability: Double = 0.10

    // Track how many actions since last micro-feedback
    private var actionsSinceLastFeedback = 0
    private let actionsThreshold = 5 // Show every 5th action (on average)

    /// Check if micro-feedback should be shown for an action
    func shouldShowMicroFeedback(for actionType: String) -> Bool {
        actionsSinceLastFeedback += 1

        // Don't show too frequently
        if let lastShown = lastShownDates[actionType] {
            let timeSinceLastShown = Date().timeIntervalSince(lastShown)
            if timeSinceLastShown < cooldownInterval {
                return false
            }
        }

        // Show based on action count or probability
        if actionsSinceLastFeedback >= actionsThreshold || Double.random(in: 0...1) < showProbability {
            actionsSinceLastFeedback = 0
            return true
        }

        return false
    }

    /// Mark micro-feedback as shown for an action type
    func markShown(for actionType: String) {
        lastShownDates[actionType] = Date()
        actionsSinceLastFeedback = 0
    }

    /// Record the micro-feedback response
    func recordResponse(actionType: String, isPositive: Bool) {
        markShown(for: actionType)

        #if DEBUG
        print("[MicroFeedback] \(actionType): \(isPositive ? "positive" : "negative")")
        #endif
    }
}

// MARK: - Micro Feedback View

struct MicroFeedbackView: View {
    let actionType: String
    let contextMessage: String
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme
    @StateObject private var manager = MicroFeedbackManager.shared
    @State private var selectedResponse: Bool? = nil
    @State private var showingThankYou = false

    var body: some View {
        VStack(spacing: 12) {
            if showingThankYou {
                thankYouContent
            } else {
                feedbackContent
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface1)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .padding(.horizontal, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var feedbackContent: some View {
        VStack(spacing: 12) {
            Text(contextMessage)
                .font(.system(size: 15, weight: .medium))
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                // Thumbs up
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedResponse = true
                        manager.recordResponse(actionType: actionType, isPositive: true)
                        showingThankYou = true
                    }
                    dismissAfterDelay()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)

                        Text("Yes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)

                // Thumbs down
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedResponse = false
                        manager.recordResponse(actionType: actionType, isPositive: false)
                        showingThankYou = true
                    }
                    dismissAfterDelay()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)

                        Text("Not quite")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }

            // Dismiss button
            Button("Skip") {
                manager.markShown(for: actionType)
                onDismiss()
            }
            .font(.system(size: 13))
            .foregroundColor(theme.textSecondary)
        }
    }

    private var thankYouContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundColor(AppColors.primary)

            Text("Thanks for your feedback!")
                .font(.system(size: 15, weight: .medium))
        }
    }

    private func dismissAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onDismiss()
        }
    }
}

// MARK: - Micro Feedback Modifier

struct MicroFeedbackModifier: ViewModifier {
    let actionType: String
    let contextMessage: String
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if isPresented {
                Color.black.opacity(0.001) // Invisible tap area
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }

                MicroFeedbackView(
                    actionType: actionType,
                    contextMessage: contextMessage,
                    onDismiss: {
                        withAnimation {
                            isPresented = false
                        }
                    }
                )
                .padding(.bottom, 100)
            }
        }
    }
}

extension View {
    /// Show contextual micro-feedback after an action
    func microFeedback(
        actionType: String,
        contextMessage: String,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(MicroFeedbackModifier(
            actionType: actionType,
            contextMessage: contextMessage,
            isPresented: isPresented
        ))
    }
}

// MARK: - Common Micro Feedback Messages

enum MicroFeedbackContext {
    case momentLogged
    case goalCreated
    case goalCompleted
    case reflectionSaved

    var actionType: String {
        switch self {
        case .momentLogged: return "moment_logged"
        case .goalCreated: return "goal_created"
        case .goalCompleted: return "goal_completed"
        case .reflectionSaved: return "reflection_saved"
        }
    }

    var message: String {
        switch self {
        case .momentLogged: return "Was that easy to log?"
        case .goalCreated: return "Happy with this goal setup?"
        case .goalCompleted: return "Celebration feel right?"
        case .reflectionSaved: return "Reflection helpful today?"
        }
    }
}

// MARK: - Preview

#Preview("Feedback Prompt") {
    FeedbackPromptView()
}
