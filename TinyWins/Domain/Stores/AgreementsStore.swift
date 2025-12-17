import Foundation
import Combine

/// Store responsible for agreement system management.
/// Extracted from FamilyViewModel to provide focused agreement state management.
@MainActor
final class AgreementsStore: ObservableObject {

    // MARK: - Dependencies

    private let repository: RepositoryProtocol

    // MARK: - Published State

    @Published var newGoalNeedsAgreement: UUID? = nil

    // MARK: - Initialization

    init(repository: RepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Agreement Query Methods

    /// Get the current agreement version for a child
    /// Preserves exact logic from FamilyViewModel.currentAgreement(forChild:)
    func currentAgreement(forChild childId: UUID, agreementVersions: [AgreementVersion]) -> AgreementVersion? {
        agreementVersions.first { $0.childId == childId && $0.isCurrent }
    }

    /// Check if child has any fully signed agreement (both parent and child signatures)
    /// Preserves exact logic from FamilyViewModel.hasAnySignedAgreement(forChild:)
    func hasAnySignedAgreement(forChild childId: UUID, agreementVersions: [AgreementVersion]) -> Bool {
        agreementVersions.contains {
            $0.childId == childId && $0.isFullySigned
        }
    }

    /// Check if current agreement covers all active goals
    /// Preserves exact logic from FamilyViewModel.hasCurrentAgreementForGoals(forChild:)
    func hasCurrentAgreementForGoals(
        forChild childId: UUID,
        agreementVersions: [AgreementVersion],
        rewards: [Reward]
    ) -> Bool {
        guard let agreement = currentAgreement(forChild: childId, agreementVersions: agreementVersions),
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
    /// Preserves exact logic from FamilyViewModel.agreementCoverageStatus(forChild:)
    func agreementCoverageStatus(
        forChild childId: UUID,
        agreementVersions: [AgreementVersion],
        rewards: [Reward]
    ) -> AgreementCoverageStatus {
        let hasSigned = hasAnySignedAgreement(forChild: childId, agreementVersions: agreementVersions)
        let coversGoals = hasCurrentAgreementForGoals(
            forChild: childId,
            agreementVersions: agreementVersions,
            rewards: rewards
        )

        if !hasSigned {
            return .neverSigned
        } else if coversGoals {
            return .signedCurrent
        } else {
            return .signedOutOfDate
        }
    }

    /// Check if a reward is covered by the current agreement
    /// Preserves exact logic from FamilyViewModel.isRewardCoveredByAgreement(rewardId:childId:)
    func isRewardCoveredByAgreement(
        rewardId: UUID,
        childId: UUID,
        agreementVersions: [AgreementVersion]
    ) -> Bool {
        guard let agreement = currentAgreement(forChild: childId, agreementVersions: agreementVersions),
              agreement.isFullySigned else {
            return false
        }
        return agreement.coveredRewardIds.contains(rewardId)
    }

    /// Check if a reward needs to be added to an agreement
    /// Preserves exact logic from FamilyViewModel.rewardNeedsAgreement(rewardId:childId:)
    func rewardNeedsAgreement(
        rewardId: UUID,
        childId: UUID,
        rewards: [Reward],
        behaviorEvents: [BehaviorEvent],
        agreementVersions: [AgreementVersion],
        activeRewardForChild: Reward?
    ) -> Bool {
        guard let reward = rewards.first(where: { $0.id == rewardId }) else { return false }

        // Only active rewards need agreement consideration
        let status = reward.status(from: behaviorEvents, isPrimaryReward: activeRewardForChild?.id == rewardId)
        guard status == .active || status == .activeWithDeadline || status == .readyToRedeem else {
            return false
        }

        // Check if covered by current signed agreement
        return !isRewardCoveredByAgreement(
            rewardId: rewardId,
            childId: childId,
            agreementVersions: agreementVersions
        )
    }

    /// Get list of rewards that need agreement for a child
    /// Preserves exact logic from FamilyViewModel.rewardsNeedingAgreement(forChild:)
    func rewardsNeedingAgreement(
        forChild childId: UUID,
        rewards: [Reward],
        behaviorEvents: [BehaviorEvent],
        agreementVersions: [AgreementVersion],
        activeRewardForChild: Reward?
    ) -> [Reward] {
        let childRewards = rewards.filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
        return childRewards.filter {
            rewardNeedsAgreement(
                rewardId: $0.id,
                childId: childId,
                rewards: rewards,
                behaviorEvents: behaviorEvents,
                agreementVersions: agreementVersions,
                activeRewardForChild: activeRewardForChild
            )
        }
    }

    /// Get rewards that ARE covered by current agreement
    /// Preserves exact logic from FamilyViewModel.rewardsCoveredByAgreement(forChild:)
    func rewardsCoveredByAgreement(
        forChild childId: UUID,
        rewards: [Reward],
        agreementVersions: [AgreementVersion]
    ) -> [Reward] {
        let childRewards = rewards.filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
        return childRewards.filter {
            isRewardCoveredByAgreement(
                rewardId: $0.id,
                childId: childId,
                agreementVersions: agreementVersions
            )
        }
    }

    /// Get agreement status for a child (legacy, use agreementCoverageStatus instead)
    /// Preserves exact logic from FamilyViewModel.agreementStatus(forChild:)
    func agreementStatus(
        forChild childId: UUID,
        agreementVersions: [AgreementVersion],
        rewards: [Reward],
        behaviorEvents: [BehaviorEvent],
        activeRewardForChild: Reward?
    ) -> AgreementStatus {
        let agreement = currentAgreement(forChild: childId, agreementVersions: agreementVersions)
        let activeRewards = rewards.filter {
            $0.childId == childId && !$0.isRedeemed && !$0.isExpired
        }
        let needingAgreement = rewardsNeedingAgreement(
            forChild: childId,
            rewards: rewards,
            behaviorEvents: behaviorEvents,
            agreementVersions: agreementVersions,
            activeRewardForChild: activeRewardForChild
        )

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

    // MARK: - Agreement Mutation Methods

    /// Sign the agreement for a child (updates or creates current version)
    /// Preserves exact logic from FamilyViewModel.signAgreement(childId:signatureType:signatureData:)
    func signAgreement(
        childId: UUID,
        signatureType: SignatureType,
        signatureData: Data,
        agreementVersions: [AgreementVersion],
        rewards: [Reward],
        behaviorTypes: [BehaviorType],
        onChildUpdated: (Child) -> Void,
        onReloadStores: () -> Void
    ) {
        // Also update old signature system for backward compatibility
        if var child = repository.getChildren().first(where: { $0.id == childId }) {
            let signature = AgreementSignature(signatureData: signatureData, signedAt: Date())
            switch signatureType {
            case .child:
                child.childSignature = signature
            case .parent:
                child.parentSignature = signature
            }
            repository.updateChild(child)
            onChildUpdated(child)
        }

        // Get or create current agreement version
        if var existing = currentAgreement(forChild: childId, agreementVersions: agreementVersions) {
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

                let activeBehaviorIds = behaviorTypes
                    .filter { $0.isActive }
                    .map { $0.id }
                existing.coveredBehaviorIds = activeBehaviorIds
            }

            repository.updateAgreementVersion(existing)
        } else {
            // Create new version
            let activeRewardIds = rewards
                .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
                .map { $0.id }
            let activeBehaviorIds = behaviorTypes
                .filter { $0.isActive }
                .map { $0.id }

            var newAgreement = AgreementVersion(
                childId: childId,
                coveredRewardIds: activeRewardIds,
                coveredBehaviorIds: activeBehaviorIds,
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
        onReloadStores()
    }

    /// Create a new agreement version (marks old as not current)
    /// Preserves exact logic from FamilyViewModel.createNewAgreementVersion(forChild:)
    func createNewAgreementVersion(
        forChild childId: UUID,
        agreementVersions: [AgreementVersion],
        rewards: [Reward],
        behaviorTypes: [BehaviorType],
        onReloadStores: () -> Void,
        onClearSignatures: (UUID) -> Void
    ) {
        // Mark existing as not current
        if var existing = currentAgreement(forChild: childId, agreementVersions: agreementVersions) {
            existing.isCurrent = false
            repository.updateAgreementVersion(existing)
        }

        // Create new version
        let activeRewardIds = rewards
            .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
            .map { $0.id }
        let activeBehaviorIds = behaviorTypes
            .filter { $0.isActive }
            .map { $0.id }

        let newAgreement = AgreementVersion(
            childId: childId,
            coveredRewardIds: activeRewardIds,
            coveredBehaviorIds: activeBehaviorIds,
            isCurrent: true
        )

        repository.addAgreementVersion(newAgreement)
        onReloadStores()

        // Also clear old signatures on child
        onClearSignatures(childId)
    }

    /// Clear agreement signatures for a child
    /// Preserves exact logic from FamilyViewModel.clearAgreementSignatures(childId:)
    func clearAgreementSignatures(childId: UUID, onChildUpdated: (Child) -> Void) {
        guard var child = repository.getChildren().first(where: { $0.id == childId }) else { return }

        child.childSignature = AgreementSignature()
        child.parentSignature = AgreementSignature()
        child.agreementVersion += 1

        repository.updateChild(child)
        onChildUpdated(child)
    }

    /// Dismiss the new goal banner
    /// Preserves exact logic from FamilyViewModel.dismissNewGoalBanner()
    func dismissNewGoalBanner() {
        newGoalNeedsAgreement = nil
    }

    /// Set new goal needs agreement
    func setNewGoalNeedsAgreement(_ childId: UUID) {
        newGoalNeedsAgreement = childId
    }

    /// Clear new goal needs agreement
    func clearNewGoalNeedsAgreement() {
        newGoalNeedsAgreement = nil
    }
}
