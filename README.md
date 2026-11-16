# Safari Arcade

A personal gaming hub for the Mac. Open the app and the arcade appears in its own window. Everything runs offline, with no account and no server.

The project is being built in milestones. See [docs/CHECKLIST.md](docs/CHECKLIST.md) for what is done, what has been tested and what comes next.

## Current status

Milestone 1 (project structure, Mac app, saved data, automated build) is in place. The arcade currently opens a system check screen that confirms the app works and that saved data persists. The dashboard and the six games arrive in the following milestones:

1. Tetris
2. Snake
3. Minesweeper
4. Tic Tac Toe
5. Survival Race (3D)
6. Table Tennis Tour (3D)

### Why it is an app and not only a Safari extension

The first version ran only as a Safari extension. Testing it on a real Mac showed two problems with an extension that is not signed with a paid Apple developer certificate: Safari has to be told to allow it again every time Safari is opened, and the saved data was gone after quitting Safari. So the arcade now runs in the Safari Arcade app itself, where neither problem exists. The Safari extension is still included as an optional extra. [docs/SIGNING.md](docs/SIGNING.md) has the details.

## How it fits together

There are three parts.

**The web app** (`src/`) is the arcade itself, written in React and TypeScript. `npm run build` compiles it into the `dist/` folder.

**The Mac app** (`macos-app/`) is a small Swift app. It opens one window, shows the web app inside it using the same engine Safari uses (WebKit), and keeps saved data in a file on your Mac. The web files are packaged inside the app, so nothing is downloaded when you play.

**The Safari extension** (`safari-extension/`) is optional. It is a manifest, a small background script and the icons. It adds a toolbar button to Safari that opens the arcade in a tab. It rides along inside the Mac app, because Safari on macOS only accepts extensions delivered inside an app.

```
src/                 React + TypeScript app
  components/        Reusable interface pieces
  games/             One folder per game (from Milestone 3)
  hooks/             Reusable React logic
  pages/             Full screens
  services/          Storage, diagnostics and bridges to the app, shared by all games
  styles/            Design tokens and global styles
safari-extension/    manifest.json, background.js, icons
macos-app/           Swift app, extension target, project.yml
scripts/             Build helpers (icons, verification, launch test, DMG)
design/              Icon artwork (SVG)
docs/                Checklist and signing notes
.github/workflows/   Automated macOS build
```

## Getting the app

Download the latest `.dmg` from the [Releases page](https://github.com/neilsethia2/arcade/releases).

Every push to `main` is also built by GitHub Actions on a Mac. That build compiles the web app, generates the Xcode project, builds the app, checks its contents, launches it twice to test that it loads and that saved data survives a restart, and packages a DMG. Those in-between builds can be downloaded from the **Actions** tab: open the most recent run with a green tick and look under **Artifacts** at the bottom.

## Installing

1. Open the DMG and drag **Safari Arcade** onto the **Applications** shortcut.
2. Open **Safari Arcade** from Applications. macOS will block it the first time because the build is not signed with a paid Apple developer certificate. To allow it, open **System Settings**, go to **Privacy & Security**, scroll down and click **Open Anyway** next to the Safari Arcade message.

That is all. From then on it opens like any other app.

If you prefer Terminal, this one command does the same as the Open Anyway step:

```
xattr -dr com.apple.quarantine "/Applications/Safari Arcade.app"
```

## Saved data

High scores and settings are kept in one file:

```
~/Library/Application Support/Safari Arcade/storage.json
```

It belongs to you, not to the app. Replacing the app with a newer version leaves it alone. Deleting that file resets everything.

## Updating

Download the newer DMG, drag the app into Applications and choose **Replace**. macOS treats a newly downloaded copy as new, so the **Open Anyway** step is needed once per update.

## The optional Safari extension

The app also contains a Safari extension that adds an arcade button to Safari's toolbar and opens the arcade in a tab. Without a paid Apple developer membership it has two drawbacks, both seen in testing: Safari must be told to allow it again on every launch, and it forgets saved data when Safari quits. To try it anyway:

1. In Safari choose **Safari > Settings**, open the **Advanced** tab and tick **Show features for web developers**.
2. Open the **Developer** tab and tick **Allow unsigned extensions**.
3. Open the **Extensions** tab and tick **Safari Arcade**.

## Working on the code

You do not need any of this to use the app. It is here for when you want to run or change it on your own Mac.

```
npm install        # once
npm run dev        # preview the arcade in a normal browser tab
npm run check      # type-check, run the tests and build
```

To build the Mac app locally you need Xcode and XcodeGen (`brew install xcodegen`):

```
npm run build
xcodegen generate --spec macos-app/project.yml
open macos-app/SafariArcade.xcodeproj
```

Then press the Run button in Xcode. An app you build yourself this way was not downloaded, so it opens without the Open Anyway step.

After changing anything in `src/`, run `npm run build` again before building in Xcode, because the app packages whatever is in `dist/`.

The version number lives in one place, `package.json`. The build copies it into the extension manifest and the macOS app.

## Releasing a version

1. Change `version` in `package.json` and push.
2. On GitHub open the **Actions** tab, choose **Build macOS app** on the left, and click **Run workflow**.
3. Tick **Publish this build on the Releases page** and click the green **Run workflow** button.

A few minutes later the DMG appears on the Releases page. The build refuses to publish the same version twice, so raise the version number first. Versions below 1.0.0 are marked as pre-releases.
