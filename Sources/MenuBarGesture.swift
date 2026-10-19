import Cocoa

/// Shared state machine for menu-bar dragging and a persistent right-click list.
struct MenuBarDrag {
    enum Action: Equatable {
        case pass, consume, replayClick, open(CGPoint), openPinned, update, hover, select, cancel, cancelAndPass
    }
    private enum State {
        case idle, pending(CGPoint), active, rightOpening, latched
        case clicking(CGEventType), cancelled(CGEventType)
    }
    private var state: State = .idle

    mutating func reset() { state = .idle }

    mutating func handle(_ type: CGEventType, at point: CGPoint,
                         eligible: Bool = false, escape: Bool = false,
                         insidePicker: Bool = false) -> Action {
        if type == .keyDown {
            guard escape else { return .pass }
            switch state {
            case .pending, .active: state = .cancelled(.leftMouseUp)
            case .rightOpening: state = .cancelled(.rightMouseUp)
            case .clicking(let up): state = .cancelled(up)
            case .latched: state = .idle
            default: return .pass
            }
            return .cancel
        }
        switch state {
        case .idle:
            guard eligible else { return .pass }
            if type == .rightMouseDown { state = .rightOpening; return .openPinned }
            guard type == .leftMouseDown else { return .pass }
            state = .pending(point)
            return .consume
        case .pending(let start):
            if type == .leftMouseDragged {
                if point.y - start.y >= 8 {
                    state = .active
                    return .open(start)
                }
                return .consume
            }
            if type == .leftMouseUp { state = .idle; return .replayClick }
            return .pass
        case .active:
            if type == .leftMouseDragged { return .update }
            if type == .leftMouseUp { state = .idle; return .select }
            return .pass
        case .rightOpening:
            if type == .rightMouseUp { state = .latched; return .consume }
            return type == .rightMouseDragged ? .consume : .pass
        case .latched:
            if type == .mouseMoved { return .hover }
            if type == .leftMouseDown || type == .rightMouseDown {
                if insidePicker {
                    state = .clicking(type == .leftMouseDown ? .leftMouseUp : .rightMouseUp)
                    return .update
                }
                state = .idle
                return .cancelAndPass
            }
            return .pass
        case .clicking(let up):
            if type == up { state = .idle; return .select }
            if type == .leftMouseDragged || type == .rightMouseDragged { return .update }
            return .pass
        case .cancelled(let up):
            if type == up { state = .idle; return .consume }
            return type == .leftMouseDragged || type == .rightMouseDragged ? .consume : .pass
        }
    }
}

final class MenuBarGesture {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var drag = MenuBarDrag()
    private var pendingDown: CGEvent?
    private static let replayTag: Int64 = 0x4D5744524147
    var containsPicker: ((CGPoint) -> Bool)?
    var onEvent: ((CGEventType, CGPoint) -> Void)?

    @discardableResult
    func start() -> Bool {
        if tap != nil { return true }
        guard AXIsProcessTrusted() else { return false }
        let mask = [CGEventType.leftMouseDown, .leftMouseDragged, .leftMouseUp,
                    .rightMouseDown, .rightMouseDragged, .rightMouseUp, .mouseMoved, .keyDown]
            .reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context = context else { return Unmanaged.passUnretained(event) }
                let gesture = Unmanaged<MenuBarGesture>.fromOpaque(context).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    gesture.finish()
                    DispatchQueue.main.async { gesture.onEvent?(.keyDown, .zero) }
                    if let tap = gesture.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                if event.getIntegerValueField(.eventSourceUserData) == MenuBarGesture.replayTag {
                    return Unmanaged.passUnretained(event)
                }
                let point = event.location
                let eligible = (type == .leftMouseDown || type == .rightMouseDown) && gesture.isMenuBar(at: point)
                let action = gesture.drag.handle(type, at: point, eligible: eligible,
                    escape: event.getIntegerValueField(.keyboardEventKeycode) == 53,
                    insidePicker: gesture.containsPicker?(point) == true)
                switch action {
                case .pass: return Unmanaged.passUnretained(event)
                case .consume:
                    if type == .leftMouseDown { gesture.pendingDown = event.copy() }
                    if type == .leftMouseUp { gesture.pendingDown = nil }
                case .replayClick:
                    if let down = gesture.pendingDown, let up = event.copy() {
                        down.setIntegerValueField(.eventSourceUserData, value: MenuBarGesture.replayTag)
                        up.setIntegerValueField(.eventSourceUserData, value: MenuBarGesture.replayTag)
                        // Replay at the original control, preserving click count and modifiers.
                        up.location = down.location
                        down.post(tap: .cgSessionEventTap)
                        up.post(tap: .cgSessionEventTap)
                    }
                    gesture.pendingDown = nil
                case .open(let start):
                    gesture.pendingDown = nil
                    DispatchQueue.main.async {
                        gesture.onEvent?(.leftMouseDown, start)
                        gesture.onEvent?(.leftMouseDragged, point)
                    }
                case .openPinned:
                    DispatchQueue.main.async { gesture.onEvent?(.rightMouseDown, point) }
                case .update, .hover:
                    DispatchQueue.main.async { gesture.onEvent?(.leftMouseDragged, point) }
                    if action == .hover { return Unmanaged.passUnretained(event) }
                case .select:
                    DispatchQueue.main.async { gesture.onEvent?(.leftMouseUp, point) }
                case .cancel, .cancelAndPass:
                    gesture.pendingDown = nil
                    DispatchQueue.main.async { gesture.onEvent?(.keyDown, point) }
                    if action == .cancelAndPass { return Unmanaged.passUnretained(event) }
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

    func finish() {
        drag.reset()
        pendingDown = nil
    }

    func stop() {
        if let tap = tap { CFMachPortInvalidate(tap) }
        if let source = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
        finish()
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
