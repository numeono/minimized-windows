import Cocoa
import ServiceManagement

// MARK: - Minimization timestamps

var minimizeTimestamps: [CGWindowID: Date] = [:]

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var accessAlert: NSAlert?
    private var alertHasAccessibility: Bool?
    private let gesture = MenuBarGesture()
    private let windowPicker = WindowPicker()
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        gesture.onOpen = { [weak self] point in self?.showWindowMenu(at: point) }
        updateGestureAvailability()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordNewlyMinimized()
            self?.updateGestureAvailability()
        }
        recordNewlyMinimized()
        registerLoginItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        gesture.stop()
        windowPicker.dismiss()
        pollTimer?.invalidate()
    }

    private func updateGestureAvailability() {
        if !AXIsProcessTrusted() {
            gesture.stop()
            windowPicker.dismiss()
        }
        if gesture.start() {
            accessAlert?.window.orderOut(nil)
            accessAlert = nil
            alertHasAccessibility = nil
        } else {
            showAccessSetup()
        }
    }

    private func showAccessSetup() {
        let trusted = AXIsProcessTrusted()
        guard accessAlert == nil || alertHasAccessibility != trusted else { return }
        accessAlert?.window.orderOut(nil)
        let alert = NSAlert()
        alert.messageText = trusted ? "Menu-bar access could not start" : "Allow Accessibility access"
        alert.informativeText = trusted
            ? "Minimized Windows cannot listen for menu-bar clicks yet. It will keep retrying. If this continues, quit and reopen the app."
            : "Open System Settings → Privacy & Security → Accessibility and enable Minimized Windows. If it is missing, use the + button to add this app. This window closes automatically when access is ready."
        let settings = alert.addButton(withTitle: "Open Accessibility Settings")
        settings.target = self
        settings.action = #selector(openAccessibilitySettings)
        let quit = alert.addButton(withTitle: "Quit")
        quit.target = NSApp
        quit.action = #selector(NSApplication.terminate(_:))
        accessAlert = alert
        alertHasAccessibility = trusted
        alert.window.center()
        NSApp.activate(ignoringOtherApps: true)
        alert.window.makeKeyAndOrderFront(nil)
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func showWindowMenu(at point: CGPoint) {
        guard let primary = NSScreen.screens.first else { return }
        let location = NSPoint(x: point.x, y: primary.frame.maxY - point.y)
        guard let screen = NSScreen.screens.first(where: {
            location.x >= $0.frame.minX && location.x < $0.frame.maxX &&
            location.y >= $0.frame.minY && location.y <= $0.frame.maxY
        }) else { return }
        recordNewlyMinimized()
        windowPicker.show(windows: getMinimizedWindows(), on: screen, at: location) { [weak self] info in
            self?.restoreWindow(info)
        }
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

    private func restoreWindow(_ info: WindowInfo) {
        guard AXUIElementSetAttributeValue(info.axWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef) == .success else { return }
        AXUIElementPerformAction(info.axWindow, kAXRaiseAction as CFString)
        minimizeTimestamps.removeValue(forKey: info.cgWindowID)
        NSRunningApplication(processIdentifier: info.pid)?.activate()
    }

    private func registerLoginItem() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        } else {
            SMLoginItemSetEnabled(Bundle.main.bundleIdentifier! as CFString, true)
        }
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
