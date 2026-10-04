import Cocoa
import ServiceManagement

// MARK: - Icon

func makeDiamondIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    let scale = size / 1024.0
    ctx.scaleBy(x: scale, y: -scale)
    ctx.translateBy(x: 0, y: -1024)
    NSColor.labelColor.setFill()
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 488.38, y: 134.33))
    path.addCurve(to: CGPoint(x: 544.15, y: 140.80), control1: CGPoint(x: 504.58, y: 120.22), control2: CGPoint(x: 531.79, y: 124.20))
    path.addCurve(to: CGPoint(x: 623.64, y: 243.57), control1: CGPoint(x: 570.01, y: 175.52), control2: CGPoint(x: 597.03, y: 209.39))
    path.addCurve(to: CGPoint(x: 731.17, y: 381.52), control1: CGPoint(x: 659.45, y: 289.57), control2: CGPoint(x: 695.34, y: 335.52))
    path.addCurve(to: CGPoint(x: 805.48, y: 476.93), control1: CGPoint(x: 755.94, y: 413.33), control2: CGPoint(x: 780.52, y: 445.28))
    path.addCurve(to: CGPoint(x: 817.47, y: 503.20), control1: CGPoint(x: 811.72, y: 484.84), control2: CGPoint(x: 816.70, y: 492.90))
    path.addCurve(to: CGPoint(x: 809.24, y: 531.23), control1: CGPoint(x: 818.25, y: 513.64), control2: CGPoint(x: 815.66, y: 522.98))
    path.addCurve(to: CGPoint(x: 737.99, y: 622.65), control1: CGPoint(x: 785.50, y: 561.71), control2: CGPoint(x: 761.76, y: 592.19))
    path.addCurve(to: CGPoint(x: 603.63, y: 794.79), control1: CGPoint(x: 693.22, y: 680.04), control2: CGPoint(x: 648.45, y: 737.44))
    path.addCurve(to: CGPoint(x: 543.14, y: 871.79), control1: CGPoint(x: 583.53, y: 820.51), control2: CGPoint(x: 563.42, y: 846.22))
    path.addCurve(to: CGPoint(x: 483.18, y: 871.72), control1: CGPoint(x: 527.78, y: 891.16), control2: CGPoint(x: 498.56, y: 891.17))
    path.addCurve(to: CGPoint(x: 416.33, y: 786.32), control1: CGPoint(x: 460.75, y: 843.37), control2: CGPoint(x: 438.59, y: 814.81))
    path.addCurve(to: CGPoint(x: 320.67, y: 663.82), control1: CGPoint(x: 384.44, y: 745.49), control2: CGPoint(x: 352.56, y: 704.66))
    path.addCurve(to: CGPoint(x: 216.43, y: 530.26), control1: CGPoint(x: 285.92, y: 619.30), control2: CGPoint(x: 251.13, y: 574.81))
    path.addCurve(to: CGPoint(x: 216.97, y: 481.94), control1: CGPoint(x: 205.59, y: 516.34), control2: CGPoint(x: 206.08, y: 495.89))
    path.addCurve(to: CGPoint(x: 316.41, y: 354.19), control1: CGPoint(x: 250.18, y: 439.41), control2: CGPoint(x: 283.26, y: 396.77))
    path.addCurve(to: CGPoint(x: 387.68, y: 262.75), control1: CGPoint(x: 340.15, y: 323.70), control2: CGPoint(x: 363.96, y: 293.26))
    path.addCurve(to: CGPoint(x: 461.86, y: 167.25), control1: CGPoint(x: 412.42, y: 230.93), control2: CGPoint(x: 436.95, y: 198.94))
    path.addCurve(to: CGPoint(x: 488.38, y: 134.33), control1: CGPoint(x: 470.49, y: 156.27), control2: CGPoint(x: 478.28, y: 144.59))
    path.closeSubpath()
    path.move(to: CGPoint(x: 612.92, y: 354.55))
    path.addCurve(to: CGPoint(x: 513.33, y: 226.26), control1: CGPoint(x: 579.84, y: 311.95), control2: CGPoint(x: 546.77, y: 269.35))
    path.addCurve(to: CGPoint(x: 502.13, y: 240.26), control1: CGPoint(x: 509.35, y: 231.23), control2: CGPoint(x: 505.66, y: 235.68))
    path.addCurve(to: CGPoint(x: 449.91, y: 307.88), control1: CGPoint(x: 484.70, y: 262.78), control2: CGPoint(x: 467.37, y: 285.38))
    path.addCurve(to: CGPoint(x: 377.77, y: 400.53), control1: CGPoint(x: 425.90, y: 338.80), control2: CGPoint(x: 401.76, y: 369.61))
    path.addCurve(to: CGPoint(x: 298.51, y: 502.84), control1: CGPoint(x: 351.33, y: 434.62), control2: CGPoint(x: 325.06, y: 468.84))
    path.addCurve(to: CGPoint(x: 298.58, y: 510.82), control1: CGPoint(x: 295.99, y: 506.08), control2: CGPoint(x: 296.24, y: 507.88))
    path.addCurve(to: CGPoint(x: 345.73, y: 571.02), control1: CGPoint(x: 314.39, y: 530.81), control2: CGPoint(x: 330.04, y: 550.93))
    path.addCurve(to: CGPoint(x: 502.34, y: 771.47), control1: CGPoint(x: 397.93, y: 637.84), control2: CGPoint(x: 450.11, y: 704.68))
    path.addCurve(to: CGPoint(x: 513.12, y: 784.25), control1: CGPoint(x: 505.79, y: 775.89), control2: CGPoint(x: 508.99, y: 780.57))
    path.addCurve(to: CGPoint(x: 517.25, y: 780.22), control1: CGPoint(x: 515.38, y: 783.41), control2: CGPoint(x: 516.16, y: 781.62))
    path.addCurve(to: CGPoint(x: 614.23, y: 655.61), control1: CGPoint(x: 549.59, y: 738.69), control2: CGPoint(x: 581.82, y: 697.08))
    path.addCurve(to: CGPoint(x: 721.18, y: 519.12), control1: CGPoint(x: 649.81, y: 610.06), control2: CGPoint(x: 685.57, y: 564.65))
    path.addCurve(to: CGPoint(x: 729.68, y: 506.63), control1: CGPoint(x: 724.33, y: 515.09), control2: CGPoint(x: 729.72, y: 511.35))
    path.addCurve(to: CGPoint(x: 721.20, y: 494.10), control1: CGPoint(x: 729.64, y: 501.94), control2: CGPoint(x: 724.34, y: 498.15))
    path.addCurve(to: CGPoint(x: 612.92, y: 354.55), control1: CGPoint(x: 685.31, y: 447.73), control2: CGPoint(x: 649.32, y: 401.43))
    path.closeSubpath()
    ctx.addPath(path)
    ctx.fillPath(using: .evenOdd)
    image.unlockFocus()
    image.isTemplate = true
    return image
}

