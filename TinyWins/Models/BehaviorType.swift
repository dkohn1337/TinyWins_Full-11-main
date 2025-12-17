import Foundation

enum BehaviorCategory: String, Codable, CaseIterable, Identifiable {
 case routinePositive
 case positive
 case negative
 
 var id: String { rawValue }
 
 var displayName: String {
 switch self {
 case .routinePositive: return "Routines"
 case .positive: return "Positive"
 case .negative: return "Challenges"
 }
 }
 
 var emoji: String {
 switch self {
 case .routinePositive: return ""
 case .positive: return ""
 case .negative: return ""
 }
 }
 
 var iconName: String {
 switch self {
 case .routinePositive: return "calendar.badge.clock"
 case .positive: return "hand.thumbsup.fill"
 case .negative: return "exclamationmark.triangle.fill"
 }
 }
}

/// Age range for behavior suggestions
struct AgeRange: Codable, Equatable {
 var minAge: Int
 var maxAge: Int
 
 static let infant = AgeRange(minAge: 0, maxAge: 2)
 static let toddler = AgeRange(minAge: 1, maxAge: 4) // Include 1-year-olds
 static let preschool = AgeRange(minAge: 4, maxAge: 6)
 static let earlyElementary = AgeRange(minAge: 6, maxAge: 8)
 static let lateElementary = AgeRange(minAge: 8, maxAge: 11)
 static let tweens = AgeRange(minAge: 11, maxAge: 13)
 static let teens = AgeRange(minAge: 13, maxAge: 18)
 static let allAges = AgeRange(minAge: 0, maxAge: 18)
 
 func contains(age: Int) -> Bool {
 age >= minAge && age <= maxAge
 }
 
 var displayName: String {
 if minAge == 0 && maxAge == 18 { return "All Ages" }
 return "\(minAge)-\(maxAge) years"
 }
}

/// Difficulty level for behaviors
enum DifficultyLevel: Int, Codable, CaseIterable, Identifiable {
 case simple = 1
 case easy = 2
 case medium = 3
 case hard = 4
 case veryHard = 5
 
 var id: Int { rawValue }
 
 var displayName: String {
 switch self {
 case .simple: return "Simple"
 case .easy: return "Easy"
 case .medium: return "Medium"
 case .hard: return "Hard"
 case .veryHard: return "Very Hard"
 }
 }
 
 /// Suggested point range for this difficulty
 var suggestedPointRange: ClosedRange<Int> {
 switch self {
 case .simple: return 1...2
 case .easy: return 2...3
 case .medium: return 3...5
 case .hard: return 5...7
 case .veryHard: return 7...10
 }
 }
 
 /// Default points for this difficulty
 var defaultPoints: Int {
 switch self {
 case .simple: return 1
 case .easy: return 2
 case .medium: return 3
 case .hard: return 5
 case .veryHard: return 8
 }
 }
}

struct BehaviorType: Identifiable, Codable, Equatable {
 let id: UUID
 var name: String
 var category: BehaviorCategory
 var defaultPoints: Int
 var isActive: Bool
 var iconName: String
 var suggestedAgeRange: AgeRange
 var difficultyScore: Int // 1-5 scale
 var isMonetized: Bool // Whether this behavior counts toward allowance
 var isCustom: Bool // User-created vs pre-seeded
 
 init(
 id: UUID = UUID(),
 name: String,
 category: BehaviorCategory,
 defaultPoints: Int,
 isActive: Bool = true,
 iconName: String = "star.fill",
 suggestedAgeRange: AgeRange = .allAges,
 difficultyScore: Int = 3,
 isMonetized: Bool = false,
 isCustom: Bool = false
 ) {
 self.id = id
 self.name = name
 self.category = category
 self.defaultPoints = defaultPoints
 self.isActive = isActive
 self.iconName = iconName
 self.suggestedAgeRange = suggestedAgeRange
 self.difficultyScore = max(1, min(5, difficultyScore))
 self.isMonetized = isMonetized
 self.isCustom = isCustom
 }
 
 var difficulty: DifficultyLevel {
 DifficultyLevel(rawValue: difficultyScore) ?? .medium
 }
 
 /// Suggested point range based on category
 static func suggestedPointRange(for category: BehaviorCategory) -> ClosedRange<Int> {
 switch category {
 case .routinePositive: return 3...10
 case .positive: return 1...5
 case .negative: return -10...(-1)
 }
 }
 
 /// Get suggested points based on difficulty and category
 static func suggestedPoints(difficulty: DifficultyLevel, category: BehaviorCategory) -> Int {
 let basePoints = difficulty.defaultPoints
 if category == .negative {
 return -basePoints
 }
 return basePoints
 }
}

