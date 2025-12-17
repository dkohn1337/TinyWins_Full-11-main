import SwiftUI

// MARK: - Stat Card Components
// Components for displaying statistics and data cards

/// Compact stat display card with icon
struct StatCardView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        )
    }
}

/// Visual difficulty indicator for goals
struct DifficultyBadgeView: View {
    let level: DifficultyLevel

    enum DifficultyLevel: String {
        case easy = "Easy"
        case medium = "Medium"
        case challenging = "Challenging"
        case epic = "Epic"

        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .blue
            case .challenging: return .orange
            case .epic: return .purple
            }
        }

        var stars: Int {
            switch self {
            case .easy: return 1
            case .medium: return 2
            case .challenging: return 3
            case .epic: return 4
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<level.stars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(level.color)
            }

            Text(level.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(level.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(level.color.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview("Stats") {
    LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
        StatCardView(value: "847", label: "Moments Logged", icon: "heart.fill", color: .pink)
        StatCardView(value: "12", label: "Day Streak", icon: "flame.fill", color: .orange)
        StatCardView(value: "93%", label: "Positive Focus", icon: "sun.max.fill", color: .yellow)
        StatCardView(value: "8", label: "Goals Reached", icon: "trophy.fill", color: .purple)
    }
    .padding()
}
