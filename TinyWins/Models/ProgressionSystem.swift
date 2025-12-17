import Foundation
import SwiftUI

// MARK: - Array Extension for Safe Subscripting

extension Array {
    /// Safe subscript that returns nil instead of crashing for out-of-bounds access
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Parent Activity Tracking

struct ParentActivity: Codable {
 var activeDays: Set<String> = [] // Date strings"yyyy-MM-dd"
 var goalsCreated: Int = 0
 var goalsCompleted: Int = 0
 var lastActiveDate: Date?
 
 // Daily prompt tracking
 var lastPromptDate: Date?
 var promptsCompleted: Int = 0
 
 // Bonus star tracking (childId -> last date given)
 var lastBonusStarDates: [String: Date] = [:]
 
 mutating func recordActivity(on date: Date = Date()) {
 let dateString = Self.dateString(from: date)
 activeDays.insert(dateString)
 lastActiveDate = date
 }
 
 static func dateString(from date: Date) -> String {
 let formatter = DateFormatter()
 formatter.dateFormat = "yyyy-MM-dd"
 return formatter.string(from: date)
 }
 
 mutating func recordBonusStar(forChild childId: UUID) {
 lastBonusStarDates[childId.uuidString] = Date()
 }
 
 func canOfferBonusStar(forChild childId: UUID) -> Bool {
 guard let lastDate = lastBonusStarDates[childId.uuidString] else {
 return true // Never given before
 }
 
 let calendar = Calendar.current
 let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
 return daysSince >= 7 // At most once per week
 }
 
 // MARK: - Weekly Activity (non-consecutive)
 
 var activeDaysThisWeek: Int {
 let calendar = Calendar.current
 let today = Date()
 let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
 
 return (0..<7).filter { dayOffset in
 guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { return false }
 return activeDays.contains(Self.dateString(from: date))
 }.count
 }
 
 var activeDaysThisMonth: Int {
 let calendar = Calendar.current
 let today = Date()
 let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
 let range = calendar.range(of: .day, in: .month, for: today)!
 
 return range.filter { day in
 guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return false }
 return activeDays.contains(Self.dateString(from: date))
 }.count
 }
 
 // MARK: - Activity Status (Weekly-based, no consecutive requirement)
 
 var activityStatus: ActivityStatus {
 let thisWeek = activeDaysThisWeek
 let thisMonth = activeDaysThisMonth
 
 if thisWeek >= 5 {
 return .activeWeek(days: thisWeek)
 } else if thisWeek >= 3 {
 return .buildingHabit(days: thisWeek)
 } else if thisMonth >= 10 {
 return .activeMonth(days: thisMonth)
 } else if thisWeek >= 1 {
 return .gettingStarted(days: thisWeek)
 } else {
 return .readyWhenYouAre
 }
 }
 
 // MARK: - Parent Coach Level
 
 var coachLevel: CoachLevel {
 let weeksActive = activeDays.count / 3 // Rough estimate
 let goalRatio = goalsCreated > 0 ? Double(goalsCompleted) / Double(goalsCreated) : 0
 
 if weeksActive >= 12 && goalRatio >= 0.6 {
 return .steadyCoach
 } else if weeksActive >= 4 && goalsCompleted >= 2 {
 return .findingRhythm
 } else {
 return .gettingStarted
 }
 }
}

// MARK: - Activity Status (non-consecutive, pressure-free)

enum ActivityStatus {
 case readyWhenYouAre
 case gettingStarted(days: Int)
 case buildingHabit(days: Int)
 case activeWeek(days: Int)
 case activeMonth(days: Int)
 
 var displayText: String {
 switch self {
 case .readyWhenYouAre:
 return "Ready when you are"
 case .gettingStarted(let days):
 return "Active \(days) day\(days == 1 ? "" : "s") this week"
 case .buildingHabit(let days):
 return "Active \(days) days this week"
 case .activeWeek(let days):
 return "Active \(days) days this week. Nice!"
 case .activeMonth(let days):
 return "\(days) days active this month"
 }
 }
 
