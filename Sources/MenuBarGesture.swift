import Cocoa

/// A click opens on release; a held drag opens while the button is still down.
struct MenuBarInteraction {
    enum Action: Equatable { case pass, consume, open, openHeld }
    private var awaitingRelease = false

    mutating func reset() { awaitingRelease = false }

    mutating func handle(_ type: CGEventType, eligible: Bool = false) -> Action {
        if awaitingRelease {
            if type == .rightMouseUp { awaitingRelease = false; return .open }
            if type == .rightMouseDragged { awaitingRelease = false; return .openHeld }
        }
        if type == .rightMouseDown, eligible {
            awaitingRelease = true
            return .consume
        }
        return .pass
    }
}

final class MenuBarGesture {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var interaction = MenuBarInteraction()
    private var openingPoint = CGPoint.zero
    private var trackingMenu = false
    private var selectingWhileHeld = false
    var onHeldRelease: (() -> Void)?
    var onOpen: ((CGPoint) -> Void)?

    @discardableResult
    func start() -> Bool {
        if tap != nil { return true }
        guard AXIsProcessTrusted() else { return false }
        let mask = [CGEventType.rightMouseDown, .rightMouseDragged, .rightMouseUp]
            .reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context = context else { return Unmanaged.passUnretained(event) }
                let gesture = Unmanaged<MenuBarGesture>.fromOpaque(context).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    gesture.interaction.reset()
                    if let tap = gesture.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                // Native tracking handles motion and ordinary clicks. Only the
                // opening held gesture needs an explicit release action.
                if gesture.trackingMenu {
                    if gesture.selectingWhileHeld && type == .rightMouseUp {
                        gesture.selectingWhileHeld = false
                        // The menu is running a nested tracking loop inside the
                        // main-queue open callback. Use that run loop rather than
                        // queueing behind the still-blocked main-queue callback.
                        RunLoop.main.perform(inModes: [.eventTracking, .common]) {
                            gesture.onHeldRelease?()
                        }
                        return nil
                    }
                    return Unmanaged.passUnretained(event)
                }
                let eligible = type == .rightMouseDown && gesture.isMenuBar(at: event.location)
                switch gesture.interaction.handle(type, eligible: eligible) {
                case .pass: return Unmanaged.passUnretained(event)
                case .consume:
                    if type == .rightMouseDown { gesture.openingPoint = event.location }
                case .open, .openHeld:
                    gesture.selectingWhileHeld = type == .rightMouseDragged
                    let point = gesture.openingPoint
                    gesture.trackingMenu = true
                    DispatchQueue.main.async {
                        gesture.onOpen?(point)
                        gesture.trackingMenu = false
                        gesture.selectingWhileHeld = false
                    }
                }
                return nil
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = tap { CFMachPortInvalidate(tap) }
        if let source = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
        interaction.reset()
    }

    private func isMenuBar(at point: CGPoint) -> Bool {
        guard NSMenu.menuBarVisible(), let primary = NSScreen.screens.first else { return false }
        let cocoaPoint = CGPoint(x: point.x, y: primary.frame.maxY - point.y)
        return NSScreen.screens.contains {
            menuBarContains(cocoaPoint, frame: $0.frame, height: menuBarHeight($0))
        }
    }

    deinit { stop() }
}

func menuBarHeight(_ screen: NSScreen) -> CGFloat {
    let inset = screen.frame.maxY - screen.visibleFrame.maxY
    return max(NSStatusBar.system.thickness, screen.safeAreaInsets.top,
               inset <= 64 ? inset : 0)
}

func menuBarContains(_ point: CGPoint, frame: CGRect, height: CGFloat) -> Bool {
    point.x >= frame.minX && point.x < frame.maxX &&
    point.y <= frame.maxY && point.y >= frame.maxY - height
}
