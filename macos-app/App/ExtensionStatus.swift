import Foundation
import SafariServices

/// Must match PRODUCT_BUNDLE_IDENTIFIER of the extension target in project.yml.
let extensionBundleIdentifier = "com.neilsethia2.SafariArcade.Extension"

/// Asks Safari whether the Safari Arcade extension is switched on, and
/// opens Safari's Extensions settings on request.
final class ExtensionStatus: ObservableObject {
    enum State: Equatable {
        case checking
        case enabled
        case disabled
        /// Safari could not report on the extension. With an unsigned build
        /// this usually means "Allow unsigned extensions" is off in Safari.
        case unavailable(String)
    }

    @Published private(set) var state: State = .checking
    @Published private(set) var lastError: String?

    func refresh() {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { [weak self] state, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let state {
                    self.state = state.isEnabled ? .enabled : .disabled
                } else {
                    self.state = .unavailable(error?.localizedDescription ?? "Safari did not report a status.")
                }
            }
        }
    }

    func openSafariExtensionSettings() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { [weak self] error in
            DispatchQueue.main.async {
                self?.lastError = error?.localizedDescription
            }
        }
    }
}
