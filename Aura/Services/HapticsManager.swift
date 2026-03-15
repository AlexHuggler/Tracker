import SwiftUI
import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }

    func sliderTick() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    // 3.6: Graduated haptic intensity based on pain level
    func painLevelTick(level: Int) {
        switch level {
        case 0...3:
            impactLight.impactOccurred()
            impactLight.prepare()
        case 4...6:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case 7...9:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        case 10:
            impactHeavy.impactOccurred(intensity: 1.0)
            notification.notificationOccurred(.warning)
            impactHeavy.prepare()
            notification.prepare()
        default:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        }
    }

    func saveSuccess() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    func lightTap() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    func heavyTap() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
}
