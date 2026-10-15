# Contributing to Nailong

## Development setup

Use macOS 14.2 or newer. Xcode Command Line Tools are free and required to build. From the repository folder, run `bash Run.command` to build and launch the app. No paid Apple developer membership is needed for a local source build. The app uses an ad-hoc development signature; distributing a one-click public download requires Developer ID signing and Apple notarization. Rebuilding may require renewed macOS privacy permissions.

For browser checks, install Node.js and Google Chrome, then run `npm install --no-save playwright` in the repository. Run `bash Tests/run-tests.sh` for native, bridge and isolated browser checks. `CHROME_PATH` can select another Chrome executable; `PLAYWRIGHT_PATH` can select an existing Playwright module. These checks use fixtures and do not replace live editor checks.

## Project layout

| Location | Purpose |
| --- | --- |
| `Sources/` | Native macOS application |
| `BrowserExtension/` | Website integration and local bridge UI |
| `Assets/` | Runtime character sprites |
| `Guide/` | Shared starter-page styles and script |
| `docs/` | Maintainer checklists and release notes |
| `Tests/` | Automated checks |

Keep English and Chinese user documentation in sync. Keep the starter guides focused on setup and everyday use; maintainer checks belong in `docs/`.

## Reporting problems

Include macOS and browser versions, the build or commit, detection method (native, browser or visual scan), zoom and display arrangement, and steps to reproduce. Use a short sample sentence and redact personal content from screenshots. Describe the expected result and what happened instead.

## Before proposing a change

Run checks relevant to the change and repeat affected items in [the manual checklist](docs/TESTING.md). State what was verified and any checks skipped. Keep generated builds, local state, dependencies and reference archives out of commits.
