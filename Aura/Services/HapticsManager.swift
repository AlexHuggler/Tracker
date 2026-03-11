import SwiftUI
import UIKit

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
