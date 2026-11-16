# Development checklist

Updated after every milestone. Three marks are used:

- `[x]` done and tested, with how it was tested
- `[~]` built but not yet tested where it matters
- `[ ]` not started

## Milestone 1: Environment and Safari architecture

- [x] GitHub repository (`neilsethia2/arcade`, created by Neil)
- [x] Project structure
- [x] React + TypeScript app builds (`npm run check`: type-check, 18 unit tests, production build)
- [x] Storage service with extension storage, localStorage and in-memory backends (unit tested)
- [x] Web extension: toolbar click opens the arcade in a tab, a second click refocuses the same tab, a counter saved in extension storage survives reloads. Tested by loading the built extension into Chrome with a Chrome-style copy of the manifest. Chrome and Safari share these APIs, but this is not a Safari test.
- [x] macOS container app and Safari Web Extension target compile on GitHub Actions (macOS 26, Xcode 26.6) with no errors or warnings
- [x] Built app passes `scripts/verify-app.sh` on the build machine: extension embedded, web files inside it, declared as a Safari Web Extension, versions match, universal (Apple silicon and Intel), ad-hoc signature verifies, extension sandboxed
- [x] GitHub Actions workflow: build, verify, package DMG, upload artifact (first run passed on commit e5a9698)
- [~] The app and extension have been compiled and inspected, but never launched. Nothing has run on a Mac with a screen yet.
- [ ] DMG installed on a real Mac
- [ ] Extension enabled in real Safari and the arcade tab opens from the toolbar
- [ ] Launch counter keeps increasing after quitting and reopening Safari

Completion requirement: valid macOS build structure, and the Safari extension can open its interface. The last three items need Neil's Mac.

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

- Unsigned build: "Allow unsigned extensions" must be re-enabled each time Safari launches. See [SIGNING.md](SIGNING.md).
- If Safari restores an arcade tab after a restart, the tab's address may no longer be valid, because Safari can assign the extension a new internal address per launch. To be checked on a real Mac in Milestone 6. Saved data is kept in extension storage, which does not depend on that address.
- The repository is named `arcade` rather than `Safari-Arcade`. The app and extension are still called Safari Arcade.
