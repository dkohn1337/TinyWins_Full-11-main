import SwiftUI

// MARK: - TinyWins Design System Guide
// Complete visual specifications and measurements

// MARK: - Spacing System (8px Base Grid)

/// Consistent spacing values based on 8px grid
struct AppSpacing {
    /// 4px - Minimal spacing for tight elements
    static let xxs: CGFloat = 4

    /// 8px - Small spacing between related elements
    static let xs: CGFloat = 8

    /// 12px - Compact spacing
    static let sm: CGFloat = 12

    /// 16px - Default spacing between elements
    static let md: CGFloat = 16

    /// 20px - Medium-large spacing
    static let lg: CGFloat = 20

    /// 24px - Large spacing between sections
    static let xl: CGFloat = 24

    /// 32px - Extra large spacing for major sections
    static let xxl: CGFloat = 32

    /// 40px - Hero spacing
    static let xxxl: CGFloat = 40

    /// 48px - Maximum spacing
    static let huge: CGFloat = 48
}

// MARK: - Typography System

/// Consistent typography scale
struct AppTypography {

    // MARK: - Display (Heroes, Numbers)

    /// 88pt - Giant hero numbers (progress ring center)
    static let heroNumber = Font.system(size: 88, weight: .black, design: .rounded)

    /// 72pt - Large hero stats
    static let displayLarge = Font.system(size: 72, weight: .black, design: .rounded)

    /// 48pt - Medium display
    static let displayMedium = Font.system(size: 48, weight: .bold, design: .rounded)

    /// 36pt - Small display
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)

    // MARK: - Headings

    /// 32pt - Page titles
    static let h1 = Font.system(size: 32, weight: .bold)

    /// 28pt - Section headers
    static let h2 = Font.system(size: 28, weight: .bold)

    /// 24pt - Subsection headers
    static let h3 = Font.system(size: 24, weight: .bold)

    /// 22pt - Card titles
    static let h4 = Font.system(size: 22, weight: .semibold)

    /// 20pt - Component headers
    static let h5 = Font.system(size: 20, weight: .semibold)

    /// 18pt - List item headers
    static let h6 = Font.system(size: 18, weight: .semibold)

    // MARK: - Body Text

    /// 18pt - Large body text
    static let bodyLarge = Font.system(size: 18, weight: .regular)

    /// 16pt - Default body text
    static let body = Font.system(size: 16, weight: .regular)

    /// 15pt - Compact body text
    static let bodySmall = Font.system(size: 15, weight: .regular)

    // MARK: - Supporting Text

    /// 14pt - Labels, captions
    static let label = Font.system(size: 14, weight: .medium)

    /// 13pt - Secondary labels
    static let labelSmall = Font.system(size: 13, weight: .medium)

    /// 12pt - Captions, timestamps
    static let caption = Font.system(size: 12, weight: .regular)

    /// 11pt - Fine print
    static let caption2 = Font.system(size: 11, weight: .regular)

    /// 10pt - Badges, tags
    static let micro = Font.system(size: 10, weight: .semibold)
}

// MARK: - Corner Radius System

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

    /// 28px - Full-width cards
    static let xxxl: CGFloat = 28

    /// 32px - Premium cards
    static let huge: CGFloat = 32

    /// Full circle (use frame dimension / 2)
    static func circle(_ size: CGFloat) -> CGFloat { size / 2 }
}

// MARK: - Shadow System

/// Consistent shadow configurations
struct AppShadows {

    /// Subtle shadow for cards at rest
    static let subtle = Shadow(color: .black.opacity(0.04), radius: 8, y: 4)

    /// Light shadow for interactive elements
    static let light = Shadow(color: .black.opacity(0.06), radius: 12, y: 6)

    /// Medium shadow for elevated cards
    static let medium = Shadow(color: .black.opacity(0.08), radius: 16, y: 8)

    /// Strong shadow for modals
    static let strong = Shadow(color: .black.opacity(0.12), radius: 20, y: 10)

