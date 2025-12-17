import SwiftUI

// MARK: - Device Performance Helper

private enum DevicePerformance {
    /// Returns appropriate particle count based on device capability
    /// Reduces particles on older/lower-memory devices for smooth animation
    static var recommendedParticleCount: Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryGB = Double(totalMemory) / 1_073_741_824 // bytes to GB

        // Reduce particles on devices with less RAM (proxy for device age/capability)
        // - 3GB or less (older iPhones like 6s, 7, SE): 50 particles
        // - 4GB (iPhone 11, XR): 75 particles
        // - 6GB+ (iPhone 12 Pro+, 14+): 100 particles
        if memoryGB <= 3 {
            return 50
        } else if memoryGB <= 4 {
            return 75
        } else {
            return 100
        }
    }
}

// MARK: - Enhanced Confetti View

/// Multi-shape, physics-based confetti animation for celebrations
/// More visually rich than the basic ConfettiView
struct EnhancedConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let particleCount: Int
    let duration: Double

    init(particleCount: Int? = nil, duration: Double = 3.0) {
        // Use device-appropriate particle count if not specified
        self.particleCount = particleCount ?? DevicePerformance.recommendedParticleCount
        self.duration = duration
    }

    let colors: [Color] = [
        .yellow, .orange, .pink, .purple,
        .blue, .green, .mint, .cyan,
        .red, .indigo
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleShape(shape: particle.shape)
                        .foregroundColor(particle.color)
                        .frame(width: 12 * particle.scale, height: 12 * particle.scale)
                        .rotationEffect(Angle.degrees(particle.rotation))
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .drawingGroup() // GPU-accelerate particle rendering for smooth animation
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createConfetti(in size: CGSize) {
        // Create particles
        for _ in 0..<particleCount {
            let particle = ConfettiParticle(
                x: size.width / 2 + CGFloat.random(in: -100...100),
                y: -50,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720),
                scale: CGFloat.random(in: 0.6...1.4),
                opacity: 1,
                color: colors.randomElement()!,
                shape: ParticleShapeType.allCases.randomElement()!,
                velocity: CGFloat.random(in: 200...400)
            )
            particles.append(particle)
        }

        // Animate with realistic physics
        for i in particles.indices {
            let particleDuration = duration * Double.random(in: 0.8...1.2)
            let delay = Double.random(in: 0...0.5)
            let targetX = particles[i].x + CGFloat.random(in: -150...150)
            let targetY = size.height + 100

            withAnimation(
                .easeIn(duration: particleDuration)
                .delay(delay)
            ) {
                particles[i].x = targetX
                particles[i].y = targetY
                particles[i].rotation += particles[i].rotationSpeed * particleDuration
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Confetti Particle Data

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var rotationSpeed: Double
    var scale: CGFloat
    var opacity: Double
    var color: Color
    var shape: ParticleShapeType
    var velocity: CGFloat
}

// MARK: - Particle Shape Types

enum ParticleShapeType: CaseIterable {
    case circle, square, star, heart, triangle, diamond

    var shape: any Shape {
        switch self {
        case .circle:
            return Circle()
        case .square:
            return RoundedRectangle(cornerRadius: 2)
        case .star:
            return StarShape()
        case .heart:
            return HeartShape()
        case .triangle:
            return TriangleShape()
        case .diamond:
            return DiamondShape()
        }
    }
}

// MARK: - Particle Shape View

struct ParticleShape: View {
    let shape: ParticleShapeType

    var body: some View {
        Group {
            switch shape {
            case .circle:
                Circle()
            case .square:
                RoundedRectangle(cornerRadius: 2)
            case .star:
                StarShape()
            case .heart:
                HeartShape()
            case .triangle:
                TriangleShape()
            case .diamond:
                DiamondShape()
            }
        }
    }
}

// MARK: - Custom Shapes

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? radius : radius * 0.5
            let point = CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            control1: CGPoint(x: width / 2, y: height * 3 / 4),
            control2: CGPoint(x: 0, y: height / 2)
        )
        path.addArc(
            center: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: width * 3 / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height / 2),
            control2: CGPoint(x: width / 2, y: height * 3 / 4)
        )
        return path
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Fireworks Effect

/// Fireworks-style particle burst for extra special moments
struct FireworksEffect: View {
    let origin: CGPoint
    let color: Color
    @State private var particles: [FireworkParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(color)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createFirework()
        }
    }

    private func createFirework() {
        // Create burst of particles from origin
        for _ in 0..<30 {
            let particle = FireworkParticle(
                x: origin.x,
                y: origin.y,
                size: CGFloat.random(in: 3...8),
                opacity: 1
            )
            particles.append(particle)
        }

        // Animate outward
        for i in particles.indices {
            let angle = Double(i) * (2 * .pi) / Double(particles.count)
            let distance = CGFloat.random(in: 50...150)
            let targetX = origin.x + distance * cos(angle)
            let targetY = origin.y + distance * sin(angle)

            withAnimation(
                .easeOut(duration: 0.8)
            ) {
                particles[i].x = targetX
                particles[i].y = targetY
                particles[i].opacity = 0
                particles[i].size *= 0.5
            }
        }
    }
}

struct FireworkParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

// MARK: - Preview

#Preview("Enhanced Confetti") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        EnhancedConfettiView(particleCount: 100, duration: 3.0)
    }
}

#Preview("Fireworks") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        FireworksEffect(origin: CGPoint(x: 200, y: 400), color: .yellow)
    }
}
