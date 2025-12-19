import SwiftUI

#if DEBUG
// MARK: - Screen Tracking Modifier

/// Tracks when a screen appears for stall attribution.
/// Use on the root view of each screen/tab.
struct TrackScreen: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                FrameStallMonitor.shared.setScreen(name)
            }
    }
}

extension View {
    /// Marks this view as a screen root for stall attribution.
    /// Call on the outermost view of each tab or navigation destination.
    ///
    /// Example:
    /// ```swift
    /// var body: some View {
    ///     ScrollView { ... }
    ///         .trackScreen("InsightsHome")
    /// }
    /// ```
    func trackScreen(_ name: String) -> some View {
        modifier(TrackScreen(name: name))
    }
}

// MARK: - Action Name Environment Key

private struct FrameStallActionNameKey: EnvironmentKey {
    static let defaultValue: String = "button_tap"
}

extension EnvironmentValues {
    /// The action name to use for stall attribution when a button is tapped.
    var frameStallActionName: String {
        get { self[FrameStallActionNameKey.self] }
        set { self[FrameStallActionNameKey.self] = newValue }
    }
}

extension View {
    /// Sets the action name for stall attribution on descendant buttons.
    ///
    /// Example:
    /// ```swift
    /// Button("Save") { vm.save() }
    ///     .stallActionName("save_button")
    /// ```
    func stallActionName(_ name: String) -> some View {
        environment(\.frameStallActionName, name)
    }
}

// MARK: - Tracking Button Style

/// A primitive button style that intercepts taps to log them for stall attribution.
/// Apply this at the app root to automatically track all Button taps.
struct TrackingPrimitiveButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TrackingButton(configuration: configuration)
    }

    private struct TrackingButton: View {
        let configuration: PrimitiveButtonStyle.Configuration
        @Environment(\.frameStallActionName) private var actionName

        var body: some View {
            configuration.label
                .contentShape(Rectangle())
                .onTapGesture {
                    FrameStallMonitor.shared.markAction(actionName)
                    configuration.trigger()
                }
        }
    }
}

// MARK: - Tap Tracking Helper

extension View {
    /// Tracks a non-button tap gesture for stall attribution.
    /// Use for tappable rows, cards, or other custom tap handlers.
    ///
    /// Example:
    /// ```swift
    /// RowView()
    ///     .trackTap("row_tap_\(item.id)")
    ///     .onTapGesture { selectItem(item) }
    /// ```
    func trackTap(_ name: String, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            FrameStallMonitor.shared.markAction(name)
            action()
        }
    }
}

#else
// MARK: - No-op implementations for Release builds

extension View {
    func trackScreen(_ name: String) -> some View { self }
    func stallActionName(_ name: String) -> some View { self }
    func trackTap(_ name: String, action: @escaping () -> Void) -> some View {
        self.onTapGesture(perform: action)
    }
}
#endif
