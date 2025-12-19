import SwiftUI

// MARK: - Social Proof Components
// Components for displaying social validation and testimonials

/// Avatar stack with count
struct SocialProofView: View {
    let count: Int
    let message: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            // Avatar stack
            HStack(spacing: -12) {
                ForEach(0..<min(5, count), id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: avatarColors[index % avatarColors.count],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(theme.surface1, lineWidth: 3)
                        )
                }

                if count > 5 {
                    Circle()
                        .fill(theme.borderStrong)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("+\(count - 5)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(theme.surface1, lineWidth: 3)
                        )
                }
            }

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
    }

    private let avatarColors: [[Color]] = [
        [.blue, .cyan],
        [.purple, .pink],
        [.orange, .yellow],
        [.green, .mint],
        [.red, .orange]
    ]
}

/// User testimonial with rating
struct TestimonialCardView: View {
    let quote: String
    let author: String
    let rating: Int

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            // Stars
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < rating ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
            }

            // Quote
            Text("\"\(quote)\"")
                .font(.system(size: 16))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
                .italic()

            // Author
            Text("- \(author)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textSecondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.surface1)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        )
    }
}

/// Horizontal scrolling badge collection
struct BadgeShowcaseView: View {
    @Environment(\.theme) private var theme
    let badges: [BadgeItem]

    struct BadgeItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        let isUnlocked: Bool
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(badges) { badge in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    badge.isUnlocked ?
                                    LinearGradient(
                                        colors: [badge.color, badge.color.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [theme.textDisabled.opacity(0.3), theme.textDisabled.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: badge.isUnlocked ? badge.color.opacity(0.4) : .clear, radius: 12)

                            if badge.isUnlocked {
                                Image(systemName: badge.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.textDisabled)
                            }
                        }

                        Text(badge.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(badge.isUnlocked ? theme.textPrimary : theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