    /// Colored glow shadow for accent elements
    static func glow(_ color: Color, intensity: CGFloat = 0.4) -> Shadow {
        Shadow(color: color.opacity(intensity), radius: 16, y: 8)
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
}

// MARK: - Icon Sizes

/// Standard icon sizes
struct AppIconSizes {
    /// 12pt - Inline icons
    static let xs: CGFloat = 12

    /// 16pt - Small icons
    static let sm: CGFloat = 16

    /// 20pt - Default icons
    static let md: CGFloat = 20

    /// 24pt - Medium icons
    static let lg: CGFloat = 24

    /// 28pt - Large icons
    static let xl: CGFloat = 28

    /// 32pt - Hero icons
    static let xxl: CGFloat = 32

    /// 40pt - Feature icons
    static let xxxl: CGFloat = 40

    /// 48pt - Display icons
    static let huge: CGFloat = 48

    /// 56pt - Giant icons
    static let giant: CGFloat = 56
}

// MARK: - Component Sizes

/// Standard component dimensions
struct AppSizes {

    // MARK: - Avatars
    static let avatarXS: CGFloat = 24
    static let avatarSM: CGFloat = 32
    static let avatarMD: CGFloat = 40
    static let avatarLG: CGFloat = 44
    static let avatarXL: CGFloat = 52
    static let avatarXXL: CGFloat = 64
    static let avatarHuge: CGFloat = 80

    // MARK: - Progress Rings
    static let progressRingSmall: CGFloat = 60
    static let progressRingMedium: CGFloat = 120
    static let progressRingLarge: CGFloat = 180
    static let progressRingGiant: CGFloat = 260

    static let progressStrokeSmall: CGFloat = 6
    static let progressStrokeMedium: CGFloat = 12
    static let progressStrokeLarge: CGFloat = 20
    static let progressStrokeGiant: CGFloat = 28

    // MARK: - Buttons
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightMedium: CGFloat = 44
    static let buttonHeightLarge: CGFloat = 52
    static let buttonHeightHero: CGFloat = 56

    // MARK: - Cards
    static let cardMinHeight: CGFloat = 80
    static let cardMediumHeight: CGFloat = 120
    static let cardLargeHeight: CGFloat = 180

    // MARK: - Milestones
    static let milestoneMarkerSmall: CGFloat = 8
    static let milestoneMarkerMedium: CGFloat = 12
    static let milestoneMarkerLarge: CGFloat = 16

    // MARK: - Touch Targets
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Animation Specifications

/// Standard animation configurations
struct AppAnimations {

    // MARK: - Durations
    static let durationFast: Double = 0.15
    static let durationNormal: Double = 0.25
    static let durationSlow: Double = 0.4
    static let durationHero: Double = 0.6

    // MARK: - Spring Animations
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let springSmooth = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let springHero = Animation.spring(response: 1.0, dampingFraction: 0.7)

    // MARK: - Easing
    static let easeOut = Animation.easeOut(duration: durationNormal)
    static let easeIn = Animation.easeIn(duration: durationNormal)
    static let easeInOut = Animation.easeInOut(duration: durationNormal)

    // MARK: - Repeating
    static let pulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    static let rotate = Animation.linear(duration: 20).repeatForever(autoreverses: false)
}

// MARK: - Color Opacity System

/// Standard opacity values
struct AppOpacity {
    /// 5% - Subtle backgrounds
    static let subtle: CGFloat = 0.05

    /// 8% - Light tints
    static let light: CGFloat = 0.08

    /// 10% - Backgrounds
    static let background: CGFloat = 0.10

    /// 15% - Card backgrounds
    static let card: CGFloat = 0.15

    /// 20% - Borders, dividers
    static let border: CGFloat = 0.20

    /// 30% - Secondary elements
    static let secondary: CGFloat = 0.30

    /// 40% - Shadows, overlays
    static let overlay: CGFloat = 0.40

    /// 50% - Half opacity
    static let half: CGFloat = 0.50

    /// 70% - Prominent elements
    static let prominent: CGFloat = 0.70

