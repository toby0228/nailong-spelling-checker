# Nailong · Your little desktop proofreader

[Website & setup guide](https://toby0228.github.io/nailong/)

**English** · [点击这里切换到中文](README.zh-CN.md) · [Open the setup guide](START-HERE.html)

Nailong is a draggable macOS desktop pet. When it detects a suspected English spelling mistake, it runs to the word and points at it. Correct the word and it returns to its resting spot.

**macOS 14.2+ · English (US) spelling · Local processing.** Google Docs and visual scans use OCR; support varies by editor and display setup.

## Start with the playground

1. Download or clone this repository. If you download a ZIP, extract it first and keep the whole folder together.
2. Double-click `Start-Nailong.command`. It builds the app if needed, then opens it. Later launches reuse the existing build.
3. In the setup window, click **Try the playground**. This is the easiest first test and needs no browser extension or extra privacy permissions.
4. Type `This is a beautifull day. ` with a space at the end. Nailong should run to **beautifull**. Change it to **beautiful** to send it home.

Drag Nailong to choose its resting spot. Right-click the pet, or use the yellow menu-bar icon, to open its controls. Opening the HTML guide only shows instructions; it does not start the desktop app.

## Before the first build

Building requires Xcode Command Line Tools. If they are missing, open Terminal, run `xcode-select --install`, finish the macOS installer, and launch Nailong again.

If the launcher cannot run, open Terminal, type `cd `, drag the extracted project folder into Terminal, and press Return. Run `bash build.sh`, then open `build/Nailong.app`. For an existing build, open that app directly. Only open a downloaded development build if you trust its source; macOS may require approval in Privacy & Security.

## Choose where to use it

| Where you type | What to enable |
| --- | --- |
| Built-in playground | Nothing extra |
| Supported native apps, such as TextEdit | Accessibility |
| Standard Chrome website text boxes | Browser extension + local helper |
| Google Docs in Chrome (experimental) | Browser extension + local helper + Screen Recording |
| Manual 3-second visual scan | Screen Recording |
| Automatic visual checks in other apps | Screen Recording + Accessibility + opt in that app |

These are separate connections. Turning on Screen Recording does not install the Chrome extension. The guide language switch changes documentation only; the app interface and spelling checker remain English.

## Set up Chrome

1. Keep Nailong running. Click **Connect / repair browser…** in its setup window and choose **Chrome**. This installs the local helper and copies the extension folder path.
2. On the Extensions page, turn on **Developer mode**, then choose **Load unpacked**. Select the `BrowserExtension` folder inside this repository. In the folder chooser, Shift–Command–G lets you paste the copied path.
3. Refresh any website tabs that were already open.
4. Click **Test browser connection** in Nailong. The test page should say **Connected. Nailong is running.** Click its text box and try the sample sentence.

Already installed? Reload the extension instead of loading another copy, then refresh the website. Edge, Brave and Chromium also have helper setup options, but test each browser before claiming support. Keep the repository in a stable location; moving it requires reconnecting the helper and reloading the extension.

## Try Google Docs or a visual scan

For Google Docs, enable **Screen Recording** using Nailong’s setup button, approve Nailong in macOS, and restart it if asked. Finish Chrome setup, refresh the document, and type the sample sentence in a test document. Keep the caret visible and pause for about 2–3 seconds. Nailong uses local image-to-text recognition (OCR) near the caret; it does not check the whole document.

For a manual check, keep the target app in front and choose **Check around pointer in 3 seconds** from the yellow menu-bar icon. Move the pointer over the typo before the countdown ends. A dashed box shows the selected area, which is checked for about 25 seconds. The orange word outline must overlap the actual word. For a new line or different location, start another scan.

For automatic visual checks in another app, grant Screen Recording and Accessibility, switch to that app, and choose **Toggle visual checking for current app**. Use the same menu item again to turn it off.

## If something does not work

- **No pet:** open `build/Nailong.app` or use the launcher, then choose **Reset position** from the yellow menu-bar icon.
- **Browser says disconnected:** keep Nailong running and unpaused; use **Connect / repair browser…**, reload the extension, and refresh the webpage. Use the browser test page for a connection check. The setup window’s Browser line reflects recent traffic and can show disconnected when idle.
- **macOS switch is on, but Nailong says not enabled:** replacing or rebuilding this development app can invalidate the saved grant. Quit Nailong, remove its old entry from the affected macOS privacy list, add the current `build/Nailong.app`, enable it, and reopen it. Approve Touch ID/password prompts yourself. Avoid rebuilding between ordinary launches.
- **Word outline points into blank space:** record which method was active, the window position, browser/document zoom, and a screenshot using test text. Retry with the window still. Browser popup offsets apply to extension text targets; they do not calibrate manual OCR scans.
- **No response in Docs:** confirm Screen Recording, reload the extension and page, click in the document, and pause after a completed word. Try the 3-second scan separately.

## Project documentation

- [Getting started](START-HERE.html): installation, browser connection and everyday controls. Download the project and open the HTML file in a browser.
- [Contributing](CONTRIBUTING.md): development setup, checks and bug reports.
- [Maintainer checklist](docs/TESTING.md): repeatable regression checks.
- [Release preparation](docs/RELEASE.md): validation notes and remaining publication steps.

## Privacy and limits

Spelling checks run locally through macOS; visual recognition uses Apple Vision. The app and extension make no network requests and do not save document text or screenshots. The browser helper and short-lived target/status files live in `~/Library/Application Support/Nailong`; macOS preferences store the resting position, ignored words and visual-check app choices. Browser registration files live in the selected browser’s Application Support folder.

This checks English spelling, not grammar. OCR can misread names, code and unfinished words. Password and private-window exclusions apply to the browser extension; visual checking cannot reliably classify every sensitive canvas region. Use visual checks only where you want visible text checked. Embedded frames, closed shadow DOM, protected windows and some custom editors are unsupported or unreliable. Windows and Linux are not supported.

## Development

Open the folder in VS Code or another editor. `bash build.sh` rebuilds the app. `bash Tests/run-tests.sh` rebuilds and runs native, browser and bridge checks; browser checks need Node, Playwright and Chrome. Install browser test dependencies with `npm install --no-save playwright`. Rebuilding may require fresh macOS permission approval.

`build/Nailong.app/Contents/MacOS/Nailong --capture-test` checks OCR coordinates in a temporary test window at two positions. It needs Screen Recording and does not modify your documents. These controlled checks do not replace testing the real Google Docs flow.

Main folders: `Sources/` for the native app, `BrowserExtension/` for the browser integration, `Assets/` for sprites, and `Tests/` for checks.

## Artwork

Character sprites were generated with OpenAI image generation from visual references. The running animation alternates two poses with a bounce. Artwork provenance is recorded in [ARTWORK.md](ARTWORK.md).

Local build output, runtime files and reference archives are excluded from the repository. See the license and artwork terms below before reusing the project.

---

[点击这里切换到中文](README.zh-CN.md)

## License

Source code and documentation are licensed under [MIT](LICENSE). Character artwork is excluded; see [artwork terms](ARTWORK.md).
