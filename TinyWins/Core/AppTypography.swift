import SwiftUI

/// Comprehensive typography system for TinyWins
/// Provides a consistent, scalable type hierarchy with emotional impact
struct AppTypography {

    // MARK: - Display (Hero Moments)

    /// Extra-large display text for celebration moments and hero screens
    /// Usage: Goal celebrations, major milestones
    static let display = Font.system(size: 40, weight: .black, design: .rounded)

    /// Large display text for impactful headers
    /// Usage: Kid view hero headers, onboarding
    static let displayLarge = Font.system(size: 36, weight: .bold, design: .rounded)

    // MARK: - Titles

    /// Primary screen titles
    /// Usage: Navigation bar titles, main screen headers
    static let title1 = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Section headers and card titles
    /// Usage: "Today's Focus", "Your Journey", card headers
    static let title2 = Font.system(size: 24, weight: .bold, design: .default)

    /// List item titles and sub-section headers
    /// Usage: Child names, behavior names, reward titles
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body Text

    /// Large body text for important messages
    /// Usage: Focus cards, important instructions, celebration copy
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .default)

    /// Standard body text (default for most content)
    /// Usage: Descriptions, list items, general content
    static let body = Font.system(size: 16, weight: .regular, design: .default)

    /// Small body text for secondary content
    /// Usage: Metadata, supporting text
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    // MARK: - UI Elements

    /// Captions for timestamps and metadata
    /// Usage: "2 hours ago", "Last updated", tips
    static let caption = Font.system(size: 12, weight: .medium, design: .default)

    /// Labels for form fields and chips
    /// Usage: Input labels, chip text, tags
    static let label = Font.system(size: 14, weight: .semibold, design: .default)

    /// Large button text
    /// Usage: Primary CTAs, important actions
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .default)

    /// Standard button text
    /// Usage: Secondary actions, list buttons
    static let button = Font.system(size: 15, weight: .semibold, design: .default)

    /// Small button text
    /// Usage: Tertiary actions, inline links
    static let buttonSmall = Font.system(size: 14, weight: .medium, design: .default)

    // MARK: - Child-Friendly Variants

    /// Extra-large, friendly text for kid-facing screens
    /// Usage: Kid view greetings, goal names
    static let childHero = Font.system(size: 36, weight: .black, design: .rounded)

    /// Large, friendly text for kid-facing content
    /// Usage: Kid view section headers, achievements
    static let childTitle = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Medium, friendly text for kid-facing body
    /// Usage: Kid view descriptions, progress messages
    static let childBody = Font.system(size: 20, weight: .semibold, design: .rounded)

    // MARK: - Helper Extensions
}

// MARK: - Text Extensions

extension Text {
    /// Apply display typography
    func displayStyle() -> Text {
        self.font(AppTypography.display)
    }

    /// Apply title1 typography
    func title1Style() -> Text {
        self.font(AppTypography.title1)
    }

    /// Apply title2 typography
    func title2Style() -> Text {
        self.font(AppTypography.title2)
    }

    /// Apply title3 typography
    func title3Style() -> Text {
        self.font(AppTypography.title3)
    }

    /// Apply bodyLarge typography
    func bodyLargeStyle() -> Text {
        self.font(AppTypography.bodyLarge)
    }

    /// Apply child-friendly hero typography
    func childHeroStyle() -> Text {
        self.font(AppTypography.childHero)
    }

    /// Apply child-friendly title typography
    func childTitleStyle() -> Text {
        self.font(AppTypography.childTitle)
    }

    /// Apply child-friendly body typography
    func childBodyStyle() -> Text {
        self.font(AppTypography.childBody)
    }
}

// MARK: - Preview

#Preview("Typography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Display")
                    .font(AppTypography.display)

                Text("Display Large")
                    .font(AppTypography.displayLarge)

                Text("Title 1 - Screen Headers")
                    .font(AppTypography.title1)

                Text("Title 2 - Section Headers")
                    .font(AppTypography.title2)

                Text("Title 3 - Card Headers")
                    .font(AppTypography.title3)
            }

            Divider()

            Group {
                Text("Body Large - Important messages that deserve emphasis and breathing room")
                    .font(AppTypography.bodyLarge)

                Text("Body - Standard text for most content. This is what you'll read most often in the app. It's comfortable at 16pt and easy on the eyes.")
                    .font(AppTypography.body)

                Text("Body Small - Supporting text that provides additional context without competing for attention")
                    .font(AppTypography.bodySmall)

                Text("Caption - Timestamps and metadata")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            Group {
                Text("Button Large")
                    .font(AppTypography.buttonLarge)

                Text("Button Standard")
                    .font(AppTypography.button)

                Text("Button Small")
                    .font(AppTypography.buttonSmall)
            }

            Divider()

            Group {
                Text("🎉 Child Hero Text")
                    .font(AppTypography.childHero)

                Text("Child Title")
                    .font(AppTypography.childTitle)

                Text("Child Body Text")
                    .font(AppTypography.childBody)
            }
        }
        .padding()
    }
}
