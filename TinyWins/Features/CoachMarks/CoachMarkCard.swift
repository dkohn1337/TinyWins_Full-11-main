import SwiftUI

// MARK: - Coach Mark Card

/// Warm, friendly tooltip card displayed alongside the spotlight
/// Design is soft, approachable, and matches the app's family-focused brand
struct CoachMarkCard: View {

    let step: CoachMarkStep
    let stepIndex: Int
    let totalSteps: Int
    let position: SpotlightPosition
    let targetRect: CGRect?
    let onNext: () -> Void
    let onSkip: () -> Void
    let onSkipAll: () -> Void

    @State private var appear = false

    // Warm accent color that matches the app's positive/family tone
    private let accentColor = Color(red: 0.35, green: 0.65, blue: 0.55) // Soft teal-green

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with icon and progress dots
            HStack(alignment: .center) {
                // Warm icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: step.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Progress indicator: "1 of 2" text + dots
                if totalSteps > 1 {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Clear "X of Y" text
                        Text("\(stepIndex + 1) of \(totalSteps)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.gray)

                        // Subtle progress dots
                        HStack(spacing: 6) {
                            ForEach(0..<totalSteps, id: \.self) { index in
                                Circle()
                                    .fill(index <= stepIndex ? accentColor : Color.gray.opacity(0.25))
                                    .frame(width: 7, height: 7)
                            }
                        }
                    }
                }
            }

            // Title - warm and conversational
            Text(step.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            // Message - friendly and supportive
            Text(step.message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Actions - simple and clear
            HStack(spacing: 16) {
                // Skip link (not a menu - simpler)
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.gray)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip this tip")
                .accessibilityHint("Double tap to skip to the next tip")

                Spacer()

                // Primary action button - warm color
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onNext()
                }) {
                    Text(stepIndex < totalSteps - 1 ? "Next" : "Got it")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(accentColor)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
        )
        .frame(maxWidth: 300)
        .scaleEffect(appear ? 1 : 0.92)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }
}

// MARK: - Positioned Coach Mark Card

/// Positions the coach mark card relative to the target
/// Uses safe area insets to ensure card is never clipped off-screen
struct PositionedCoachMarkCard: View {

    let step: CoachMarkStep
    let stepIndex: Int
    let totalSteps: Int
    let targetRect: CGRect?
    let onNext: () -> Void
    let onSkip: () -> Void
    let onSkipAll: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let safeSize = CGSize(
                width: geometry.size.width,
                height: geometry.size.height
            )
            let position = bestPosition(
                for: targetRect ?? .zero,
                in: safeSize,
                safeArea: safeArea
            )

            CoachMarkCard(
                step: step,
                stepIndex: stepIndex,
                totalSteps: totalSteps,
                position: position,
                targetRect: targetRect,
                onNext: onNext,
                onSkip: onSkip,
                onSkipAll: onSkipAll
            )
            .position(cardPosition(for: position, targetRect: targetRect, in: safeSize, safeArea: safeArea))
        }
    }

    /// Determine best position accounting for safe area
    private func bestPosition(
        for targetRect: CGRect,
        in screenSize: CGSize,
        safeArea: EdgeInsets
    ) -> SpotlightPosition {
        let cardHeight: CGFloat = 200  // Generous estimate for card + spacing
        let cardWidth: CGFloat = 300

        // Calculate available space accounting for safe areas
        let topSpace = targetRect.minY - safeArea.top
        let bottomSpace = screenSize.height - targetRect.maxY - safeArea.bottom
        let leftSpace = targetRect.minX - safeArea.leading
        let rightSpace = screenSize.width - targetRect.maxX - safeArea.trailing

        // Prefer below if there's enough room
        if bottomSpace >= cardHeight + 30 {
            return .below
        }
        // Then try above
        if topSpace >= cardHeight + 30 {
            return .above
        }
        // Then try sides
        if rightSpace >= cardWidth + 40 {
            return .right
        }
        if leftSpace >= cardWidth + 40 {
            return .left
        }

        // Default to centered overlay if nothing fits well
        return .below
    }

    private func cardPosition(
        for position: SpotlightPosition,
        targetRect: CGRect?,
        in screenSize: CGSize,
        safeArea: EdgeInsets
    ) -> CGPoint {
        guard let rect = targetRect else {
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }

        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 200  // Increased to prevent clipping
        let spacing: CGFloat = 24      // More breathing room

        // Horizontal bounds with padding from edges
        let minX = cardWidth / 2 + 16
        let maxX = screenSize.width - cardWidth / 2 - 16

        // Vertical bounds accounting for safe area
        let minY = safeArea.top + cardHeight / 2 + 16
        let maxY = screenSize.height - safeArea.bottom - cardHeight / 2 - 16

        switch position {
        case .above:
            let proposedY = rect.minY - spacing - cardHeight / 2
            return CGPoint(
                x: min(max(rect.midX, minX), maxX),
                y: max(proposedY, minY)  // Ensure we don't go above safe area
            )
        case .below:
            let proposedY = rect.maxY + spacing + cardHeight / 2
            return CGPoint(
                x: min(max(rect.midX, minX), maxX),
                y: min(proposedY, maxY)  // Ensure we don't go below safe area
            )
        case .left:
            return CGPoint(
                x: max(rect.minX - spacing - cardWidth / 2, minX),
                y: min(max(rect.midY, minY), maxY)
            )
        case .right:
            return CGPoint(
                x: min(rect.maxX + spacing + cardWidth / 2, maxX),
                y: min(max(rect.midY, minY), maxY)
            )
        }
    }
}

// MARK: - Arrow Pointer (Optional Enhancement)

struct TooltipArrow: Shape {
    let direction: SpotlightPosition

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arrowSize: CGFloat = 12

        switch direction {
        case .above:
            // Arrow pointing down
            path.move(to: CGPoint(x: rect.midX - arrowSize, y: rect.maxY - arrowSize))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX + arrowSize, y: rect.maxY - arrowSize))
        case .below:
            // Arrow pointing up
            path.move(to: CGPoint(x: rect.midX - arrowSize, y: rect.minY + arrowSize))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + arrowSize, y: rect.minY + arrowSize))
        case .left:
            // Arrow pointing right
            path.move(to: CGPoint(x: rect.maxX - arrowSize, y: rect.midY - arrowSize))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - arrowSize, y: rect.midY + arrowSize))
        case .right:
            // Arrow pointing left
            path.move(to: CGPoint(x: rect.minX + arrowSize, y: rect.midY - arrowSize))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + arrowSize, y: rect.midY + arrowSize))
        }

        return path
    }
}

// MARK: - Preview

#if DEBUG
struct CoachMarkCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            CoachMarkCard(
                step: CoachMarkStep(
                    id: "preview",
                    title: "Log your first moment",
                    message: "Tap + when you notice something, good or tough. Both matter.",
                    icon: "plus.circle.fill",
                    target: .addButton
                ),
                stepIndex: 0,
                totalSteps: 3,
                position: .below,
                targetRect: CGRect(x: 100, y: 100, width: 60, height: 60),
                onNext: {},
                onSkip: {},
                onSkipAll: {}
            )
            .padding()
        }
    }
}
#endif
