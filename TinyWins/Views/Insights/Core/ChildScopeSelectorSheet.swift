import SwiftUI

// MARK: - Scope Selector Sheet

/// Full-screen sheet for selecting insights scope.
/// Shows Family, all children, and You options with rich previews.
struct ScopeSelectorSheet: View {
    @Environment(\.insightsContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var childrenStore: ChildrenStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header explanation
                    headerSection

                    // Scope options
                    VStack(spacing: 12) {
                        // Family option
                        familyScopeRow

                        // Divider with label
                        scopeDivider(label: String(localized: "Children", table: "Insights"))

                        // Children
                        ForEach(context.sortedChildren(childrenStore.activeChildren)) { child in
                            childScopeRow(child)
                        }

                        // Divider with label
                        scopeDivider(label: String(localized: "Parent", table: "Insights"))

                        // You option
                        youScopeRow
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 20)
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle(Text("select_scope_title", tableName: "Insights"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel", table: "Insights")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.success],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("scope_selector_header", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Text("scope_selector_description", tableName: "Insights")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Family Scope Row

    private var familyScopeRow: some View {
        Button {
            context.selectFamily()
            dismiss()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "house.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.accentPrimary)
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text("Family", tableName: "Insights")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    Text("family_scope_description", tableName: "Insights")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Selection indicator
                if context.scope == .family {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.accentPrimary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(context.scope == .family ? theme.accentPrimary.opacity(0.08) : theme.surface1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(context.scope == .family ? theme.accentPrimary.opacity(0.3) : theme.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(context.scope == .family ? .isSelected : [])
    }

    // MARK: - Child Scope Row

    private func childScopeRow(_ child: Child) -> some View {
        let isSelected = context.selectedChildId == child.id

        return Button {
            context.selectChild(child.id)
            dismiss()
        } label: {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(child.colorTag.color)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(child.initials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    Text("child_scope_description", tableName: "Insights")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(child.colorTag.color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? child.colorTag.color.opacity(0.08) : theme.surface1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? child.colorTag.color.opacity(0.3) : theme.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(child.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - You Scope Row

    private var youScopeRow: some View {
        Button {
            context.selectYou()
            dismiss()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.success.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.success)
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text("You", tableName: "Insights")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    Text("you_scope_description", tableName: "Insights")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Selection indicator
                if context.scope == .you {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.success)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(context.scope == .you ? theme.success.opacity(0.08) : theme.surface1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(context.scope == .you ? theme.success.opacity(0.3) : theme.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(context.scope == .you ? .isSelected : [])
    }

    // MARK: - Scope Divider

    private func scopeDivider(label: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(theme.borderSoft)
                .frame(height: 1)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)

            Rectangle()
                .fill(theme.borderSoft)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Child Switcher

/// Compact horizontal child switcher for inline use
struct QuickChildSwitcher: View {
    @Environment(\.insightsContext) private var context
    @Environment(\.theme) private var theme
    @EnvironmentObject private var childrenStore: ChildrenStore

    let onShowAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(context.sortedChildren(childrenStore.activeChildren)) { child in
                    quickChildChip(child)
                }

                // "More" button if needed
                if childrenStore.activeChildren.count > 4 {
                    Button {
                        onShowAll()
                    } label: {
                        Text("more_children", tableName: "Insights")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(theme.borderSoft, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func quickChildChip(_ child: Child) -> some View {
        let isSelected = context.selectedChildId == child.id

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                context.selectChild(child.id)
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(child.colorTag.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(child.initials)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    )

                Text(child.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? child.colorTag.color : theme.accentMuted)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Scope Selector Sheet") {
    let context = InsightsContext()
    let repository = Repository.preview

    ScopeSelectorSheet()
        .withInsightsContext(context)
        .environmentObject(ChildrenStore(repository: repository))
        .withTheme(Theme())
}

#Preview("Quick Child Switcher") {
    let context = InsightsContext()
    let repository = Repository.preview

    QuickChildSwitcher(onShowAll: {})
        .withInsightsContext(context)
        .environmentObject(ChildrenStore(repository: repository))
        .withTheme(Theme())
}