// MARK: - Default Behavior Types
extension BehaviorType {
 static let defaultBehaviors: [BehaviorType] = [
 // Positive routine behaviors - All ages
 BehaviorType(name:"Morning routine completed", category: .routinePositive, defaultPoints: 5, iconName:"sun.horizon.fill", suggestedAgeRange: .allAges, difficultyScore: 3),
 BehaviorType(name:"Bedtime routine completed", category: .routinePositive, defaultPoints: 5, iconName:"moon.stars.fill", suggestedAgeRange: .allAges, difficultyScore: 3),
 BehaviorType(name:"Homework completed", category: .routinePositive, defaultPoints: 5, iconName:"book.fill", suggestedAgeRange: AgeRange(minAge: 5, maxAge: 18), difficultyScore: 3, isMonetized: true),
 BehaviorType(name:"Brushed teeth", category: .routinePositive, defaultPoints: 2, iconName:"mouth.fill", suggestedAgeRange: .allAges, difficultyScore: 1),
 BehaviorType(name:"Made bed", category: .routinePositive, defaultPoints: 2, iconName:"bed.double.fill", suggestedAgeRange: AgeRange(minAge: 4, maxAge: 18), difficultyScore: 1, isMonetized: true),
 
 // Age-specific routine behaviors (chores - monetizable)
 BehaviorType(name:"Put toys away", category: .routinePositive, defaultPoints: 2, iconName:"tray.full.fill", suggestedAgeRange: .toddler, difficultyScore: 1, isMonetized: true),
 BehaviorType(name:"Helped tidy up", category: .routinePositive, defaultPoints: 2, iconName:"hands.sparkles.fill", suggestedAgeRange: .infant, difficultyScore: 1),
 BehaviorType(name:"Got dressed independently", category: .routinePositive, defaultPoints: 3, iconName:"tshirt.fill", suggestedAgeRange: .preschool, difficultyScore: 2),
 BehaviorType(name:"Packed school bag", category: .routinePositive, defaultPoints: 3, iconName:"backpack.fill", suggestedAgeRange: .earlyElementary, difficultyScore: 2, isMonetized: true),
 BehaviorType(name:"Completed chores", category: .routinePositive, defaultPoints: 5, iconName:"checklist", suggestedAgeRange: .lateElementary, difficultyScore: 3, isMonetized: true),
 BehaviorType(name:"Managed screen time", category: .routinePositive, defaultPoints: 3, iconName:"iphone", suggestedAgeRange: .tweens, difficultyScore: 2),
 BehaviorType(name:"Completed project on time", category: .routinePositive, defaultPoints: 8, iconName:"doc.text.fill", suggestedAgeRange: .teens, difficultyScore: 5, isMonetized: true),
 BehaviorType(name:"Set the table", category: .routinePositive, defaultPoints: 2, iconName:"fork.knife", suggestedAgeRange: AgeRange(minAge: 5, maxAge: 12), difficultyScore: 1, isMonetized: true),
 BehaviorType(name:"Helped with dishes", category: .routinePositive, defaultPoints: 3, iconName:"sink.fill", suggestedAgeRange: AgeRange(minAge: 8, maxAge: 18), difficultyScore: 2, isMonetized: true),
 BehaviorType(name:"Folded laundry", category: .routinePositive, defaultPoints: 3, iconName:"washer.fill", suggestedAgeRange: AgeRange(minAge: 8, maxAge: 18), difficultyScore: 2, isMonetized: true),
 BehaviorType(name:"Cleaned room", category: .routinePositive, defaultPoints: 5, iconName:"sparkles", suggestedAgeRange: AgeRange(minAge: 6, maxAge: 18), difficultyScore: 3, isMonetized: true),
 BehaviorType(name:"Fed the pet", category: .routinePositive, defaultPoints: 2, iconName:"pawprint.fill", suggestedAgeRange: AgeRange(minAge: 5, maxAge: 18), difficultyScore: 1, isMonetized: true),
 
 // Positive behaviors (not monetized - character building)
 BehaviorType(name:"Helped sibling", category: .positive, defaultPoints: 3, iconName:"heart.fill", suggestedAgeRange: .allAges, difficultyScore: 2),
 BehaviorType(name:"Listened the first time", category: .positive, defaultPoints: 2, iconName:"ear.fill", suggestedAgeRange: .allAges, difficultyScore: 2),
 BehaviorType(name:"Shared toys", category: .positive, defaultPoints: 2, iconName:"gift.fill", suggestedAgeRange: AgeRange(minAge: 1, maxAge: 10), difficultyScore: 2),
 BehaviorType(name:"Used gentle hands", category: .positive, defaultPoints: 2, iconName:"hand.raised.fill", suggestedAgeRange: AgeRange(minAge: 0, maxAge: 8), difficultyScore: 2),
 BehaviorType(name:"Gave hugs or kisses", category: .positive, defaultPoints: 2, iconName:"heart.circle.fill", suggestedAgeRange: .infant, difficultyScore: 1),
 BehaviorType(name:"Kind words", category: .positive, defaultPoints: 2, iconName:"bubble.left.fill", suggestedAgeRange: .allAges, difficultyScore: 1),
 BehaviorType(name:"Cleaned up without asking", category: .positive, defaultPoints: 3, iconName:"sparkles", suggestedAgeRange: .allAges, difficultyScore: 2),
 BehaviorType(name:"Showed patience", category: .positive, defaultPoints: 3, iconName:"clock.fill", suggestedAgeRange: .allAges, difficultyScore: 3),
 BehaviorType(name:"Tried something new", category: .positive, defaultPoints: 3, iconName:"star.fill", suggestedAgeRange: .allAges, difficultyScore: 2),
 BehaviorType(name:"Read for fun", category: .positive, defaultPoints: 2, iconName:"book.closed.fill", suggestedAgeRange: AgeRange(minAge: 5, maxAge: 18), difficultyScore: 1),
 BehaviorType(name:"Exercised/Played outside", category: .positive, defaultPoints: 2, iconName:"figure.run", suggestedAgeRange: .allAges, difficultyScore: 1),
 BehaviorType(name:"Said please and thank you", category: .positive, defaultPoints: 1, iconName:"face.smiling.fill", suggestedAgeRange: .allAges, difficultyScore: 1),
 BehaviorType(name:"Stayed calm when upset", category: .positive, defaultPoints: 4, iconName:"heart.circle.fill", suggestedAgeRange: .allAges, difficultyScore: 4),
 
 // Negative behaviors
 BehaviorType(name:"Hit sibling", category: .negative, defaultPoints: -5, iconName:"hand.raised.slash.fill", suggestedAgeRange: .allAges, difficultyScore: 4),
 BehaviorType(name:"Shouting at parent", category: .negative, defaultPoints: -3, iconName:"speaker.wave.3.fill", suggestedAgeRange: .allAges, difficultyScore: 3),
 BehaviorType(name:"Refused shower/bath", category: .negative, defaultPoints: -2, iconName:"drop.fill", suggestedAgeRange: .allAges, difficultyScore: 2),
 BehaviorType(name:"Didn't listen", category: .negative, defaultPoints: -2, iconName:"ear.trianglebadge.exclamationmark", suggestedAgeRange: .allAges, difficultyScore: 2),
 BehaviorType(name:"Tantrum", category: .negative, defaultPoints: -3, iconName:"cloud.bolt.fill", suggestedAgeRange: AgeRange(minAge: 1, maxAge: 10), difficultyScore: 3),
 BehaviorType(name:"Broke rules", category: .negative, defaultPoints: -3, iconName:"exclamationmark.triangle.fill", suggestedAgeRange: .allAges, difficultyScore: 3),
 BehaviorType(name:"Lying", category: .negative, defaultPoints: -5, iconName:"xmark.circle.fill", suggestedAgeRange: .allAges, difficultyScore: 4),
 BehaviorType(name:"Screen time violation", category: .negative, defaultPoints: -3, iconName:"iphone.slash", suggestedAgeRange: AgeRange(minAge: 6, maxAge: 18), difficultyScore: 3),
 BehaviorType(name:"Refused to do homework", category: .negative, defaultPoints: -3, iconName:"book.closed.fill", suggestedAgeRange: AgeRange(minAge: 5, maxAge: 18), difficultyScore: 3),
 ]
 
