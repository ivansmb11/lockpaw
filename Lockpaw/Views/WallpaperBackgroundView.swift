import AVFoundation
import SwiftUI

/// The desktop wallpaper behind the lock UI — an Aerial clip (playing or frozen, see
/// `WallpaperPlaybackPolicy`) or a still, dimmed so the mascot, message and timer stay
/// legible.
struct WallpaperBackgroundView: View {
    let content: WallpaperContent

    var body: some View {
        ZStack {
            switch content {
            case .clip(let clip):
                ClipLayerView(clip: clip)
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

/// This screen's layer on the shared clip player. The player itself belongs to
/// `WallpaperClip`; the layer only tells it when it is in a window, so a fade to black
/// (which unmounts the lock UI) leaves no layer and the player pauses.
private struct ClipLayerView: NSViewRepresentable {
    let clip: WallpaperClip

    func makeNSView(context: Context) -> PlayerLayerView {
        PlayerLayerView(clip: clip)
    }

    func updateNSView(_ nsView: PlayerLayerView, context: Context) {}

    static func dismantleNSView(_ nsView: PlayerLayerView, coordinator: ()) {
        nsView.detach()
    }

    final class PlayerLayerView: NSView {
        private let clip: WallpaperClip
        private let playerLayer: AVPlayerLayer
        private var counted = false
        private var readyObservation: NSKeyValueObservation?

        init(clip: WallpaperClip) {
            self.clip = clip
            playerLayer = AVPlayerLayer(player: clip.player)
            super.init(frame: .zero)
            playerLayer.videoGravity = .resizeAspectFill
            // Fade the first frame in rather than popping from black once it decodes.
            playerLayer.opacity = 0
            layer = playerLayer
            wantsLayer = true
            readyObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { layer, _ in
                guard layer.isReadyForDisplay else { return }
                DispatchQueue.main.async {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.8)
                    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1))
                    layer.opacity = 1
                    CATransaction.commit()
                }
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil, !counted {
                counted = true
                clip.layerAppeared()
            } else if window == nil {
                detach()
            }
        }

        func detach() {
            guard counted else { return }
            counted = false
            clip.layerDisappeared()
        }
    }
}
