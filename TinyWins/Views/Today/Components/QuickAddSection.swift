import SwiftUI

// MARK: - QuickAddSection

/// The primary action area on Today: child picker + big Add Moment button.
/// Designed to minimize time-to-first-log.
struct QuickAddSection: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore

    @Binding var selectedChildId: UUID?
    let onAddMoment: (Child) -> Void

    private var selectedChild: Child? {
        guard let id = selectedChildId else { return nil }
        return childrenStore.activeChildren.first { $0.id == id }
    }

    private var activeGoal: Reward? {
        guard let childId = selectedChildId else { return nil }
        return rewardsStore.activeReward(forChild: childId)
    }

    private var goalProgress: (earned: Int, target: Int)? {
        guard let goal = activeGoal else { return nil }
        let earned = goal.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
        return (earned, goal.targetPoints)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Child picker (horizontal scroll)
            if childrenStore.activeChildren.isEmpty {
                noChildrenState
            } else {
                CompactChildPicker(
                    children: childrenStore.activeChildren,
                    selectedChildId: $selectedChildId,
                    onChildSelected: { _ in }
                )
            }

            // Primary Add Moment button
            if let child = selectedChild {
                addMomentButton(for: child)
            } else if !childrenStore.activeChildren.isEmpty {
                // Auto-select first child if none selected
                Color.clear
                    .onAppear {
                        if selectedChildId == nil {
                            selectedChildId = childrenStore.activeChildren.first?.id
                        }
                    }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeProvider.cardBackground)
                .shadow(color: themeProvider.cardShadow, radius: 8, y: 4)
        )
    }

    // MARK: - Add Moment Button

    private func addMomentButton(for child: Child) -> some View {
        VStack(spacing: 12) {
            // Big primary button
            Button(action: { onAddMoment(child) }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))

                    Text("Add Moment")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [child.colorTag.color, child.colorTag.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: child.colorTag.color.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Add moment for \(child.name)")
            .accessibilityHint("Double tap to log a new moment")

            // Context line: who + goal progress
            contextLine(for: child)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Context Line

    private func contextLine(for child: Child) -> some View {
        HStack(spacing: 6) {
            Text("Adding for")
                .font(.system(size: 13))
                .foregroundColor(themeProvider.secondaryText)

            Text(child.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(child.colorTag.color)

            if let progress = goalProgress {
                Text("·")
                    .foregroundColor(themeProvider.secondaryText)

                HStack(spacing: 3) {
                    Text("\(progress.earned)/\(progress.target)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeProvider.secondaryText)

                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(themeProvider.starColor)
                }
            } else {
                Text("·")
                    .foregroundColor(themeProvider.secondaryText)

                Text("No goal yet")
                    .font(.system(size: 13))
                    .foregroundColor(themeProvider.secondaryText.opacity(0.7))
            }
        }
    }

    // MARK: - Empty State

    private var noChildrenState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 36))
                .foregroundColor(themeProvider.secondaryText.opacity(0.5))

            Text("Add your first child to get started")
                .font(.system(size: 15))
                .foregroundColor(themeProvider.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

// Previews disabled - require full environment setup with repository injection
// See TodayView preview for complete preview configuration
