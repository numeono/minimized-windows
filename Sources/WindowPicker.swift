import Cocoa

func shortenedWindowTitle(_ title: String) -> String {
    guard title.count > 42 else { return title }
    return String(title.prefix(41)) + "…"
}

/// A nonactivating dropdown with explicit release selection. It does not depend
/// on NSMenu receiving a synthetic mouse-down in an invisible window.
final class WindowPicker {
    var isVisible: Bool { panel?.isVisible == true }
    private var panel: NSPanel?
    private var rows: PickerRows?
    private var selection: ((WindowInfo) -> Void)?

    func show(windows: [WindowInfo], on screen: NSScreen, selection: @escaping (WindowInfo) -> Void) {
        dismiss()
        self.selection = selection
        let width = min(CGFloat(360), screen.frame.width - 16)
        let top = screen.frame.maxY - menuBarHeight(screen)
        let height = min(CGFloat(max(1, windows.count) + 1) * 30 + 12,
                         top - screen.visibleFrame.minY - 8)
        let panel = NSPanel(contentRect: NSRect(x: screen.frame.midX - width / 2,
            y: top - height, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        let background = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        background.material = .menu
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 7
        background.layer?.masksToBounds = true
        let scroll = NSScrollView(frame: background.bounds.insetBy(dx: 0, dy: 6))
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        let rows = PickerRows(windows: windows, width: width)
        scroll.documentView = rows
        background.addSubview(scroll)
        panel.contentView = background
        self.panel = panel
        self.rows = rows
        panel.orderFrontRegardless()
    }

    func contains(_ point: NSPoint) -> Bool { panel?.frame.contains(point) == true }

    func highlight(at screenPoint: NSPoint) {
        rows?.selected = row(at: screenPoint)
    }

    func release(at screenPoint: NSPoint) {
        let index = row(at: screenPoint)
        let windows = rows?.windows ?? []
        let callback = selection
        let quit = index == max(1, windows.count)
        dismiss()
        if let index = index, windows.indices.contains(index) { callback?(windows[index]) }
        else if quit { NSApp.terminate(nil) }
    }

    private func row(at point: NSPoint) -> Int? {
        guard let panel = panel, let rows = rows, panel.frame.contains(point),
              let clip = rows.superview else { return nil }
        let local = rows.convert(panel.convertPoint(fromScreen: point), from: nil)
        guard rows.visibleRect.contains(local), clip.bounds.contains(clip.convert(local, from: rows)) else { return nil }
        let index = Int(local.y / 30)
        guard index >= 0, index <= max(1, rows.windows.count),
              !rows.windows.isEmpty || index != 0 else { return nil }
        return index
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        rows = nil
        selection = nil
    }
}

private final class PickerRows: NSView {
    let windows: [WindowInfo]
    var selected: Int? { didSet { needsDisplay = true } }
    override var isFlipped: Bool { true }

    init(windows: [WindowInfo], width: CGFloat) {
        self.windows = windows
        super.init(frame: NSRect(x: 0, y: 0, width: width,
                                height: CGFloat(max(1, windows.count) + 1) * 30))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        for index in 0...max(1, windows.count) {
            let row = NSRect(x: 5, y: CGFloat(index) * 30, width: bounds.width - 10, height: 30)
            let highlighted = selected == index
            if highlighted {
                NSColor.selectedContentBackgroundColor.setFill()
                NSBezierPath(roundedRect: row, xRadius: 4, yRadius: 4).fill()
            }
            let isWindow = windows.indices.contains(index)
            let title = isWindow ? shortenedWindowTitle(windows[index].title) :
                (index == 0 ? "No minimized windows" : "Quit")
            if isWindow {
                let icon = windows[index].appIcon ?? NSImage(named: NSImage.applicationIconName)
                icon?.draw(in: NSRect(x: 13, y: row.minY + 6, width: 18, height: 18),
                           from: .zero, operation: .sourceOver, fraction: 1,
                           respectFlipped: true, hints: nil)
            }
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byTruncatingTail
            let color: NSColor = highlighted ? .alternateSelectedControlTextColor : .labelColor
            (title as NSString).draw(in: NSRect(x: 40, y: row.minY + 7,
                width: bounds.width - 57, height: 18), withAttributes: [
                    .font: NSFont.menuFont(ofSize: 13), .foregroundColor: color,
                    .paragraphStyle: paragraph
                ])
        }
    }
}
