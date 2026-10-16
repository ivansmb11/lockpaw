import SwiftUI

/// The agents waiting on the user, urgent first — the standing companion to the glow
/// pulses, shown until unlock. Capped so a busy afternoon cannot push the unlock
/// prompt off a small screen.
struct AgentPingList: View {
    let queue: AgentPingQueue
    let breathe: CGFloat

    static let maxRows = 4

    var body: some View {
        VStack(spacing: 6) {
            ForEach(queue.rows.prefix(Self.maxRows)) { ping in
                row(ping)
            }
            if queue.pings.count > Self.maxRows {
                Text("and \(queue.pings.count - Self.maxRows) more")
                    .font(.lockCaption)
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(0.5)
            }
        }
        .allowsHitTesting(false)
    }

    private func row(_ ping: AgentPing) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ping.kind.status.dotColor)
                .frame(width: 5, height: 5)
                .opacity(0.55 + breathe * 0.3)
            Text(ping.summary())
                .font(.lockCaption)
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.5)
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(Constants.formatWaitTime(context.date.timeIntervalSince(ping.receivedAt)))
                    .font(.lockMono)
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(0.5)
            }
        }
        .lineLimit(1)
    }
}

extension AgentPingStatus {
    /// The row's marker: teal done, amber waiting, red for an error — the one place red
    /// appears for an agent, since the glow itself stays amber.
    var dotColor: Color {
        switch self {
        case .done, .attention: return Color("LockpawTeal")
        case .waiting: return Color("LockpawAmber")
        case .error: return Color("LockpawError")
        }
    }
}

extension AgentGlowTone {
    var color: Color {
        switch self {
        case .teal: return Color("LockpawTeal")
        case .amber: return Color("LockpawAmber")
        }
    }
}

extension AgentPingQueue {
    /// The glow takes the colour of the most urgent outstanding ping.
    var glowColor: Color { glowTone.color }
}
