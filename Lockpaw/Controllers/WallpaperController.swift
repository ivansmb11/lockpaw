import AppKit
import ImageIO

/// What a screen's wallpaper background shows. Built once per screen at lock time;
/// the view only reads it.
enum WallpaperContent {
    case still(WallpaperStill)
    case clip(URL)
}

/// A still wallpaper, decoded and downsampled off the main thread. The lock screen
/// re-renders every second for its clock, so the decode can't live in a view body.
/// `image` stays nil until the decode lands (or for good, if the file won't decode),
/// and the overlay's black backdrop shows meanwhile.
@MainActor
final class WallpaperStill: ObservableObject {
    @Published private(set) var image: CGImage?

    init(url: URL, filling targetPixels: CGSize) {
        Task.detached(priority: .userInitiated) { [weak self] in
            let image = ImageDownsampling.image(at: url, filling: targetPixels)
            await MainActor.run { [weak self] in self?.image = image }
        }
    }
}

/// The desktop wallpaper for each overlay, for one lock session.
///
/// The store and the current Spaces are read once at `begin`, and each still is decoded
/// once per session at its screen's pixel size; screens showing the same file at the
/// same size share one decode. `end` drops the session's references — views that are
/// still fading out keep what they hold until the overlay windows let them go.
@MainActor
final class WallpaperController {
    private struct StillKey: Hashable {
        let url: URL
        let width: Int
        let height: Int
    }

    private var active = false
    private var reduceMotion = false
    private var indexPlist: Data?
    private var managedSpaces: [[String: Any]]?
    private var stills: [StillKey: WallpaperStill] = [:]

    func begin(reduceMotion: Bool) {
        end()
        active = true
        self.reduceMotion = reduceMotion
        indexPlist = try? Data(contentsOf: DesktopWallpaper.indexURL)
        managedSpaces = DisplaySpaces.managedDisplaySpaces()
    }

    /// The background for the overlay on `NSScreen.screens[index]` — the overlay
    /// manager's content factory runs once per screen, in that order, and again on a
    /// display change.
    func content(forScreenAt index: Int) -> WallpaperContent? {
        let screens = NSScreen.screens
        guard active, screens.indices.contains(index) else { return nil }
        let screen = screens[index]
        switch DesktopWallpaper.current(
            for: screen, indexPlist: indexPlist, managedSpaces: managedSpaces, reduceMotion: reduceMotion
        ) {
        case .video(let url):
            return .clip(url)
        case .image(let url):
            return .still(still(url, for: screen))
        case nil:
            return nil
        }
    }

    func end() {
        active = false
        indexPlist = nil
        managedSpaces = nil
        stills.removeAll()
    }

    private func still(_ url: URL, for screen: NSScreen) -> WallpaperStill {
        let pixels = CGSize(
            width: screen.frame.width * screen.backingScaleFactor,
            height: screen.frame.height * screen.backingScaleFactor
        )
        let key = StillKey(url: url, width: Int(pixels.width), height: Int(pixels.height))
        if let cached = stills[key] { return cached }
        let still = WallpaperStill(url: url, filling: pixels)
        stills[key] = still
        return still
    }

    /// Opens each screen's still once, off the main thread, when the setting is switched
    /// on. A wallpaper kept in Desktop, Documents or Downloads makes macOS ask for folder
    /// access the first time Lockpaw reads it, and behind a shield-level overlay that
    /// prompt would never be seen — so it comes up here, in front of Settings, instead.
    static func requestAccessToStills() {
        let urls = NSScreen.screens.compactMap { NSWorkspace.shared.desktopImageURL(for: $0) }
        Task.detached(priority: .utility) {
            for url in Set(urls) {
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { continue }
                _ = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            }
        }
    }
}
