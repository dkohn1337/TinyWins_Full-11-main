import UIKit

// MARK: - Haptic Service

/// Provides haptic feedback throughout the app.
/// Use dependency injection via DependencyContainer for new code.
struct HapticService {
    /// Shared singleton instance for backward compatibility.
    /// New code should use dependency injection via DependencyContainer.
    static let shared = HapticService()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let successGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    /// Creates a new HapticService instance.
    init() {}

    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        successGenerator.prepare()
        selectionGenerator.prepare()
    }

    func light() {
        lightGenerator.impactOccurred()
    }

    func medium() {
        mediumGenerator.impactOccurred()
    }

    func heavy() {
        heavyGenerator.impactOccurred()
    }

    func success() {
        successGenerator.notificationOccurred(.success)
    }

    func warning() {
        successGenerator.notificationOccurred(.warning)
    }

    func error() {
        successGenerator.notificationOccurred(.error)
    }

    func selection() {
        selectionGenerator.selectionChanged()
    }
}

// MARK: - Type Alias for Backward Compatibility

/// Type alias to maintain compatibility with existing code using HapticManager
typealias HapticManager = HapticService
