import SwiftUI

// MARK: - Reusable Progress Ring

/// A configurable circular progress ring that preserves all existing visual patterns.
/// Supports different sizes, stroke widths, and optional milestone markers.
/// Now theme-aware - background ring uses a tinted version of the progress color.
struct ProgressRingView: View {
    let progress: CGFloat // 0.0 to 1.0
    let color: Color
    let size: CGFloat
    let strokeWidth: CGFloat
    let milestones: [Int]?
    let targetPoints: Int?
    let currentPoints: Int?
    let showMilestoneGlow: Bool
    let animateOnAppear: Bool

    @EnvironmentObject private var themeProvider: ThemeProvider
    @State private var animatedProgress: CGFloat = 0

    /// Standard progress ring initializer
    init(
        progress: CGFloat,
        color: Color,
        size: CGFloat = 140,
        strokeWidth: CGFloat = 12,
        milestones: [Int]? = nil,
        targetPoints: Int? = nil,
        currentPoints: Int? = nil,
        showMilestoneGlow: Bool = true,
        animateOnAppear: Bool = true
    ) {
        self.progress = progress
        self.color = color
        self.size = size
        self.strokeWidth = strokeWidth
        self.milestones = milestones
        self.targetPoints = targetPoints
        self.currentPoints = currentPoints
        self.showMilestoneGlow = showMilestoneGlow
        self.animateOnAppear = animateOnAppear
    }

    /// Background ring color - uses a light tint of the progress color for theme consistency
    private var backgroundRingColor: Color {
        if themeProvider.isDarkMode {
            return color.opacity(0.15)
        } else {
            // Use a subtle tint of the progress color for themed appearance
            return color.opacity(0.12)
        }
    }

    var body: some View {
        ZStack {
            // Background ring - now themed with subtle color tint
            Circle()
                .stroke(backgroundRingColor, lineWidth: strokeWidth)
                .frame(width: size, height: size)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animateOnAppear ? animatedProgress : progress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.6), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 8)

            // Milestone dots on ring (if provided) - use progress color for consistency
            if let milestones = milestones, let target = targetPoints, let current = currentPoints {
                ForEach(milestones, id: \.self) { milestone in
                    let milestoneProgress = Double(milestone) / Double(target)
                    let angle = milestoneProgress * 360 - 90
                    let reached = current >= milestone

                    Circle()
                        .fill(reached ? color : Color(.systemGray5))
                        .frame(width: strokeWidth, height: strokeWidth)
                        .overlay(
                            Circle()
                                .stroke(reached ? color.opacity(0.6) : Color(.systemGray4), lineWidth: 2)
                        )
                        .shadow(color: (reached && showMilestoneGlow) ? color.opacity(0.4) : .clear, radius: 4)
                        .offset(y: -size / 2)
                        .rotationEffect(.degrees(angle))
                }
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressAccessibilityLabel)
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

    private var progressAccessibilityLabel: String {
        if let current = currentPoints, let target = targetPoints {
            return "Progress: \(current) of \(target) points"
        }
        return "Progress ring"
    }
}

// MARK: - Large Progress Ring (KidView Style)

/// Large 260px progress ring used in KidView with 28pt stroke
/// Now theme-aware - background ring uses a tinted version of the progress color
struct LargeProgressRingView: View {
    let progress: CGFloat
    let color: Color
    let milestones: [Int]
    let targetPoints: Int
    let currentPoints: Int

    @EnvironmentObject private var themeProvider: ThemeProvider

    /// Background ring color - uses a light tint of the progress color
    private var backgroundRingColor: Color {
        if themeProvider.isDarkMode {
            return color.opacity(0.15)
        } else {
            return color.opacity(0.12)
        }
    }

    var body: some View {
        ZStack {
            // Background ring - now themed with child's color tint
            Circle()
                .stroke(backgroundRingColor, lineWidth: 28)
                .frame(width: 260, height: 260)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color,
                            color.opacity(0.8),
                            color.opacity(0.6),
                            color
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 28, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 12, y: 6)
                .animation(.spring(response: 0.6, dampingFraction: 0.75), value: progress)

            // Milestone markers on the circle - use progress color for consistency
            ForEach(milestones, id: \.self) { milestone in
                let milestoneProgress = Double(milestone) / Double(targetPoints)
                let angle = milestoneProgress * 360 - 90
                let isReached = currentPoints >= milestone

                ZStack {
                    // Glow for reached milestones - use progress color
                    if isReached {
                        Circle()
                            .fill(color.opacity(0.4))
                            .frame(width: 24, height: 24)
                            .blur(radius: 6)
                    }

                    Circle()
                        .fill(isReached ? color : Color(.systemGray5))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(isReached ? color.opacity(0.6) : Color(.systemGray4), lineWidth: 2)
                        )
                }
                .offset(y: -130)
                .rotationEffect(.degrees(angle))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(currentPoints) of \(targetPoints) points")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Glowing Icon Background

/// Reusable glowing icon with radial gradient background
struct GlowingIconView: View {
    let systemName: String
    let color: Color
    let size: IconSize

    enum IconSize {
        case small   // 80x80 outer, 48px icon
        case medium  // 120x120 outer, 52px icon
        case large   // 140x140 outer, 60px icon

        var outerSize: CGFloat {
            switch self {
            case .small: return 80
            case .medium: return 120
            case .large: return 140
            }
        }

        var innerSize: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 100
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 50
            case .large: return 52
            }
        }
    }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                        center: .center,
                        startRadius: size.innerSize / 3,
                        endRadius: size.outerSize / 2
                    )
                )
                .frame(width: size.outerSize, height: size.outerSize)

            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.innerSize, height: size.innerSize)

            Image(systemName: systemName)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 16)
        }
    }
}

