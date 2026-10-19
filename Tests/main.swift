import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let screen = NSScreen.screens.first!
let picker = WindowPicker()
let fixture = WindowInfo(pid: getpid(), cgWindowID: 1,
    axWindow: AXUIElementCreateApplication(getpid()),
    title: "Design notes — macOS menu appearance and window selection behavior",
    appIcon: NSWorkspace.shared.icon(forFile: "/System/Applications/TextEdit.app"), minimizedAt: Date())
let menu = picker.makeMenu(windows: [fixture])
assert(menu.items.count == 3)
assert(menu.items[0].image?.size == NSSize(width: 16, height: 16))
assert(menu.items[0].title == String(fixture.title.prefix(41)) + "…")
assert(menu.items[0].toolTip == fixture.title)
assert(menu.items[1].isSeparatorItem)
assert(menu.items[2].title == "Quit")
assert(menu.size.width >= 360)
let click = NSPoint(x: screen.frame.midX + 50, y: screen.frame.maxY - 10)
let origin = picker.menuOrigin(size: menu.size, screen: screen, point: click)
assert(abs(origin.x + menu.size.width / 2 - click.x) < 0.1)
let barBottom = screen.frame.maxY - menuBarHeight(screen)
assert(abs(origin.y - (barBottom - 8)) < 0.1)
for clickY in [screen.frame.maxY, screen.frame.maxY - 1, barBottom + 1] {
    let anchor = picker.menuOrigin(size: menu.size, screen: screen,
                                  point: NSPoint(x: click.x, y: clickY))
    assert(anchor.y == barBottom - 8, "All menu-bar click heights must open below the bar")
}
if #available(macOS 27.0, *) {
    assert(menu.items[0].preferredImageVisibility == .visible)
}
let left = picker.menuOrigin(size: menu.size, screen: screen, point: NSPoint(x: screen.frame.minX, y: click.y))
let right = picker.menuOrigin(size: menu.size, screen: screen, point: NSPoint(x: screen.frame.maxX, y: click.y))
assert(left.x >= screen.frame.minX)
assert(right.x + menu.size.width <= screen.frame.maxX)
let emptyMenu = picker.makeMenu(windows: [])
assert(emptyMenu.items[0].title == "No minimized windows")
assert(!emptyMenu.items[0].isEnabled)

var interaction = MenuBarInteraction()
for type in [CGEventType.leftMouseDown, .leftMouseDragged, .leftMouseUp] {
    assert(interaction.handle(type, eligible: true) == .pass)
}
assert(interaction.handle(.rightMouseDown) == .pass)
assert(interaction.handle(.rightMouseDown, eligible: true) == .consume)
assert(interaction.handle(.rightMouseUp) == .open)
assert(interaction.handle(.rightMouseUp) == .pass)
interaction.reset()
assert(interaction.handle(.rightMouseUp) == .pass)
assert(interaction.handle(.rightMouseDown, eligible: true) == .consume)
assert(interaction.handle(.rightMouseDragged) == .openHeld)
assert(interaction.handle(.rightMouseDragged) == .pass)
assert(interaction.handle(.rightMouseUp) == .pass)
let frame = CGRect(x: -1920, y: 900, width: 1920, height: 1080)
for y in [frame.maxY, frame.maxY - 1, frame.maxY - 16, frame.maxY - 32] {
    assert(menuBarContains(CGPoint(x: -960, y: y), frame: frame, height: 32))
}
assert(!menuBarContains(CGPoint(x: -960, y: frame.maxY - 33), frame: frame, height: 32))
assert(shortenedWindowTitle("Short title") == "Short title")

// Exercise a real AppKit tracking session, its action, and its cancellation.
var selected: [CGWindowID] = []
var timerFired = false
let timer = Timer(timeInterval: 0.1, repeats: false) { _ in
    timerFired = true
    let visibleWindows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    let ownBounds = visibleWindows.filter {
        ($0[kCGWindowOwnerPID as String] as? Int) == Int(getpid())
    }.compactMap { $0[kCGWindowBounds as String] as? [String: CGFloat] }
    let displayedMenu = ownBounds.first { ($0["Width"] ?? 0) >= menu.minimumWidth }!
    let barBottomInQuartz = NSScreen.screens.first!.frame.maxY - screen.frame.maxY + menuBarHeight(screen)
    assert(displayedMenu["Y"]! >= barBottomInQuartz,
           "The native menu must start below the menu bar without pointer movement")
    assert(abs(displayedMenu["X"]! + displayedMenu["Width"]! / 2 - click.x) <= 1,
           "The actual menu frame must remain horizontally centered on the click")
    picker.menu?.performActionForItem(at: 0)
    picker.dismiss()
}
RunLoop.main.add(timer, forMode: .common)
RunLoop.main.add(timer, forMode: .eventTracking)
picker.show(windows: [fixture], on: screen, at: click) { selected.append($0.cgWindowID) }
assert(timerFired && selected == [1])
assert(picker.menu == nil)
let cancelTimer = Timer(timeInterval: 0.1, repeats: false) { _ in picker.dismiss() }
RunLoop.main.add(cancelTimer, forMode: .common)
RunLoop.main.add(cancelTimer, forMode: .eventTracking)
picker.show(windows: [fixture], on: screen, at: click) { _ in fatalError("Cancellation selected a window") }
print("PASS: native menu tracking/action/cancellation, icons, separators, prefix titles, initial native frame below menu bar, cursor-centered anchor, explicit icon visibility, right-click opening, left-button passthrough, empty list, full-height boundaries")

