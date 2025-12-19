import SwiftUI

// MARK: - CharacterRadarChart

/// Spider/radar chart displaying 6 character trait scores.
/// Used in premium tier to visualize a child's character development.
struct CharacterRadarChart: View {
    @Environment(\.theme) private var theme

    let traitScores: [TraitScore]
    var size: CGFloat = 200
    var showLabels: Bool = true
    var showGridLines: Bool = true
    var fillOpacity: Double = 0.3

    // Number of sides (6 traits)
    private let sides = 6

    // Angle between each vertex
    private var angleIncrement: Double {
        360.0 / Double(sides)
    }

    // Ordered trait scores matching CharacterTrait.allCases order
    private var orderedScores: [Double] {
        CharacterTrait.allCases.map { trait in
            traitScores.first(where: { $0.trait == trait })?.score ?? 0
        }
    }

    // Normalized scores (0-1 scale)
    private var normalizedScores: [Double] {
        orderedScores.map { min(max($0 / 100.0, 0), 1) }
    }

    var body: some View {
        ZStack {
            // Grid lines (background)
            if showGridLines {
                gridLines
            }

            // Data polygon
            dataPolygon

            // Labels
            if showLabels {
                traitLabels
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Grid Lines

    private var gridLines: some View {
        ZStack {
            // Concentric hexagons at 25%, 50%, 75%, 100%
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                hexagonPath(scale: scale)
                    .stroke(theme.borderSoft, lineWidth: 0.5)
            }

            // Radial lines from center to each vertex
            ForEach(0..<sides, id: \.self) { index in
                Path { path in
                    let center = CGPoint(x: size / 2, y: size / 2)
                    let angle = angleForIndex(index)
                    let point = pointOnCircle(center: center, radius: size / 2 - labelPadding, angle: angle)
                    path.move(to: center)
                    path.addLine(to: point)
                }
                .stroke(theme.borderSoft.opacity(0.5), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Data Polygon

    private var dataPolygon: some View {
        let center = CGPoint(x: size / 2, y: size / 2)
        let maxRadius = size / 2 - labelPadding

        return ZStack {
            // Filled polygon
            Path { path in
                for (index, score) in normalizedScores.enumerated() {
                    let angle = angleForIndex(index)
                    let radius = maxRadius * score
                    let point = pointOnCircle(center: center, radius: radius, angle: angle)

                    if index == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [theme.accentPrimary.opacity(fillOpacity), theme.success.opacity(fillOpacity)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Stroke outline
            Path { path in
                for (index, score) in normalizedScores.enumerated() {
                    let angle = angleForIndex(index)
                    let radius = maxRadius * score
                    let point = pointOnCircle(center: center, radius: radius, angle: angle)

                    if index == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
            .stroke(
                LinearGradient(
                    colors: [theme.accentPrimary, theme.success],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )

            // Data points
            ForEach(Array(normalizedScores.enumerated()), id: \.offset) { index, score in
                let angle = angleForIndex(index)
                let radius = maxRadius * score
                let point = pointOnCircle(center: center, radius: radius, angle: angle)

                Circle()
                    .fill(traitColor(for: index))
                    .frame(width: 8, height: 8)
                    .position(point)
            }
        }
    }

    // MARK: - Trait Labels

    private var traitLabels: some View {
        let center = CGPoint(x: size / 2, y: size / 2)
        let labelRadius = size / 2 - 8

        return ZStack {
            ForEach(Array(CharacterTrait.allCases.enumerated()), id: \.offset) { index, trait in
                let angle = angleForIndex(index)
                let point = pointOnCircle(center: center, radius: labelRadius, angle: angle)
                let score = Int(orderedScores[index])

                VStack(spacing: 2) {
                    Text(shortLabel(for: trait))
                        .font(.system(size: labelFontSize, weight: .medium))
                        .foregroundColor(theme.textPrimary)

                    Text("\(score)")
                        .font(.system(size: labelFontSize - 2, weight: .semibold))
                        .foregroundColor(traitColor(for: index))
                }
                .position(adjustedLabelPosition(point: point, angle: angle))
            }
        }
    }

    // MARK: - Helper Methods

    private var labelPadding: CGFloat {
        showLabels ? 35 : 10
    }

    private var labelFontSize: CGFloat {
        size < 150 ? 9 : 11
    }

    private func angleForIndex(_ index: Int) -> Double {
        // Start from top (-90 degrees) and go clockwise
        -90 + Double(index) * angleIncrement
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }

    private func hexagonPath(scale: Double) -> Path {
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = (size / 2 - labelPadding) * CGFloat(scale)

        return Path { path in
            for index in 0..<sides {
                let angle = angleForIndex(index)
                let point = pointOnCircle(center: center, radius: radius, angle: angle)

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }

    private func shortLabel(for trait: CharacterTrait) -> String {
        switch trait {
        case .kindness: return "Kind"
        case .courage: return "Brave"
        case .patience: return "Patient"
        case .responsibility: return "Resp."
        case .creativity: return "Create"
        case .resilience: return "Resil."
        }
    }

    private func traitColor(for index: Int) -> Color {
        CharacterTrait.allCases[index].color
    }

    private func adjustedLabelPosition(point: CGPoint, angle: Double) -> CGPoint {
        // Adjust label position to avoid overlapping with chart
        let offset: CGFloat = 12
        let radians = angle * .pi / 180

        return CGPoint(
            x: point.x + offset * CGFloat(cos(radians)),
            y: point.y + offset * CGFloat(sin(radians))
        )
    }

    private var accessibilityDescription: String {
        let topTraits = traitScores
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { "\($0.trait.displayName): \(Int($0.score))" }
            .joined(separator: ", ")

        return "Character profile. Top traits: \(topTraits)"
    }
}

// MARK: - Compact Radar Chart

/// Smaller version of the radar chart without labels, for inline use.
struct CompactRadarChart: View {
    let traitScores: [TraitScore]
    var size: CGFloat = 80

    var body: some View {
        CharacterRadarChart(
            traitScores: traitScores,
            size: size,
            showLabels: false,
            showGridLines: false,
            fillOpacity: 0.4
        )
    }
}

// MARK: - Character Profile Card

/// Full card displaying the character radar chart with title and context.
struct CharacterProfileCard: View {
    @Environment(\.theme) private var theme

    let childName: String
    let traitScores: [TraitScore]
    var onTapGrowthRings: (() -> Void)? = nil

    private var topTrait: TraitScore? {
        traitScores.max(by: { $0.score < $1.score })
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(childName)'s Character")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    if let top = topTrait {
                        Text("Strongest: \(top.trait.displayName)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                if onTapGrowthRings != nil {
                    Button(action: { onTapGrowthRings?() }) {
                        HStack(spacing: 4) {
                            Text("History")
                                .font(.caption)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(theme.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Radar chart
            CharacterRadarChart(traitScores: traitScores, size: 180)

            // Trait legend
            traitLegend
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    private var traitLegend: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(traitScores.sorted(by: { $0.score > $1.score })) { score in
                HStack(spacing: 4) {
                    Circle()
                        .fill(score.trait.color)
                        .frame(width: 8, height: 8)

                    Text(score.trait.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Character Radar Chart") {
    let sampleScores: [TraitScore] = [
        TraitScore(trait: .kindness, score: 75, eventCount: 12, totalPoints: 36),
        TraitScore(trait: .courage, score: 45, eventCount: 6, totalPoints: 18),
        TraitScore(trait: .patience, score: 60, eventCount: 8, totalPoints: 24),
        TraitScore(trait: .responsibility, score: 80, eventCount: 15, totalPoints: 45),
        TraitScore(trait: .creativity, score: 55, eventCount: 7, totalPoints: 21),
        TraitScore(trait: .resilience, score: 40, eventCount: 5, totalPoints: 15)
    ]

    VStack(spacing: 20) {
        CharacterRadarChart(traitScores: sampleScores, size: 220)
        CharacterRadarChart(traitScores: sampleScores, size: 150)
    }
    .padding()
    .withTheme(Theme())
}

#Preview("Compact Radar") {
    let sampleScores: [TraitScore] = [
        TraitScore(trait: .kindness, score: 75, eventCount: 12, totalPoints: 36),
        TraitScore(trait: .courage, score: 45, eventCount: 6, totalPoints: 18),
        TraitScore(trait: .patience, score: 60, eventCount: 8, totalPoints: 24),
        TraitScore(trait: .responsibility, score: 80, eventCount: 15, totalPoints: 45),
        TraitScore(trait: .creativity, score: 55, eventCount: 7, totalPoints: 21),
        TraitScore(trait: .resilience, score: 40, eventCount: 5, totalPoints: 15)
    ]

    HStack(spacing: 20) {
        CompactRadarChart(traitScores: sampleScores, size: 60)
        CompactRadarChart(traitScores: sampleScores, size: 80)
        CompactRadarChart(traitScores: sampleScores, size: 100)
    }
    .padding()
    .withTheme(Theme())
}

#Preview("Character Profile Card") {
    let sampleScores: [TraitScore] = [
        TraitScore(trait: .kindness, score: 75, eventCount: 12, totalPoints: 36),
        TraitScore(trait: .courage, score: 45, eventCount: 6, totalPoints: 18),
        TraitScore(trait: .patience, score: 60, eventCount: 8, totalPoints: 24),
        TraitScore(trait: .responsibility, score: 80, eventCount: 15, totalPoints: 45),
        TraitScore(trait: .creativity, score: 55, eventCount: 7, totalPoints: 21),
        TraitScore(trait: .resilience, score: 40, eventCount: 5, totalPoints: 15)
    ]

    CharacterProfileCard(
        childName: "Emma",
        traitScores: sampleScores,
        onTapGrowthRings: {}
    )
    .padding()
    .background(Theme().bg1)
    .withTheme(Theme())
}
