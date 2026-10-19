import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let screen = NSScreen.screens.first!
let picker = WindowPicker()
let fixture = WindowInfo(pid: getpid(), cgWindowID: 1,
    axWindow: AXUIElementCreateApplication(getpid()),
    title: "A very long window title that should be shortened to fit comfortably in the dropdown — document.txt",
    appIcon: NSImage(named: NSImage.applicationIconName), minimizedAt: Date())
var restored: [CGWindowID] = []
let top = screen.frame.maxY - menuBarHeight(screen)
let firstRow = NSPoint(x: screen.frame.midX, y: top - 21)
func show() { picker.show(windows: [fixture], on: screen) { restored.append($0.cgWindowID) } }
show()
let panel = app.windows.first { $0.isVisible && $0 is NSPanel }!
assert(abs(panel.frame.midX - screen.frame.midX) < 0.1)
assert(abs(panel.frame.maxY - top) < 0.1)
assert(panel.frame.width == min(360, screen.frame.width - 16))
picker.highlight(at: firstRow)
// Render the actual dropdown view for visual inspection.
let view = panel.contentView!
view.display()
if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
    view.cacheDisplay(in: view.bounds, to: bitmap)
    try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "/tmp/minimized-windows-picker.png"))
}
picker.release(at: firstRow)
assert(restored == [1], "Release over the row must select exactly once")
picker.release(at: firstRow)
assert(restored == [1], "Repeated release must not restore twice")
show()
picker.release(at: NSPoint(x: screen.frame.minX, y: screen.frame.midY))
assert(restored == [1], "Release outside must cancel")
show()
picker.dismiss()
picker.release(at: firstRow)
assert(restored == [1], "Escape/dismiss must cancel")
picker.show(windows: [], on: screen) { _ in fatalError("Empty row selected") }
picker.release(at: firstRow)
var interaction = MenuBarInteraction()
let start = CGPoint(x: 500, y: 5)
assert(interaction.handle(.rightMouseDown, at: start) == .pass)
assert(interaction.handle(.leftMouseDown, at: start) == .pass)
for type in [CGEventType.leftMouseDown, .leftMouseDragged, .leftMouseUp] {
    assert(interaction.handle(type, at: start, eligible: true) == .pass,
           "Left clicks and drags must pass through even on the menu bar")
}
assert(interaction.handle(.rightMouseDown, at: start, eligible: true) == .openPinned)
assert(interaction.handle(.rightMouseUp, at: start) == .consume)
assert(interaction.handle(.mouseMoved, at: start) == .hover)
assert(interaction.handle(.leftMouseDown, at: start, insidePicker: true) == .update)
assert(interaction.handle(.leftMouseUp, at: start, insidePicker: true) == .select)
assert(interaction.handle(.leftMouseUp, at: start) == .pass)
assert(interaction.handle(.rightMouseDown, at: start, eligible: true) == .openPinned)
assert(interaction.handle(.rightMouseUp, at: start) == .consume)
assert(interaction.handle(.leftMouseDown, at: start) == .cancelAndPass)
assert(interaction.handle(.rightMouseDown, at: start, eligible: true) == .openPinned)
assert(interaction.handle(.rightMouseUp, at: start) == .consume)
assert(interaction.handle(.keyDown, at: start, escape: true) == .cancel)
assert(interaction.handle(.rightMouseDown, at: start, eligible: true) == .openPinned)
assert(interaction.handle(.keyDown, at: start, escape: true) == .cancel)
assert(interaction.handle(.rightMouseUp, at: start) == .consume)
assert(shortenedWindowTitle(fixture.title) == String(fixture.title.prefix(41)) + "…")
let frame = CGRect(x: -1920, y: 900, width: 1920, height: 1080)
for y in [frame.maxY, frame.maxY - 1, frame.maxY - 16, frame.maxY - 32] {
    assert(menuBarContains(CGPoint(x: -960, y: y), frame: frame, height: 32))
}
assert(!menuBarContains(CGPoint(x: -960, y: frame.maxY - 33), frame: frame, height: 32))
assert(!menuBarContains(CGPoint(x: 1, y: frame.maxY), frame: frame, height: 32))
assert(shortenedWindowTitle(fixture.title).count == 42)
assert(shortenedWindowTitle("Short title") == "Short title")
print("PASS: persistent right-click, click selection, outside-click/Escape dismissal, prefix titles, ordinary left-click/drag passthrough, release selection, Escape cancellation, centered dropdown, release selection, repeat protection, outside/dismiss cancellation, empty list, full-height boundaries, title truncation")
