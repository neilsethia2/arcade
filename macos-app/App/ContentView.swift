import SwiftUI

struct ContentView: View {
    @StateObject private var status = ExtensionStatus()

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("Safari Arcade")
                    .font(.system(size: 26, weight: .bold))
                Text("Your personal gaming corner.")
                    .foregroundStyle(.secondary)
            }

            statusBadge

            Text(instructions)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Open Safari Extension Settings") {
                    status.openSafariExtensionSettings()
                }
                .keyboardShortcut(.defaultAction)

                Button("Check Again") {
                    status.refresh()
                }
            }

            if let error = status.lastError {
                Text("Safari could not open its settings: \(error)")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Version \(version)")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 460)
        .onAppear { status.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // The user usually comes back here after changing a Safari setting.
            status.refresh()
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
            Text(statusText)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.primary.opacity(0.07)))
    }

    private var statusColor: Color {
        switch status.state {
        case .enabled: return .green
        case .disabled: return .orange
        case .unavailable: return .red
        case .checking: return .gray
        }
    }

    private var statusText: String {
        switch status.state {
        case .enabled: return "The extension is on"
        case .disabled: return "The extension is off"
        case .unavailable: return "Safari cannot see the extension yet"
        case .checking: return "Checking Safari…"
        }
    }

    private var instructions: String {
        switch status.state {
        case .enabled:
            return "Click the Safari Arcade icon in Safari's toolbar to start playing. You can close this window."
        case .disabled:
            return "Open Safari's Extensions settings and tick the box next to Safari Arcade."
        case .unavailable(let reason):
            return "This build is not signed with an Apple developer certificate, so Safari hides it until you allow unsigned extensions. In Safari choose Settings, open the Advanced tab and tick \"Show features for web developers\". Then open the Developer tab and tick \"Allow unsigned extensions\". Come back here and press Check Again.\n\nDetails from Safari: \(reason)"
        case .checking:
            return "Asking Safari whether the extension is switched on."
        }
    }
}
