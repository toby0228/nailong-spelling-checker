# Feature tests before publishing

[中文](TESTING.zh-CN.md) · [Setup guide](../START-HERE.html)

Every item starts untested. Record Pass, Fail or N/A separately; this checklist does not certify that a feature works.

Environment: commit/build ____; macOS ____; browser/version ____; browser zoom ____; Docs zoom ____; displays/scaling ____; date ____

## Launch & idle

Open Nailong.

Expected: One pet appears, stays visible over ordinary windows, and has a gentle idle animation.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Drag & remember home

Drag the pet to a clear spot. Quit and reopen it.

Expected: It stays at the chosen position and remembers it after relaunch.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Playground typo

Open Try the playground. Type the sample sentence with a trailing space.

Expected: Nailong runs toward beautifull, points, and outlines that word.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Correction & return

Replace beautifull with beautiful.

Expected: The outline disappears and Nailong returns home and idles.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Pause & resume

Pause detection from the pet menu, type a typo, then resume.

Expected: No new target while paused; detection resumes afterward.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Native text fields

Enable Accessibility. Type the sample in a plain-text TextEdit document.

Expected: The correct word is outlined; fixing it sends Nailong home. Record any unsupported app.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Browser connection

Set up Chrome, then open Test browser connection.

Expected: The page reports Connected. Nailong is running. Typing a typo reports that its position was sent.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Website editors

Try the browser test page’s text box and rich-text editor; then a normal website input.

Expected: Each focused editor detects the same typo and clears it after correction.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Google Docs — experimental

Enable Screen Recording and connect Chrome. In a test document, type the sample and pause 2–3 seconds with the caret visible.

Expected: The orange box overlaps the actual typo, not blank space. Correction clears it. Record browser zoom and document zoom.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## 3-second pointer scan

Keep the target app in front. Choose Check around pointer in 3 seconds and move the pointer over the typo before the countdown ends.

Expected: The scan region appears, then the word is outlined accurately. It checks for about 25 seconds and returns home after correction.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Position, scrolling & zoom

Repeat the pointer test after moving/resizing the window, scrolling, and changing zoom. Test near both screen edges.

Expected: The box remains on the word; the pet faces it and stays on screen. The pointer line may be diagonal at screen edges.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Extra display — if available

Move the target window to each connected display and repeat a scan.

Expected: No offset on displays above, below or beside the main screen. Mark N/A when no extra display is available.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Ignore a word

For a native or visual target, choose Ignore current word; repeat it elsewhere.

Expected: That word is no longer flagged, including after restarting. Use a disposable test word.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Excluded browser fields

Pause visual checks. Using dummy text only, test a password field and an incognito window.

Expected: The browser extension sends no typo target for either. Visual OCR is a separate opt-in feature.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Recovery & quit

Use Bring pet home, Reset position, and Quit Nailong.

Expected: The pet returns home, resets to a visible location, and fully disappears when quit.

Result: [ ] Pass  [ ] Fail  [ ] N/A
Notes:

## Release review

- [ ] Try first-time setup from a clean download.
- [ ] Document remaining failures; recheck exact Google Docs pointing.
- [ ] Exclude runtime state, caches, personal paths and private screenshots; review test-script portability.
- [ ] Add a code license and confirm artwork redistribution rights.
