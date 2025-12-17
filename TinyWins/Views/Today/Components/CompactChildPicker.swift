import SwiftUI

// MARK: - CompactChildPicker

/// Horizontal scrollable child picker optimized for quick selection.
/// Ensures selected child is always visible and scrolled into view.
struct CompactChildPicker: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var behaviorsStore: BehaviorsStore

    let children: [Child]
    @Binding var selectedChildId: UUID?
    let onChildSelected: (Child) -> Void

    // Track if we need to scroll on appear
    @State private var hasScrolledOnAppear = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(children) { child in
                        ChildAvatarButton(
                            child: child,
                            isSelected: selectedChildId == child.id,
                            todayStars: behaviorsStore.todayPoints(forChild: child.id),
                            hasMomentsToday: hasMomentsToday(for: child),
                            onTap: {
                                selectChild(child, proxy: proxy)
                            }
                        )
                        .id(child.id)
                    }
                }
                // Extra content padding ensures edge items can scroll fully into view
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedChildId) { _, newId in
                scrollToChild(id: newId, proxy: proxy)
            }
            .onAppear {
                // Scroll to selected child on first appear
                if !hasScrolledOnAppear {
                    hasScrolledOnAppear = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToChild(id: selectedChildId, proxy: proxy)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func hasMomentsToday(for child: Child) -> Bool {
        behaviorsStore.todayEvents.contains { $0.childId == child.id }
    }

    private func selectChild(_ child: Child, proxy: ScrollViewProxy) {
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedChildId = child.id
        }

        onChildSelected(child)

        // Scroll to center
        scrollToChild(id: child.id, proxy: proxy)
    }

    private func scrollToChild(id: UUID?, proxy: ScrollViewProxy) {
        guard let id = id else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(id, anchor: .center)
        }
    }
}

// MARK: - ChildAvatarButton

/// Individual child avatar button with selection state.
/// Tapping navigates to add moment for this child.
private struct ChildAvatarButton: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore

    let child: Child
    let isSelected: Bool
    let todayStars: Int
    let hasMomentsToday: Bool
    let onTap: () -> Void

    private let avatarSize: CGFloat = 46

    private var hasActiveGoal: Bool {
        rewardsStore.activeReward(forChild: child.id) != nil
    }

    /// Check if goal target has been reached today
    private var hasReachedGoalToday: Bool {
        guard let goal = rewardsStore.activeReward(forChild: child.id) else { return false }
        let earned = goal.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
        return earned >= goal.targetPoints
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 4) {
                // Avatar with selection ring and tap affordance
                ZStack {
                    // Selection ring
                    Circle()
                        .stroke(
                            isSelected ? child.colorTag.color : Color.clear,
                            lineWidth: 2.5
                        )
                        .frame(width: avatarSize + 6, height: avatarSize + 6)

                    // Avatar background
                    Circle()
                        .fill(
                            isSelected
                                ? child.colorTag.color
                                : child.colorTag.color.opacity(0.15)
                        )
                        .frame(width: avatarSize, height: avatarSize)

                    // Child initials
                    Text(child.initials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : child.colorTag.color)

                    // Goal reached indicator (replaces confusing green dot)
                    if hasReachedGoalToday {
                        // Checkmark badge for goal reached
                        ZStack {
                            Circle()
                                .fill(themeProvider.positiveColor)
                                .frame(width: 16, height: 16)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(themeProvider.cardBackground, lineWidth: 2)
                        )
                        .offset(x: avatarSize / 2 - 4, y: -avatarSize / 2 + 4)
                    }

                    // "+" badge to indicate tappable for adding moment
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(child.colorTag.color)
                                .frame(width: 18, height: 18)
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(themeProvider.cardBackground, lineWidth: 2)
                        )
                        .offset(x: avatarSize / 2 - 2, y: avatarSize / 2 - 2)
                    }
                }

                // Name
                Text(child.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? themeProvider.primaryText : themeProvider.secondaryText)
                    .lineLimit(1)

                // Selection indicator dot
                Circle()
                    .fill(isSelected ? child.colorTag.color : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(minWidth: 60)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isSelected ? "Tap to add moment" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accessibilityLabel: String {
        var label = child.name
        if todayStars != 0 {
            label += ", \(todayStars) stars today"
        }
        if hasReachedGoalToday {
            label += ", goal reached"
        } else if hasActiveGoal {
            label += ", has active goal"
        }
        if hasMomentsToday {
            label += ", has moments logged today"
        }
        return label
    }
}

// MARK: - Preview

// Previews disabled - require full environment setup with repository injection
// See TodayView preview for complete preview configuration
