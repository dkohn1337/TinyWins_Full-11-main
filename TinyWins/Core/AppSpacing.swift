import SwiftUI

/// 8px grid-based spacing system for consistent rhythm and alignment
/// All spacing values are multiples of 4 or 8 for visual harmony
struct AppSpacing {

    // MARK: - Core Spacing Scale (8px grid)

    /// 2pt - Minimal spacing for very tight layouts
    /// Usage: Between icon and adjacent text in chips, inline elements
    static let xxxs: CGFloat = 2

    /// 4pt - Tight spacing within single UI elements
    /// Usage: Icon-to-text gaps, badge padding
    static let xxs: CGFloat = 4

    /// 8pt - Small spacing, minimum for tap targets
    /// Usage: Button padding (vertical), list item gaps
    static let xs: CGFloat = 8

    /// 12pt - Comfortable small spacing
    /// Usage: Component padding, small card margins
    static let sm: CGFloat = 12

    /// 16pt - Default spacing for most use cases
    /// Usage: Card padding, section spacing, standard margins
    static let md: CGFloat = 16

    /// 24pt - Large section spacing
    /// Usage: Between major sections, screen padding
    static let lg: CGFloat = 24

    /// 32pt - Extra large spacing
    /// Usage: Screen edge margins, hero spacing
    static let xl: CGFloat = 32

    /// 48pt - Hero spacing for dramatic layouts
    /// Usage: Celebration screens, onboarding, kid view headers
    static let xxl: CGFloat = 48

    /// 64pt - Maximum spacing for special moments
    /// Usage: Full-screen celebrations, dramatic reveals
    static let xxxl: CGFloat = 64

    // MARK: - Semantic Spacing

    /// Standard horizontal padding for screen edges
    static let screenPadding: CGFloat = md // 16pt

    /// Comfortable reading width (horizontal padding for text)
    static let readingPadding: CGFloat = lg // 24pt

    /// Gap between cards in vertical list
    static let cardGap: CGFloat = sm // 12pt

    /// Gap between major sections
    static let sectionGap: CGFloat = lg // 24pt

    /// Internal padding for cards
    static let cardPadding: CGFloat = md // 16pt

    /// Internal padding for large cards
    static let cardPaddingLarge: CGFloat = lg // 24pt

    /// Minimum tap target size (44pt iOS standard)
    static let minTapTarget: CGFloat = 44

    /// Comfortable tap target size
    static let comfortableTapTarget: CGFloat = 52

    /// Large tap target for important actions
    static let largeTapTarget: CGFloat = 60

    // MARK: - Helper Methods

    /// Get spacing for a given multiplier of the base unit (8pt)
    /// - Parameter multiplier: Number of base units (e.g., 2 = 16pt, 3 = 24pt)
    /// - Returns: Calculated spacing
    static func grid(_ multiplier: CGFloat) -> CGFloat {
        return multiplier * 8
    }

    /// Get custom spacing while maintaining rhythm
    /// Rounds to nearest 4pt increment
    /// - Parameter value: Desired spacing value
    /// - Returns: Rounded spacing that maintains grid
    static func custom(_ value: CGFloat) -> CGFloat {
        return round(value / 4) * 4
    }
}

// MARK: - Corner Radius Scale

/// Consistent corner radius values
struct AppCorners {
    /// 4px - Badges, small pills
    static let xs: CGFloat = 4

    /// 8px - Buttons, inputs
    static let sm: CGFloat = 8

    /// 12px - Cards, containers
    static let md: CGFloat = 12

    /// 16px - Large cards
    static let lg: CGFloat = 16

    /// 20px - Hero cards
    static let xl: CGFloat = 20

    /// 24px - Modals, sheets
    static let xxl: CGFloat = 24
}

// MARK: - Card Anatomy Tokens

/// Card padding constants for consistent card layouts
struct AppCardPadding {
    /// Standard card internal padding (16pt)
    static let standard: CGFloat = 16
    /// Compact card padding (12pt)
    static let compact: CGFloat = 12
    /// Large card padding (20pt)
    static let large: CGFloat = 20
}

