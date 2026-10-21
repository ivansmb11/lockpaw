import SwiftUI

/// The four Settings panes, grouped by what the user is trying to do rather than by how
/// the app is built: the shortcut, unlocking and permissions live in General; everything
/// that changes what the cover looks like lives in Lock Screen.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case lockScreen
    case agents
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: return "General"
        case .lockScreen: return "Lock Screen"
        case .agents: return "Agents"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .lockScreen: return "lock.display"
        case .agents: return "terminal"
        case .about: return "info.circle"
        }
    }

    /// Every pane is the same size, so the window stays put when switching tabs and only
    /// the content changes. A pane taller than this scrolls, like System Settings.
    var height: CGFloat { 640 }

    static let width: CGFloat = 600
}

/// Opens Settings on a given pane from anywhere (the supporter card, a Debug URL).
@MainActor
enum SettingsRequest {
    static func open(_ section: SettingsSection) {
        SettingsWindowController.shared.show(section)
    }
}

/// Text and controls in Settings: the deeper control teal, readable on light and dark and
/// under white text. Brand teal (`LockpawTeal`) is for glows, not for words.
let settingsAccentColor = Color("LockpawAccent")

extension View {
    /// The shared frame of a Settings pane: System Settings-style grouped form, Lockpaw teal.
    func settingsPane(_ section: SettingsSection) -> some View {
        self
            .formStyle(.grouped)
            .toggleStyle(.switch)
            .frame(width: SettingsSection.width, height: section.height)
    }
}

/// A two-line label for a form row: the setting, then one line on what it does when on.
struct SettingLabel: View {
    let title: String
    let detail: String?

    init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let detail {
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
