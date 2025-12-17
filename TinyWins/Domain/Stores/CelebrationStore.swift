import Foundation
import Combine

/// Store responsible for celebration state and logic.
/// Extracted from FamilyViewModel to provide focused celebration management.
@MainActor
final class CelebrationStore: ObservableObject {

    // MARK: - Published State

    /// Milestone celebration (25%, 50%, 75%)
    @Published var recentMilestone: MilestoneCelebration? = nil

    /// Reward earned celebration (when goal reaches 100%)
    @Published var rewardEarnedCelebration: RewardEarnedCelebration? = nil

    /// Reward completed notification (after reward is delivered to child)
    @Published var rewardCompletedNotification: RewardCompletedNotification? = nil

    // MARK: - Celebration Data Models

    struct MilestoneCelebration: Identifiable {
        let id = UUID()
        let childId: UUID
        let childName: String
        let rewardId: UUID
        let rewardName: String
        let milestone: Int
        let target: Int
        let message: String
    }

    struct RewardEarnedCelebration: Identifiable {
        let id = UUID()
        let childId: UUID
        let childName: String
        let rewardId: UUID
        let rewardName: String
        let rewardIcon: String?
    }

    struct RewardCompletedNotification: Identifiable, Equatable {
        let id = UUID()
        let rewardName: String
        let childName: String
        let hasNextReward: Bool

        static func == (lhs: RewardCompletedNotification, rhs: RewardCompletedNotification) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Celebration Logic

    /// Check and trigger celebrations for milestone or reward earned
    /// Preserves exact logic from FamilyViewModel behavior event tracking (lines 436-479)
    func checkAndTriggerCelebrations(
        reward: Reward,
        previousPoints: Int,
        behaviorEvents: [BehaviorEvent],
        isPrimary: Bool,
        child: Child
    ) {
        // Check if reward was below target before and now at or above
        let wasBelowTarget = previousPoints < reward.targetPoints
        let newPoints = reward.pointsEarnedInWindow(from: behaviorEvents, isPrimaryReward: isPrimary)
        let isNowAtTarget = newPoints >= reward.targetPoints

        // If just reached 100%, trigger reward earned celebration (not milestone)
        if wasBelowTarget && isNowAtTarget && !reward.isRedeemed && !reward.isExpired {
            // Don't show both milestone and reward earned - only show reward earned
            rewardEarnedCelebration = RewardEarnedCelebration(
                childId: child.id,
                childName: child.name,
                rewardId: reward.id,
                rewardName: reward.name,
                rewardIcon: reward.imageName
            )
            return // Skip milestone check - reward earned is the bigger celebration
        }

        // Check for milestone (25%, 50%, 75%) - but not 100%
        if let milestone = reward.justReachedMilestone(previousPoints: previousPoints, currentPoints: newPoints),
           milestone < reward.targetPoints { // Only show milestones below 100%

            let percentage = Int((Double(milestone) / Double(reward.targetPoints)) * 100)
            let message = milestoneMessage(percentage: percentage, childName: child.name)

            recentMilestone = MilestoneCelebration(
                childId: child.id,
                childName: child.name,
                rewardId: reward.id,
                rewardName: reward.name,
                milestone: milestone,
                target: reward.targetPoints,
                message: message
            )
        }
    }

    /// Generate milestone message based on percentage
    /// Preserves exact logic from FamilyViewModel.milestoneMessage(percentage:childName:)
    private func milestoneMessage(percentage: Int, childName: String) -> String {
        switch percentage {
        case 0..<30:
            return "Great start! Tell \(childName) what they did well this week."
        case 30..<50:
            return "Making progress! Keep noticing those positive moments."
        case 50..<75:
            return "Halfway there! \(childName) is doing great."
        case 75..<100:
            return "Almost there! The goal is within reach."
        default:
            return "Nice progress on the way to the goal!"
        }
    }

    /// Trigger reward completed notification
    /// Preserves exact logic from FamilyViewModel (lines 666-670)
    func triggerRewardCompletedNotification(
        rewardName: String,
        childName: String,
        hasNextReward: Bool
    ) {
        rewardCompletedNotification = RewardCompletedNotification(
            rewardName: rewardName,
            childName: childName,
            hasNextReward: hasNextReward
        )
    }

    /// Clear all celebrations/notifications
    /// Preserves exact logic from FamilyViewModel.dismissRecentEvent()
    func clearAllCelebrations() {
        recentMilestone = nil
        rewardEarnedCelebration = nil
        rewardCompletedNotification = nil
    }

    // MARK: - Dismissal Methods

    /// Dismiss milestone celebration
    /// Preserves exact logic from FamilyViewModel.dismissMilestone()
    func dismissMilestone() {
        recentMilestone = nil
    }

    /// Dismiss reward earned celebration
    /// Preserves exact logic from FamilyViewModel.dismissRewardEarnedCelebration()
    func dismissRewardEarnedCelebration() {
        rewardEarnedCelebration = nil
    }

    /// Dismiss reward completed notification
    /// Preserves exact logic from FamilyViewModel.dismissRewardCompletedNotification()
    func dismissRewardCompletedNotification() {
        rewardCompletedNotification = nil
    }

    // MARK: - Setter Methods

    /// Set recent milestone celebration
    func setRecentMilestone(_ milestone: MilestoneCelebration) {
        recentMilestone = milestone
    }

    /// Set reward earned celebration
    func setRewardEarnedCelebration(_ celebration: RewardEarnedCelebration) {
        rewardEarnedCelebration = celebration
    }

    /// Set reward completed notification
    func setRewardCompletedNotification(_ notification: RewardCompletedNotification) {
        rewardCompletedNotification = notification
    }
}
