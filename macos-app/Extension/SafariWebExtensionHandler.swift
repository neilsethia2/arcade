import Foundation
import SafariServices
import os.log

/// The native half of the Safari Web Extension.
///
/// Safari requires every web extension to ship with a small native handler
/// like this one. The arcade itself runs entirely in the web extension
/// (HTML, CSS and JavaScript), so this class has nothing to do yet. It
/// simply acknowledges any message the web side sends, which keeps the door
/// open for native features later without changing the project structure.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let log = OSLog(subsystem: "com.neilsethia2.SafariArcade.Extension", category: "native-messaging")

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey]
        os_log("Received message from the web extension: %{public}@", log: log, type: .default, String(describing: message))

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["received": true]]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
