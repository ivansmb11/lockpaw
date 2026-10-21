import AppKit
import Sparkle

/// Sparkle's state for the Updates row in Settings → About. Only a check the user started
/// reports back; background checks stay silent.

final class UpdateCheckViewModel: NSObject, ObservableObject, SPUUpdaterDelegate {
    @Published var canCheckForUpdates = false
    @Published var isChecking = false
    @Published var updateStatus: UpdateStatus?

    enum UpdateStatus {
        case upToDate
        case available(String)
        case error(String)
    }

    weak var updater: SPUUpdater?
    private var userInitiated = false

    func bind(to updater: SPUUpdater) {
        self.updater = updater
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        guard let updater else { return }
        NSApp.activate(ignoringOtherApps: true)
        userInitiated = true
        isChecking = true
        updateStatus = nil
        updater.checkForUpdates()
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        guard userInitiated else { return }
        userInitiated = false
        isChecking = false
        updateStatus = .available(item.displayVersionString)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        guard userInitiated else { return }
        userInitiated = false
        isChecking = false
        updateStatus = .upToDate
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        guard userInitiated else { return }
        userInitiated = false
        isChecking = false
        updateStatus = .error(error.localizedDescription)
    }
}
