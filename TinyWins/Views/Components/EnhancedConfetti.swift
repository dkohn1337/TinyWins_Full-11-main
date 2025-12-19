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

/// Multi-shape, physics-based confetti animation for celebrations.
///
/// PERFORMANCE OPTIMIZATION:
/// - Uses single animation progress value instead of per-particle animations
/// - All particle positions computed from progress value (0→1)
/// - Eliminates 50-100 separate animation controllers
/// - Uses .drawingGroup() for GPU-accelerated rendering
struct EnhancedConfettiView: View {
    let particleCount: Int
    let duration: Double

    /// Single animation progress (0 to 1) controls all particles
    @State private var animationProgress: CGFloat = 0

    /// Pre-computed particle configurations (immutable after creation)
    @State private var particleConfigs: [ConfettiParticleConfig] = []

    /// Track if animation has started
    @State private var hasStarted = false

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
                ForEach(particleConfigs) { config in
                    // Compute current position from progress
                    let currentPos = interpolatedPosition(for: config, progress: animationProgress, screenHeight: geometry.size.height)

                    ParticleShape(shape: config.shape)
                        .foregroundColor(config.color)
                        .frame(width: 12 * config.scale, height: 12 * config.scale)
                        .rotationEffect(Angle.degrees(config.startRotation + config.rotationSpeed * Double(animationProgress)))
                        .opacity(currentPos.opacity)
                        .position(x: currentPos.x, y: currentPos.y)
                }
            }
            .drawingGroup() // GPU-accelerate particle rendering
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true
                setupParticles(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false)
    }

    /// Pre-compute all particle configurations (called once)
    private func setupParticles(in size: CGSize) {
        var configs: [ConfettiParticleConfig] = []
        configs.reserveCapacity(particleCount)

        for _ in 0..<particleCount {
            let startX = size.width / 2 + CGFloat.random(in: -100...100)
            let config = ConfettiParticleConfig(
                startX: startX,
                startY: -50,
                endX: startX + CGFloat.random(in: -150...150),
                startRotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720),
                scale: CGFloat.random(in: 0.6...1.4),
                color: colors.randomElement()!,
                shape: ParticleShapeType.allCases.randomElement()!,
                delay: CGFloat.random(in: 0...0.15) // Stagger start times
            )
            configs.append(config)
        }

        particleConfigs = configs
    }

    /// Single animation that drives all particles
    private func startAnimation() {
        withAnimation(.easeIn(duration: duration)) {
            animationProgress = 1.0
        }
    }

    /// Compute particle position based on animation progress
    private func interpolatedPosition(for config: ConfettiParticleConfig, progress: CGFloat, screenHeight: CGFloat) -> (x: CGFloat, y: CGFloat, opacity: Double) {
        // Account for per-particle delay
        let adjustedProgress = max(0, (progress - config.delay) / (1 - config.delay))

        // Eased progress for natural motion
        let easedProgress = adjustedProgress * adjustedProgress // ease-in curve

        let x = config.startX + (config.endX - config.startX) * easedProgress
        let y = config.startY + (screenHeight + 150) * easedProgress

        // Fade out in last 30% of animation
        let opacity = adjustedProgress > 0.7 ? Double(1 - (adjustedProgress - 0.7) / 0.3) : 1.0

        return (x, y, max(0, opacity))
    }
}

// MARK: - Confetti Particle Configuration (immutable)

/// Pre-computed particle configuration - does not change during animation
struct ConfettiParticleConfig: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let startRotation: Double
    let rotationSpeed: Double
    let scale: CGFloat
    let color: Color
    let shape: ParticleShapeType
    let delay: CGFloat // Stagger animation start
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

/// Fireworks-style particle burst for extra special moments.
///
/// PERFORMANCE OPTIMIZATION:
/// - Uses single animation progress instead of per-particle animations
/// - Particle positions computed from progress value
struct FireworksEffect: View {
    let origin: CGPoint
    let color: Color

    /// Single animation progress controls all particles
    @State private var animationProgress: CGFloat = 0
    @State private var particleConfigs: [FireworkParticleConfig] = []
    @State private var hasStarted = false

    private let particleCount = 30

    var body: some View {
        ZStack {
            ForEach(particleConfigs) { config in
                let pos = interpolatedPosition(for: config, progress: animationProgress)
                Circle()
                    .fill(color)
                    .frame(width: config.startSize * (1 - animationProgress * 0.5), height: config.startSize * (1 - animationProgress * 0.5))
                    .opacity(1 - Double(animationProgress))
                    .position(x: pos.x, y: pos.y)
            }
        }
        .drawingGroup()
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            setupParticles()
            startAnimation()
        }
    }

    private func setupParticles() {
        var configs: [FireworkParticleConfig] = []
        configs.reserveCapacity(particleCount)

        for i in 0..<particleCount {
            let angle = Double(i) * (2 * .pi) / Double(particleCount)
            let distance = CGFloat.random(in: 50...150)
            let config = FireworkParticleConfig(
                angle: angle,
                distance: distance,
                startSize: CGFloat.random(in: 3...8)
            )
            configs.append(config)
        }
        particleConfigs = configs
    }

    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            animationProgress = 1.0
        }
    }

    private func interpolatedPosition(for config: FireworkParticleConfig, progress: CGFloat) -> CGPoint {
        let currentDistance = config.distance * progress
        return CGPoint(
            x: origin.x + currentDistance * CGFloat(cos(config.angle)),
            y: origin.y + currentDistance * CGFloat(sin(config.angle))
        )
    }
}

/// Pre-computed firework particle configuration
struct FireworkParticleConfig: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let startSize: CGFloat
}

// Legacy struct kept for compatibility
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
        Theme().bg1
            .ignoresSafeArea()

        EnhancedConfettiView(particleCount: 100, duration: 3.0)
    }
    .withTheme(Theme())
}

#Preview("Fireworks") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        FireworksEffect(origin: CGPoint(x: 200, y: 400), color: .yellow)
    }
}
