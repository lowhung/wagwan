import UIKit

@MainActor
final class HapticService {
    static let shared = HapticService()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm the generators
        impactLight.prepare()
        impactMedium.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Impact Feedback

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred(intensity: 0.5)
        case .rigid:
            impactHeavy.impactOccurred(intensity: 0.8)
        @unknown default:
            impactMedium.impactOccurred()
        }
    }

    // MARK: - Notification Feedback

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Custom Patterns

    func buttonTap() {
        impactLight.impactOccurred(intensity: 0.7)
    }

    func cardTap() {
        impactMedium.impactOccurred(intensity: 0.5)
    }

    func celebrate() {
        // A fun pattern for achievements
        Task { @MainActor in
            notificationGenerator.notificationOccurred(.success)
            try? await Task.sleep(nanoseconds: 100_000_000)
            impactMedium.impactOccurred()
            try? await Task.sleep(nanoseconds: 100_000_000)
            impactLight.impactOccurred()
        }
    }
}
