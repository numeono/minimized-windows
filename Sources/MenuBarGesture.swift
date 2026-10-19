import Cocoa

/// Opens a persistent list on right-click; ordinary left-button input passes through.
struct MenuBarInteraction {
    enum Action: Equatable {
        case pass, consume, openPinned, update, hover, select, cancel, cancelAndPass
    }
    private enum State {
        case idle, rightOpening, latched
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
            case .rightOpening: state = .cancelled(.rightMouseUp)
            case .clicking(let up): state = .cancelled(up)
            case .latched: state = .idle
            default: return .pass
            }
            return .cancel
        }
        switch state {
        case .idle:
            guard type == .rightMouseDown, eligible else { return .pass }
            state = .rightOpening
            return .openPinned
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
    private var interaction = MenuBarInteraction()
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
                let point = event.location
                let eligible = type == .rightMouseDown && gesture.isMenuBar(at: point)
                let action = gesture.interaction.handle(type, at: point, eligible: eligible,
                    escape: event.getIntegerValueField(.keyboardEventKeycode) == 53,
                    insidePicker: gesture.containsPicker?(point) == true)
                switch action {
                case .pass: return Unmanaged.passUnretained(event)
                case .consume: break
                case .openPinned:
                    DispatchQueue.main.async { gesture.onEvent?(.rightMouseDown, point) }
                case .update, .hover:
                    DispatchQueue.main.async { gesture.onEvent?(.leftMouseDragged, point) }
                    if action == .hover { return Unmanaged.passUnretained(event) }
                case .select:
                    DispatchQueue.main.async { gesture.onEvent?(.leftMouseUp, point) }
                case .cancel, .cancelAndPass:
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
        interaction.reset()
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
