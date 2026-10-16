import AVFoundation
import SwiftUI

/// The desktop wallpaper behind the lock UI — a muted, looping Aerial clip or a still,
/// dimmed so the mascot, message and timer stay legible.
struct WallpaperBackgroundView: View {
    let content: WallpaperContent

    var body: some View {
        ZStack {
            switch content {
            case .clip(let url):
                LoopingVideoView(url: url)
            case .still(let still):
                StillWallpaperView(still: still)
            }

            Color.black.opacity(0.35)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Draws the already-decoded still; nothing until the decode lands, then fades it in
/// over the overlay's black backdrop (explicit opacity — see OverlayRootView).
private struct StillWallpaperView: View {
    @ObservedObject var still: WallpaperStill

    var body: some View {
        Color.clear
            .overlay {
                if let image = still.image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .opacity(still.image == nil ? 0 : 1)
            .animation(Constants.Anim.entrance, value: still.image == nil)
    }
}

// ponytail: one decoder per screen; share a single player across displays if multi-4K playback shows up in energy use.
private struct LoopingVideoView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PlayerView {
        PlayerView(url: url)
    }

    func updateNSView(_ nsView: PlayerView, context: Context) {}

    final class PlayerView: NSView {
        private let player = AVQueuePlayer()
        private let looper: AVPlayerLooper

        init(url: URL) {
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            super.init(frame: .zero)
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            self.layer = layer
            wantsLayer = true
            player.isMuted = true
            // Keep the display awake decisions with SleepPreventer, not the player.
            player.preventsDisplaySleepDuringVideoPlayback = false
            player.play()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window == nil { player.pause() } else { player.play() }
        }
    }
}
