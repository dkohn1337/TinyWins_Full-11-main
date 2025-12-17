import SwiftUI
import Combine

/// Manages celebration display to ensure at most one full-screen modal per user action.
/// Secondary celebrations are converted to lightweight banners/toasts.
@MainActor
class CelebrationManager: ObservableObject {
    
    // MARK: - Celebration Types with Priority
    
    /// Celebration types ordered by priority (highest first)
    enum CelebrationType: Comparable {
        case goalReached(childId: UUID, childName: String, rewardId: UUID, rewardName: String, rewardIcon: String?)
        case goldStarDay(childId: UUID, childName: String, momentCount: Int)
        case milestoneReached(childId: UUID, childName: String, rewardId: UUID, rewardName: String, milestone: Int, target: Int, message: String)
        case patternFound(childId: UUID, childName: String, behaviorId: UUID, behaviorName: String, count: Int, insight: PatternInsight)
        
        /// Priority value (lower = higher priority)
        var priorityValue: Int {
            switch self {
            case .goalReached: return 0
            case .goldStarDay: return 1
            case .milestoneReached: return 2
            case .patternFound: return 3
            }
        }
        
        static func < (lhs: CelebrationType, rhs: CelebrationType) -> Bool {
            lhs.priorityValue < rhs.priorityValue
        }
        
        var childId: UUID {
            switch self {
            case .goalReached(let childId, _, _, _, _): return childId
            case .goldStarDay(let childId, _, _): return childId
            case .milestoneReached(let childId, _, _, _, _, _, _): return childId
            case .patternFound(let childId, _, _, _, _, _): return childId
            }
        }
        
        var displayName: String {
            switch self {
            case .goalReached: return "Goal Reached"
            case .goldStarDay: return "Gold Star Day"
            case .milestoneReached: return "Milestone Reached"
            case .patternFound: return "Pattern Found"
            }
        }
    }
    
    /// Pattern insight data for secondary display
    struct PatternInsight: Equatable {
        let title: String
        let message: String
        let suggestion: String?
        let icon: String
        let color: Color
    }
    
    /// Secondary celebration for banner/toast display
    struct SecondaryCelebration: Identifiable, Equatable {
        let id = UUID()
        let type: String
        let childName: String
        let message: String
        let icon: String
        let color: Color
        
        static func == (lhs: SecondaryCelebration, rhs: SecondaryCelebration) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Published State
    
    /// Currently showing full-screen modal type
    @Published private(set) var activeCelebration: CelebrationType?
    
    /// Whether a modal is currently being presented
    @Published private(set) var isShowingModal: Bool = false
    
    /// Secondary celebrations to show as banners after modal dismissal
    @Published var pendingSecondaryCelebrations: [SecondaryCelebration] = []
    
    /// Current secondary celebration to display as banner
    @Published var currentSecondaryBanner: SecondaryCelebration?
    
    // MARK: - Private State
    
    /// Tracks current action to batch celebrations
    private var currentActionId: UUID?
    
    /// Pending celebrations for current action
    private var pendingCelebrations: [CelebrationType] = []
    
    // MARK: - Public API
    
    /// Queue a celebration for the current action.
    /// Call `processCelebrations()` when the action is complete.
    func queueCelebration(_ celebration: CelebrationType, forAction actionId: UUID) {
        // If this is a new action, clear previous pending
        if currentActionId != actionId {
            // DIAGNOSTIC: New action detected, clearing previous batch
            #if DEBUG
            if !pendingCelebrations.isEmpty {
                print("⚠️ CelebrationManager: New action \(actionId.uuidString.prefix(8)) detected. Dropping \(pendingCelebrations.count) pending celebrations from previous action.")
            }
            #endif
            currentActionId = actionId
            pendingCelebrations = []
        }

        #if DEBUG
        print("📥 CelebrationManager: Queued \(celebration.displayName) for action \(actionId.uuidString.prefix(8)) (total: \(pendingCelebrations.count + 1))")
        #endif
        pendingCelebrations.append(celebration)
    }
    
