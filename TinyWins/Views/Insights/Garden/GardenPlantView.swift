import SwiftUI

// MARK: - Garden Plant View

/// A single animated plant representing a character trait.
/// Growth stages are visualized through plant height, leaves, and flowers.
///
/// ## Design Philosophy
/// - Plants are ALWAYS alive and healthy - just different sizes
/// - Seeds = "potential waiting to grow", not failure
/// - Blooming plants celebrate with sparkles
/// - Gentle sway animation brings life to the garden
struct GardenPlantView: View {
    @Environment(\.theme) private var theme
    let plant: GardenPlant
    let isSelected: Bool
    var onTap: (() -> Void)? = nil

    @State private var swayPhase: Double = 0
    @State private var sparklePhase: Double = 0
    @State private var isAnimating = false

    // Plant dimensions based on container
    private let maxPlantHeight: CGFloat = 100
    private let potWidth: CGFloat = 50
    private let potHeight: CGFloat = 28

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 6) {
                // Plant visualization
                plantVisualization
                    .frame(height: maxPlantHeight + 10)

                // Pot with trait icon
                potView

                // Trait name
                Text(plant.trait.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? plant.trait.color : theme.textSecondary)
                    .lineLimit(1)

                // Moments count or encouragement
                momentsBadge
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(selectionBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Plant Visualization

    private var plantVisualization: some View {
        ZStack(alignment: .bottom) {
            // Soil mound
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.6), Color.brown.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40, height: 12)
                .offset(y: 4)

            // The plant itself
            plantForStage
                .rotationEffect(.degrees(swayAmount), anchor: .bottom)
                .animation(
                    .easeInOut(duration: 2.5 + Double.random(in: 0...0.5))
                    .repeatForever(autoreverses: true),
                    value: swayPhase
                )
        }
    }

    @ViewBuilder
    private var plantForStage: some View {
        switch plant.stage {
        case .seedling:
            seedlingView
        case .sprout:
            sproutView
        case .youngPlant:
            youngPlantView
        case .budding:
            buddingView
        case .blooming:
            bloomingView
        case .fullBloom:
            fullBloomView
        }
    }

    // MARK: - Growth Stage Views

    private var seedlingView: some View {
        // A tiny seed just peeking out - full of potential!
        VStack(spacing: 0) {
            Spacer()

            // Tiny sprout emerging
            ZStack {
                // Seed body
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [plant.trait.color.opacity(0.8), plant.trait.color.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 8)

                // Tiny leaf bud
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .offset(y: -6)
            }
        }
    }

    private var sproutView: some View {
        // A small sprout with first leaves
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottom) {
                // Stem
                stemView(height: 20)

                // Two tiny leaves
                HStack(spacing: 2) {
                    leafView(size: 10, rotation: -30)
                    leafView(size: 10, rotation: 30)
                }
                .offset(y: -16)
            }
        }
    }

    private var youngPlantView: some View {
        // Growing nicely with more leaves
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottom) {
                // Stem
                stemView(height: 40)

                // Lower leaves
                HStack(spacing: 4) {
                    leafView(size: 14, rotation: -40)
                    leafView(size: 14, rotation: 40)
                }
                .offset(y: -18)

                // Upper leaves
                HStack(spacing: 2) {
                    leafView(size: 11, rotation: -25)
                    leafView(size: 11, rotation: 25)
                }
                .offset(y: -34)
            }
        }
    }

    private var buddingView: some View {
        // Plant with a bud forming - excitement building!
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottom) {
                // Stem
                stemView(height: 55)

                // Leaves at different heights
                Group {
                    HStack(spacing: 6) {
                        leafView(size: 16, rotation: -45)
                        leafView(size: 16, rotation: 45)
                    }
                    .offset(y: -20)

                    HStack(spacing: 4) {
                        leafView(size: 13, rotation: -35)
                        leafView(size: 13, rotation: 35)
                    }
                    .offset(y: -38)
                }

                // Bud at top
                budView
                    .offset(y: -52)
            }
        }
    }

    private var bloomingView: some View {
        // Flower is opening!
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottom) {
                // Stem
                stemView(height: 70)

                // Leaves
                Group {
                    HStack(spacing: 8) {
                        leafView(size: 18, rotation: -50)
                        leafView(size: 18, rotation: 50)
                    }
                    .offset(y: -22)

                    HStack(spacing: 5) {
                        leafView(size: 14, rotation: -35)
                        leafView(size: 14, rotation: 35)
                    }
                    .offset(y: -44)
                }

                // Opening flower
                flowerView(size: 26, isPulsing: false)
                    .offset(y: -68)
            }
        }
    }

    private var fullBloomView: some View {
        // Full glory with sparkles!
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottom) {
                // Sparkles around flower
                sparklesView
                    .offset(y: -85)

                // Stem
                stemView(height: 85)

                // Lush leaves
                Group {
                    HStack(spacing: 10) {
                        leafView(size: 20, rotation: -55)
                        leafView(size: 20, rotation: 55)
                    }
                    .offset(y: -24)

                    HStack(spacing: 6) {
                        leafView(size: 16, rotation: -40)
                        leafView(size: 16, rotation: 40)
                    }
                    .offset(y: -48)

                    HStack(spacing: 4) {
                        leafView(size: 12, rotation: -25)
                        leafView(size: 12, rotation: 25)
                    }
                    .offset(y: -68)
                }

                // Full bloom flower
                flowerView(size: 34, isPulsing: true)
                    .offset(y: -84)
            }
        }
    }

    // MARK: - Plant Components

    private func stemView(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.65, blue: 0.35),
                        Color(red: 0.35, green: 0.55, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: height)
    }

    private func leafView(size: CGFloat, rotation: Double) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.45, green: 0.75, blue: 0.4),
                        Color(red: 0.35, green: 0.6, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.6, height: size)
            .rotationEffect(.degrees(rotation))
    }

    private var budView: some View {
        ZStack {
            // Outer sepals
            ForEach(0..<3) { i in
                Ellipse()
                    .fill(Color(red: 0.4, green: 0.65, blue: 0.35))
                    .frame(width: 8, height: 14)
                    .rotationEffect(.degrees(Double(i) * 45 - 45))
            }

            // Inner bud showing color
            Circle()
                .fill(plant.trait.color.opacity(0.7))
                .frame(width: 10, height: 10)
        }
    }

    private func flowerView(size: CGFloat, isPulsing: Bool) -> some View {
        ZStack {
            // Petals
            ForEach(0..<6) { i in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                plant.trait.color,
                                plant.trait.color.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.45, height: size * 0.7)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(i) * 60))
            }

            // Center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow,
                            Color.orange.opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.2
                    )
                )
                .frame(width: size * 0.35, height: size * 0.35)
        }
        .scaleEffect(isPulsing ? (1.0 + sin(sparklePhase) * 0.05) : 1.0)
    }

    private var sparklesView: some View {
        ZStack {
            ForEach(0..<5) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundColor(plant.trait.color.opacity(0.8))
                    .offset(
                        x: cos(Double(i) * .pi * 2 / 5 + sparklePhase) * 22,
                        y: sin(Double(i) * .pi * 2 / 5 + sparklePhase) * 18
                    )
                    .opacity(0.6 + sin(sparklePhase + Double(i)) * 0.4)
            }
        }
    }

    // MARK: - Pot View

    private var potView: some View {
        ZStack {
            // Pot body
            UnevenRoundedRectangle(
                topLeadingRadius: 2,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 2
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.72, green: 0.45, blue: 0.35),
                        Color(red: 0.6, green: 0.38, blue: 0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: potWidth, height: potHeight)

            // Pot rim
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.75, green: 0.48, blue: 0.38))
                .frame(width: potWidth + 4, height: 6)
                .offset(y: -potHeight / 2 + 3)

            // Trait icon on pot
            Image(systemName: plant.trait.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .offset(y: 2)
        }
    }

    // MARK: - Moments Badge

    private var momentsBadge: some View {
        Group {
            if plant.moments > 0 {
                HStack(spacing: 3) {
                    Text("\(plant.moments)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))

                    Text(plant.moments == 1 ? "moment" : "moments")
                        .font(.system(size: 9))
                }
                .foregroundColor(plant.trait.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(plant.trait.color.opacity(0.15))
                )
            } else {
                Text("Ready to grow")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Selection Background

    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? plant.trait.color.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? plant.trait.color.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
    }

    // MARK: - Animation Helpers

    private var swayAmount: Double {
        switch plant.stage {
        case .seedling:
            return 0 // Seeds don't sway
        case .sprout:
            return sin(swayPhase) * 3
        case .youngPlant:
            return sin(swayPhase) * 4
        case .budding:
            return sin(swayPhase) * 5
        case .blooming:
            return sin(swayPhase) * 6
        case .fullBloom:
            return sin(swayPhase) * 7
        }
    }

    private func startAnimations() {
        // Stagger the sway phase so plants don't all move together
        swayPhase = Double.random(in: 0...(.pi * 2))

        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: true)) {
            swayPhase = swayPhase + .pi * 2
        }

        if plant.stage == .fullBloom {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparklePhase = .pi * 2
            }
        }
    }
}

// MARK: - Preview

#Preview("Garden Plant - All Stages") {
    let stages: [(GrowthStage, Int)] = [
        (.seedling, 0),
        (.sprout, 2),
        (.youngPlant, 4),
        (.budding, 7),
        (.blooming, 12),
        (.fullBloom, 18)
    ]

    ScrollView(.horizontal) {
        HStack(spacing: 8) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, item in
                let trait = CharacterTrait.allCases[index % CharacterTrait.allCases.count]
                GardenPlantView(
                    plant: GardenPlant(
                        trait: trait,
                        moments: item.1,
                        points: item.1 * 5,
                        stage: item.0,
                        isGrowing: item.1 > 0
                    ),
                    isSelected: index == 4
                )
                .frame(width: 90)
            }
        }
        .padding()
    }
    .background(Theme().bg1)
}

#Preview("Garden Plant - Kindness Full Bloom") {
    GardenPlantView(
        plant: GardenPlant(
            trait: .kindness,
            moments: 20,
            points: 100,
            stage: .fullBloom,
            isGrowing: true
        ),
        isSelected: true
    )
    .frame(width: 100, height: 200)
    .padding()
    .background(Theme().bg1)
}
