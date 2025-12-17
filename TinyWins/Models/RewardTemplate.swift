import SwiftUI

// MARK: - Reward Template

/// A template for creating reward goals with suggested values
struct RewardTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let defaultPoints: Int
    let defaultDurationDays: Int
    let category: Category
    let minAge: Int?
    let maxAge: Int?
    var isPopular: Bool = false      // "Popular with families" badge
    var isQuickWin: Bool = false     // "Quick win" badge for short duration goals
    
    enum Category: String, CaseIterable {
        case outing = "Outing"
        case treat = "Treat"
        case qualityTime = "Quality Time"
        case learning = "Learning"
        case privilege = "Privilege"
        case experience = "Experience"
        
        var icon: String {
            switch self {
            case .outing: return "figure.walk"
            case .treat: return "birthday.cake.fill"
            case .qualityTime: return "heart.fill"
            case .learning: return "book.fill"
            case .privilege: return "star.fill"
            case .experience: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .outing: return .green
            case .treat: return .orange
            case .qualityTime: return .pink
            case .learning: return .blue
            case .privilege: return .purple
            case .experience: return .yellow
            }
        }
    }
    
    /// Check if this template is appropriate for a given age
    func isAppropriate(forAge age: Int?) -> Bool {
        guard let age = age else { return true }
        if let minAge = minAge, age < minAge { return false }
        if let maxAge = maxAge, age > maxAge { return false }
        return true
    }
}

// MARK: - Template Library

extension RewardTemplate {
    /// All available reward templates
    static let allTemplates: [RewardTemplate] = [
        // Outings
        RewardTemplate(
            id: "park_adventure",
            name: "Park Adventure",
            icon: "leaf.fill",
            defaultPoints: 12,
            defaultDurationDays: 5,
            category: .outing,
            minAge: nil,
            maxAge: 10,
            isPopular: true,
            isQuickWin: true
        ),
        RewardTemplate(
            id: "playground_champion",
            name: "Playground Champion",
            icon: "figure.play",
            defaultPoints: 10,
            defaultDurationDays: 5,
            category: .outing,
            minAge: nil,
            maxAge: 8
        ),
        RewardTemplate(
            id: "special_outing",
            name: "Special Outing Day",
            icon: "ticket.fill",
            defaultPoints: 30,
            defaultDurationDays: 14,
            category: .outing,
            minAge: 6,
            maxAge: nil
        ),
        RewardTemplate(
            id: "adventure_activity",
            name: "Adventure Activity",
            icon: "figure.run",
            defaultPoints: 25,
            defaultDurationDays: 10,
            category: .experience,
            minAge: 8,
            maxAge: nil
        ),
        
        // Treats
        RewardTemplate(
            id: "ice_cream_quest",
            name: "Ice Cream Quest",
            icon: "cup.and.saucer.fill",
            defaultPoints: 8,
            defaultDurationDays: 3,
            category: .treat,
            minAge: nil,
            maxAge: nil,
            isPopular: true,
            isQuickWin: true
        ),
        RewardTemplate(
            id: "pizza_party",
            name: "Pizza Party",
            icon: "fork.knife",
            defaultPoints: 15,
            defaultDurationDays: 5,
            category: .treat,
            minAge: nil,
            maxAge: nil
        ),
        RewardTemplate(
            id: "choose_dinner",
            name: "Choose Dinner",
            icon: "menucard.fill",
            defaultPoints: 12,
            defaultDurationDays: 5,
            category: .treat,
            minAge: nil,
            maxAge: nil
        ),
        
        // Quality Time
        RewardTemplate(
            id: "movie_night",
            name: "Movie Night",
            icon: "tv.fill",
            defaultPoints: 15,
            defaultDurationDays: 7,
            category: .qualityTime,
            minAge: nil,
            maxAge: nil,
            isPopular: true
        ),
        RewardTemplate(
            id: "story_time_journey",
            name: "Story Time Journey",
            icon: "book.fill",
            defaultPoints: 10,
            defaultDurationDays: 5,
            category: .qualityTime,
            minAge: nil,
            maxAge: 7
        ),
        RewardTemplate(
            id: "game_time_hero",
            name: "Game Time Hero",
            icon: "gamecontroller.fill",
            defaultPoints: 20,
            defaultDurationDays: 7,
            category: .qualityTime,
            minAge: 5,
            maxAge: nil,
            isPopular: true
        ),
        RewardTemplate(
            id: "sleepover_adventure",
            name: "Sleepover Adventure",
            icon: "moon.stars.fill",
            defaultPoints: 30,
            defaultDurationDays: 14,
            category: .experience,
            minAge: 6,
            maxAge: nil
        ),
        RewardTemplate(
            id: "friend_hangout",
            name: "Friend Hangout",
            icon: "person.2.fill",
            defaultPoints: 20,
            defaultDurationDays: 7,
            category: .qualityTime,
            minAge: 5,
            maxAge: nil
        ),
        
        // Privileges
        RewardTemplate(
            id: "screen_time_bonus",
            name: "Screen Time Bonus",
            icon: "iphone",
            defaultPoints: 15,
            defaultDurationDays: 5,
            category: .privilege,
            minAge: 6,
            maxAge: nil
        ),
        RewardTemplate(
            id: "late_night_unlock",
            name: "Stay Up Late",
            icon: "clock.fill",
            defaultPoints: 18,
            defaultDurationDays: 7,
            category: .privilege,
            minAge: 6,
            maxAge: nil
        ),
        RewardTemplate(
            id: "special_toy",
            name: "Special Toy Hunt",
            icon: "teddybear.fill",
            defaultPoints: 25,
            defaultDurationDays: 10,
            category: .experience,
            minAge: nil,
            maxAge: 10
        ),
        RewardTemplate(
            id: "shopping_trip",
            name: "Shopping Trip",
            icon: "bag.fill",
            defaultPoints: 35,
            defaultDurationDays: 14,
            category: .experience,
            minAge: 8,
            maxAge: nil
        )
    ]
    
    /// Get templates appropriate for a child's age
    static func templates(forAge age: Int?) -> [RewardTemplate] {
        allTemplates.filter { $0.isAppropriate(forAge: age) }
    }
    
    /// Get a selection of templates for the goal picker (3 random appropriate templates)
    static func goalPickerSelection(forAge age: Int?) -> [RewardTemplate] {
        let appropriate = templates(forAge: age)
        return Array(appropriate.shuffled().prefix(3))
    }
    
    /// Convert template to KidGoalOption with category mapping and badges
    func toKidGoalOption() -> KidGoalOption {
        KidGoalOption(
            name: name,
            icon: icon,
            stars: defaultPoints,
            days: defaultDurationDays,
            category: category.toKidGoalCategory(),
            isPopular: isPopular,
            isQuickWin: isQuickWin
        )
    }

    /// Get ALL templates as KidGoalOptions for the goal picker (grouped by category)
    static func allGoalOptions(forAge age: Int?) -> [KidGoalOption] {
        templates(forAge: age).map { $0.toKidGoalOption() }
    }
}

// MARK: - Category Mapping

extension RewardTemplate.Category {
    /// Map RewardTemplate.Category to KidGoalOption.KidGoalCategory
    func toKidGoalCategory() -> KidGoalOption.KidGoalCategory {
        switch self {
        case .treat: return .treats
        case .qualityTime: return .qualityTime
        case .outing: return .outings
        case .learning: return .qualityTime  // Group learning with quality time
        case .privilege: return .privileges
        case .experience: return .outings    // Group experiences with adventures
        }
    }
}
