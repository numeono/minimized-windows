import Cocoa

func shortenedWindowTitle(_ title: String) -> String {
    guard title.count > 42 else { return title }
    return String(title.prefix(41)) + "…"
}

/// AppKit supplies the menu material, corner treatment, typography, and tracking.
final class WindowPicker: NSObject {
    private(set) var menu: NSMenu?
    private var selection: ((WindowInfo) -> Void)?

    func show(windows: [WindowInfo], on screen: NSScreen, at point: NSPoint, selection: @escaping (WindowInfo) -> Void) {
        dismiss()
        self.selection = selection
        let menu = makeMenu(windows: windows)
        self.menu = menu
        menu.popUp(positioning: nil, at: menuOrigin(size: menu.size, screen: screen, point: point), in: nil)
        self.menu = nil
        self.selection = nil
    }

    func makeMenu(windows: [WindowInfo]) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.minimumWidth = 360
        if windows.isEmpty {
            let item = NSMenuItem(title: "No minimized windows", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        for window in windows {
            let item = NSMenuItem(title: shortenedWindowTitle(window.title),
                                  action: #selector(chooseWindow(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = window
            item.toolTip = window.title
            let icon = (window.appIcon ?? NSImage(named: NSImage.applicationIconName))?.copy() as? NSImage
            icon?.size = NSSize(width: 16, height: 16)
            item.image = icon
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        return menu
    }

    func menuOrigin(size: NSSize, screen: NSScreen, point: NSPoint) -> NSPoint {
        // Center beneath the click, but keep the menu on the clicked display.
        let x = min(max(point.x - size.width / 2, screen.frame.minX + 4),
                    max(screen.frame.minX + 4, screen.frame.maxX - size.width - 4))
        return NSPoint(x: x, y: point.y - 4)
    }

    @objc private func chooseWindow(_ sender: NSMenuItem) {
        guard let window = sender.representedObject as? WindowInfo else { return }
        selection?(window)
    }

    func dismiss() { menu?.cancelTracking() }
}
