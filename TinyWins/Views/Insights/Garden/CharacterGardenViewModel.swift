import SwiftUI
import Observation

// MARK: - Character Garden ViewModel

/// Manages the data and logic for the Character Garden visualization.
/// Calculates plant growth stages based on logged moments.
@Observable
final class CharacterGardenViewModel {

    // MARK: - Constants

    /// Thresholds for plant growth stages
    static let seedlingMax = 0
    static let sproutMax = 2
    static let youngPlantMax = 5
    static let buddingMax = 9
    static let bloomingMax = 14
    // 15+ = fullBloom

    // MARK: - Properties

    let child: Child
    private let events: [BehaviorEvent]
    private let behaviorTypes: [BehaviorType]

    var timeRange: GardenTimeRange = .thisWeek {
        didSet { recalculate() }
    }

    private(set) var plants: [GardenPlant] = []
    private(set) var heroMessage: GardenHeroMessage?
    private(set) var totalMoments: Int = 0
    private(set) var growingTraits: Int = 0

    // MARK: - Initialization

    init(child: Child, events: [BehaviorEvent], behaviorTypes: [BehaviorType]) {
        self.child = child
        self.events = events
        self.behaviorTypes = behaviorTypes
        recalculate()
    }

    // MARK: - Calculations

    private func recalculate() {
        let dateRange = timeRange.dateRange
        let childEvents = events.filter { $0.childId == child.id && dateRange.contains($0.timestamp) }

        // Calculate moments per trait
        var traitMoments: [CharacterTrait: Int] = [:]
        var traitPoints: [CharacterTrait: Int] = [:]

        for trait in CharacterTrait.allCases {
            traitMoments[trait] = 0
            traitPoints[trait] = 0
        }

        for event in childEvents {
            guard let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                continue
            }

            // Only count positive behaviors
            guard behaviorType.category == .positive || behaviorType.category == .routinePositive else {
                continue
            }

            let traits = CharacterTrait.traitsForBehavior(behaviorType.name)
            for trait in traits {
                traitMoments[trait, default: 0] += 1
                traitPoints[trait, default: 0] += max(0, event.pointsApplied)
            }
        }

        // Build plants array
        plants = CharacterTrait.allCases.map { trait in
            let moments = traitMoments[trait] ?? 0
            let points = traitPoints[trait] ?? 0
            let stage = GrowthStage.forMoments(moments)

            return GardenPlant(
                trait: trait,
                moments: moments,
                points: points,
                stage: stage,
                isGrowing: moments > 0
            )
        }

        // Sort by growth (most grown first for visual appeal)
        plants.sort { $0.moments > $1.moments }

        // Calculate summary stats
        totalMoments = childEvents.filter { event in
            guard let bt = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else { return false }
            return bt.category == .positive || bt.category == .routinePositive
        }.count

        growingTraits = plants.filter { $0.moments > 0 }.count

        // Generate hero message
        heroMessage = generateHeroMessage()
    }

    private func generateHeroMessage() -> GardenHeroMessage {
        // Find the strongest trait
        guard let strongestPlant = plants.first, strongestPlant.moments > 0 else {
            // No data yet - encouraging message
            return GardenHeroMessage(
                headline: "Ready to grow!",
                subheadline: "Log moments to watch \(child.name)'s garden bloom",
                trait: nil,
                mood: .encouraging
            )
        }

        // Check for multiple strong traits
        let bloomingPlants = plants.filter { $0.stage == .blooming || $0.stage == .fullBloom }

        if bloomingPlants.count >= 3 {
            return GardenHeroMessage(
                headline: "The garden is flourishing!",
                subheadline: "\(bloomingPlants.count) traits are blooming beautifully",
                trait: nil,
                mood: .celebration
            )
        }

        if strongestPlant.stage == .fullBloom {
            return GardenHeroMessage(
                headline: "\(strongestPlant.trait.displayName) is radiating!",
                subheadline: "\(strongestPlant.moments) moments of \(strongestPlant.trait.displayName.lowercased()) this \(timeRange.periodName)",
                trait: strongestPlant.trait,
                mood: .celebration
            )
        }

        if strongestPlant.stage == .blooming {
            return GardenHeroMessage(
                headline: "\(strongestPlant.trait.displayName) is blooming!",
                subheadline: "Keep nurturing - it's growing beautifully",
                trait: strongestPlant.trait,
                mood: .celebration
            )
        }

        if strongestPlant.stage == .budding {
            return GardenHeroMessage(
                headline: "\(strongestPlant.trait.displayName) is budding!",
                subheadline: "Almost ready to bloom - keep going!",
                trait: strongestPlant.trait,
                mood: .encouraging
            )
        }

        // Growing but not yet budding
        return GardenHeroMessage(
            headline: "\(strongestPlant.trait.displayName) is growing",
            subheadline: "Every moment helps the garden flourish",
            trait: strongestPlant.trait,
            mood: .encouraging
        )
    }
}