    /// Process all queued celebrations for the current action.
    /// Shows the highest priority as a modal, converts others to secondary.
    func processCelebrations(forAction actionId: UUID) {
        // DIAGNOSTIC: Check for action ID mismatch (race condition indicator)
        #if DEBUG
        if currentActionId != actionId {
            print("⚠️ CelebrationManager: Action ID mismatch in processCelebrations. Expected \(actionId.uuidString.prefix(8)), got \(currentActionId?.uuidString.prefix(8) ?? "nil"). This may indicate a race condition.")
        }
        #endif

        guard currentActionId == actionId, !pendingCelebrations.isEmpty else {
            #if DEBUG
            if pendingCelebrations.isEmpty {
                print("ℹ️ CelebrationManager: processCelebrations called for action \(actionId.uuidString.prefix(8)) but no celebrations queued.")
            }
            #endif
            return
        }

        #if DEBUG
        print("🎉 CelebrationManager: Processing \(pendingCelebrations.count) celebration(s) for action \(actionId.uuidString.prefix(8))")
        #endif

        // Sort by priority (lowest priorityValue = highest priority)
        let sorted = pendingCelebrations.sorted()

        // If already showing a modal, convert ALL to secondary
        if isShowingModal {
            #if DEBUG
            print("⚠️ CelebrationManager: Modal already showing. Converting all \(sorted.count) celebrations to secondary banners.")
            #endif
            for celebration in sorted {
                addSecondary(from: celebration)
            }
            pendingCelebrations = []
            currentActionId = nil
            return
        }

        // Take highest priority for full modal
        if let primary = sorted.first {
            #if DEBUG
            print("✅ CelebrationManager: Showing primary celebration: \(primary.displayName)")
            #endif
            activeCelebration = primary
            isShowingModal = true

            // Convert rest to secondary celebrations
            #if DEBUG
            if sorted.count > 1 {
                print("📋 CelebrationManager: Converting \(sorted.count - 1) celebration(s) to secondary banners")
            }
            #endif
            for celebration in sorted.dropFirst() {
                addSecondary(from: celebration)
            }
        }

        pendingCelebrations = []
        currentActionId = nil
    }
    
    /// Dismiss the current full-screen celebration.
    /// Will show secondary banners if any are pending.
    func dismissCelebration() {
        activeCelebration = nil
        isShowingModal = false

        // Show first secondary banner after a brief delay
        if !pendingSecondaryCelebrations.isEmpty {
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                self?.showNextSecondaryBanner()
            }
        }
    }

    /// Dismiss the current secondary banner
    func dismissSecondaryBanner() {
        currentSecondaryBanner = nil

        // Show next secondary after delay if any remain
        if !pendingSecondaryCelebrations.isEmpty {
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                self?.showNextSecondaryBanner()
            }
        }
    }
    
    /// Check if we should show Gold Star Day celebration
    func shouldTriggerGoldStarDay(positiveCount: Int) -> Bool {
        positiveCount == 5 // Only trigger exactly at 5 to avoid re-triggering
    }
    
    /// Clear all celebrations (for testing or reset)
    func clearAll() {
        activeCelebration = nil
        isShowingModal = false
        pendingCelebrations = []
        pendingSecondaryCelebrations = []
        currentSecondaryBanner = nil
        currentActionId = nil
    }
    
    // MARK: - Private Helpers
    
    private func showNextSecondaryBanner() {
        guard !pendingSecondaryCelebrations.isEmpty else { return }
        currentSecondaryBanner = pendingSecondaryCelebrations.removeFirst()

        // Auto-dismiss after 5 seconds
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if self?.currentSecondaryBanner != nil {
                self?.dismissSecondaryBanner()
            }
        }
    }
    
    private func addSecondary(from celebration: CelebrationType) {
        let secondary: SecondaryCelebration
        
        switch celebration {
        case .goalReached(_, let childName, _, let rewardName, _):
            secondary = SecondaryCelebration(
                type: "Goal Reached",
                childName: childName,
                message: "\(childName) reached their goal: \(rewardName)!",
                icon: "trophy.fill",
                color: .green
            )
            
        case .goldStarDay(_, let childName, let count):
            secondary = SecondaryCelebration(
                type: "Gold Star Day",
                childName: childName,
                message: "Gold Star Day! \(count) positive moments today.",
                icon: "star.fill",
                color: .yellow
            )
            
        case .milestoneReached(_, let childName, _, let rewardName, let milestone, let target, _):
            let percent = Int((Double(milestone) / Double(target)) * 100)
            secondary = SecondaryCelebration(
                type: "Milestone",
                childName: childName,
                message: "\(childName) reached \(percent)% of \(rewardName)!",
                icon: "flag.fill",
                color: .blue
            )
            
        case .patternFound(_, let childName, _, let behaviorName, _, _):
            secondary = SecondaryCelebration(
                type: "Pattern Found",
                childName: childName,
                message: "'\(behaviorName)' is becoming a strength for \(childName).",
                icon: "star.fill",
                color: .purple
            )
        }
        
        pendingSecondaryCelebrations.append(secondary)
    }
}

// MARK: - Convenience Extensions

extension CelebrationManager.CelebrationType {
    /// Create a goal reached celebration
    static func goalReached(
        childId: UUID,
        childName: String,
        reward: Reward
    ) -> CelebrationManager.CelebrationType {
        .goalReached(
            childId: childId,
            childName: childName,
            rewardId: reward.id,
            rewardName: reward.name,
            rewardIcon: reward.imageName
        )
    }
    
    /// Create a milestone celebration
    static func milestone(
        childId: UUID,
        childName: String,
        reward: Reward,
        milestone: Int,
        message: String
    ) -> CelebrationManager.CelebrationType {
        .milestoneReached(
            childId: childId,
            childName: childName,
            rewardId: reward.id,
            rewardName: reward.name,
            milestone: milestone,
            target: reward.targetPoints,
            message: message
        )
    }
}
