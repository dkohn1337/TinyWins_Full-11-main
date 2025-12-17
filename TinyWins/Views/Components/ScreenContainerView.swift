import SwiftUI

/// Standardized container for main app screens with consistent safe area handling
/// Use this wrapper to ensure content doesn't get hidden behind tab bar or home indicator
struct ScreenContainerView<Content: View>: View {
    let content: Content

    /// Whether this screen is shown in the main tab bar (requires bottom padding for floating bar)
    var isTabBarScreen: Bool = true

    /// Whether this screen needs a scroll view (if false, content must handle its own scrolling)
    var needsScrollView: Bool = true

    init(
        isTabBarScreen: Bool = true,
        needsScrollView: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.isTabBarScreen = isTabBarScreen
        self.needsScrollView = needsScrollView
        self.content = content()
    }

    var body: some View {
        if needsScrollView {
            ScrollView {
                content
                    .padding()
                    .padding(.bottom, isTabBarScreen ? 80 : 0)
            }
        } else {
            content
                .padding(.bottom, isTabBarScreen ? 80 : 0)
        }
    }
}

/// Alternative: Use safe area insets for tab bar spacing (more robust approach)
extension View {
    /// Adds bottom padding to account for floating tab bar without covering content
    /// Use this on ScrollView or main content containers in tab bar screens
    func tabBarSafeArea() -> some View {
        self.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20) // Extra spacing beyond safe area
        }
    }
}

#Preview("With ScrollView") {
    ScreenContainerView(isTabBarScreen: true, needsScrollView: true) {
        VStack(spacing: 20) {
            ForEach(0..<20) { index in
                Text("Item \(index)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview("Without ScrollView") {
    ScreenContainerView(isTabBarScreen: true, needsScrollView: false) {
        VStack {
            Text("No scroll view")
            Spacer()
            Button("Bottom button") {}
                .padding()
        }
    }
}
