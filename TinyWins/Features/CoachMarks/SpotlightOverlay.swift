import SwiftUI

// MARK: - Spotlight Overlay

/// Creates a softly dimmed overlay with a transparent cutout around the target element
/// Uses a gentler opacity for a less intimidating feel
struct SpotlightOverlay: View {

    let targetRect: CGRect?
    let padding: CGFloat
    let cornerRadius: CGFloat

    init(
        targetRect: CGRect?,
        padding: CGFloat = 12,
        cornerRadius: CGFloat = 16
    ) {
        self.targetRect = targetRect
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Softer semi-transparent background (was 0.6, now 0.45)
                Color.black.opacity(0.45)

                // Cutout for the target element
                if let rect = targetRect {
                    SpotlightCutoutShape(
                        targetRect: rect,
                        padding: padding,
                        cornerRadius: cornerRadius
                    )
                    .fill(Color.black)
                    .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Cutout Shape

/// Shape that creates a rounded rectangle cutout
struct SpotlightCutoutShape: Shape {
    let targetRect: CGRect
    let padding: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let expandedRect = targetRect.insetBy(dx: -padding, dy: -padding)
        return RoundedRectangle(cornerRadius: cornerRadius)
            .path(in: expandedRect)
    }
}

// MARK: - Animated Spotlight

/// Animated version with gentle glow effect around the spotlight
struct AnimatedSpotlightOverlay: View {

    let targetRect: CGRect?
    let padding: CGFloat
    let cornerRadius: CGFloat
    @State private var glowOpacity: Double = 0.3

    init(
        targetRect: CGRect?,
        padding: CGFloat = 12,
        cornerRadius: CGFloat = 16
    ) {
        self.targetRect = targetRect
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            // Base spotlight overlay
            SpotlightOverlay(
                targetRect: targetRect,
                padding: padding,
                cornerRadius: cornerRadius
            )

            // Gentle glow around target (softer than pulse)
            if let rect = targetRect {
                let expandedRect = rect.insetBy(dx: -padding - 4, dy: -padding - 4)
                RoundedRectangle(cornerRadius: cornerRadius + 4)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: expandedRect.width, height: expandedRect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .opacity(glowOpacity)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            startGlowAnimation()
        }
    }

    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.7
        }
    }
}

// MARK: - Pulse Ring

struct PulseRing: View {
    let rect: CGRect
    let cornerRadius: CGFloat
    let scale: CGFloat
    let opacity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color.white, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .scaleEffect(scale)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

// MARK: - Spotlight Position Helper

/// Helper to determine best position for coach mark card relative to spotlight
enum SpotlightPosition {
    case above
    case below
    case left
    case right

    static func bestPosition(
        for targetRect: CGRect,
        in screenSize: CGSize,
        cardHeight: CGFloat = 160
    ) -> SpotlightPosition {
        let topSpace = targetRect.minY
        let bottomSpace = screenSize.height - targetRect.maxY
        let leftSpace = targetRect.minX
        let rightSpace = screenSize.width - targetRect.maxX

        // Prefer above or below
        if bottomSpace >= cardHeight + 40 {
            return .below
        } else if topSpace >= cardHeight + 40 {
            return .above
        } else if rightSpace >= 200 {
            return .right
        } else if leftSpace >= 200 {
            return .left
        }

        // Default to below with scroll adjustment
        return .below
    }
}

// MARK: - Preview

#if DEBUG
struct SpotlightOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background content
            VStack {
                Text("Some content above")
                    .padding()

                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }
                .padding()

                Text("Some content below")
                    .padding()

                Spacer()
            }

            // Spotlight overlay
            AnimatedSpotlightOverlay(
                targetRect: CGRect(x: 150, y: 200, width: 100, height: 60),
                padding: 12,
                cornerRadius: 16
            )
        }
    }
}
#endif