 static let availableIcons: [String] = [
"star.fill","heart.fill","sun.horizon.fill","moon.stars.fill",
"book.fill","book.closed.fill","pencil","graduationcap.fill","backpack.fill",
"gift.fill","sparkles","hands.clap.fill","hand.thumbsup.fill",
"figure.run","bicycle","sportscourt.fill","trophy.fill",
"music.note","paintpalette.fill","gamecontroller.fill","puzzlepiece.fill",
"fork.knife","cup.and.saucer.fill","leaf.fill","drop.fill",
"bed.double.fill","house.fill","car.fill","airplane",
"bubble.left.fill","ear.fill","eye.fill","face.smiling.fill",
"hand.raised.slash.fill","speaker.wave.3.fill","cloud.bolt.fill",
"exclamationmark.triangle.fill","xmark.circle.fill","ear.trianglebadge.exclamationmark",
"tray.full.fill","tshirt.fill","checklist","doc.text.fill",
"iphone","iphone.slash","clock.fill","mouth.fill",
"dollarsign.circle.fill","banknote.fill","creditcard.fill",
"pawprint.fill","sink.fill","washer.fill","hand.raised.fill",
"heart.circle.fill"
 ]
 
 /// Get suggested behaviors for a specific age
 static func suggestedBehaviors(forAge age: Int) -> [BehaviorType] {
 defaultBehaviors.filter { $0.suggestedAgeRange.contains(age: age) }
 }
}