    /// 85% - Near-full opacity
    static let high: CGFloat = 0.85
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

// MARK: - Z-Index Layers

/// Standard z-index values for layering
struct AppLayers {
    static let base: Double = 0
    static let content: Double = 1
    static let overlay: Double = 10
    static let dropdown: Double = 20
    static let modal: Double = 30
    static let toast: Double = 40
    static let celebration: Double = 50
}

// MARK: - Gradient Presets

/// Common gradient configurations
struct AppGradients {

    /// Primary purple-pink gradient
    static let primary = LinearGradient(
        colors: [.purple, .pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success green gradient
    static let success = LinearGradient(
        colors: [.green, .green.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Warning orange gradient
    static let warning = LinearGradient(
        colors: [.orange, .yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Streak fire gradient
    static let fire = LinearGradient(
        colors: [.red, .orange, .yellow],
        startPoint: .bottom,
        endPoint: .top
    )

    /// Premium gold gradient
    static let premium = LinearGradient(
        colors: [.yellow, .orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle background gradient
    static func subtle(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.15), color.opacity(0.05), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Child color gradient
    static func childColor(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Angular gradient for progress rings
    static func progressRing(_ color: Color) -> AngularGradient {
        AngularGradient(
            colors: [
                color,
                color.opacity(0.7),
                color.opacity(0.5),
                color
            ],
            center: .center
        )
    }
}

// MARK: - Component Specifications

/// Detailed specs for key components
struct ComponentSpecs {

    // MARK: - Progress Ring (Giant)

    struct GiantProgressRing {
        static let size: CGFloat = 260
        static let strokeWidth: CGFloat = 28
        static let centerNumberSize: CGFloat = 88
        static let secondaryTextSize: CGFloat = 24
        static let milestoneMarkerSize: CGFloat = 16
        static let milestoneGlowRadius: CGFloat = 8
    }

    // MARK: - Hero Stat Card

    struct HeroStatCard {
        static let numberSize: CGFloat = 72
        static let labelSize: CGFloat = 20
        static let iconSize: CGFloat = 48
        static let cornerRadius: CGFloat = 24
        static let padding: CGFloat = 24
        static let shadowRadius: CGFloat = 20
    }

    // MARK: - Child Switcher Pill

    struct ChildSwitcherPill {
        static let avatarSize: CGFloat = 44
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let spacing: CGFloat = 12
    }

    // MARK: - Goal Card

    struct GoalCard {
        static let iconContainerSize: CGFloat = 56
        static let progressBarHeight: CGFloat = 12
        static let milestoneMarkerSize: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
    }

    // MARK: - Ready Badge

    struct ReadyBadge {
        static let iconSizeSmall: CGFloat = 24
        static let iconSizeMedium: CGFloat = 40
        static let iconSizeLarge: CGFloat = 56
        static let pulseScale: CGFloat = 1.15
        static let glowRadius: CGFloat = 20
    }

    // MARK: - Streak Flame

    struct StreakFlame {
        static let baseSizeNormal: CGFloat = 48
        static let baseSizeMedium: CGFloat = 56
        static let baseSizeLarge: CGFloat = 64
        static let baseSizeLegendary: CGFloat = 72
        static let danceOffset: CGFloat = 6
    }

    // MARK: - Countdown Timer

    struct CountdownTimer {
        static let iconSize: CGFloat = 18
        static let fontSize: CGFloat = 18
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 10
        static let cornerRadius: CGFloat = 999 // Capsule
    }

    // MARK: - CTA Button

    struct CTAButton {
        static let height: CGFloat = 56
        static let cornerRadius: CGFloat = 20
        static let fontSize: CGFloat = 22
        static let shadowRadius: CGFloat = 20
        static let shadowY: CGFloat = 10
    }

    // MARK: - Feature Row

    struct FeatureRow {
        static let iconContainerSize: CGFloat = 56
        static let iconSize: CGFloat = 24
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - Pricing Card

    struct PricingCard {
        static let priceSize: CGFloat = 32
        static let titleSize: CGFloat = 24
        static let padding: CGFloat = 24
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 3
    }

    // MARK: - Testimonial Card

    struct TestimonialCard {
        static let starSize: CGFloat = 16
        static let quoteSize: CGFloat = 16
        static let authorSize: CGFloat = 14
        static let padding: CGFloat = 24
        static let cornerRadius: CGFloat = 20
    }
}

// MARK: - Preview Guide

#Preview("Typography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("88pt Hero Number")
                    .font(AppTypography.heroNumber)
                Text("72pt Display Large")
                    .font(AppTypography.displayLarge)
                Text("48pt Display Medium")
                    .font(AppTypography.displayMedium)
                Text("36pt Display Small")
                    .font(AppTypography.displaySmall)
            }

            Divider()

            Group {
                Text("32pt Heading 1")
                    .font(AppTypography.h1)
                Text("28pt Heading 2")
                    .font(AppTypography.h2)
                Text("24pt Heading 3")
                    .font(AppTypography.h3)
                Text("22pt Heading 4")
                    .font(AppTypography.h4)
                Text("20pt Heading 5")
                    .font(AppTypography.h5)
                Text("18pt Heading 6")
                    .font(AppTypography.h6)
            }

            Divider()

            Group {
                Text("18pt Body Large")
                    .font(AppTypography.bodyLarge)
                Text("16pt Body")
                    .font(AppTypography.body)
                Text("15pt Body Small")
                    .font(AppTypography.bodySmall)
                Text("14pt Label")
                    .font(AppTypography.label)
                Text("12pt Caption")
                    .font(AppTypography.caption)
                Text("10pt Micro")
                    .font(AppTypography.micro)
            }
        }
        .padding()
    }
}

#Preview("Spacing Scale") {
    VStack(alignment: .leading, spacing: 8) {
        SpacingRow(name: "xxs", value: AppSpacing.xxs)
        SpacingRow(name: "xs", value: AppSpacing.xs)
        SpacingRow(name: "sm", value: AppSpacing.sm)
        SpacingRow(name: "md", value: AppSpacing.md)
        SpacingRow(name: "lg", value: AppSpacing.lg)
        SpacingRow(name: "xl", value: AppSpacing.xl)
        SpacingRow(name: "xxl", value: AppSpacing.xxl)
        SpacingRow(name: "xxxl", value: AppSpacing.xxxl)
        SpacingRow(name: "huge", value: AppSpacing.huge)
    }
    .padding()
}

private struct SpacingRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 50, alignment: .leading)

            Rectangle()
                .fill(Color.purple)
                .frame(width: value, height: 24)

            Text("\(Int(value))px")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Corner Radius Scale") {
    HStack(spacing: 16) {
        RoundedRectangle(cornerRadius: AppCorners.xs)
            .fill(Color.purple.opacity(0.3))
            .frame(width: 60, height: 60)
            .overlay(Text("4").font(.caption))

        RoundedRectangle(cornerRadius: AppCorners.sm)
            .fill(Color.purple.opacity(0.4))
            .frame(width: 60, height: 60)
            .overlay(Text("8").font(.caption))

        RoundedRectangle(cornerRadius: AppCorners.md)
            .fill(Color.purple.opacity(0.5))
            .frame(width: 60, height: 60)
            .overlay(Text("12").font(.caption))

        RoundedRectangle(cornerRadius: AppCorners.lg)
            .fill(Color.purple.opacity(0.6))
            .frame(width: 60, height: 60)
            .overlay(Text("16").font(.caption))

        RoundedRectangle(cornerRadius: AppCorners.xl)
            .fill(Color.purple.opacity(0.7))
            .frame(width: 60, height: 60)
            .overlay(Text("20").font(.caption))

        RoundedRectangle(cornerRadius: AppCorners.xxl)
            .fill(Color.purple.opacity(0.8))
            .frame(width: 60, height: 60)
            .overlay(Text("24").font(.caption))
    }
    .padding()
}
