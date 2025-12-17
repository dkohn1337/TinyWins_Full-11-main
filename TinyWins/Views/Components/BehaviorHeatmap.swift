import SwiftUI

// MARK: - BehaviorHeatmap

/// A 7x24 heatmap showing behavior patterns by day and hour.
struct BehaviorHeatmap: View {
    @Environment(\.themeProvider) private var theme

    let data: HeatmapData
    let colorScheme: HeatmapColorScheme

    @State private var selectedCell: (day: Int, hour: Int)?

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let hourLabels = ["12a", "6a", "12p", "6p"]

    var body: some View {
        VStack(spacing: 8) {
            // Hour labels row
            hourLabelsRow

            HStack(spacing: 4) {
                // Day labels column
                dayLabelsColumn

                // Heatmap grid
                heatmapGrid
            }

            // Legend
            legendRow
        }
    }

    // MARK: - Hour Labels

    private var hourLabelsRow: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 16)

            ForEach(0..<24, id: \.self) { hour in
                if hour % 6 == 0 {
                    Text(hourLabels[hour / 6])
                        .font(.system(size: 8))
                        .foregroundColor(theme.secondaryText)
                        .frame(width: 10 * 6)
                }
            }
        }
    }

    // MARK: - Day Labels

    private var dayLabelsColumn: some View {
        VStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { day in
                Text(dayLabels[day])
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 14, height: 14)
            }
        }
    }

    // MARK: - Heatmap Grid

    private var heatmapGrid: some View {
        VStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { day in
                HStack(spacing: 2) {
                    ForEach(0..<24, id: \.self) { hour in
                        cellView(day: day, hour: hour)
                    }
                }
            }
        }
    }

    private func cellView(day: Int, hour: Int) -> some View {
        let value = data.normalizedValue(day: day, hour: hour)
        let isSelected = selectedCell?.day == day && selectedCell?.hour == hour

        return Rectangle()
            .fill(cellColor(for: value))
            .frame(width: 10, height: 14)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? theme.primaryText : Color.clear, lineWidth: 1)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedCell?.day == day && selectedCell?.hour == hour {
                        selectedCell = nil
                    } else {
                        selectedCell = (day, hour)
                    }
                }
            }
    }

    private func cellColor(for value: Double) -> Color {
        if value == 0 {
            return Color(.systemGray6)
        }

        // Use theme colors instead of hardcoded enum colors
        let baseColor: Color
        switch colorScheme {
        case .positive: baseColor = theme.positiveColor
        case .challenge: baseColor = theme.challengeColor
        case .neutral: baseColor = theme.accentColor
        }
        return baseColor.opacity(0.2 + value * 0.8)
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 9))
                .foregroundColor(theme.secondaryText)

            ForEach(0..<5, id: \.self) { level in
                Rectangle()
                    .fill(cellColor(for: Double(level) / 4.0))
                    .frame(width: 12, height: 12)
                    .cornerRadius(2)
            }

            Text("More")
                .font(.system(size: 9))
                .foregroundColor(theme.secondaryText)
        }
    }
}

// MARK: - Heatmap Color Scheme

enum HeatmapColorScheme {
    case positive
    case challenge
    case neutral

    var baseColor: Color {
        switch self {
        case .positive: return Color.green
        case .challenge: return Color.orange
        case .neutral: return Color.blue
        }
    }
}

// MARK: - Compact Heatmap

/// A smaller, more compact version of the heatmap for dashboards.
struct CompactBehaviorHeatmap: View {
    @Environment(\.themeProvider) private var theme

    let data: HeatmapData
    let colorScheme: HeatmapColorScheme

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 4) {
            // Grid
            HStack(spacing: 2) {
                // Day labels
                VStack(spacing: 1) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(dayLabels[day])
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 10, height: 8)
                    }
                }

                // Heatmap
                VStack(spacing: 1) {
                    ForEach(0..<7, id: \.self) { day in
                        HStack(spacing: 1) {
                            ForEach(0..<24, id: \.self) { hour in
                                let value = data.normalizedValue(day: day, hour: hour)
                                Rectangle()
                                    .fill(cellColor(for: value))
                                    .frame(width: 6, height: 8)
                                    .cornerRadius(1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cellColor(for value: Double) -> Color {
        if value == 0 {
            return Color(.systemGray6)
        }
        // Use theme colors instead of hardcoded enum colors
        let baseColor: Color
        switch colorScheme {
        case .positive: baseColor = theme.positiveColor
        case .challenge: baseColor = theme.challengeColor
        case .neutral: baseColor = theme.accentColor
        }
        return baseColor.opacity(0.2 + value * 0.8)
    }
}

// MARK: - Preview

#Preview("Full Heatmap") {
    BehaviorHeatmap(
        data: HeatmapData.preview,
        colorScheme: .positive
    )
    .padding()
    .withThemeProvider(ThemeProvider())
}

#Preview("Compact Heatmap") {
    CompactBehaviorHeatmap(
        data: HeatmapData.preview,
        colorScheme: .challenge
    )
    .padding()
    .withThemeProvider(ThemeProvider())
}

// MARK: - Preview Data

extension HeatmapData {
    static var preview: HeatmapData {
        var data = [[Int]](repeating: [Int](repeating: 0, count: 24), count: 7)

        // Generate some sample data
        for day in 0..<7 {
            for hour in 0..<24 {
                // More activity in morning (7-9) and evening (17-20)
                if (7...9).contains(hour) || (17...20).contains(hour) {
                    data[day][hour] = Int.random(in: 0...5)
                } else if (10...16).contains(hour) {
                    data[day][hour] = Int.random(in: 0...2)
                }
            }
        }

        return HeatmapData(data: data, maxValue: 5, period: .thisMonth)
    }
}
