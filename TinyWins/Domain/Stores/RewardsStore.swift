import Foundation
import Combine

/// Store responsible for managing rewards/goals and reward history.
/// Extracted from FamilyViewModel to provide focused state management for all reward-related operations.
///
/// PERFORMANCE: Uses single Snapshot pattern to batch all state updates into one objectWillChange.
/// This prevents multiple view invalidations during loadData() which caused tab switch jank.
@MainActor
final class RewardsStore: ObservableObject {

    // MARK: - Snapshot (single publish for all state)

    struct Snapshot: Equatable {
        var rewards: [Reward] = []
        var rewardHistoryEvents: [RewardHistoryEvent] = []
        var agreementVersions: [AgreementVersion] = []
    }

    // MARK: - Dependencies

    private let repository: RepositoryProtocol

    // MARK: - Published State (single snapshot = single objectWillChange)

    @Published private(set) var snapshot = Snapshot()

    // MARK: - Convenience Accessors (no additional publishes)

    var rewards: [Reward] { snapshot.rewards }
    var rewardHistoryEvents: [RewardHistoryEvent] { snapshot.rewardHistoryEvents }
    var agreementVersions: [AgreementVersion] { snapshot.agreementVersions }

    // MARK: - Initialization

    init(repository: RepositoryProtocol) {
        self.repository = repository
        loadData()
    }

    // MARK: - Data Loading

    /// PERFORMANCE: Single snapshot assignment = single objectWillChange notification
    func loadData() {
        #if DEBUG
        FrameStallMonitor.shared.markBlockReason(.storeRecompute)
        defer { FrameStallMonitor.shared.clearBlockReason() }
        #endif

        snapshot = Snapshot(
            rewards: repository.getRewards(),
            rewardHistoryEvents: repository.getRewardHistoryEvents(),
            agreementVersions: repository.getAgreementVersions()
        )
    }

    // MARK: - Reward Queries

    func activeReward(forChild childId: UUID) -> Reward? {
        // Find the primary (active) reward - the one with lowest priority that isn't completed/expired
        return rewards
            .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
            .first
    }

    func rewards(forChild childId: UUID) -> [Reward] {
        rewards.filter { $0.childId == childId }
    }

    /// Get rewards that can accept points (not completed, not expired, not at target)
    func rewardsCanAcceptPoints(forChild childId: UUID, behaviorEvents: [BehaviorEvent]) -> [Reward] {
        rewards
            .filter { reward in
                reward.childId == childId &&
                reward.canAcceptPoints &&
                !reward.isRedeemed &&
                !reward.isExpired
            }
            .sorted { $0.priority < $1.priority }
    }

    /// Get the default star target for logging a moment
    /// Returns the active reward if it can accept points, nil otherwise
    func defaultStarTarget(forChild childId: UUID, behaviorEvents: [BehaviorEvent]) -> Reward? {
        guard let active = activeReward(forChild: childId) else { return nil }

        // Check if the active reward can accept points
        // Also check if it's already at or above target (readyToRedeem state)
        let status = active.status(from: behaviorEvents, isPrimaryReward: true)
        if status == .readyToRedeem || status == .completed || status == .expired {
            return nil
        }

        return active
    }

    /// Get all rewards for selection UI with their eligibility status
    struct RewardSelectionOption: Identifiable {
        let id: UUID
        let reward: Reward
        let isDefault: Bool
        let canAcceptPoints: Bool
        let statusNote: String?
    }

    func rewardSelectionOptions(forChild childId: UUID, behaviorEvents: [BehaviorEvent]) -> [RewardSelectionOption] {
        let childRewards = rewards
            .filter { $0.childId == childId && !$0.isRedeemed }
            .sorted { $0.priority < $1.priority }

        let defaultTarget = defaultStarTarget(forChild: childId, behaviorEvents: behaviorEvents)

        return childRewards.map { reward in
            let status = reward.status(from: behaviorEvents, isPrimaryReward: reward.id == defaultTarget?.id)
            let canAccept = reward.canAcceptPoints && status != .readyToRedeem

            let note: String?
            switch status {
            case .readyToRedeem:
                note = "Already earned"
            case .expired:
                note = "Expired"
            case .completed:
                note = "Completed"
            default:
                note = nil
            }

            return RewardSelectionOption(
                id: reward.id,
                reward: reward,
                isDefault: reward.id == defaultTarget?.id,
                canAcceptPoints: canAccept,
                statusNote: note
            )
        }
    }