// MARK: - Empty State View

/// Reusable empty state view that matches existing visual patterns
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let iconColor: Color
    let iconGradient: [Color]?
    let action: (() -> Void)?
    let actionTitle: String?
    let actionIcon: String?
    let showAnimatedGlow: Bool

    @State private var animateGlow = false

    init(
        icon: String,
        title: String,
        message: String,
        iconColor: Color = .secondary,
        iconGradient: [Color]? = nil,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        showAnimatedGlow: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
        self.iconGradient = iconGradient
        self.action = action
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.showAnimatedGlow = showAnimatedGlow
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated icon with glow
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [iconColor.opacity(0.2), iconColor.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(showAnimatedGlow && animateGlow ? 1.1 : 1.0)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: iconGradient ?? [iconColor.opacity(0.15), iconColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        if let gradient = iconGradient {
                            Image(systemName: icon)
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [iconColor, iconColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))

                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)

                // Optional action button
                if let action = action, let actionTitle = actionTitle {
                    Button(action: action) {
                        HStack(spacing: 10) {
                            if let actionIcon = actionIcon {
                                Image(systemName: actionIcon)
                                    .font(.system(size: 18))
                            }
                            Text(actionTitle)
                                .font(.system(size: 17, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: iconColor.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 8)
                    .accessibilityLabel(actionTitle)
                    .accessibilityHint("Double tap to activate")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding()
            .padding(.bottom, 120) // Space for floating tab bar
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if showAnimatedGlow {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
    }
}

// MARK: - Simple Empty State (Minimal)

/// Simpler empty state for in-context use (not full screen)
struct SimpleEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let iconSize: CGFloat
    let iconBackgroundSize: CGFloat

    init(
        icon: String,
        title: String,
        message: String,
        iconSize: CGFloat = 32,
        iconBackgroundSize: CGFloat = 64
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconSize = iconSize
        self.iconBackgroundSize = iconBackgroundSize
    }

    var body: some View {
        VStack(spacing: 16) {
            StyledIcon(
                systemName: icon,
                color: .secondary,
                size: iconSize,
                backgroundSize: iconBackgroundSize,
                isCircle: true
            )

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Progress Ring - Small") {
    ProgressRingView(
        progress: 0.7,
        color: .purple,
        size: 100,
        strokeWidth: 10
    )
    .padding()
}

// MARK: - Offline Banner

/// Banner shown when the app is offline, indicating data is saved locally
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))

            Text("Offline - changes saved locally")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.9))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You are offline. Changes are being saved locally and will sync when you reconnect.")
    }
}

#Preview("Offline Banner") {
    VStack {
        OfflineBanner()
        Spacer()
    }
}

#Preview("Progress Ring - With Milestones") {
    ProgressRingView(
        progress: 0.65,
        color: .blue,
        size: 140,
        strokeWidth: 12,
        milestones: [5, 10, 15],
        targetPoints: 20,
        currentPoints: 13
    )
    .padding()
}

#Preview("Large Progress Ring") {
    LargeProgressRingView(
        progress: 0.75,
        color: .green,
        milestones: [5, 10, 15],
        targetPoints: 20,
        currentPoints: 15
    )
    .padding()
}

#Preview("Glowing Icon") {
    VStack(spacing: 20) {
        GlowingIconView(systemName: "gift.fill", color: .yellow, size: .small)
        GlowingIconView(systemName: "star.fill", color: .purple, size: .medium)
        GlowingIconView(systemName: "trophy.fill", color: .orange, size: .large)
    }
    .padding()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "figure.2.and.child.holdinghands",
        title: "Let's get started",
        message: "Add your first child to begin noticing the small moments that make a big difference.",
        iconColor: AppColors.primary,
        action: {},
        actionTitle: "Add a Child",
        actionIcon: "plus.circle.fill"
    )
}
