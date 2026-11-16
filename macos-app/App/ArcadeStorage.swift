import Foundation
import WebKit

/// Saved data for the arcade: high scores, settings, favourites.
///
/// Everything is kept in one small file:
///
///     ~/Library/Application Support/Safari Arcade/storage.json
///
/// The file belongs to the user, not to the app, so replacing the app with
/// a newer version leaves it alone. Each entry is a name and a piece of
/// JSON text. The web app decides what the JSON means; this class only
/// stores and returns it.
final class ArcadeStorage {
    private let directory: URL
    private let fileURL: URL
    private var values: [String: String] = [:]

    /// Where saved data lives. The ARCADE_STORAGE_DIR environment variable
    /// overrides it, which the automated self-test uses so that it never
    /// touches real saved data.
    static func defaultDirectory() -> URL {
        if let override = ProcessInfo.processInfo.environment["ARCADE_STORAGE_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent("Safari Arcade", isDirectory: true)
    }

    init(directory: URL) {
        self.directory = directory
        self.fileURL = directory.appendingPathComponent("storage.json")
        load()
    }

    func get(_ key: String) -> String? {
        values[key]
    }

    func set(_ key: String, to json: String) throws {
        let previous = values[key]
        values[key] = json
        do {
            try save()
        } catch {
            // Keep memory and disk in agreement if the write failed.
            values[key] = previous
            throw error
        }
    }

    func remove(_ key: String) throws {
        guard let previous = values.removeValue(forKey: key) else { return }
        do {
            try save()
        } catch {
            values[key] = previous
            throw error
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            values = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            // Never delete data that cannot be read. Move it aside so it
            // can be inspected, and start with an empty store.
            let stamp = Int(Date().timeIntervalSince1970)
            let aside = directory.appendingPathComponent("storage.unreadable-\(stamp).json")
            try? FileManager.default.moveItem(at: fileURL, to: aside)
            NSLog("Safari Arcade: saved data could not be read (%@). It was moved to %@.", error.localizedDescription, aside.path)
        }
    }

    private func save() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // .atomic writes a complete new file and then swaps it in, so a
        // crash or power cut mid-save cannot leave a half-written file.
        try encoder.encode(values).write(to: fileURL, options: .atomic)
    }
}

/// Receives storage requests from the web page and answers them.
///
/// The page calls
/// `window.webkit.messageHandlers.arcadeStorage.postMessage({ op, key, value })`
/// (see src/services/native.ts) and gets a promise back. Each request gets
/// a pair in reply: a value, or an error message. An error message makes
/// the page's promise fail, so a save that did not work is reported to the
/// game rather than silently lost.
@MainActor
final class StorageBridge: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "arcadeStorage"

    private let storage: ArcadeStorage

    init(storage: ArcadeStorage) {
        self.storage = storage
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        guard
            let body = message.body as? [String: Any],
            let operation = body["op"] as? String,
            let key = body["key"] as? String
        else {
            return (nil, "Malformed storage request.")
        }

        do {
            switch operation {
            case "get":
                return (storage.get(key), nil)
            case "set":
                guard let value = body["value"] as? String else {
                    return (nil, "A storage 'set' request needs a text value.")
                }
                try storage.set(key, to: value)
                return (true, nil)
            case "remove":
                try storage.remove(key)
                return (true, nil)
            default:
                return (nil, "Unknown storage operation '\(operation)'.")
            }
        } catch {
            return (nil, "Saving failed: \(error.localizedDescription)")
        }
    }
}
