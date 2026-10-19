import Cocoa
import ServiceManagement

// MARK: - Minimization timestamps

var minimizeTimestamps: [CGWindowID: Date] = [:]

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var pendingUpdate: ReleaseUpdate?
    private var updateAlert: NSAlert?
    private var updateURL: URL?
    private var accessAlert: NSAlert?
    private var enabledAlert: NSAlert?
    private let enabledNoticeKey = "hasAcknowledgedMenuBarSetup"
    private var alertHasAccessibility: Bool?
    private let gesture = MenuBarGesture()
    private let windowPicker = WindowPicker()
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        gesture.onOpen = { [weak self] point in self?.showWindowMenu(at: point) }
        gesture.onHeldRelease = { [weak self] in self?.windowPicker.releaseHeldGesture() }
        updateGestureAvailability()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        UpdateChecker.check(currentVersion: version) { [weak self] update in
            self?.pendingUpdate = update
            self?.showUpdateIfReady()
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordNewlyMinimized()
            self?.updateGestureAvailability()
            self?.showUpdateIfReady()
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
            showEnabledNoticeIfNeeded()
        } else {
            enabledAlert?.window.orderOut(nil)
            enabledAlert = nil
            showAccessSetup()
        }
    }

    private func showUpdateIfReady() {
        guard let update = pendingUpdate, accessAlert == nil, enabledAlert == nil,
              windowPicker.menu == nil, updateAlert == nil else { return }
        pendingUpdate = nil
        updateURL = update.url
        let alert = makeUpdateAlert(version: update.version)
        alert.buttons[0].target = self
        alert.buttons[0].action = #selector(viewUpdate)
        alert.buttons[1].target = self
        alert.buttons[1].action = #selector(dismissUpdate)
        updateAlert = alert
        alert.window.center()
        NSApp.activate(ignoringOtherApps: true)
        alert.window.makeKeyAndOrderFront(nil)
    }

    @objc private func viewUpdate() {
        if let url = updateURL { NSWorkspace.shared.open(url) }
        dismissUpdate()
    }

    @objc private func dismissUpdate() {
        updateAlert?.window.orderOut(nil)
        updateAlert = nil
        updateURL = nil
    }

    private func showEnabledNoticeIfNeeded() {
        guard enabledAlert == nil, !UserDefaults.standard.bool(forKey: enabledNoticeKey) else { return }
        let alert = makeEnabledAlert()
        alert.buttons[0].target = self
        alert.buttons[0].action = #selector(dismissEnabledNotice)
        enabledAlert = alert
        alert.window.center()
        NSApp.activate(ignoringOtherApps: true)
        alert.window.makeKeyAndOrderFront(nil)
    }

    @objc private func dismissEnabledNotice() {
        enabledAlert?.window.orderOut(nil)
        enabledAlert = nil
        UserDefaults.standard.set(true, forKey: enabledNoticeKey)
    }

    private func showAccessSetup() {
        let trusted = AXIsProcessTrusted()
        guard accessAlert == nil || alertHasAccessibility != trusted else { return }
        accessAlert?.window.orderOut(nil)
        let alert = makeAccessSetupAlert(trusted: trusted)
        let settings = alert.buttons[0]
        settings.target = self
        settings.action = #selector(openAccessibilitySettings)
        let quit = alert.buttons[1]
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

/// NSAlert normally lays out during modal presentation. This setup window is
/// modeless so it can close when permission changes, so layout must be explicit.
func makeAccessSetupAlert(trusted: Bool) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = trusted ? "Menu-bar access could not start" : "Allow Accessibility access"
    alert.informativeText = trusted
        ? "Minimized Windows cannot listen for menu-bar clicks yet. It will keep retrying. If this continues, quit and reopen the app."
        : "Open System Settings → Privacy & Security → Accessibility and enable Minimized Windows. If it is missing, use the + button to add this app. This window closes automatically when access is ready."
    alert.showsHelp = false
    alert.showsSuppressionButton = false
    alert.addButton(withTitle: "Open Accessibility Settings")
    alert.addButton(withTitle: "Quit")
    alert.layout()
    return alert
}

func makeEnabledAlert() -> NSAlert {
    let alert = NSAlert()
    alert.messageText = "Successfully enabled"
    alert.informativeText = "Right-click in the middle of the menu bar to see your minimized windows. Click a window in the list to restore it."
    alert.showsHelp = false
    alert.showsSuppressionButton = false
    alert.addButton(withTitle: "Got it")
    alert.layout()
    return alert
}

func makeUpdateAlert(version: String) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = "Update available"
    alert.informativeText = "Minimized Windows \(version) is available. Open the GitHub release page to download the update."
    alert.showsHelp = false
    alert.showsSuppressionButton = false
    alert.addButton(withTitle: "View Update")
    alert.addButton(withTitle: "Later")
    alert.layout()
    return alert
}
