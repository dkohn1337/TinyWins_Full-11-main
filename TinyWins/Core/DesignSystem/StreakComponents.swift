import SwiftUI

// MARK: - Streak System Components
// Components for displaying and animating streak progress

/// Animated flame icon that dances when streak is active
struct StreakFlameView: View {
    let streakCount: Int
    @State private var flame1Offset: CGFloat = 0
    @State private var flame2Offset: CGFloat = 0
    @State private var flame3Offset: CGFloat = 0

    private var flameSize: CGFloat {
        switch streakCount {
        case 0...6: return 48
        case 7...13: return 56
        case 14...29: return 64
        default: return 72
        }
    }

    private var flameColor: Color {
        switch streakCount {
        case 0...6: return .yellow
        case 7...13: return .orange
        case 14...29: return .red
        default: return .purple // Legendary streak
        }
    }

    var body: some View {
        ZStack {
            // Base flame
            Image(systemName: "flame.fill")
                .font(.system(size: flameSize))
                .foregroundColor(flameColor)
                .offset(y: flame1Offset)
                .shadow(color: flameColor.opacity(0.6), radius: 20)

            // Dancing flames for visual interest
            if streakCount >= 7 {
                Image(systemName: "flame.fill")
                    .font(.system(size: flameSize * 0.75))
                    .foregroundColor(.yellow)
                    .offset(x: -8, y: flame2Offset)
                    .opacity(0.7)

                Image(systemName: "flame.fill")
                    .font(.system(size: flameSize * 0.75))
                    .foregroundColor(.red)
                    .offset(x: 8, y: flame3Offset)
                    .opacity(0.7)
            }
        }
        .onAppear {
            startFlameAnimation()
        }
    }

    private func startFlameAnimation() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            flame1Offset = -4
        }
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(0.1)) {
            flame2Offset = -6
        }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.2)) {
            flame3Offset = -5
        }
    }
}

/// Complete streak display with count and messaging
struct StreakBadgeView: View {
    @Environment(\.theme) private var theme
    let streakCount: Int
    let showDangerWarning: Bool

    private var message: String {
        switch streakCount {
        case 0: return "Start your streak!"
        case 1...2: return "Keep it going!"
        case 3...6: return "You're on fire!"
        case 7...13: return "Amazing streak!"
        case 14...29: return "Unstoppable!"
        default: return "LEGENDARY!"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            StreakFlameView(streakCount: streakCount)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(streakCount) Days")
                    .font(.system(size: 32, weight: .black, design: .rounded))

                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textSecondary)

                if showDangerWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Log before midnight!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.2), .yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .orange.opacity(0.2), radius: 16, y: 8)
    }
}

// MARK: - Preview

#Preview("Streak Badge") {
    VStack(spacing: 20) {
        StreakBadgeView(streakCount: 14, showDangerWarning: false)
        StreakBadgeView(streakCount: 5, showDangerWarning: true)
    }
    .padding()
}
