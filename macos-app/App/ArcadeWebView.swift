import SwiftUI
import WebKit

/// Puts the web view that runs the arcade into the SwiftUI window.
struct ArcadeWebView: NSViewRepresentable {
    func makeCoordinator() -> ArcadeController {
        ArcadeController()
    }

    func makeNSView(context: Context) -> WKWebView {
        context.coordinator.makeWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}
}

/// Creates the web view, connects it to the packaged web files and to
/// saved data, and reacts to page loads and failures.
@MainActor
final class ArcadeController: NSObject, WKNavigationDelegate {
    /// "arcade://app/" is a private address that only exists inside this
    /// app. BundleSchemeHandler answers it with files from the app bundle.
    static let startURL = URL(string: "\(BundleSchemeHandler.scheme)://app/index.html")!

    /// Matches --color-bg in src/styles/tokens.css, so the window does not
    /// flash white before the page appears.
    private static let backgroundColor = NSColor(srgbRed: 0.071, green: 0.075, blue: 0.090, alpha: 1)

    private var selfTest: SelfTest?
    private var reloadsAfterCrash = 0

    func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()

        let webRoot = (Bundle.main.resourceURL ?? Bundle.main.bundleURL)
            .appendingPathComponent("web", isDirectory: true)
        configuration.setURLSchemeHandler(
            BundleSchemeHandler(root: webRoot),
            forURLScheme: BundleSchemeHandler.scheme
        )

        let storage = ArcadeStorage(directory: ArcadeStorage.defaultDirectory())
        configuration.userContentController.addScriptMessageHandler(
            StorageBridge(storage: storage),
            contentWorld: .page,
            name: StorageBridge.name
        )

        // Games play sound effects without waiting for a click first.
        configuration.mediaTypesRequiringUserActionForPlayback = []

        if SelfTest.isRequested {
            configuration.userContentController.addUserScript(
                WKUserScript(
                    source: SelfTest.errorCaptureScript,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )
            )
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.underPageBackgroundColor = Self.backgroundColor
        if #available(macOS 13.3, *) {
            // Lets Safari's Develop menu attach its Web Inspector to this
            // window, which is the way to debug a game on a real Mac.
            webView.isInspectable = true
        }

        if SelfTest.isRequested {
            let test = SelfTest()
            test.startWatchdog()
            selfTest = test
        }

        webView.load(URLRequest(url: Self.startURL))
        return webView
    }

    // MARK: - WKNavigationDelegate

    /// Only the arcade's own pages load inside the window. Ordinary web
    /// links open in the default browser, and anything else is refused.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            return .cancel
        }
        switch scheme {
        case BundleSchemeHandler.scheme, "about":
            return .allow
        case "http", "https", "mailto":
            NSWorkspace.shared.open(url)
            return .cancel
        default:
            return .cancel
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Give the page keyboard focus so arrow keys reach the games
        // without the player having to click first.
        webView.window?.makeFirstResponder(webView)
        selfTest?.pageDidLoad(in: webView)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        report(error, in: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        report(error, in: webView)
    }

    /// The process that draws the page can be stopped by the system, for
    /// example under memory pressure. Reload, but not in an endless loop.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        reloadsAfterCrash += 1
        if reloadsAfterCrash <= 3 {
            webView.load(URLRequest(url: Self.startURL))
        } else {
            show(message: "The arcade stopped unexpectedly several times. Quit Safari Arcade and open it again.", in: webView)
        }
    }

    // MARK: - Errors

    private func report(_ error: Error, in webView: WKWebView) {
        let nsError = error as NSError
        // -999 means a load was cancelled on purpose (see the policy above).
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }

        NSLog("Safari Arcade: page failed to load: %@", nsError.localizedDescription)
        if let selfTest {
            selfTest.fail("The page failed to load: \(nsError.localizedDescription)")
            return
        }
        show(message: "The arcade could not be loaded (\(nsError.localizedDescription)). Reinstalling Safari Arcade from the DMG should fix this.", in: webView)
    }

    private func show(message: String, in webView: WKWebView) {
        let escaped = message
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let html = """
        <!doctype html><html><head><meta charset="utf-8"><style>
        body { margin: 0; height: 100vh; display: flex; align-items: center; justify-content: center;
               background: #121317; color: #f5f6f8; font: 15px -apple-system, sans-serif; }
        p { max-width: 420px; text-align: center; line-height: 1.5; color: #9aa0ad; }
        </style></head><body><p>\(escaped)</p></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
