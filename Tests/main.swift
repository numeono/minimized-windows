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
assert(abs(origin.y - (click.y - 4)) < 0.1)
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
assert(interaction.handle(.rightMouseDragged) == .consume)
assert(interaction.handle(.rightMouseUp) == .open)
assert(interaction.handle(.rightMouseUp) == .pass)
interaction.reset()
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
print("PASS: native menu tracking/action/cancellation, icons, separators, prefix titles, cursor-centered anchor, right-click opening, left-button passthrough, empty list, full-height boundaries")

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