 var icon: String {
 switch self {
 case .readyWhenYouAre: return "leaf.fill"
 case .gettingStarted: return "sparkles"
 case .buildingHabit: return "heart.fill"
 case .activeWeek: return "star.fill"
 case .activeMonth: return "calendar.badge.checkmark"
 }
 }
 
 var color: String {
 switch self {
 case .readyWhenYouAre: return "blue"
 case .gettingStarted: return "green"
 case .buildingHabit: return "orange"
 case .activeWeek: return "yellow"
 case .activeMonth: return "purple"
 }
 }
}

enum CoachLevel: String, Codable, CaseIterable {
 case gettingStarted = "Explorer"
 case findingRhythm = "Guide"
 case steadyCoach = "Champion"
 
 var icon: String {
 switch self {
 case .gettingStarted: return "leaf.fill"
 case .findingRhythm: return "wind"
 case .steadyCoach: return "star.circle.fill"
 }
 }
 
 var description: String {
 switch self {
 case .gettingStarted:
 return "You're starting the journey of noticing the good moments"
 case .findingRhythm:
 return "You're discovering your family's unique rhythm"
 case .steadyCoach:
 return "You're a steady guide in your child's adventure"
 }
 }
}

// MARK: - Child Skill Badges

struct SkillBadge: Identifiable, Codable, Equatable {
 let id: UUID
 let childId: UUID
 let type: BadgeType
 let level: Int // 1, 2, 3
 let earnedDate: Date
 let behaviorCount: Int // How many times they did this
 
 init(id: UUID = UUID(), childId: UUID, type: BadgeType, level: Int, earnedDate: Date = Date(), behaviorCount: Int) {
 self.id = id
 self.childId = childId
 self.type = type
 self.level = level
 self.earnedDate = earnedDate
 self.behaviorCount = behaviorCount
 }
}

enum BadgeType: String, Codable, CaseIterable {
 case sharing = "Sharing Star"
 case helping = "Helper Hero"
 case kindness = "Kindness Champion"
 case patience = "Patience Pro"
 case bedtime = "Bedtime Hero"
 case morning = "Morning Master"
 case learning = "Learning Legend"
 case cleanup = "Cleanup Crew"
 case manners = "Manners Maven"
 case teamwork = "Team Player"
 
 var icon: String {
 switch self {
 case .sharing: return "gift.fill"
 case .helping: return "hands.sparkles.fill"
 case .kindness: return "heart.fill"
 case .patience: return "clock.fill"
 case .bedtime: return "moon.stars.fill"
 case .morning: return "sunrise.fill"
 case .learning: return "book.fill"
 case .cleanup: return "sparkles"
 case .manners: return "hand.wave.fill"
 case .teamwork: return "person.2.fill"
 }
 }
 
 var color: String {
 switch self {
 case .sharing: return "purple"
 case .helping: return "green"
 case .kindness: return "pink"
 case .patience: return "blue"
 case .bedtime: return "indigo"
 case .morning: return "orange"
 case .learning: return "teal"
 case .cleanup: return "mint"
 case .manners: return "cyan"
 case .teamwork: return "yellow"
 }
 }
 
 // Keywords that match this badge type
 var keywords: [String] {
 switch self {
 case .sharing: return ["share","sharing","gave","split"]
 case .helping: return ["help","helped","helping","assist"]
 case .kindness: return ["kind","nice","gentle","caring","compassion"]
 case .patience: return ["patient","wait","calm","frustrated"]
 case .bedtime: return ["bed","sleep","night","bedtime","pajamas"]
 case .morning: return ["morning","wake","breakfast","ready","dressed"]
 case .learning: return ["learn","read","homework","school","study"]
 case .cleanup: return ["clean","tidy","pick up","organize","put away"]
 case .manners: return ["please","thank","sorry","excuse","polite"]
 case .teamwork: return ["together","team","cooperate","sibling"]
 }
 }
 
