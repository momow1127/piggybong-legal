import SwiftUI

// MARK: - Tab Selection Manager
class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 0

    // Tab indices
    static let home = 0
    static let events = 1
    static let profile = 2

    // Convenience methods for navigation
    func switchToHome() {
        selectedTab = Self.home
    }

    func switchToEvents() {
        selectedTab = Self.events
        HapticManager.light()
    }

    func switchToProfile() {
        selectedTab = Self.profile
    }
}