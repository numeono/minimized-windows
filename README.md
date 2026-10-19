# Minimized Windows

A lightweight macOS app that lists your minimized windows. Hold the primary mouse button anywhere on the menu bar and drag down to open the list. Release over a window to restore it. Or right-click the menu bar once, then click a window in the list.

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
- Hold the primary mouse button anywhere on the visible menu bar, including over app menus, status icons, and the camera gap.
- Drag down at least 8 points to open the window list. Keep holding, move onto a window, and release to restore it.
- Release outside the dropdown or press Escape to cancel.
- Choose Quit in the dropdown to stop the app.

The dropdown is 360 points wide and centered on the display where the drag starts, directly below its menu bar. Titles show their first 41 characters followed by an ellipsis when needed. Text that exceeds the row width is also truncated at the end. Each window row has an app icon. Recently minimized windows appear first.

A plain left-click does not open the window list. The app holds the initial menu-bar press while it checks for a drag. If you release without dragging down 8 points, it forwards the click to the original menu-bar control. This means ordinary menu-bar clicks take effect on release. Downward dragging from native menus or status icons now opens this app's list instead of their usual drag interaction.

Double-click activation is not enabled. With an automatically hidden menu bar, reveal the bar first. The app registers itself to launch at login.

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

macOS requires Accessibility access for any app that reads window state from other applications. This app uses it to detect and restore minimized windows, track primary-button drags and secondary clicks on the menu bar, and forward ordinary left-clicks.

## How it works

The app uses the macOS Accessibility API (`AXMinimizedWindows` attribute) to query each running application for its minimized windows. It polls lightly in the background (every 2 seconds) to track the order in which windows were minimized. No network access, no data collection.

## Verification

The app builds locally and passes code-signature verification. Native fixture tests verify persistent right-click opening, subsequent click selection, outside-click dismissal, the downward-drag threshold, ordinary-click forwarding decisions, release selection, dropdown position, cancellation, empty-list behavior, title limits, and menu-bar boundary geometry. The dropdown was also rendered and inspected for its icon and shortened title. Live event interception and restoration still need testing in a logged-in macOS session with Accessibility access for this build, including on a notched MacBook.

Run the fixture tests with `bash Tests/run.sh`. They briefly display a test dropdown and save a preview to `/tmp/minimized-windows-picker.png`.

Check these cases when testing a new build:

- Minimize two windows, hold the primary button on the menu bar, drag down to each entry, and release. Only the chosen window should restore and activate.
- Right-click once and release. The list should stay open until you choose a window, click outside, or press Escape.
- Cancel with Escape and by releasing outside the menu. Neither should restore a window.
- Test the empty list, ordinary desktop clicks, and right-clicks. Check that plain clicks on app menus and status icons still open them after release, and that dragging down from those same controls opens the window list.
- Test each connected display, including one above or to the left of the main display, and a revealed auto-hidden menu bar.
- Revoke and restore Accessibility access. The fallback icon should appear and then disappear without restarting the app.

## License

MIT. See [LICENSE](LICENSE).
