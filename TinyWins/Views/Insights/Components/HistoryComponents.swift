import SwiftUI

// MARK: - Filter Dropdown Label

/// Premium dropdown filter button - clean, warm, no text wrapping
struct FilterDropdownLabel: View {
    @Environment(\.theme) private var theme

    let text: String
    var icon: String? = nil  // Optional - icons removed for cleaner look
    var accentColor: Color? = nil  // Optional accent for selected state

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(theme.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 70)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor?.opacity(0.08) ?? theme.surface1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentColor ?? theme.borderSoft, lineWidth: 1)
        )
        .foregroundColor(accentColor ?? theme.textPrimary)
        .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        .animation(nil, value: accentColor)  // Disable animation on color changes
    }
}

/// Legacy initializer for backward compatibility
extension FilterDropdownLabel {
    init(text: String, icon: String) {
        self.text = text
        self.icon = icon
        self.accentColor = nil
    }
}

// MARK: - Filter Chip

/// Chip button for selecting filter options
struct FilterChip: View {
    @Environment(\.theme) private var theme
    let label: String
    let isSelected: Bool
    let color: Color
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon, isSelected {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : theme.borderSoft)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Summary Pill

/// Compact stat display for summary bar
struct SummaryPill: View {
    @Environment(\.theme) private var theme
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Detail Row

/// Row showing a label-value pair with icon
struct DetailRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

// MARK: - Child Filter Button

/// Button for filtering by child
struct ChildFilterButton: View {
    @Environment(\.theme) private var theme
    let title: String
    var color: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : theme.borderSoft)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History Filter Section

/// Three-row filter section for time, child, and type
struct HistoryFilterSection: View {
    @Environment(\.theme) private var theme

    @Binding var selectedPeriod: TimePeriod
    @Binding var selectedChildId: UUID?
    @Binding var selectedTypeFilter: HistoryTypeFilter
    let children: [Child]

    var body: some View {
        VStack(spacing: 10) {
            // Row 1: Time chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([TimePeriod.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .allTime], id: \.self) { period in
                        FilterChip(
                            label: period.displayName,
                            isSelected: selectedPeriod == period,
                            color: AppColors.primary
                        ) {
                            withAnimation { selectedPeriod = period }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Row 2: Who chips (children)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All Kids",
                        isSelected: selectedChildId == nil,
                        color: AppColors.primary
                    ) {
                        withAnimation { selectedChildId = nil }
                    }

                    ForEach(children) { child in
                        FilterChip(
                            label: child.name,
                            isSelected: selectedChildId == child.id,
                            color: child.colorTag.color
                        ) {
                            withAnimation { selectedChildId = child.id }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Row 3: What chips (type filter)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HistoryTypeFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            label: filter.rawValue,
                            isSelected: selectedTypeFilter == filter,
                            color: typeFilterColor(for: filter),
                            icon: filter.icon
                        ) {
                            withAnimation { selectedTypeFilter = filter }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(theme.surface1)
    }

    private func typeFilterColor(for filter: HistoryTypeFilter) -> Color {
        switch filter {
        case .allMoments: return .gray
        case .positiveOnly: return AppColors.positive
        case .challengesOnly: return AppColors.challenge
        case .goalsOnly: return AppColors.primary
        }
    }
}

// MARK: - History Summary Bar

/// Summary bar showing positive/challenge/net star counts
struct HistorySummaryBar: View {
    @Environment(\.theme) private var theme

    let positiveCount: Int
    let challengeCount: Int
    let netStars: Int

    var body: some View {
        HStack(spacing: 0) {
            SummaryPill(
                icon: "hand.thumbsup.fill",
                value: "\(positiveCount)",
                label: "Positive",
                color: AppColors.positive
            )

            Divider()
                .frame(height: 30)

            SummaryPill(
                icon: "exclamationmark.triangle.fill",
                value: "\(challengeCount)",
                label: "Challenges",
                color: AppColors.challenge
            )

            Divider()
                .frame(height: 30)

            SummaryPill(
                icon: "star.fill",
                value: netStars >= 0 ? "+\(netStars)" : "\(netStars)",
                label: "Net Stars",
                color: netStars >= 0 ? AppColors.positive : .red
            )
        }
        .padding(.vertical, 12)
        .background(theme.surface1)
    }
}

// MARK: - History Empty State

/// Empty state for history view
struct HistoryEmptyState: View {
    @Environment(\.theme) private var theme
    let hasAnyData: Bool
    let onResetFilters: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StyledIcon(systemName: "clock.badge.checkmark", color: theme.textSecondary, size: 32, backgroundSize: 64, isCircle: true)

                if !hasAnyData {
                    Text("Your timeline will grow here")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Every moment you log becomes part of your family's story.")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                } else {
                    Text("Nothing matches this filter")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Try widening your filters to see more moments.")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    Button(action: onResetFilters) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Show everything")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .padding(.top, 16)
            .tabBarBottomPadding()
        }
    }
}

// MARK: - Previews

#Preview("Filter Chip") {
    HStack {
        FilterChip(label: "Today", isSelected: true, color: .purple, action: {})
        FilterChip(label: "This Week", isSelected: false, color: .purple, action: {})
    }
    .padding()
}

#Preview("Summary Bar") {
    HistorySummaryBar(positiveCount: 12, challengeCount: 3, netStars: 9)
}

#Preview("Empty State") {
    HistoryEmptyState(hasAnyData: true, onResetFilters: {})
}
