import SwiftUI
import Combine

// MARK: - Coach Mark Manager

/// Manages the state and progression of coach mark sequences
@MainActor
final class CoachMarkManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentStep: CoachMarkStep?
    @Published private(set) var currentSequence: CoachMarkSequence?
    @Published private(set) var stepIndex: Int = 0
    @Published private(set) var totalSteps: Int = 0
    @Published var targetRects: [CoachMarkTarget: CGRect] = [:]

    // MARK: - Dependencies

    private let userPreferences: UserPreferencesStore

    // MARK: - Private State

    private var activeSequenceSteps: [CoachMarkStep] = []

    // MARK: - Computed Properties

    var isShowingCoachMark: Bool {
        currentStep != nil
    }

    var hasSkippedAll: Bool {
        userPreferences.hasSkippedAllCoachMarks
    }

    // MARK: - Initialization

    init(userPreferences: UserPreferencesStore) {
        self.userPreferences = userPreferences
    }

    // MARK: - Public Methods

    /// Start a coach mark sequence if not already completed
    func startSequenceIfNeeded(_ sequence: CoachMarkSequence) {
        // Don't show if user skipped all coach marks
        guard !userPreferences.hasSkippedAllCoachMarks else { return }

        // Don't show if already completed this sequence
        guard !hasCompletedSequence(sequence) else { return }

        // Don't start if already showing a sequence
        guard currentSequence == nil else { return }

        // Small delay to let the view render and register targets
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startSequence(sequence)
        }
    }

    /// Start a specific sequence
    private func startSequence(_ sequence: CoachMarkSequence) {
        let steps = CoachMarkContent.sequence(for: sequence)
        guard !steps.isEmpty else { return }

        activeSequenceSteps = steps
        currentSequence = sequence
        stepIndex = 0
        totalSteps = steps.count
        currentStep = steps[0]

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    /// Advance to the next step or complete the sequence
    func nextStep() {
        guard currentSequence != nil else { return }

        let nextIndex = stepIndex + 1

        if nextIndex < activeSequenceSteps.count {
            stepIndex = nextIndex
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep = activeSequenceSteps[nextIndex]
            }

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            completeCurrentSequence()
        }
    }

    /// Skip the current sequence
    func skipSequence() {
        guard let sequence = currentSequence else { return }

        // Mark as completed so it won't show again
        markSequenceCompleted(sequence)

        // Clear state
        withAnimation(.easeOut(duration: 0.2)) {
            currentStep = nil
        }
        currentSequence = nil
        activeSequenceSteps = []
        stepIndex = 0
        totalSteps = 0

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    /// Skip all future coach marks
    func skipAll() {
        userPreferences.hasSkippedAllCoachMarks = true
        skipSequence()
    }

    /// Register a target rect for spotlighting
    func registerTarget(_ target: CoachMarkTarget, rect: CGRect) {
        targetRects[target] = rect
    }

    /// Reset all coach marks (for testing or settings)
    func resetAll() {
        userPreferences.resetAllCoachMarks()
        currentStep = nil
        currentSequence = nil
        activeSequenceSteps = []
        stepIndex = 0
        totalSteps = 0
        targetRects = [:]
    }

    // MARK: - Private Methods

    private func completeCurrentSequence() {
        guard let sequence = currentSequence else { return }

        // Mark sequence as completed
        markSequenceCompleted(sequence)

        // Clear state
        withAnimation(.easeOut(duration: 0.2)) {
            currentStep = nil
        }
        currentSequence = nil
        activeSequenceSteps = []
        stepIndex = 0
        totalSteps = 0

        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    private func hasCompletedSequence(_ sequence: CoachMarkSequence) -> Bool {
        switch sequence {
        case .today:
            return userPreferences.hasCompletedTodayCoachMarks
        case .kids:
            return userPreferences.hasCompletedKidsCoachMarks
        case .goals:
            return userPreferences.hasCompletedGoalsCoachMarks
        case .insights:
            return userPreferences.hasCompletedInsightsCoachMarks
        }
    }

    private func markSequenceCompleted(_ sequence: CoachMarkSequence) {
        switch sequence {
        case .today:
            userPreferences.hasCompletedTodayCoachMarks = true
        case .kids:
            userPreferences.hasCompletedKidsCoachMarks = true
        case .goals:
            userPreferences.hasCompletedGoalsCoachMarks = true
        case .insights:
            userPreferences.hasCompletedInsightsCoachMarks = true
        }
    }
}

// MARK: - Target Rect Preference Key

/// Preference key for collecting target rects from views
struct CoachMarkTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [CoachMarkTarget: CGRect] = [:]

    static func reduce(value: inout [CoachMarkTarget: CGRect], nextValue: () -> [CoachMarkTarget: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - View Extension for Target Registration

extension View {
    /// Mark this view as a coach mark target
    func coachMarkTarget(_ target: CoachMarkTarget) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: CoachMarkTargetPreferenceKey.self,
                    value: [target: geometry.frame(in: .global)]
                )
            }
        )
    }
}

// MARK: - Conditional Coach Mark Target

/// A view modifier that conditionally applies a coach mark target
struct ConditionalCoachMarkTarget: ViewModifier {
    let target: CoachMarkTarget
    let condition: Bool

    func body(content: Content) -> some View {
        if condition {
            content.coachMarkTarget(target)
        } else {
            content
        }
    }
}
