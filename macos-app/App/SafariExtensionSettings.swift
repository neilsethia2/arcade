import AppKit
import SafariServices

/// Opens Safari's settings at the Safari Arcade extension.
///
/// The extension is optional. It adds a toolbar button to Safari that opens
/// the arcade in a tab. See docs/SIGNING.md for why it is awkward to use
/// without a paid Apple developer membership.
enum SafariExtensionSettings {
    /// Must match PRODUCT_BUNDLE_IDENTIFIER of the extension target in project.yml.
    static let extensionBundleIdentifier = "com.neilsethia2.SafariArcade.Extension"

    static func open() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            guard let error else { return }
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Safari could not show the extension"
                alert.informativeText = "\(error.localizedDescription)\n\nIn Safari, open Settings, choose Developer and tick \"Allow unsigned extensions\", then try again."
                alert.runModal()
            }
        }
    }
}
