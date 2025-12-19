import SwiftUI

// MARK: - Insights Scope Chips

/// Horizontal scrollable chip switcher for selecting insights scope.
/// Shows: Family | [Child chips] | You
struct InsightsScopeChips: View {
    @Environment(\.insightsContext) private var context
    @Environment(\.theme) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 8) {
                    // Family chip
                    ScopeChip(
                        icon: "house.fill",
                        label: String(localized: "Family", table: "Insights"),
                        isSelected: context.scope == .family,
                        accentColor: theme.accentPrimary
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            context.selectFamily()
                        }
                    }
                    .id("family")

                    // Child chips (sorted by recently viewed)
                    ForEach(context.sortedChildren(childrenStore.activeChildren)) { child in
                        ChildScopeChip(
                            child: child,
                            isSelected: context.selectedChildId == child.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                context.selectChild(child.id)
                            }
                        }
                        .id(child.id.uuidString)
                    }

                    // You chip (parent journey)
                    ScopeChip(
                        icon: "person.fill",
                        label: String(localized: "You", table: "Insights"),
                        isSelected: context.scope == .you,
                        accentColor: theme.accentPrimary
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            context.selectYou()
                        }
                    }
                    .id("you")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onChange(of: context.scope) { _, newScope in
                    // Scroll to selected chip
                    withAnimation {
                        switch newScope {
                        case .family:
                            proxy.scrollTo("family", anchor: .center)
                        case .child(let id):
                            proxy.scrollTo(id.uuidString, anchor: .center)
                        case .you:
                            proxy.scrollTo("you", anchor: .center)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("scope_switcher_label", tableName: "Insights"))
    }
}

// MARK: - Scope Chip

/// Generic scope chip (Family, You)
struct ScopeChip: View {
    @Environment(\.theme) private var theme

    let icon: String
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : theme.accentMuted)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : theme.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Child Scope Chip

/// Child-specific chip with avatar and name
struct ChildScopeChip: View {
    @Environment(\.theme) private var theme

    let child: Child
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Mini avatar
                Circle()
                    .fill(child.colorTag.color)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(child.initials)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    )

                Text(child.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
            }
            .padding(.leading, 4)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? child.colorTag.color : theme.accentMuted)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : theme.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(child.name)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Compact Scope Pills

/// Even more compact version for tight spaces
struct CompactScopePills: View {
    @Environment(\.insightsContext) private var context
    @Environment(\.theme) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore

    var body: some View {
        HStack(spacing: 6) {
            // Show current scope as main pill
            currentScopePill

            // Quick switcher dots for other options
            if childrenStore.activeChildren.count > 0 {
                quickSwitcherDots
            }
        }
    }

    private var currentScopePill: some View {
        HStack(spacing: 4) {
            Image(systemName: currentIcon)
                .font(.system(size: 10, weight: .semibold))

            Text(currentLabel)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(theme.accentPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.accentPrimary.opacity(0.12))
        )
    }

    private var quickSwitcherDots: some View {
        HStack(spacing: 4) {
            ForEach(context.sortedChildren(childrenStore.activeChildren).prefix(3)) { child in
                Circle()
                    .fill(child.colorTag.color.opacity(context.selectedChildId == child.id ? 1.0 : 0.4))
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            context.selectChild(child.id)
                        }
                    }
            }
        }
    }

    private var currentIcon: String {
        context.scope.icon
    }

    private var currentLabel: String {
        switch context.scope {
        case .family:
            return String(localized: "Family", table: "Insights")
        case .child(let id):
            if let child = childrenStore.activeChildren.first(where: { $0.id == id }) {
                return child.name
            }
            return String(localized: "Child", table: "Insights")
        case .you:
            return String(localized: "You", table: "Insights")
        }
    }
}

// MARK: - Preview

#Preview("Scope Chips") {
    let context = InsightsContext()
    let repository = Repository.preview

    VStack(spacing: 20) {
        InsightsScopeChips()

        Divider()

        CompactScopePills()
    }
    .padding()
    .withInsightsContext(context)
    .environmentObject(ChildrenStore(repository: repository))
    .withTheme(Theme())
}
