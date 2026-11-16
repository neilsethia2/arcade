import SwiftUI

/// The container app.
///
/// On macOS a Safari extension cannot be installed on its own. It has to be
/// delivered inside a normal app, and Safari discovers the extension when
/// that app is in the Applications folder and has been opened once. So this
/// app's whole purpose is to carry the extension and to guide the user
/// through switching it on. The games do not run here; they run in Safari.
@main
struct SafariArcadeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            // A single-window helper app has no use for File > New Window.
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
