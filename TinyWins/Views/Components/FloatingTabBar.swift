import SwiftUI

// MARK: - Tab Bar Inset Environment

/// Constants for floating tab bar dimensions
enum FloatingTabBarMetrics {
    /// The height of the tab bar container
    static let height: CGFloat = 64
    /// Bottom padding below the tab bar
    static let bottomPadding: CGFloat = 12
    /// Extra clearance to guarantee no overlap
    static let contentClearance: CGFloat = 8
    /// Total fixed height (bar + padding + clearance)
    static let totalFixedHeight: CGFloat = height + bottomPadding + contentClearance // 84pt
}

/// Environment key for tab bar bottom inset
struct TabBarInsetKey: EnvironmentKey {
    /// Fallback used only when tabBarInset is not injected via .environment().
    /// Does not include safe area - views using this fallback may have incorrect insets.
    static let defaultValue: CGFloat = FloatingTabBarMetrics.totalFixedHeight
}

extension EnvironmentValues {
    /// The bottom inset needed to clear the floating tab bar.
    /// Computed as: tab bar height (64) + bottom padding (8) + safe area bottom inset.
    var tabBarInset: CGFloat {
        get { self[TabBarInsetKey.self] }
        set { self[TabBarInsetKey.self] = newValue }
    }
}

// MARK: - Tab Bar Bottom Padding Modifier

/// View modifier that applies bottom padding to clear the floating tab bar.
/// Uses the environment-provided inset value for device-aware spacing.
struct TabBarBottomPaddingModifier: ViewModifier {
    @Environment(\.tabBarInset) private var tabBarInset

    func body(content: Content) -> some View {
        content
            .padding(.bottom, tabBarInset)
            #if DEBUG
            .onAppear {
                // Guardrail: warn once if using fallback value (suggests environment not injected)
                if tabBarInset == FloatingTabBarMetrics.totalFixedHeight {
                    print("[TabBar] Warning: tabBarInset using fallback (\(Int(tabBarInset))pt). Ensure .environment(\\.tabBarInset, ...) is set in parent.")
                }
            }
            #endif
    }
}

extension View {
    /// Applies bottom padding to clear the floating tab bar.
    /// Uses device-aware inset from the environment.
    func tabBarBottomPadding() -> some View {
        modifier(TabBarBottomPaddingModifier())
    }
}

// MARK: - Tab Bar Inset Provider

/// Wrapper view that computes and provides the tab bar inset to child views.
/// Place this at the root of your tab bar container.
struct TabBarInsetProvider<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let computedInset = FloatingTabBarMetrics.totalFixedHeight + safeAreaBottom

            content
                .environment(\.tabBarInset, computedInset)
        }
    }
}

// MARK: - Elegant Floating Tab Bar (4 tabs)

struct FloatingTabBar: View {
    @Binding var selectedTab: AppCoordinator.Tab
    @Namespace private var tabAnimation
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var themeProvider: ThemeProvider

    // Tab configuration
    struct TabItem: Identifiable {
        let id: AppCoordinator.Tab
        let icon: String
        let selectedIcon: String
        let label: String
        let gradient: [Color]
    }

    private let tabs: [TabItem] = [
        TabItem(id: .today, icon: "sun.max", selectedIcon: "sun.max.fill", label: "Today", gradient: [.orange, .yellow]),
        TabItem(id: .kids, icon: "figure.2.and.child.holdinghands", selectedIcon: "figure.2.and.child.holdinghands", label: "Kids", gradient: [.blue, .cyan]),
        TabItem(id: .rewards, icon: "gift", selectedIcon: "gift.fill", label: "Goals", gradient: [.purple, .pink]),
        TabItem(id: .insights, icon: "lightbulb", selectedIcon: "lightbulb.fill", label: "Insights", gradient: [.green, .mint])
    ]

    var body: some View {
        let resolved = themeProvider.resolved
        let isDark = resolved.isDark

        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                ElegantTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab.id,
                    namespace: tabAnimation,
                    isDark: isDark,
                    themeProvider: themeProvider
                ) {
                    if selectedTab != tab.id {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab.id
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(height: 64)
        .background(
            ZStack {
                // Solid background for dark mode, glass for light
                if isDark {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(resolved.cardBackground)
                } else {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                }

                // Gradient overlay for depth
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.8),
                                isDark ? Color.white.opacity(0.02) : Color.white.opacity(0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Elegant border
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                isDark ? resolved.cardBorderColor : Color.white.opacity(0.6),
                                isDark ? resolved.cardBorderColor.opacity(0.5) : Color.white.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: isDark ? 1 : 0.5
                    )
            }
            .shadow(color: .black.opacity(isDark ? 0.3 : 0.08), radius: isDark ? 12 : 16, y: 6)
            .shadow(color: .black.opacity(isDark ? 0.1 : 0.04), radius: 4, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, FloatingTabBarMetrics.bottomPadding)
    }
}

// MARK: - Elegant Tab Button

struct ElegantTabButton: View {
    let tab: FloatingTabBar.TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let isDark: Bool
    let themeProvider: ThemeProvider
    let action: () -> Void

    @State private var isPressed = false

    /// Returns a stable accessibility identifier for a tab
    private func accessibilityIdentifierForTab(_ tabId: AppCoordinator.Tab) -> String {
        switch tabId {
        case .today: return "today_tab"
        case .kids: return "kids_tab"
        case .rewards: return "rewards_tab"
        case .insights: return InsightsAccessibilityIdentifiers.insightsTab
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Selected pill background with matched geometry
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [tab.gradient[0].opacity(isDark ? 0.3 : 0.2), tab.gradient[1].opacity(isDark ? 0.25 : 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 28)
                            .matchedGeometryEffect(id: "tabPill", in: namespace)
                    }

                    // Icon
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(colors: tab.gradient, startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [isDark ? Color.white.opacity(0.5) : Color(.systemGray)], startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(isPressed ? 0.85 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                }
                .frame(height: 28)

                // Label
                Text(tab.label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? tab.gradient[0] : (isDark ? Color.white.opacity(0.5) : Color(.systemGray)))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.label) tab")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(tab.label)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier(accessibilityIdentifierForTab(tab.id))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        FloatingTabBar(selectedTab: .constant(.today))
    }
}