/// Card anatomy spacing for consistent internal structure
struct CardAnatomy {
    /// Space between overline and title (4pt)
    static let overlineToTitle: CGFloat = 4
    /// Space between title and support line (6pt)
    static let titleToSupport: CGFloat = 6
    /// Space between support line and content (12pt)
    static let supportToContent: CGFloat = 12
    /// Space between content and takeaway (16pt)
    static let contentToTakeaway: CGFloat = 16
    /// Space between takeaway lines (8pt)
    static let takeawaySpacing: CGFloat = 8
    /// Space between takeaway and footer (12pt)
    static let takeawayToFooter: CGFloat = 12
    /// Space between footer and action (16pt)
    static let footerToAction: CGFloat = 16
}

// MARK: - Surface Colors

/// Surface colors for card components with proper dark mode contrast
struct AppSurfaces {
    /// Takeaway/Try background surface - uses secondarySystemGroupedBackground for proper contrast
    static let takeawayBackground = Color(.secondarySystemGroupedBackground)
}

// MARK: - Insight Card Overlines

/// Category labels for insight cards - Title Case for calm, premium feel
struct InsightOverlines {
    static let summary = "Summary"
    static let activity = "Activity"
    static let strength = "Strength"
    static let pattern = "Pattern"
}

// MARK: - Standard Icon Gradients

/// Standardized icon gradients for insight cards - reduces visual noise
struct InsightIconGradients {
    static let summary: [Color] = [.purple, .indigo]
    static let activity: [Color] = [.blue, .cyan]
    static let strength: [Color] = [.green, .mint]
    static let challenge: [Color] = [.orange, .red]
}

// MARK: - SwiftUI Extensions

extension EdgeInsets {
    /// Create EdgeInsets with uniform spacing
    static func all(_ spacing: CGFloat) -> EdgeInsets {
        EdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
    }

    /// Create EdgeInsets with horizontal and vertical spacing
    static func symmetric(horizontal: CGFloat = 0, vertical: CGFloat = 0) -> EdgeInsets {
        EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    /// Standard screen edge insets
    static var screen: EdgeInsets {
        .all(AppSpacing.screenPadding)
    }

    /// Standard card insets
    static var card: EdgeInsets {
        .all(AppSpacing.cardPadding)
    }

    /// Large card insets
    static var cardLarge: EdgeInsets {
        .all(AppSpacing.cardPaddingLarge)
    }
}

// MARK: - Preview

#Preview("Spacing Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Spacing Scale (8px Grid)")
                .font(AppTypography.title2)
                .padding(.bottom, AppSpacing.sm)

            // Visual spacing demonstration
            Group {
                SpacingRow(name: "xxxs (2pt)", spacing: AppSpacing.xxxs)
                SpacingRow(name: "xxs (4pt)", spacing: AppSpacing.xxs)
                SpacingRow(name: "xs (8pt)", spacing: AppSpacing.xs)
                SpacingRow(name: "sm (12pt)", spacing: AppSpacing.sm)
                SpacingRow(name: "md (16pt)", spacing: AppSpacing.md)
                SpacingRow(name: "lg (24pt)", spacing: AppSpacing.lg)
                SpacingRow(name: "xl (32pt)", spacing: AppSpacing.xl)
                SpacingRow(name: "xxl (48pt)", spacing: AppSpacing.xxl)
                SpacingRow(name: "xxxl (64pt)", spacing: AppSpacing.xxxl)
            }

            Divider()
                .padding(.vertical, AppSpacing.md)

            Text("Tap Targets")
                .font(AppTypography.title3)
                .padding(.bottom, AppSpacing.sm)

            HStack(spacing: AppSpacing.md) {
                TapTargetExample(size: AppSpacing.minTapTarget, label: "Min (44pt)")
                TapTargetExample(size: AppSpacing.comfortableTapTarget, label: "Comfort (52pt)")
                TapTargetExample(size: AppSpacing.largeTapTarget, label: "Large (60pt)")
            }
        }
        .padding(AppSpacing.screenPadding)
    }
}

// MARK: - Preview Helpers

private struct SpacingRow: View {
    let name: String
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(name)
                .font(AppTypography.bodySmall)
                .frame(width: 100, alignment: .leading)

            Rectangle()
                .fill(Color.blue)
                .frame(width: spacing, height: 20)

            Text("\(Int(spacing))pt")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct TapTargetExample: View {
    let size: CGFloat
    let label: String

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }
}