    // MARK: - Reward CRUD

    func addReward(_ reward: Reward) {
        repository.addReward(reward)
        loadData()
    }

    func updateReward(_ reward: Reward) {
        guard rewards.contains(where: { $0.id == reward.id }) else {
            #if DEBUG
            print("⚠️ RewardsStore: Attempted to update non-existent reward: \(reward.id)")
            #endif
            return
        }
        repository.updateReward(reward)
        loadData()
    }

    func deleteReward(id: UUID) {
        guard rewards.contains(where: { $0.id == id }) else {
            #if DEBUG
            print("⚠️ RewardsStore: Attempted to delete non-existent reward: \(id)")
            #endif
            return
        }
        repository.deleteReward(id: id)
        loadData()
    }

    func setRewardAsPrimary(_ rewardId: UUID, forChild childId: UUID) {
        // Get all active rewards for this child
        let childRewards = rewards.filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }

        // Update priorities: set selected to 0, others to 1+
        for reward in childRewards {
            var updated = reward
            if reward.id == rewardId {
                updated.priority = 0
            } else {
                updated.priority = max(1, reward.priority + 1)
            }
            repository.updateReward(updated)
        }

        loadData()
    }

    // MARK: - Reward Redemption

    /// Complete/redeem a reward and handle promotion of queued rewards
    func completeReward(id: UUID, childName: String) -> (hasNextReward: Bool, rewardName: String)? {
        guard var reward = rewards.first(where: { $0.id == id }) else { return nil }

        let rewardName = reward.name

        // Check if this is the primary reward
        let isPrimary = activeReward(forChild: reward.childId)?.id == id

        // Freeze earned points at current value (requires behaviorEvents to calculate)
        // Note: This will be called from FamilyViewModel which has access to events
        reward.isRedeemed = true
        reward.redeemedDate = Date()

        repository.updateReward(reward)

        // Check if there's a next queued reward BEFORE promoting
        let queuedRewards = rewards
            .filter { $0.childId == reward.childId && !$0.isRedeemed && !$0.isExpired && $0.priority > 0 }
        let hasNextReward = !queuedRewards.isEmpty

        // Auto-promote next queued reward if this was the primary
        if isPrimary {
            promoteNextQueuedReward(forChild: reward.childId)
        }

        // Refresh data
        loadData()

        return (hasNextReward: hasNextReward, rewardName: rewardName)
    }

    /// Promote the next queued reward to be the active (primary) reward
    private func promoteNextQueuedReward(forChild childId: UUID) {
        // Find the next queued reward (lowest priority after 0 that isn't completed/expired)
        let queuedRewards = rewards
            .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired && $0.priority > 0 }
            .sorted { $0.priority < $1.priority }

        if var nextReward = queuedRewards.first {
            nextReward.priority = 0
            nextReward.startDate = Date() // Reset start date for fresh tracking
            repository.updateReward(nextReward)
        }
    }

    // MARK: - Reward History

    /// Log a reward history event
    func logRewardHistoryEvent(reward: Reward, eventType: RewardHistoryEvent.EventType, starsEarned: Int) {
        let event = RewardHistoryEvent(
            childId: reward.childId,
            rewardId: reward.id,
            rewardName: reward.name,
            rewardIcon: reward.imageName,
            eventType: eventType,
            starsRequired: reward.targetPoints,
            starsEarnedAtEvent: starsEarned
        )
        repository.addRewardHistoryEvent(event)
        // Update only history in snapshot (single publish)
        snapshot.rewardHistoryEvents = repository.getRewardHistoryEvents()
    }

    /// Get reward history events for a time period and optional child filter
    func rewardEvents(forChild childId: UUID? = nil, period: TimePeriod) -> [RewardHistoryEvent] {
        let (start, end) = period.dateRange
        return rewardHistoryEvents.filter { event in
            let matchesTime = event.timestamp >= start && event.timestamp <= end
            let matchesChild = childId == nil || event.childId == childId
            return matchesTime && matchesChild
        }.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Timed Rewards

    func checkExpiredRewards(behaviorEvents: [BehaviorEvent]) {
        for reward in rewards where reward.hasDeadline && reward.isExpired && !reward.isRedeemed {
            // Check if we've already logged this expiration
            let alreadyLogged = rewardHistoryEvents.contains {
                $0.rewardId == reward.id && $0.eventType == .expired
            }

            if !alreadyLogged {
                // Log expired history event
                let isPrimary = activeReward(forChild: reward.childId)?.id == reward.id
                let starsEarned = reward.pointsEarnedInWindow(from: behaviorEvents, isPrimaryReward: isPrimary)
                logRewardHistoryEvent(
                    reward: reward,
                    eventType: .expired,
                    starsEarned: starsEarned
                )
            }

            if reward.autoResetOnExpire {
                // Apply soft reset - halve progress and restart
                var updatedReward = reward
                updatedReward.applySoftReset()
                updateReward(updatedReward)
            }
        }
    }

    // MARK: - Goals Completed Count

    func goalsCompleted(forChild childId: UUID) -> Int {
        rewards.filter { $0.childId == childId && $0.isRedeemed }.count
    }

    // MARK: - Kid Goal Options Generation

    func generateKidGoalOptions(forChild child: Child) -> [KidGoalOption] {
        // Return ALL age-appropriate templates for full category browsing
        return RewardTemplate.allGoalOptions(forAge: child.age)
    }

    // MARK: - Agreement System

    /// Get the current agreement version for a child
    func currentAgreement(forChild childId: UUID) -> AgreementVersion? {
        agreementVersions.first { $0.childId == childId && $0.isCurrent }
    }

    /// Check if child has any fully signed agreement (both parent and child signatures)
    func hasAnySignedAgreement(forChild childId: UUID) -> Bool {
        agreementVersions.contains {
            $0.childId == childId && $0.isFullySigned
        }
    }

    /// Check if current agreement covers all active goals
    func hasCurrentAgreementForGoals(forChild childId: UUID) -> Bool {
        guard let agreement = currentAgreement(forChild: childId),
              agreement.isFullySigned else {
            return false
        }

        let activeRewardIds = Set(rewards
            .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
            .map { $0.id })

        let coveredIds = Set(agreement.coveredRewardIds)

        // All active rewards must be covered
        return activeRewardIds.isSubset(of: coveredIds)
    }

    /// Get the high-level agreement coverage status (single source of truth for UI)
    func agreementCoverageStatus(forChild childId: UUID) -> AgreementCoverageStatus {
        let hasSigned = hasAnySignedAgreement(forChild: childId)
        let coversGoals = hasCurrentAgreementForGoals(forChild: childId)

        if !hasSigned {
            return .neverSigned
        } else if coversGoals {
            return .signedCurrent
        } else {
            return .signedOutOfDate
        }
    }

    /// Check if a reward is covered by the current agreement
    func isRewardCoveredByAgreement(rewardId: UUID, childId: UUID) -> Bool {
        guard let agreement = currentAgreement(forChild: childId),
              agreement.isFullySigned else {
            return false
        }
        return agreement.coveredRewardIds.contains(rewardId)
    }

    /// Check if a reward needs to be added to an agreement
    func rewardNeedsAgreement(rewardId: UUID, childId: UUID, behaviorEvents: [BehaviorEvent]) -> Bool {
        guard let reward = rewards.first(where: { $0.id == rewardId }) else { return false }

        // Only active rewards need agreement consideration
        let status = reward.status(from: behaviorEvents, isPrimaryReward: activeReward(forChild: childId)?.id == rewardId)
        guard status == .active || status == .activeWithDeadline || status == .readyToRedeem else {
            return false
        }

        // Check if covered by current signed agreement
        return !isRewardCoveredByAgreement(rewardId: rewardId, childId: childId)
    }

    /// Get list of rewards that need agreement for a child
    func rewardsNeedingAgreement(forChild childId: UUID, behaviorEvents: [BehaviorEvent]) -> [Reward] {
        let childRewards = rewards.filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
        return childRewards.filter { rewardNeedsAgreement(rewardId: $0.id, childId: childId, behaviorEvents: behaviorEvents) }
    }

    /// Get rewards that ARE covered by current agreement
    func rewardsCoveredByAgreement(forChild childId: UUID) -> [Reward] {
        let childRewards = rewards.filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
        return childRewards.filter { isRewardCoveredByAgreement(rewardId: $0.id, childId: childId) }
    }

    /// Get agreement status for a child (legacy, use agreementCoverageStatus instead)
    func agreementStatus(forChild childId: UUID, behaviorEvents: [BehaviorEvent]) -> AgreementStatus {
        let agreement = currentAgreement(forChild: childId)
        let activeRewards = rewards.filter {
            $0.childId == childId && !$0.isRedeemed && !$0.isExpired
        }
        let needingAgreement = rewardsNeedingAgreement(forChild: childId, behaviorEvents: behaviorEvents)

        // No current agreement or not fully signed
        guard let agreement = agreement, agreement.isFullySigned else {
            return .notSignedYet
        }

        // Check if any rewards need agreement
        if !needingAgreement.isEmpty {
            return .needsReview(newGoalsCount: needingAgreement.count)
        }

        // All rewards are covered
        return .signedAndUpToDate(activeGoalsCount: activeRewards.count)
    }

    /// Sign the agreement for a child (updates or creates current version)
    func signAgreement(childId: UUID, signatureType: SignatureType, signatureData: Data, activeBehaviorTypeIds: [UUID]) {
        // Get or create current agreement version
        if var existing = currentAgreement(forChild: childId) {
            // Update existing
            switch signatureType {
            case .child:
                existing.childSignedAt = Date()
                existing.childSignatureData = signatureData
            case .parent:
                existing.parentSignedAt = Date()
                existing.parentSignatureData = signatureData
            }

            // If now fully signed, include all active rewards
            if existing.isFullySigned {
                let activeRewardIds = rewards
                    .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
                    .map { $0.id }
                existing.coveredRewardIds = activeRewardIds
                existing.coveredBehaviorIds = activeBehaviorTypeIds
            }

            repository.updateAgreementVersion(existing)
        } else {
            // Create new version
            let activeRewardIds = rewards
                .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
                .map { $0.id }

            var newAgreement = AgreementVersion(
                childId: childId,
                coveredRewardIds: activeRewardIds,
                coveredBehaviorIds: activeBehaviorTypeIds,
                isCurrent: true
            )

            switch signatureType {
            case .child:
                newAgreement.childSignedAt = Date()
                newAgreement.childSignatureData = signatureData
            case .parent:
                newAgreement.parentSignedAt = Date()
                newAgreement.parentSignatureData = signatureData
            }

            repository.addAgreementVersion(newAgreement)
        }

        // Update only agreements in snapshot (single publish)
        snapshot.agreementVersions = repository.getAgreementVersions()
    }

    /// Create a new agreement version (marks old as not current)
    func createNewAgreementVersion(forChild childId: UUID, activeBehaviorTypeIds: [UUID]) {
        // Mark existing as not current
        if var existing = currentAgreement(forChild: childId) {
            existing.isCurrent = false
            repository.updateAgreementVersion(existing)
        }

        // Create new version
        let activeRewardIds = rewards
            .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
            .map { $0.id }

        let newAgreement = AgreementVersion(
            childId: childId,
            coveredRewardIds: activeRewardIds,
            coveredBehaviorIds: activeBehaviorTypeIds,
            isCurrent: true
        )

        repository.addAgreementVersion(newAgreement)
        // Update only agreements in snapshot (single publish)
        snapshot.agreementVersions = repository.getAgreementVersions()
    }
}
