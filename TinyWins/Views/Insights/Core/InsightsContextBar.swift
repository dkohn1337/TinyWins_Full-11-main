import SwiftUI

// MARK: - Insights Context Bar

/// Sticky context bar shown at the top of all Insights screens
/// Always visible, shows: scope label, time range, change affordance
struct InsightsContextBar: View {
    @Environment(\.insightsContext) private var context
    @Environment(\.themeProvider) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore

    @Binding var showingScopeSelector: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Scope indicator with change affordance
            scopeButton

            Spacer()

            // Time range selector
            timeRangeSelector
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(contextBarBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(context.accessibilityLabel(for: currentChild))
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Scope Button

    private var scopeButton: some View {
        Button {
            showingScopeSelector = true
        } label: {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: scopeIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accentColor)

                // Label
                VStack(alignment: .leading, spacing: 1) {
                    Text(scopeLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.primaryText)

                    Text("tap_to_change", tableName: "Insights")
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accentColor.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("scope_button_label", tableName: "Insights"))
        .accessibilityHint(Text("scope_button_hint", tableName: "Insights"))
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        Menu {
            ForEach(InsightsTimeRange.allCases) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        context.setTimeRange(range)
                    }
                } label: {
                    HStack {
                        Text(range.displayKey)
                        if context.timeRange == range {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text(context.timeRange.shortDisplayKey)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(10)
            .shadow(color: theme.accentColor.opacity(0.3), radius: 4, y: 2)
        }
        .accessibilityLabel(Text("time_range_label", tableName: "Insights"))
        .accessibilityHint(Text("Double tap to change time range", tableName: "Insights"))
    }

    // MARK: - Background

    private var contextBarBackground: some View {
        Rectangle()
            .fill(theme.backgroundColor)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Computed Values

    private var scopeIcon: String {
        switch context.scope {
        case .family:
            return "house.fill"
        case .child:
            return "figure.child"
        case .you:
            return "person.fill"
        }
    }

    private var scopeLabel: LocalizedStringKey {
        switch context.scope {
        case .family:
            return "Family"
        case .child:
            if let child = currentChild {
                return LocalizedStringKey(child.name)
            }
            return "Child"
        case .you:
            return "You"
        }
    }

    private var currentChild: Child? {
        guard let childId = context.selectedChildId else { return nil }
        return childrenStore.activeChildren.first { $0.id == childId }
    }
}

// MARK: - Compact Context Bar

/// More compact version for sub-pages where space is tighter
struct CompactInsightsContextBar: View {
    @Environment(\.insightsContext) private var context
    @Environment(\.themeProvider) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore

    var body: some View {
        HStack(spacing: 8) {
            // Scope pill
            HStack(spacing: 4) {
                Image(systemName: scopeIcon)
                    .font(.system(size: 11, weight: .semibold))
                Text(scopeLabel)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(theme.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(theme.accentColor.opacity(0.12))
            )

            // Time range pill
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .semibold))
                Text(context.timeRange.shortDisplayKey)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(theme.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(theme.accentColor.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
            )

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(context.accessibilityLabel(for: currentChild))
    }

    private var scopeIcon: String {
        context.scope.icon
    }

    private var scopeLabel: LocalizedStringKey {
        switch context.scope {
        case .family:
            return "Family"
        case .child:
            if let child = currentChild {
                return LocalizedStringKey(child.name)
            }
            return "Child"
        case .you:
            return "You"
        }
    }

    private var currentChild: Child? {
        guard let childId = context.selectedChildId else { return nil }
        return childrenStore.activeChildren.first { $0.id == childId }
    }
}

// MARK: - Preview

#Preview("Context Bar") {
    let context = InsightsContext()
    let repository = Repository.preview

    VStack(spacing: 20) {
        InsightsContextBar(showingScopeSelector: .constant(false))

        CompactInsightsContextBar()
    }
    .withInsightsContext(context)
    .environmentObject(ChildrenStore(repository: repository))
    .withThemeProvider(ThemeProvider())
}
