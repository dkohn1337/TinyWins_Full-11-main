import SwiftUI

// MARK: - CollapsibleRow

/// A row that can expand/collapse to show additional content.
/// Used for streak, focus, and reflection sections on Today.
struct CollapsibleRow<CollapsedContent: View, ExpandedContent: View>: View {
    @EnvironmentObject private var themeProvider: ThemeProvider

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isExpanded: Bool
    let collapsedContent: () -> CollapsedContent
    let expandedContent: () -> ExpandedContent

    @State private var contentHeight: CGFloat = 0

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder collapsedContent: @escaping () -> CollapsedContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.collapsedContent = collapsedContent
        self.expandedContent = expandedContent
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible, tappable) - compact
            Button(action: toggleExpanded) {
                HStack(spacing: 10) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                        .frame(width: 20)

                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeProvider.primaryText)

                        if let subtitle = subtitle, !isExpanded {
                            Text(subtitle)
                                .font(.system(size: 11))
                                .foregroundColor(themeProvider.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Collapsed preview content
                    if !isExpanded {
                        collapsedContent()
                    }

                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeProvider.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? 14 : 10)
                        .fill(themeProvider.cardBackground)
                        .shadow(color: themeProvider.cardShadow.opacity(isExpanded ? 0.8 : 0.4), radius: isExpanded ? 4 : 2, y: 2)
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(subtitle ?? "")")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
            .accessibilityAddTraits(.isButton)

            // Expanded content - compact padding
            if isExpanded {
                expandedContent()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 14,
                            topTrailingRadius: 0
                        )
                        .fill(themeProvider.cardBackground)
                        .shadow(color: themeProvider.cardShadow.opacity(0.4), radius: 3, y: 2)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func toggleExpanded() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Convenience Initializer for Simple Rows

extension CollapsibleRow where CollapsedContent == EmptyView {
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        self.init(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
            isExpanded: isExpanded,
            collapsedContent: { EmptyView() },
            expandedContent: expandedContent
        )
    }
}

// MARK: - Streak Row Content

struct StreakRowContent: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    @EnvironmentObject private var progressionStore: ProgressionStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore

    private var activeDays: Int {
        progressionStore.parentActivity.activeDaysThisWeek
    }

    var body: some View {
        VStack(spacing: 10) {
            // Day indicators - compact size
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { day in
                    let calendar = Calendar.current
                    let weekdaySymbols = calendar.veryShortWeekdaySymbols
                    let adjustedIndex = (day + calendar.firstWeekday - 1) % 7
                    let dayName = weekdaySymbols[adjustedIndex]
                    let isActive = day < activeDays

                    VStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .fill(
                                    isActive
                                        ? LinearGradient(colors: [themeProvider.streakActiveColor, themeProvider.positiveColor], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [themeProvider.streakInactiveColor], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 26, height: 26)

                            if isActive {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(dayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isActive ? themeProvider.streakActiveColor : themeProvider.secondaryText)
                    }
                }
            }

            // Supportive message (no guilt) - compact
            Text(supportiveMessage)
                .font(.system(size: 12))
                .foregroundColor(themeProvider.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private var supportiveMessage: String {
        switch activeDays {
        case 0:
            return "Start whenever you're ready."
        case 1:
            return "You showed up today."
        case 2:
            return "Two days of noticing the good."
        case 3...4:
            return "Consistent this week. Your kids feel that."
        case 5...6:
            return "Amazing consistency!"
        case 7:
            return "A full week!"
        default:
            return "Keep going at your own pace."
        }
    }
}

// MARK: - Focus Row Content

struct FocusRowContent: View {
    @EnvironmentObject private var themeProvider: ThemeProvider

    let focusTip: String
    let actionTip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(focusTip)
                .font(.system(size: 13))
                .foregroundColor(themeProvider.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 11))
                    .foregroundColor(themeProvider.accentColor)

                Text(actionTip)
                    .font(.system(size: 12))
                    .foregroundColor(themeProvider.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeProvider.accentColor.opacity(0.08))
            )
        }
        .padding(.top, 6)
    }
}

// MARK: - Previews

// Previews disabled - require full environment setup with repository injection
// See TodayView preview for complete preview configuration
