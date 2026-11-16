import Foundation
import WebKit

/// Serves the packaged web app to the web view.
///
/// The web files sit in the app bundle under Contents/Resources/web/. The
/// page asks for them at addresses like arcade://app/assets/index.js and
/// this class answers each request with the matching file. Nothing goes
/// over the network, which is why the arcade works offline.
///
/// Loading the files directly with file:// addresses would be simpler, but
/// WebKit refuses to run modern JavaScript modules from file:// pages.
@MainActor
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "arcade"

    private let root: URL

    init(root: URL) {
        self.root = root.standardizedFileURL
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        var path = url.path
        if path.isEmpty || path == "/" {
            path = "/index.html"
        }

        let fileURL = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL

        // Refuse anything that would reach outside the web folder, such as
        // a path containing "../".
        guard fileURL.path.hasPrefix(root.path + "/") else {
            urlSchemeTask.didFailWithError(URLError(.noPermissionsToReadFile))
            return
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            NSLog("Safari Arcade: missing web file %@", fileURL.path)
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let headers = [
            "Content-Type": Self.mimeType(forExtension: fileURL.pathExtension),
            "Content-Length": String(data.count),
            "Cache-Control": "no-store",
        ]
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) else {
            urlSchemeTask.didFailWithError(URLError(.unknown))
            return
        }

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Every request is answered immediately in `start`, so there is
        // never anything in progress to cancel.
    }

    /// The browser engine decides how to treat a file from its type, so
    /// each kind of file the arcade ships needs the right label.
    static func mimeType(forExtension pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "js", "mjs": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json", "map": return "application/json; charset=utf-8"
        case "txt": return "text/plain; charset=utf-8"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "webp": return "image/webp"
        case "gif": return "image/gif"
        case "ico": return "image/x-icon"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "mp3": return "audio/mpeg"
        case "m4a": return "audio/mp4"
        case "ogg": return "audio/ogg"
        case "wav": return "audio/wav"
        case "wasm": return "application/wasm"
        case "glb": return "model/gltf-binary"
        case "gltf": return "model/gltf+json"
        default: return "application/octet-stream"
        }
    }
}
