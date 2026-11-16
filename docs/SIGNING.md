# Signing, Gatekeeper and Safari

This page explains the one extra step when installing Safari Arcade, why the arcade runs as an app rather than only as a Safari extension, and what a paid Apple developer membership would change.

## What the builds are today

The DMG built by GitHub Actions is **ad-hoc signed**. That means the app carries a signature that proves its files have not been altered since the build, but the signature is not tied to any Apple developer identity. No Apple account, certificate or password is involved, and nothing secret is stored in this repository or in GitHub.

## Gatekeeper (opening the app)

Gatekeeper checks apps downloaded from the internet. An app that is not signed with an Apple Developer ID and notarised by Apple is blocked the first time you open it.

To open it anyway, go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the message about Safari Arcade. You do this once per downloaded copy, so once after first installing and once after each update. The Terminal command in the README does the same thing by removing the "downloaded from the internet" mark from the app.

After that the app opens normally every time. This is the only extra step the app needs.

An app you build yourself in Xcode was never downloaded, so Gatekeeper does not block it at all.

## Why the arcade is not Safari-only

Version 0.1.0 ran only as a Safari extension. It was installed and tested on a real Mac on 16 November 2026, and two things happened:

1. **Safari had to be told to allow it again after every restart.** Safari ignores extensions that are not signed with an Apple development certificate unless **Settings > Developer > Allow unsigned extensions** is on, and Apple's documentation states that this setting resets when Safari quits.
2. **Saved data did not survive quitting Safari.** The launch counter kept in the extension's storage went back to 1 after Safari was reopened. The likely reason is that Safari drops an unsigned extension, together with its storage, when it quits. That explanation fits what was seen but has not been confirmed from Apple's documentation.

Either one alone would make a games app annoying. Together they mean an unsigned Safari extension cannot keep high scores. So from version 0.2.0 the arcade runs in the Safari Arcade app, in its own window, and saved data goes to a file the app controls. The extension is still included for anyone who wants the toolbar button, with those two drawbacks.

## Would building it in Xcode on your own Mac fix the Safari problems?

No, not with a free Apple ID. Apple's documentation says that if you are not a member of the Apple Developer Program, the extension does not show in Safari unless unsigned extensions are allowed. Building in Xcode with a free "Personal Team" does not count as program membership. Some third-party guides claim otherwise, but they disagree with Apple's documentation and with what was observed on this project's test Mac.

Building in Xcode is still useful for one thing: an app built on your own Mac skips the Gatekeeper step.

## What a paid membership would change

An **Apple Developer Program** membership is a paid yearly subscription from Apple (check [developer.apple.com/programs](https://developer.apple.com/programs/) for the current price).

With a membership the app can be signed with a **Developer ID** certificate and **notarised**, which means Apple scans the build and issues a ticket confirming it. A notarised build opens without the Gatekeeper warning. Apple's documentation also lists this as a supported way to distribute a Safari web extension outside the Mac App Store, and an Apple reply on its developer forum says support for it arrived in Safari 18.4. With that, the Safari extension would no longer need "Allow unsigned extensions".

For an app used on one Mac, the membership is not needed. The app route already works without it.

## How signing would be added to this project

Nothing below is set up. It is recorded here so the path is clear.

1. Join the Apple Developer Program and create a **Developer ID Application** certificate.
2. Export the certificate as a `.p12` file with a password.
3. Add these as **GitHub Secrets** in the repository settings (never as files in the repository): the certificate (base64 text), its password, the Apple team ID, and an app-specific password or API key for notarisation.
4. Extend the workflow to import the certificate into a temporary keychain, build with the Developer ID identity, submit the DMG with `notarytool`, and staple the ticket.

The `.gitignore` already blocks certificate and key files from being committed by accident.

Sources:

- [Running your Safari web extension](https://developer.apple.com/documentation/safariservices/running-your-safari-web-extension) (Apple)
- [Distributing your Safari web extension](https://developer.apple.com/documentation/safariservices/distributing-your-safari-web-extension) (Apple)
- [Building a Safari app extension](https://developer.apple.com/documentation/safariservices/building-a-safari-app-extension) (Apple), which states that the unsigned extensions setting resets when Safari quits
- [Developer forum thread on Developer ID-signed extensions](https://developer.apple.com/forums/thread/782005) (Apple), which gives Safari 18.4 as the version that added support
