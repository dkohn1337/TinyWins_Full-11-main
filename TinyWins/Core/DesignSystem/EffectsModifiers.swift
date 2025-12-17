import SwiftUI

// MARK: - Visual Effects & Modifiers
// Reusable view modifiers for visual effects

/// Shimmer effect modifier for loading states and attention
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    /// Applies a shimmer effect to the view
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Pulsing badge modifier for attention-grabbing badges
struct PulsingBadgeModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .shadow(color: .green.opacity(isPulsing ? 0.5 : 0.3), radius: isPulsing ? 6 : 4, y: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Applies a gentle pulsing effect for badges that need attention
    func pulsingBadge() -> some View {
        modifier(PulsingBadgeModifier())
    }
}

/// Micro-confetti modifier for celebratory badges
struct MicroConfettiModifier: ViewModifier {
    @State private var particles: [MicroConfettiParticle] = []
    @State private var hasAnimated = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        ForEach(particles) { particle in
                            particle.shape
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .position(particle.position)
                                .opacity(particle.opacity)
                                .rotationEffect(.degrees(particle.rotation))
                        }
                    }
                    .onAppear {
                        if !hasAnimated {
                            hasAnimated = true
                            generateParticles(in: geo.size)
                        }
                    }
                }
            )
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.green, .mint, .yellow, .white]
        let centerX = size.width / 2
        let centerY = size.height / 2

        for i in 0..<12 {
            // Random angle for particle direction
            let angle = Double.random(in: 0...360)
            let distance = CGFloat.random(in: 30...60)

            // Start at center, animate outward
            let startPosition = CGPoint(x: centerX, y: centerY)
            let endX = centerX + cos(angle * .pi / 180) * distance
            let endY = centerY + sin(angle * .pi / 180) * distance

            let particle = MicroConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .green,
                size: CGFloat.random(in: 3...6),
                position: startPosition,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)

            // Animate particle outward and fade
            let delay = Double(i) * 0.02
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].position = CGPoint(x: endX, y: endY)
                    particles[index].rotation += Double.random(in: 90...180)
                }
            }
            withAnimation(.easeOut(duration: 0.4).delay(delay + 0.3)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].opacity = 0
                }
            }
        }
    }
}

private struct MicroConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double

    var shape: some Shape {
        // Alternate between circles and small rectangles
        id % 2 == 0 ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 1))
    }
}

private struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

extension View {
    /// Applies micro-confetti celebration effect
    func microConfetti() -> some View {
        modifier(MicroConfettiModifier())
    }
}
