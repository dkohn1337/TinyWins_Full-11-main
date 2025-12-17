import Foundation

/// Premium features that require TinyWins Plus subscription
enum PremiumFeature: String, CaseIterable {
    case multipleChildren
    case multipleActiveGoals
    case longTermInsights
    case advancedAnalytics
    case iCloudBackup
    case premiumThemes
    case parentReflectionInsights
    case personalizedPrompts
    case coParentReflectionSharing

    var displayName: String {
        switch self {
        case .multipleChildren: return "Multiple Children"
        case .multipleActiveGoals: return "Multiple Active Goals"
        case .longTermInsights: return "Long-term Insights"
        case .advancedAnalytics: return "Advanced Insights"
        case .iCloudBackup: return "iCloud Backup"
        case .premiumThemes: return "Personalization"
        case .parentReflectionInsights: return "Parent Insights"
        case .personalizedPrompts: return "Personalized Prompts"
        case .coParentReflectionSharing: return "Share Reflections"
        }
    }

    var description: String {
        switch self {
        case .multipleChildren:
            return "Track up to 5 children in one app."
        case .multipleActiveGoals:
            return "Set up to 3 active reward goals per child."
        case .longTermInsights:
            return "See trends over 30 days, 90 days, and 6 months."
        case .advancedAnalytics:
            return "Discover strengths, patterns, and hot spots."
        case .iCloudBackup:
            return "Manual backup and restore to iCloud."
        case .premiumThemes:
            return "Make the app feel like yours with more themes."
        case .parentReflectionInsights:
            return "See your parenting patterns and strengths over time."
        case .personalizedPrompts:
            return "Get reflection prompts based on your day's events."
        case .coParentReflectionSharing:
            return "Share reflections with your partner and see alignment."
        }
    }
}

// MARK: - Tier Limits

struct TierLimits {
    // Free tier limits
    static let freeMaxChildren = 1
    static let freeMaxActiveGoalsPerChild = 1
    static let freeInsightsDays = 7
    static let freeHistoryDays = 30
    static let freeReflectionHistoryDays = 7

    // Plus tier limits
    static let plusMaxChildren = 5
    static let plusMaxActiveGoalsPerChild = 3
    static let plusInsightsDays = 180 // 6 months
    static let plusHistoryDays = 365
    static let plusReflectionHistoryDays = 365 // All time
}

// MARK: - Upsell Context

/// Context for showing premium upsells
enum PlusUpsellContext {
    case addChild
    case addGoal
    case longTermInsights
    case advancedAnalytics
    case iCloudBackup
    case premiumTheme
    
    var title: String {
        switch self {
        case .addChild: return "Add more children"
        case .addGoal: return "Set more goals"
        case .longTermInsights: return "See long-term trends"
        case .advancedAnalytics: return "Discover patterns"
        case .iCloudBackup: return "Keep your data safe"
        case .premiumTheme: return "Unlock more styles"
        }
    }
    
    var message: String {
        switch self {
        case .addChild:
            return "Track rewards for all your children in one place with TinyWins Plus."
        case .addGoal:
            return "Set up to 3 active goals per child with TinyWins Plus."
        case .longTermInsights:
            return "See what is working over weeks and months with TinyWins Plus."
        case .advancedAnalytics:
            return "Discover your child's strengths and patterns with TinyWins Plus."
        case .iCloudBackup:
            return "Back up and restore your family data to iCloud with TinyWins Plus."
        case .premiumTheme:
            return "Make the app feel like yours with themes like Forest, Midnight, and Lavender."
        }
    }
    
    var icon: String {
        switch self {
        case .addChild: return "figure.2.and.child.holdinghands"
        case .addGoal: return "star.circle"
        case .longTermInsights: return "chart.line.uptrend.xyaxis"
        case .advancedAnalytics: return "chart.bar.xaxis"
        case .iCloudBackup: return "icloud"
        case .premiumTheme: return "paintpalette"
        }
    }
}
