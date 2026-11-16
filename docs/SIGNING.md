# Signing, Gatekeeper and Safari

This page explains why installing Safari Arcade takes a few extra steps, and what would remove them.

## What the builds are today

The DMG built by GitHub Actions is **ad-hoc signed**. That means the app carries a signature that proves its files have not been altered since the build, but the signature is not tied to any Apple developer identity. No Apple account, certificate or password is involved, and nothing secret is stored in this repository or in GitHub.

Two parts of macOS react to that.

## Gatekeeper (opening the app)

Gatekeeper checks apps downloaded from the internet. An app that is not signed with an Apple Developer ID and notarised by Apple is blocked the first time you open it.

To open it anyway, go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the message about Safari Arcade. You only do this once per download. The Terminal command in the README does the same thing by removing the "downloaded from the internet" mark from the app.

## Safari (seeing the extension)

Safari ignores extensions that are not signed with an Apple development certificate, so by default an ad-hoc signed extension does not even appear in Safari's Extensions list.

Safari has a switch for this: **Settings > Developer > Allow unsigned extensions**. Apple's documentation states that this setting resets when Safari quits, so it has to be turned on again each time Safari is launched. After turning it on, Safari Arcade appears under **Settings > Extensions**.

This is the main limitation of the free route. There is no supported way to make Safari remember the setting.

## What removes these steps

An **Apple Developer Program** membership, which is a paid yearly subscription from Apple (check [developer.apple.com/programs](https://developer.apple.com/programs/) for the current price).

With a membership the app can be signed with a **Developer ID** certificate and **notarised**, which means Apple scans the build and issues a ticket confirming it. Apple's documentation lists this as a supported way to distribute a Safari web extension outside the Mac App Store. A notarised build opens without the Gatekeeper warning, and Safari treats the extension as signed, so the "Allow unsigned extensions" step goes away. Reports from developers say this works from macOS 15.4 onward. Earlier versions of macOS still treated such extensions as unsigned.

A free Apple ID is not enough. Apple's documentation says that without program membership the extension is not signed with a development certificate and Safari will ignore it unless unsigned extensions are allowed.

## How signing would be added to this project

Nothing below is set up yet. It is recorded here so the path is clear.

1. Join the Apple Developer Program and create a **Developer ID Application** certificate.
2. Export the certificate as a `.p12` file with a password.
3. Add these as **GitHub Secrets** in the repository settings (never as files in the repository): the certificate (base64 text), its password, the Apple team ID, and an app-specific password or API key for notarisation.
4. Extend the workflow to import the certificate into a temporary keychain, build with the Developer ID identity, submit the DMG with `notarytool`, and staple the ticket.

The `.gitignore` already blocks certificate and key files from being committed by accident.

## What has and has not been verified

The statements above about Safari and Gatekeeper come from Apple's documentation and developer reports. Whether the ad-hoc signed build installs and loads correctly on a real Mac has to be confirmed by installing it. The checklist in [CHECKLIST.md](CHECKLIST.md) tracks that.

Sources:

- [Running your Safari web extension](https://developer.apple.com/documentation/safariservices/running-your-safari-web-extension) (Apple)
- [Distributing your Safari web extension](https://developer.apple.com/documentation/safariservices/distributing-your-safari-web-extension) (Apple)
