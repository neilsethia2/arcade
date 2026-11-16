# Development checklist

Updated after every milestone. Three marks are used:

- `[x]` done and tested, with how it was tested
- `[~]` built but not yet tested where it matters
- `[ ]` not started

## Milestone 1: Environment and app architecture

Foundations

- [x] GitHub repository (`neilsethia2/arcade`, created by Neil)
- [x] Project structure
- [x] React + TypeScript app builds (`npm run check`: type-check, 26 unit tests, production build)
- [x] Storage service with four backends: Mac app file, extension storage, localStorage, memory (unit tested)
- [x] GitHub Actions workflow: build, verify contents, launch test, package DMG, upload artifact, publish release on request

Version 0.1.0: Safari extension only

- [x] Web extension logic tested in Chrome (toolbar click opens a tab, second click refocuses it, counter saved)
- [x] App and extension compiled and verified on GitHub Actions (macOS 26, Xcode 26.6)
- [x] Released as pre-release `v0.1.0`
- [x] Installed on Neil's Mac, 16 November 2026: the extension loaded in Safari, the toolbar icon opened the arcade tab, and the screen reported "Running in: Safari extension"
- [x] Same test found two problems. After quitting and reopening Safari the launch counter was back at 1, so **saved data did not survive**. And "Allow unsigned extensions" had to be switched on again, as expected for an unsigned build.

Decision, 16 November 2026: run the arcade as a standalone Mac app (the way Neil's Panda app works) instead of only inside Safari. Neil suggested this and is fine with it not living in the browser. It removes both problems without a paid Apple developer membership. The Safari extension stays in the bundle as an optional extra. See [SIGNING.md](SIGNING.md).

Version 0.2.0: standalone Mac app

- [x] App window shows the arcade using WebKit, loading packaged files through a private `arcade://` address
- [x] Saved data goes through a bridge to `~/Library/Application Support/Safari Arcade/storage.json`
- [x] Web side of the bridge tested in Chrome with a simulated app: counter went 1 then 2 across reloads, no page errors
- [x] Swift code compiles on GitHub Actions with no errors or warnings (first run with the new code: run 6)
- [x] **Launch test on a real Mac (GitHub's macOS 26 build machine):** the built app was started twice. Both times the page loaded with no errors and reported it was running in the Mac app and saving through it. The launch counter was 1 on the first start and 2 on the second, and `storage.json` held the value 2 afterwards. This runs on every build from now on (`scripts/self-test.sh`).
- [x] Released as pre-release `v0.2.0` (run 7) with the DMG and a picture of the app window from the launch test. The picture shows the system check screen drawn correctly, reading "Mac app", "A file on this Mac" and "Opened 2 times".
- [ ] Installed on Neil's Mac and opened from Applications
- [ ] Launch counter keeps increasing after quitting and reopening the app on Neil's Mac
- [ ] Keyboard input reaches the page without clicking first (cannot be checked until a game exists; planned for Milestone 3)

Completion requirement: valid macOS build structure, and the app can open its interface. The two unticked install items need Neil's Mac.

## Milestone 2: Arcade dashboard

- [ ] Home screen with six game cards
- [ ] Navigation and game selection
- [ ] Reusable game layout (back button, title, controls, pause and restart)
- [ ] Settings: sound, theme
- [ ] Favourites, recently played, global high-score dashboard
- [ ] Keyboard shortcuts
- [ ] Responsive layout

## Milestone 3: Four classic games

- [ ] Tetris
- [ ] Snake
- [ ] Minesweeper
- [ ] Tic Tac Toe

## Milestone 4: Survival Race (3D)

- [ ] Not started. Blocked until Milestones 1 to 3 are complete and tested.

## Milestone 5: Table Tennis Tour (3D)

- [ ] Not started. Blocked until Survival Race works.

## Milestone 6: Integration testing in Safari

- [ ] Not started

## Milestone 7: Final delivery

- [ ] Not started

## Known limitations and open questions

- The build is not signed with an Apple Developer ID, so macOS asks for **Open Anyway** once per downloaded copy (first install and each update). See [SIGNING.md](SIGNING.md).
- The optional Safari extension needs "Allow unsigned extensions" on every Safari launch and loses its saved data when Safari quits. Its data is also separate from the Mac app's. Open question for Neil: keep it as an extra, or remove it from the app.
- The app is still called Safari Arcade even though it no longer runs inside Safari. Renaming it is a small change if wanted.
- The launch test on the build machine proves the page loads and data persists. It does not prove how the window looks or feels in use. A picture of the window taken during that test is attached to each release for a visual check.
- The repository is named `arcade` rather than `Safari-Arcade`.
