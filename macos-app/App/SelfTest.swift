import AppKit
import WebKit

/// An automated check that the built app really works.
///
/// GitHub's Mac build machine starts the app with the environment variable
/// ARCADE_SELF_TEST_OUTPUT set to a file path. In that mode the app loads
/// the arcade as usual, waits for the web page to report on itself, writes
/// what it found to that file as JSON, and quits. scripts/self-test.sh runs
/// this twice and checks that the saved launch counter went from 1 to 2,
/// which proves that data survives quitting the app.
///
/// When the variable is not set, which is always the case in normal use,
/// none of this runs.
@MainActor
final class SelfTest {
    private static let environment = ProcessInfo.processInfo.environment

    static var isRequested: Bool {
        !(environment["ARCADE_SELF_TEST_OUTPUT"] ?? "").isEmpty
    }

    /// Runs before the page's own scripts and records anything that goes
    /// wrong: script errors, files that fail to load, rejected promises.
    static let errorCaptureScript = """
    window.__arcadeErrors = [];
    window.addEventListener('error', function (event) {
      var target = event.target || {};
      var where = event.filename || target.src || target.href || '';
      window.__arcadeErrors.push(String(event.message || 'failed to load') + (where ? ' @ ' + where : ''));
    }, true);
    window.addEventListener('unhandledrejection', function (event) {
      window.__arcadeErrors.push('unhandled rejection: ' + String(event.reason));
    });
    """

    /// Asks the page for its diagnostics report (src/services/diagnostics.ts).
    private static let probeScript = """
    (function () {
      var report = window.__arcadeDiagnostics || {};
      var root = document.getElementById('root');
      return JSON.stringify({
        ready: report.ready === true,
        environment: report.environment || null,
        storage: report.storage || null,
        launchCount: typeof report.launchCount === 'number' ? report.launchCount : null,
        saveError: report.error || null,
        rendered: !!root && root.childElementCount > 0,
        errors: window.__arcadeErrors || [],
        url: location.href,
        userAgent: navigator.userAgent
      });
    })()
    """

    private struct Probe: Codable {
        var ready: Bool
        var environment: String?
        var storage: String?
        var launchCount: Int?
        var saveError: String?
        var rendered: Bool
        var errors: [String]
        var url: String
        var userAgent: String
    }

    private struct Report: Codable {
        var ok: Bool
        var failure: String?
        var probe: Probe?
    }

    private static let timeout: TimeInterval = 30

    private let started = Date()
    private var lastProbe: Probe?
    private var finished = false
    private var running = false

    /// Fails the test if nothing conclusive has happened in time, so a hung
    /// app can never stall the build.
    func startWatchdog() {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(Self.timeout * 1_000_000_000))
            fail("Timed out after \(Int(Self.timeout)) seconds waiting for the page to report.")
        }
    }

    func pageDidLoad(in webView: WKWebView) {
        guard !running else { return }
        running = true
        Task {
            await run(in: webView)
        }
    }

    private func run(in webView: WKWebView) async {
        while !finished {
            if let probe = await probe(webView) {
                lastProbe = probe
                if probe.ready && probe.rendered {
                    await conclude(probe, in: webView)
                    return
                }
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    private func probe(_ webView: WKWebView) async -> Probe? {
        let text: String? = await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(Self.probeScript) { value, _ in
                continuation.resume(returning: value as? String)
            }
        }
        guard let data = text?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Probe.self, from: data)
    }

    private func conclude(_ probe: Probe, in webView: WKWebView) async {
        var problems: [String] = []
        if let saveError = probe.saveError {
            problems.append("Saving failed: \(saveError)")
        }
        if probe.launchCount == nil {
            problems.append("No launch count was read back from storage.")
        }
        if !probe.errors.isEmpty {
            problems.append("Page errors: \(probe.errors.joined(separator: "; "))")
        }

        // Leave a moment for the page to finish drawing before the picture.
        try? await Task.sleep(nanoseconds: 600_000_000)
        await saveSnapshot(of: webView)

        finish(ok: problems.isEmpty, failure: problems.isEmpty ? nil : problems.joined(separator: " "))
    }

    /// Saves a picture of the window's contents, so a person can look at
    /// what the app actually drew on the build machine.
    private func saveSnapshot(of webView: WKWebView) async {
        guard let path = Self.environment["ARCADE_SELF_TEST_SNAPSHOT"], !path.isEmpty else { return }

        let png: Data? = await withCheckedContinuation { continuation in
            webView.takeSnapshot(with: nil) { image, _ in
                guard
                    let image,
                    let tiff = image.tiffRepresentation,
                    let bitmap = NSBitmapImageRep(data: tiff)
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: bitmap.representation(using: .png, properties: [:]))
            }
        }

        guard let png else {
            NSLog("Safari Arcade self-test: no snapshot was produced.")
            return
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
        } catch {
            NSLog("Safari Arcade self-test: could not write the snapshot: %@", error.localizedDescription)
        }
    }

    func fail(_ reason: String) {
        finish(ok: false, failure: reason)
    }

    private func finish(ok: Bool, failure: String?) {
        guard !finished else { return }
        finished = true

        let report = Report(ok: ok, failure: failure, probe: lastProbe)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let path = Self.environment["ARCADE_SELF_TEST_OUTPUT"], let data = try? encoder.encode(report) {
            do {
                try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            } catch {
                NSLog("Safari Arcade self-test: could not write the result: %@", error.localizedDescription)
            }
        }

        let seconds = String(format: "%.1f", Date().timeIntervalSince(started))
        print("Safari Arcade self-test \(ok ? "passed" : "FAILED") after \(seconds)s\(failure.map { ": \($0)" } ?? "")")
        exit(ok ? 0 : 1)
    }
}
