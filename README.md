# Minimized Windows

A lightweight macOS app that lists your minimized windows. Right-click the menu bar once, then click a window in the list to restore it.

Useful if you keep your Dock hidden or [**have your Dock disabled**](https://github.com/numeono/macOS#disable-the-dock).

<p align="center">
  <img src="assets/app-icon.png" alt="Minimized Windows app icon" width="160">
</p>

![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Original icon interface

The screenshot below shows the original icon interface. The app hides the icon when the gesture is available.

![Minimized Windows menu showing minimized windows from several apps](assets/minimized-windows-menu.jpg)

## Controls

- Right-click the menu bar once to leave the list open, then click a window. Click outside the dropdown or press Escape to dismiss it.
- Choose Quit in the dropdown to stop the app.

The dropdown is 360 points wide and centered on the display where you right-click, directly below its menu bar. Titles show their first 41 characters followed by an ellipsis when needed. Text that exceeds the row width is also truncated at the end. Each window row has an app icon. Recently minimized windows appear first.

Ordinary left-clicks and drags pass through unchanged. Drag activation and double-click activation are not enabled. With an automatically hidden menu bar, reveal the bar first. The app registers itself to launch at login.

## Accessibility and fallback

Allow Accessibility access when prompted. Until access is available, or if the event tap cannot start, the original menu-bar icon remains available. The app retries every two seconds and removes the icon when the gesture becomes available. If access is revoked, the icon returns.

## Requirements

- macOS 12.0 (Monterey) or later
- Accessibility permission (required to detect and restore minimized windows)

## Installation

### Build from source

```bash
git clone https://github.com/numeono/minimized-windows.git
cd minimized-windows
bash build.sh
mv "build/Minimized Windows.app" /Applications/
open "/Applications/Minimized Windows.app"
```

Then grant Accessibility permission when prompted, or go to:  
**System Settings → Privacy & Security → Accessibility → add "Minimized Windows"**

### Requirements for building

- Xcode Command Line Tools (`xcode-select --install`)
- No other dependencies

## Why Accessibility permission?

macOS requires Accessibility access for any app that reads window state from other applications. This app uses it to detect and restore minimized windows, detect secondary clicks on the menu bar.

## How it works

The app uses the macOS Accessibility API (`AXMinimizedWindows` attribute) to query each running application for its minimized windows. It polls lightly in the background (every 2 seconds) to track the order in which windows were minimized. No network access, no data collection.

## Verification

The app builds locally and passes code-signature verification. Native fixture tests verify persistent right-click opening, subsequent click selection, outside-click dismissal, ordinary left-click and drag passthrough, release selection, dropdown position, cancellation, empty-list behavior, title limits, and menu-bar boundary geometry. The dropdown was also rendered and inspected for its icon and shortened title. Live event interception and restoration still need testing in a logged-in macOS session with Accessibility access for this build, including on a notched MacBook.

Run the fixture tests with `bash Tests/run.sh`. They briefly display a test dropdown and save a preview to `/tmp/minimized-windows-picker.png`.

Check these cases when testing a new build:

- Minimize two windows, right-click the menu bar, then click each entry in turn. Only the chosen window should restore and activate.
- Right-click once and release. The list should stay open until you choose a window, click outside, or press Escape.
- Cancel with Escape and by clicking outside the menu. Neither should restore a window.
- Test the empty list, ordinary desktop clicks, and right-clicks. Check that left-clicks and drags on app menus and status icons retain their normal behavior and do not open the window list.
- Test each connected display, including one above or to the left of the main display, and a revealed auto-hidden menu bar.
- Revoke and restore Accessibility access. The fallback icon should appear and then disappear without restarting the app.

## License

MIT. See [LICENSE](LICENSE).
