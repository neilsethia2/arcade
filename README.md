# Safari Arcade

A personal gaming hub that lives in the Safari toolbar on macOS. Click the icon and a full tab opens with the arcade. Everything runs offline, with no account and no server.

The project is being built in milestones. See [docs/CHECKLIST.md](docs/CHECKLIST.md) for what is done, what has been tested and what comes next.

## Current status

Milestone 1 (project structure, Safari extension, macOS app wrapper, automated build) is in place. The arcade currently opens a system check screen that confirms the extension works and that saved data persists. The dashboard and the six games arrive in the following milestones:

1. Tetris
2. Snake
3. Minesweeper
4. Tic Tac Toe
5. Survival Race (3D)
6. Table Tennis Tour (3D)

## How it fits together

There are three parts.

**The web app** (`src/`) is the arcade itself, written in React and TypeScript. `npm run build` compiles it into the `dist/` folder.

**The web extension** (`safari-extension/`) is a manifest, a small background script and the icons. They are copied into `dist/` next to the web app, so `dist/` is a complete Safari Web Extension. The background script does one thing: when you click the toolbar icon it opens the arcade in a tab, or brings the existing arcade tab to the front.

**The macOS app** (`macos-app/`) exists because Safari on macOS only accepts extensions that are delivered inside an app. It is a small Swift app that carries the extension and shows you how to switch it on. The games do not run in this app. They run in Safari.

```
src/                 React + TypeScript app
  components/        Reusable interface pieces
  games/             One folder per game (from Milestone 3)
  hooks/             Reusable React logic
  pages/             Full screens
  services/          Storage and extension helpers, shared by all games
  styles/            Design tokens and global styles
safari-extension/    manifest.json, background.js, icons
macos-app/           Swift container app, extension target, project.yml
scripts/             Build helpers (icons, verification, DMG)
design/              Icon artwork (SVG)
docs/                Checklist and signing notes
.github/workflows/   Automated macOS build
```

## Getting the app

Every push to `main` is built by GitHub Actions on a macOS machine. The build compiles the web app, generates the Xcode project, builds the app with the extension inside it, checks the result and packages a DMG.

To download a build:

1. Open the **Actions** tab of this repository on GitHub.
2. Click the most recent run with a green tick.
3. Scroll to **Artifacts** at the bottom and download the file whose name starts with `Safari-Arcade`. You need to be signed in to GitHub. It downloads as a zip with the DMG inside.

Tagged versions also appear on the **Releases** page, where the DMG can be downloaded directly.

## Installing

1. Open the DMG and drag **Safari Arcade** onto the **Applications** shortcut.
2. Open **Safari Arcade** from Applications. macOS will block it the first time because the build is not signed with a paid Apple developer certificate. To allow it, open **System Settings**, go to **Privacy & Security**, scroll down and click **Open Anyway** next to the Safari Arcade message. Alternatively run this once in Terminal, then open the app normally:

   ```
   xattr -dr com.apple.quarantine "/Applications/Safari Arcade.app"
   ```

3. In Safari choose **Safari > Settings**, open the **Advanced** tab and tick **Show features for web developers**.
4. Open the **Developer** tab and tick **Allow unsigned extensions**. Safari asks for your Mac password.
5. Open the **Extensions** tab and tick **Safari Arcade**.
6. Click the Safari Arcade icon in the Safari toolbar.

**Step 4 has to be repeated every time you quit and reopen Safari.** That is a Safari rule for unsigned extensions and cannot be worked around from inside the app. [docs/SIGNING.md](docs/SIGNING.md) explains why and what it would take to remove that step.

## Updating

Download the newer DMG, drag the app into Applications and choose **Replace**. Saved scores and settings are kept by Safari, separately from the app, so replacing the app should leave them alone. This will be confirmed during Milestone 6 testing.

## Working on the code

You do not need any of this to use the app. It is here for when you want to run or change it on your own Mac.

```
npm install        # once
npm run dev        # preview the arcade in a normal browser tab
npm run check      # type-check, run the tests and build
```

To build the macOS app locally you need Xcode and XcodeGen (`brew install xcodegen`):

```
npm run build
xcodegen generate --spec macos-app/project.yml
open macos-app/SafariArcade.xcodeproj
```

The version number lives in one place, `package.json`. The build copies it into the extension manifest and the macOS app.

## Releasing a version

1. Change `version` in `package.json` and push.
2. On GitHub open the **Actions** tab, choose **Build macOS app** on the left, and click **Run workflow**.
3. Tick **Publish this build on the Releases page** and click the green **Run workflow** button.

A few minutes later the DMG appears on the Releases page. The build refuses to publish the same version twice, so raise the version number first. Versions below 1.0.0 are marked as pre-releases.
