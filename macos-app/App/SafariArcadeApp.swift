import SwiftUI

/// Safari Arcade, the Mac app.
///
/// The arcade itself is a web app (the React code in src/). This app opens
/// one window and shows that web app inside it, loaded from files that are
/// packaged in the app, so it works offline. Saved data is kept in a file
/// by the app (see ArcadeStorage.swift).
///
/// The app also carries the optional Safari extension. macOS only accepts
/// Safari extensions that are delivered inside an app.
@main
struct SafariArcadeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // `Window` (rather than `WindowGroup`) means there is exactly one
        // arcade window, with no "New Window" command.
        Window("Safari Arcade", id: "arcade") {
            ArcadeWebView()
                .frame(minWidth: 900, minHeight: 620)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1180, height: 780)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Safari Extension Settings…") {
                    SafariExtensionSettings.open()
                }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Closing the window quits the app, as people expect from a game.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
