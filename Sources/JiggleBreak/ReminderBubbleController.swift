import AppKit

final class ReminderBubbleController {
    private weak var statusItem: NSStatusItem?
    private let settings: AppSettings
    private var panel: NSPanel?
    private var bubbleView: ReminderBubbleView?
    private var timer: Timer?
    private var startedAt = Date()
    private var duration: TimeInterval = TimeInterval(Defaults.reminderBubbleDurationSeconds)

    init(statusItem: NSStatusItem, settings: AppSettings) {
        self.statusItem = statusItem
        self.settings = settings
    }

    func show() {
        timer?.invalidate()

        duration = TimeInterval(settings.reminderBubbleDurationSeconds)
        startedAt = Date()

        let view = ReminderBubbleView(frame: NSRect(x: 0, y: 0, width: 330, height: 46))
        view.message = settings.reminderMessage
        view.remainingSeconds = Int(duration.rounded())
        view.progress = 1
        view.onClose = { [weak self] in
            self?.close()
        }
        bubbleView = view

        let newPanel = NSPanel(
            contentRect: view.bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        newPanel.contentView = view
        newPanel.setFrameOrigin(panelOrigin(for: view.bounds.size))
        newPanel.orderFrontRegardless()
        panel = newPanel

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func close() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel = nil
        bubbleView = nil
    }

    private func tick() {
        let elapsed = Date().timeIntervalSince(startedAt)
        let remaining = max(0, duration - elapsed)

        bubbleView?.remainingSeconds = Int(ceil(remaining))
        bubbleView?.progress = duration == 0 ? 0 : remaining / duration

        if remaining <= 0 {
            close()
        }
    }

    private func panelOrigin(for size: NSSize) -> NSPoint {
        let screenFrame = (NSScreen.screens.first ?? NSScreen.main)?.visibleFrame ?? .zero
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.maxY - size.height - 12
        return NSPoint(x: x, y: y)
    }
}

private final class ReminderBubbleView: NSView {
    private let closeButton = NSButton()

    var message = "" {
        didSet { needsDisplay = true }
    }

    var remainingSeconds = Defaults.reminderBubbleDurationSeconds {
        didSet { needsDisplay = true }
    }

    var progress: Double = 1 {
        didSet { needsDisplay = true }
    }

    var onClose: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureCloseButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var isFlipped: Bool {
        true
    }

    override func layout() {
        super.layout()
        closeButton.frame = NSRect(x: bounds.maxX - 32, y: 12, width: 20, height: 20)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bodyRect = bounds.insetBy(dx: 6, dy: 5)
        let path = NSBezierPath(roundedRect: bodyRect, xRadius: 12, yRadius: 12)

        NSColor.windowBackgroundColor.withAlphaComponent(0.96).setFill()
        path.fill()

        NSColor.separatorColor.withAlphaComponent(0.35).setStroke()
        path.lineWidth = 1
        path.stroke()

        drawText(in: bodyRect)
        drawProgress(in: bodyRect)
    }

    private func configureCloseButton() {
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "关闭")
        closeButton.image?.isTemplate = true
        closeButton.contentTintColor = .tertiaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(close)
        addSubview(closeButton)
    }

    private func drawText(in rect: NSRect) {
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.controlAccentColor
        ]

        NSString(string: message).draw(
            in: NSRect(x: rect.minX + 14, y: rect.minY + 9, width: rect.width - 124, height: 18),
            withAttributes: bodyAttributes
        )
        NSString(string: formattedTime(remainingSeconds)).draw(
            in: NSRect(x: rect.maxX - 94, y: rect.minY + 9, width: 56, height: 18),
            withAttributes: timeAttributes
        )
    }

    private func drawProgress(in rect: NSRect) {
        let trackRect = NSRect(x: rect.minX + 14, y: rect.maxY - 9, width: rect.width - 28, height: 3)
        let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: 1.5, yRadius: 1.5)
        NSColor.quaternaryLabelColor.setFill()
        trackPath.fill()

        let fillWidth = max(0, min(trackRect.width, trackRect.width * progress))
        let fillRect = NSRect(x: trackRect.minX, y: trackRect.minY, width: fillWidth, height: trackRect.height)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 3, yRadius: 3)
        NSColor.controlAccentColor.setFill()
        fillPath.fill()
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }

    @objc private func close() {
        onClose?()
    }
}