// MARK: - Garden Time Range

enum GardenTimeRange: String, CaseIterable, Identifiable {
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case allTime = "all_time"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .allTime: return "All Time"
        }
    }

    var periodName: String {
        switch self {
        case .thisWeek: return "week"
        case .thisMonth: return "month"
        case .allTime: return "time"
        }
    }

    var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return weekAgo...now

        case .thisMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return monthAgo...now

        case .allTime:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return yearAgo...now
        }
    }
}

// MARK: - Garden Plant Model

struct GardenPlant: Identifiable, Equatable {
    var id: String { trait.rawValue } // Stable ID based on trait
    let trait: CharacterTrait
    let moments: Int
    let points: Int
    let stage: GrowthStage
    let isGrowing: Bool

    var stageDescription: String {
        stage.description
    }

    var encouragement: String {
        switch stage {
        case .seedling:
            return "Ready to sprout"
        case .sprout:
            return "Just beginning"
        case .youngPlant:
            return "Growing nicely"
        case .budding:
            return "About to bloom!"
        case .blooming:
            return "Blooming beautifully"
        case .fullBloom:
            return "Radiating!"
        }
    }
}

// MARK: - Growth Stage

enum GrowthStage: Int, CaseIterable, Comparable {
    case seedling = 0
    case sprout = 1
    case youngPlant = 2
    case budding = 3
    case blooming = 4
    case fullBloom = 5

    static func < (lhs: GrowthStage, rhs: GrowthStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func forMoments(_ moments: Int) -> GrowthStage {
        switch moments {
        case 0:
            return .seedling
        case 1...CharacterGardenViewModel.sproutMax:
            return .sprout
        case (CharacterGardenViewModel.sproutMax + 1)...CharacterGardenViewModel.youngPlantMax:
            return .youngPlant
        case (CharacterGardenViewModel.youngPlantMax + 1)...CharacterGardenViewModel.buddingMax:
            return .budding
        case (CharacterGardenViewModel.buddingMax + 1)...CharacterGardenViewModel.bloomingMax:
            return .blooming
        default:
            return .fullBloom
        }
    }

    var description: String {
        switch self {
        case .seedling: return "Seedling"
        case .sprout: return "Sprout"
        case .youngPlant: return "Growing"
        case .budding: return "Budding"
        case .blooming: return "Blooming"
        case .fullBloom: return "Full Bloom"
        }
    }

    /// Height multiplier for plant visualization (0.0 to 1.0)
    var heightMultiplier: CGFloat {
        switch self {
        case .seedling: return 0.2
        case .sprout: return 0.35
        case .youngPlant: return 0.5
        case .budding: return 0.7
        case .blooming: return 0.85
        case .fullBloom: return 1.0
        }
    }

    /// Whether this stage shows flowers
    var hasFlowers: Bool {
        self >= .budding
    }

    /// Whether this stage shows full bloom effects
    var isFullyBloomed: Bool {
        self == .fullBloom
    }
}

// MARK: - Hero Message

struct GardenHeroMessage {
    let headline: String
    let subheadline: String
    let trait: CharacterTrait?
    let mood: HeroMood

    enum HeroMood {
        case encouraging
        case celebration
    }
}