// Catch the unlaid-out NSAlert template that previously exposed blank controls.
func descendants(_ view: NSView) -> [NSView] {
    [view] + view.subviews.flatMap(descendants)
}
for trusted in [false, true] {
    let alert = makeAccessSetupAlert(trusted: trusted)
    assert(alert.buttons.map(\.title) == ["Open Accessibility Settings", "Quit"])
    let content = alert.window.contentView!
    let visibleButtons = descendants(content).compactMap { $0 as? NSButton }
        .filter { !$0.isHiddenOrHasHiddenAncestor }
    assert(visibleButtons.count == 2, "Only Settings and Quit should be visible")
    assert(visibleButtons.allSatisfy { !$0.title.isEmpty })
    let info = descendants(content).compactMap { $0 as? NSTextField }
        .first { $0.stringValue == alert.informativeText }!
    let requiredHeight = info.cell!.cellSize(forBounds: NSRect(x: 0, y: 0, width: info.bounds.width, height: 1000)).height
    assert(info.bounds.height >= requiredHeight - 1, "The complete instructions must fit")

}
print("PASS: setup alert has two visible buttons, no placeholder controls, and full instruction text")

let enabledAlert = makeEnabledAlert()
assert(enabledAlert.messageText == "Successfully enabled")
assert(enabledAlert.buttons.map(\.title) == ["Got it"])
let enabledContent = enabledAlert.window.contentView!
let enabledButtons = descendants(enabledContent).compactMap { $0 as? NSButton }
    .filter { !$0.isHiddenOrHasHiddenAncestor }
assert(enabledButtons.count == 1 && enabledButtons[0].title == "Got it")
let enabledInfo = descendants(enabledContent).compactMap { $0 as? NSTextField }
    .first { $0.stringValue == enabledAlert.informativeText }!
assert(enabledInfo.bounds.height >= enabledInfo.cell!.cellSize(forBounds:
    NSRect(x: 0, y: 0, width: enabledInfo.bounds.width, height: 1000)).height - 1)
print("PASS: enabled notice has one button and complete right-click instructions")

assert(UpdateChecker.isNewer("v1.12", than: "1.9"))
assert(!UpdateChecker.isNewer("1.9", than: "1.12"))
assert(!UpdateChecker.isNewer("v1.12.0", than: "1.12"))
assert(!UpdateChecker.isNewer("v2.0-beta", than: "1.12"))
assert(!UpdateChecker.isNewer("oops", than: "1.12"))
func releaseData(tag: String = "v1.12", draft: Bool = false, prerelease: Bool = false,
                 url: String = "https://github.com/numeono/minimized-windows/releases/tag/v1.12") -> Data {
    try! JSONSerialization.data(withJSONObject: ["tag_name": tag, "draft": draft,
        "prerelease": prerelease, "html_url": url])
}
assert(UpdateChecker.update(from: releaseData(), statusCode: 200, currentVersion: "1.11")?.version == "v1.12")
for status in [403, 404, 429, 500] {
    assert(UpdateChecker.update(from: releaseData(), statusCode: status, currentVersion: "1.11") == nil)
}
for data in [releaseData(draft: true), releaseData(prerelease: true),
             releaseData(url: "https://example.com/update"), Data("broken json".utf8)] {
    assert(UpdateChecker.update(from: data, statusCode: 200, currentVersion: "1.11") == nil)
}
assert(UpdateChecker.update(from: releaseData(), statusCode: 200, currentVersion: "1.12") == nil)
let updateAlert = makeUpdateAlert(version: "v1.12")
assert(updateAlert.buttons.map(\.title) == ["View Update", "Later"])
let heldTimer = Timer(timeInterval: 0.1, repeats: false) { _ in
    RunLoop.main.perform(inModes: [.eventTracking, .common]) {
        picker.completeHeldSelection(picker.menu?.items[0])
    }
}
RunLoop.main.add(heldTimer, forMode: .eventTracking)
picker.show(windows: [fixture], on: screen, at: click) { selected.append($0.cgWindowID) }
assert(selected == [1, 1], "Held release must dispatch exactly one window action")
let outsideTimer = Timer(timeInterval: 0.1, repeats: false) { _ in picker.completeHeldSelection(nil) }
RunLoop.main.add(outsideTimer, forMode: .eventTracking)
picker.show(windows: [fixture], on: screen, at: click) { _ in fatalError("Outside release selected a window") }
print("PASS: held selection/cancellation, version comparisons, stable-release filtering, error handling, update prompt")

let loginAlert = makeLoginAlert(message: "Enable Minimized Windows in System Settings → General → Login Items so it opens automatically when you log in.")
assert(loginAlert.buttons.map(\.title) == ["Open Login Items", "Later"])
let loginContent = loginAlert.window.contentView!
let loginInfo = descendants(loginContent).compactMap { $0 as? NSTextField }
    .first { $0.stringValue == loginAlert.informativeText }!
assert(loginInfo.bounds.height >= loginInfo.cell!.cellSize(forBounds:
    NSRect(x: 0, y: 0, width: loginInfo.bounds.width, height: 1000)).height - 1)
print("PASS: login setup notice has the intended controls and complete instructions")
