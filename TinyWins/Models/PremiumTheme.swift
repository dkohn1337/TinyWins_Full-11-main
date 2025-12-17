import SwiftUI

// MARK: - Premium Color Tags

/// Extended color options including premium colors
enum ExtendedColorTag: String, CaseIterable, Identifiable {
 // Free colors (match existing ColorTag)
 case blue
 case green
 case orange
 case purple
 case pink
 case teal
 case red
 case yellow
 
 // Premium colors
 case coral
 case mint
 case lavender
 case gold
 case navy
 case rose
 case forest
 case sunset
 
 var id: String { rawValue }
 
 var color: Color {
 switch self {
 // Free colors
 case .blue: return .blue
 case .green: return .green
 case .orange: return .orange
 case .purple: return .purple
 case .pink: return .pink
 case .teal: return .teal
 case .red: return .red
 case .yellow: return .yellow
 // Premium colors
 case .coral: return Color(red: 1.0, green: 0.5, blue: 0.45)
 case .mint: return Color(red: 0.6, green: 0.9, blue: 0.8)
 case .lavender: return Color(red: 0.7, green: 0.6, blue: 0.9)
 case .gold: return Color(red: 0.85, green: 0.7, blue: 0.3)
 case .navy: return Color(red: 0.2, green: 0.25, blue: 0.45)
 case .rose: return Color(red: 0.9, green: 0.5, blue: 0.6)
 case .forest: return Color(red: 0.2, green: 0.5, blue: 0.35)
 case .sunset: return Color(red: 1.0, green: 0.6, blue: 0.4)
 }
 }
 
 var displayName: String {
 rawValue.capitalized
 }
 
 var isPremium: Bool {
 switch self {
 case .blue, .green, .orange, .purple, .pink, .teal, .red, .yellow:
 return false
 case .coral, .mint, .lavender, .gold, .navy, .rose, .forest, .sunset:
 return true
 }
 }
 
 /// Convert to standard ColorTag (for storage compatibility)
 var asColorTag: ColorTag? {
 switch self {
 case .blue: return .blue
 case .green: return .green
 case .orange: return .orange
 case .purple: return .purple
 case .pink: return .pink
 case .teal: return .teal
 case .red: return .red
 case .yellow: return .yellow
 default: return nil
 }
 }
 
 /// All free colors
 static var freeColors: [ExtendedColorTag] {
 allCases.filter { !$0.isPremium }
 }
 
 /// All premium colors
 static var premiumColors: [ExtendedColorTag] {
 allCases.filter { $0.isPremium }
 }
}

// MARK: - Avatar Styles

/// Avatar style options for children
enum AvatarStyle: String, CaseIterable, Identifiable {
 // Free styles
 case initials = "Initials"
 case emoji = "Emoji"
 
 // Premium styles
 case animal = "Animal"
 case superhero = "Superhero"
 case space = "Space"
 case nature = "Nature"
 
 var id: String { rawValue }
 
 var isPremium: Bool {
 switch self {
 case .initials, .emoji:
 return false
 case .animal, .superhero, .space, .nature:
 return true
 }
 }
 
 /// Available icons for this style
 var icons: [String] {
 switch self {
 case .initials:
 return [] // Uses initials instead
 case .emoji:
 return ["", "", "", "", "", "", "", ""]
 case .animal:
 return ["", "", "", "", "", "", "", ""]
 case .superhero:
 return ["", "", "", "", "", "", "", ""]
 case .space:
 return ["", "", "", "", "", "", "", ""]
 case .nature:
 return ["", "", "", "", "", "", "", ""]
 }
 }
 
 static var freeStyles: [AvatarStyle] {
 allCases.filter { !$0.isPremium }
 }
 
 static var premiumStyles: [AvatarStyle] {
 allCases.filter { $0.isPremium }
 }
}

// MARK: - Theme Preview

#Preview("Premium Colors") {
 LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
 ForEach(ExtendedColorTag.allCases) { color in
 VStack(spacing: 4) {
 Circle()
 .fill(color.color)
 .frame(width: 44, height: 44)
 .overlay {
 if color.isPremium {
 Image(systemName: "lock.fill")
 .font(.caption)
 .foregroundColor(.white)
 }
 }
 
 Text(color.displayName)
 .font(.caption2)
 }
 }
 }
 .padding()
}

#Preview("Avatar Styles") {
 VStack(alignment: .leading, spacing: 20) {
 ForEach(AvatarStyle.allCases) { style in
 VStack(alignment: .leading, spacing: 8) {
 HStack {
 Text(style.rawValue)
 .font(.headline)
 if style.isPremium {
 PlusBadge(small: true)
 }
 }
 
 if !style.icons.isEmpty {
 HStack {
 ForEach(style.icons.prefix(4), id: \.self) { icon in
 Text(icon)
 .font(.title2)
 }
 }
 } else {
 Text("AB")
 .font(.title2)
 .fontWeight(.semibold)
 .foregroundColor(.white)
 .frame(width: 40, height: 40)
 .background(Circle().fill(.blue))
 }
 }
 }
 }
 .padding()
}