// MARK: - Minimization timestamps

var minimizeTimestamps: [CGWindowID: Date] = [:]

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = makeDiamondIcon(size: 18)
        }
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordNewlyMinimized()
        }
        recordNewlyMinimized()
        registerLoginItem()
    }

    private func recordNewlyMinimized() {
        var seen = Set<CGWindowID>()
        forEachMinimizedWindow { _, axWindow in
            var cgWID = CGWindowID(0)
            guard _AXUIElementGetWindow(axWindow, &cgWID) == .success else { return }
            seen.insert(cgWID)
            if minimizeTimestamps[cgWID] == nil {
                minimizeTimestamps[cgWID] = Date()
            }
        }
        minimizeTimestamps = minimizeTimestamps.filter { seen.contains($0.key) }
    }

    private func buildMenu() {
        menu.removeAllItems()
        let windows = getMinimizedWindows()

        if windows.isEmpty {
            let item = NSMenuItem(title: "No minimized windows", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for info in windows {
                let item = NSMenuItem(title: info.title, action: #selector(unminimizeWindow(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = info
                if let icon = info.appIcon {
                    item.image = resizeImage(icon, to: NSSize(width: 16, height: 16))
                }
                menu.addItem(item)
            }
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func unminimizeWindow(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? WindowInfo else { return }
        AXUIElementSetAttributeValue(info.axWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef)
        minimizeTimestamps.removeValue(forKey: info.cgWindowID)
        NSRunningApplication(processIdentifier: info.pid)?.activate()
    }

    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let out = NSImage(size: size)
        out.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .sourceOver, fraction: 1.0)
        out.unlockFocus()
        return out
    }

    private func registerLoginItem() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        } else {
            SMLoginItemSetEnabled(Bundle.main.bundleIdentifier! as CFString, true)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        recordNewlyMinimized()
        buildMenu()
    }
}

// MARK: - Window Info

struct WindowInfo {
    let pid: pid_t
    let cgWindowID: CGWindowID
    let axWindow: AXUIElement
    let title: String
    let appIcon: NSImage?
    let minimizedAt: Date
}

// MARK: - Window detection
// Uses kAXMinimizedWindowsAttribute — the dedicated attribute for minimized windows.
// On modern macOS, minimized windows are removed from kAXWindowsAttribute,
// which is why checking kAXMinimizedAttribute on each window always returned false.

func forEachMinimizedWindow(_ body: (NSRunningApplication, AXUIElement) -> Void) {
    let apps = NSWorkspace.shared.runningApplications.filter {
        $0.activationPolicy == .regular && !$0.isTerminated
    }

    for app in apps {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        // Primary: kAXMinimizedWindowsAttribute — specifically lists minimized windows
        var minWinsRef: CFTypeRef?
        let minResult = AXUIElementCopyAttributeValue(axApp, "AXMinimizedWindows" as CFString, &minWinsRef)

        if minResult == .success, let minWindows = minWinsRef as? [AXUIElement], !minWindows.isEmpty {
            for axWindow in minWindows {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
                body(app, axWindow)
            }
            continue
        }

        // Fallback: scan kAXWindowsAttribute and check kAXMinimizedAttribute on each
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindows = windowsRef as? [AXUIElement] else { continue }

        for axWindow in axWindows {
            var minRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minRef) == .success,
                  let isMin = minRef as? Bool, isMin else { continue }
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
            body(app, axWindow)
        }
    }
}

func getMinimizedWindows() -> [WindowInfo] {
    var result: [WindowInfo] = []
    forEachMinimizedWindow { app, axWindow in
        var cgWID = CGWindowID(0)
        _ = _AXUIElementGetWindow(axWindow, &cgWID)
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
        let title = (titleRef as? String) ?? ""
        let display = title.isEmpty ? (app.localizedName ?? "Untitled") : title
        result.append(WindowInfo(
            pid: app.processIdentifier,
            cgWindowID: cgWID,
            axWindow: axWindow,
            title: display,
            appIcon: app.icon,
            minimizedAt: minimizeTimestamps[cgWID] ?? Date.distantPast
        ))
    }
    return result.sorted { $0.minimizedAt > $1.minimizedAt }
}
