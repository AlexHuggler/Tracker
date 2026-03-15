import SwiftUI
import Observation

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: "isPremium") }
    }

    var isDimMode: Bool {
        didSet { UserDefaults.standard.set(isDimMode, forKey: "isDimMode") }
    }

    var showingQuickLog: Bool = false {
        didSet {
            // Clear pre-filled context when QuickLog is dismissed
            if !showingQuickLog {
                quickLogDate = nil
                quickLogMedicationIDs = []
            }
        }
    }
    var showingPaywall: Bool = false
    var selectedTab: AppTab = .dashboard

    // 2.1: Pre-filled context for QuickLogView
    var quickLogDate: Date?
    var quickLogMedicationIDs: Set<UUID> = []

    enum AppTab: Int, CaseIterable, Identifiable {
        case dashboard = 0
        case episodes = 1
        case patterns = 2
        case medications = 3
        case settings = 4

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .episodes: return "Episodes"
            case .patterns: return "Patterns"
            case .medications: return "Medications"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .episodes: return "list.bullet.clipboard"
            case .patterns: return "waveform.path.ecg"
            case .medications: return "pill.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        self.isDimMode = UserDefaults.standard.bool(forKey: "isDimMode")
    }

    // MARK: - Streak Tracking

    var currentStreak: Int {
        let lastDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date
        let streak = UserDefaults.standard.integer(forKey: "currentStreak")

        guard let lastDate else { return 0 }

        if Calendar.current.isDateInToday(lastDate) {
            return streak
        } else if Calendar.current.isDateInYesterday(lastDate) {
            return streak
        } else {
            return 0
        }
    }

    func recordActivity() {
        let lastDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date
        let streak = UserDefaults.standard.integer(forKey: "currentStreak")

        let newStreak: Int
        if let lastDate {
            if Calendar.current.isDateInToday(lastDate) {
                return // Already recorded today
            } else if Calendar.current.isDateInYesterday(lastDate) {
                newStreak = streak + 1
            } else {
                newStreak = 1
            }
        } else {
            newStreak = 1
        }

        UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
        UserDefaults.standard.set(newStreak, forKey: "currentStreak")
    }

    // MARK: - Premium Feature Gating

    static let freeHistoryDays: Int = 30
    static let freeMedicationLimit: Int = 2

    func requirePremium(for feature: String) -> Bool {
        if isPremium { return true }
        showingPaywall = true
        return false
    }
}
