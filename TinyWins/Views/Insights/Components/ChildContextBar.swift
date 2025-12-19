import SwiftUI

// MARK: - Child Context Bar

/// Sticky bar showing the currently selected child.
/// Single source of truth for child selection across all Insights screens.
///
/// ## Design Principles
/// - Always visible at top of Insights screens
/// - One tap to switch children
/// - Shows child avatar and name clearly
/// - Accessible: full VoiceOver support
struct ChildContextBar: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var navigation: InsightsNavigationState
    @EnvironmentObject private var childrenStore: ChildrenStore

    var body: some View {
        HStack(spacing: 12) {
            // Child Avatar + Name (tappable)
            Button {
                navigation.showingChildPicker = true
            } label: {
                HStack(spacing: 10) {
                    // Avatar
                    childAvatar

                    // Name + change indicator
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedChildName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)

                        Text("Tap to switch", tableName: "Insights")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(theme.surface1)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(Text("Double tap to choose a different child", tableName: "Insights"))
            .accessibilityIdentifier(InsightsAccessibilityIdentifiers.childPickerOpenButton)

            Spacer()

            // Time range picker (compact)
            timeRangePicker
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 10)
        .background(theme.bg0)
        .overlay(
            // Bottom separator line
            Rectangle()
                .fill(theme.borderSoft)
                .frame(height: 1),
            alignment: .bottom
        )
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.childContextBarRoot)
    }

    // MARK: - Child Avatar

    @ViewBuilder
    private var childAvatar: some View {
        if let child = selectedChild {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                child.colorTag.color,
                                child.colorTag.color.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Text(child.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        } else {
            // No child selected - show placeholder
            Circle()
                .fill(theme.borderSoft)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(theme.textSecondary)
                )
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Menu {
            ForEach(InsightsTimeRange.allCases) { range in
                Button {
                    navigation.timeRange = range
                } label: {
                    HStack {
                        Text(range.displayKey)
                        if navigation.timeRange == range {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(navigation.timeRange.shortDisplayKey)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surface2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.borderStrong, lineWidth: 1)
            )
        }
        .accessibilityLabel(Text("Time range: \(navigation.timeRange.displayKey)", tableName: "Insights"))
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.timeRangePicker)
    }

    // MARK: - Helpers

    private var selectedChild: Child? {
        guard let id = navigation.selectedChildId else { return nil }
        return childrenStore.activeChildren.first { $0.id == id }
    }

    private var selectedChildName: String {
        selectedChild?.name ?? String(localized: "Select child", table: "Insights")
    }

    private var accessibilityLabel: Text {
        if let child = selectedChild {
            return Text("Viewing insights for \(child.name)", tableName: "Insights")
        } else {
            return Text("No child selected", tableName: "Insights")
        }
    }
}

// MARK: - Preview

#Preview("Child Context Bar") {
    let navigation = InsightsNavigationState()
    let repository = Repository.preview

    VStack {
        ChildContextBar()

        Spacer()
    }
    .environmentObject(navigation)
    .environmentObject(ChildrenStore(repository: repository))
    .withTheme(Theme())
}