 static func thresholdsForLevel(_ level: Int) -> Int {
 switch level {
 case 1: return 3
 case 2: return 10
 case 3: return 25
 default: return 50
 }
 }
}

// MARK: - Daily Parent Prompts

struct DailyPrompt: Identifiable {
 let id = UUID()
 let text: String
 let category: PromptCategory
 
 enum PromptCategory {
 case noticing
 case celebrating
 case reflecting
 }
 
 static let prompts: [DailyPrompt] = [
 // Noticing prompts
 DailyPrompt(text:"Today, try to catch one sharing moment", category: .noticing),
 DailyPrompt(text:"Notice when your child helps without being asked", category: .noticing),
 DailyPrompt(text:"Watch for a moment of patience today", category: .noticing),
 DailyPrompt(text:"Catch a moment of kindness between siblings", category: .noticing),
 DailyPrompt(text:"Notice when your child calms down after being upset", category: .noticing),
 DailyPrompt(text:"Look for a moment of cooperation today", category: .noticing),
 DailyPrompt(text:"Watch for good manners at mealtime", category: .noticing),
 DailyPrompt(text:"Notice effort, even if the result isn't perfect", category: .noticing),
 
 // Celebrating prompts
 DailyPrompt(text:"Tell your child something specific they did well yesterday", category: .celebrating),
 DailyPrompt(text:"Share a positive moment with your partner tonight", category: .celebrating),
 DailyPrompt(text:"Ask your child what they're proud of today", category: .celebrating),
 
 // Reflecting prompts
 DailyPrompt(text:"What's one strength your child showed this week?", category: .reflecting),
 DailyPrompt(text:"Think about what triggers challenges - can you prevent one?", category: .reflecting),
 ]
 
 static func randomPrompt(excluding lastPromptText: String? = nil) -> DailyPrompt {
 let filtered = prompts.filter { $0.text != lastPromptText }
 return filtered.randomElement() ?? prompts[safe: 0] ?? DailyPrompt(text: "", category: .celebrating)
 }
}

// MARK: - Special Moments (Memory Timeline)

struct SpecialMoment: Identifiable, Codable {
 let id: UUID
 let eventId: UUID // Links to BehaviorEvent
 let childId: UUID
 let markedDate: Date
 var caption: String?
 
 init(id: UUID = UUID(), eventId: UUID, childId: UUID, markedDate: Date = Date(), caption: String? = nil) {
 self.id = id
 self.eventId = eventId
 self.childId = childId
 self.markedDate = markedDate
 self.caption = caption
 }
}

// MARK: - Goal Mini Milestones

extension Reward {
 var milestones: [Int] {
 // Create milestones at ~25%, 50%, 75%
 guard targetPoints > 0 else { return [] }
 
 if targetPoints <= 10 {
 return [targetPoints / 2]
 } else if targetPoints <= 20 {
 return [targetPoints / 4, targetPoints / 2, (targetPoints * 3) / 4]
 } else {
 // Every 10 stars for larger goals
 let step = max(5, (targetPoints / 4 / 5) * 5) // Round to nearest 5
 var milestones: [Int] = []
 var current = step
 while current < targetPoints {
 milestones.append(current)
 current += step
 }
 return milestones
 }
 }
 
 func milestonesReached(currentPoints: Int) -> [Int] {
 milestones.filter { currentPoints >= $0 }
 }
 
 func nextMilestone(currentPoints: Int) -> Int? {
 milestones.first { currentPoints < $0 }
 }
 
 func justReachedMilestone(previousPoints: Int, currentPoints: Int) -> Int? {
 milestones.first { previousPoints < $0 && currentPoints >= $0 }
 }
}

// MARK: - Yearly Summary

struct YearlySummary {
 let year: Int
 let childId: UUID
 let totalPositiveMoments: Int
 let totalChallenges: Int
 let goalsCompleted: Int
 let topStrengths: [String] // Top 3 behavior names
 let improvedArea: String? // If challenge behavior reduced
 let specialMomentsCount: Int
 
