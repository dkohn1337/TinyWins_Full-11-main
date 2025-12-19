import SwiftUI

// MARK: - Coach Mark Overlay

/// Main overlay view that combines spotlight and tooltip card
struct CoachMarkOverlay: View {

    @ObservedObject var manager: CoachMarkManager
    @State private var animateIn = false

    var body: some View {
        ZStack {
            if let step = manager.currentStep {
                // Dimmed background with spotlight cutout
                AnimatedSpotlightOverlay(
                    targetRect: manager.targetRects[step.target],
                    padding: 12,
                    cornerRadius: 16
                )
                .transition(.opacity)

                // Tooltip card
                PositionedCoachMarkCard(
                    step: step,
                    stepIndex: manager.stepIndex,
                    totalSteps: manager.totalSteps,
                    targetRect: manager.targetRects[step.target],
                    onNext: {
                        manager.nextStep()
                    },
                    onSkip: {
                        manager.skipSequence()
                    },
                    onSkipAll: {
                        manager.skipAll()
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))

                // Tap anywhere to advance (except on card)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        manager.nextStep()
                    }
                    .allowsHitTesting(true)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: manager.currentStep?.id)
    }
}

// MARK: - View Modifier for Easy Integration

/// Modifier to add coach mark overlay to a view
struct CoachMarkOverlayModifier: ViewModifier {
    @ObservedObject var manager: CoachMarkManager

    func body(content: Content) -> some View {
        content
            .overlay {
                CoachMarkOverlay(manager: manager)
            }
            .onPreferenceChange(CoachMarkTargetPreferenceKey.self) { targets in
                for (target, rect) in targets {
                    manager.registerTarget(target, rect: rect)
                }
            }
    }
}

extension View {
    /// Adds coach mark overlay capability to this view
    func coachMarkOverlay(manager: CoachMarkManager) -> some View {
        modifier(CoachMarkOverlayModifier(manager: manager))
    }
}

// MARK: - Welcome Coach Mark (Simpler Single-Step Version)

/// A simpler single-tip coach mark for specific features
struct SingleCoachMark: View {
    @Environment(\.theme) private var theme

    let title: String
    let message: String
    let icon: String
    let targetRect: CGRect?
    let onDismiss: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            // Dimmed background
            AnimatedSpotlightOverlay(
                targetRect: targetRect,
                padding: 12,
                cornerRadius: 16
            )

            // Simplified card
            GeometryReader { geometry in
                let position = SpotlightPosition.bestPosition(
                    for: targetRect ?? .zero,
                    in: geometry.size,
                    cardHeight: 120
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text(title)
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)

                        Spacer()
                    }

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)

                    Button("Got it") {
                        onDismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface1)
                        .shadow(color: theme.shadowColor.opacity(0.3), radius: 16)
                )
                .frame(maxWidth: 300)
                .position(cardPosition(for: position, in: geometry.size))
                .scaleEffect(appear ? 1 : 0.9)
                .opacity(appear ? 1 : 0)
            }

            // Tap to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appear = true
            }
        }
    }

    private func cardPosition(for position: SpotlightPosition, in screenSize: CGSize) -> CGPoint {
        guard let rect = targetRect else {
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }

        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 120
        let spacing: CGFloat = 20

        switch position {
        case .below:
            return CGPoint(
                x: min(max(rect.midX, cardWidth / 2 + 16), screenSize.width - cardWidth / 2 - 16),
                y: rect.maxY + spacing + cardHeight / 2
            )
        case .above:
            return CGPoint(
                x: min(max(rect.midX, cardWidth / 2 + 16), screenSize.width - cardWidth / 2 - 16),
                y: rect.minY - spacing - cardHeight / 2
            )
        default:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CoachMarkOverlay_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }

    struct PreviewWrapper: View {
        @StateObject private var manager = CoachMarkManager(
            userPreferences: UserPreferencesStore()
        )

        var body: some View {
            ZStack {
                VStack {
                    Text("Today View")
                        .font(.title)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                    }
                    .coachMarkTarget(.addButton)

                    Spacer()
                }

                CoachMarkOverlay(manager: manager)
            }
            .onAppear {
                // Simulate starting a sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    manager.registerTarget(.addButton, rect: CGRect(x: 160, y: 400, width: 60, height: 60))
                    // For preview, we'd manually set the step
                }
            }
        }
    }
}
#endif
