import SwiftUI

// MARK: - Insights Child Picker Sheet

/// Modal sheet for selecting which child to view insights for.
/// Shows all active children sorted by recently viewed.
///
/// ## Design Principles
/// - Large touch targets for tired parents
/// - Recently viewed children appear first
/// - Clear visual feedback on selection
/// - Accessible: full VoiceOver support
struct InsightsChildSelectionSheet: View {
    @Environment(\.themeProvider) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigation: InsightsNavigationState
    @EnvironmentObject private var childrenStore: ChildrenStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header explanation
                    Text("Choose which child's insights to view", tableName: "Insights")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // Child list
                    LazyVStack(spacing: 12) {
                        ForEach(sortedChildren) { child in
                            ChildPickerRow(
                                child: child,
                                isSelected: child.id == navigation.selectedChildId
                            ) {
                                navigation.selectChild(child.id)
                                dismiss()
                            }
                            .accessibilityIdentifier(InsightsAccessibilityIdentifiers.childPickerRow(childId: child.id))
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.childPickerList)

                    // Empty state
                    if childrenStore.activeChildren.isEmpty {
                        emptyState
                    }
                }
                .padding(.vertical, 16)
            }
            .background(theme.backgroundColor)
            .navigationTitle(Text("Select Child", tableName: "Insights"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("Cancel", tableName: "Common")
                    }
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.childPickerCancelButton)
                }
            }
        }
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.childPickerSheetRoot)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sorted Children

    private var sortedChildren: [Child] {
        navigation.sortedChildren(childrenStore.activeChildren)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryText)

            Text("No children added yet", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.primaryText)

            Text("Add a child from the Kids tab to see insights", tableName: "Insights")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Child Picker Row

private struct ChildPickerRow: View {
    @Environment(\.themeProvider) private var theme

    let child: Child
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Avatar
                childAvatar

                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.headline)
                        .foregroundColor(theme.primaryText)

                    // Optional: show recent activity hint
                    if let recentActivity = recentActivityHint {
                        Text(recentActivity)
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(isSelected ? theme.accentColor.opacity(0.1) : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(isSelected ? theme.accentColor : theme.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(child.name)\(isSelected ? ", currently selected" : "")", tableName: "Insights"))
        .accessibilityHint(Text("Double tap to view \(child.name)'s insights", tableName: "Insights"))
    }

    // MARK: - Avatar

    private var childAvatar: some View {
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
                .frame(width: 52, height: 52)

            Text(child.name.prefix(1).uppercased())
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Recent Activity Hint

    private var recentActivityHint: String? {
        // Could be enhanced to show "3 wins this week" or similar
        // For now, return nil
        nil
    }
}

// MARK: - Preview

#Preview("Child Selection Sheet") {
    let navigation = InsightsNavigationState()
    let repository = Repository.preview

    InsightsChildSelectionSheet()
        .environmentObject(navigation)
        .environmentObject(ChildrenStore(repository: repository))
        .withThemeProvider(ThemeProvider())
}