 var summaryText: String {
 // Story-like narrative summary
 var text = "You've been building a beautiful map of \(totalPositiveMoments) positive moments this year."
 
 if goalsCompleted > 0 {
 text += " Together, you completed \(goalsCompleted) adventure\(goalsCompleted == 1 ? "" : "s")!"
 }
 
 if !topStrengths.isEmpty {
 if topStrengths.count == 1, let strength = topStrengths[safe: 0] {
 text += " Their superpower: \(strength)."
 } else if let lastStrength = topStrengths.last {
 let otherStrengths = topStrengths.dropLast().joined(separator: ", ")
 text += " Their superpowers: \(otherStrengths), and \(lastStrength)."
 }
 }
 
 if let improved = improvedArea {
 text += " Special growth area: \(improved)."
 }
 
 if specialMomentsCount > 0 {
 text += " You saved \(specialMomentsCount) special memor\(specialMomentsCount == 1 ?"y" :"ies") to treasure."
 }
 
 return text
 }
}

// MARK: - Cosmetic Unlocks

enum KidViewTheme: String, Codable, CaseIterable, Identifiable {
 case classic = "Classic"
 case space = "Space Adventure"
 case ocean = "Ocean Explorer"
 case forest = "Forest Friends"
 case rainbow = "Rainbow Path"
 
 var id: String { rawValue }
 
 var backgroundGradient: [String] {
 switch self {
 case .classic: return ["blue","purple"]
 case .space: return ["indigo","black"]
 case .ocean: return ["cyan","blue"]
 case .forest: return ["green","mint"]
 case .rainbow: return ["red","orange","yellow","green","blue","purple"]
 }
 }
 
 var icon: String {
 switch self {
 case .classic: return "star.fill"
 case .space: return "moon.stars.fill"
 case .ocean: return "fish.fill"
 case .forest: return "leaf.fill"
 case .rainbow: return "rainbow"
 }
 }
 
 static func unlockedThemes(goalsCompleted: Int) -> [KidViewTheme] {
 var unlocked: [KidViewTheme] = [.classic]
 if goalsCompleted >= 3 { unlocked.append(.ocean) }
 if goalsCompleted >= 5 { unlocked.append(.forest) }
 if goalsCompleted >= 8 { unlocked.append(.space) }
 if goalsCompleted >= 12 { unlocked.append(.rainbow) }
 return unlocked
 }
}

// MARK: - Kid Goal Option (for Kid Participation)

/// Represents a goal option that can be presented to a child for selection
struct KidGoalOption: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let stars: Int
    let days: Int
    let category: KidGoalCategory
    var isPopular: Bool = false      // "Popular" badge
    var isQuickWin: Bool = false     // "Quick win" badge

    /// Categories for organizing kid goal options (kid-friendly names)
    enum KidGoalCategory: String, CaseIterable, Identifiable {
        case treats = "Treats"
        case qualityTime = "Together Time"
        case outings = "Adventures"
        case privileges = "Special Perks"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .treats: return "birthday.cake.fill"
            case .qualityTime: return "heart.fill"
            case .outings: return "figure.walk"
            case .privileges: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .treats: return .orange
            case .qualityTime: return .pink
            case .outings: return .green
            case .privileges: return .purple
            }
        }
    }

    /// Initialize with category and badges
    init(name: String, icon: String, stars: Int, days: Int, category: KidGoalCategory, isPopular: Bool = false, isQuickWin: Bool = false) {
        self.name = name
        self.icon = icon
        self.stars = stars
        self.days = days
        self.category = category
        self.isPopular = isPopular
        self.isQuickWin = isQuickWin
    }

    /// Initialize without category for backward compatibility (defaults to treats)
    init(name: String, icon: String, stars: Int, days: Int) {
        self.name = name
        self.icon = icon
        self.stars = stars
        self.days = days
        self.category = .treats
        self.isPopular = false
        self.isQuickWin = false
    }
}
