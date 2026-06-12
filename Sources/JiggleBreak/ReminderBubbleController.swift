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

    func show(_ reminder: Reminder) {
        timer?.invalidate()
        close()

        duration = TimeInterval(reminder.durationSeconds)
        startedAt = Date()

        let viewSize = ReminderBubbleView.preferredSize(for: reminder.resolvedMessage)
        let view = ReminderBubbleView(frame: NSRect(origin: .zero, size: viewSize))
        view.message = reminder.resolvedMessage
        view.accentColor = NSColor(hex: reminder.colorHex) ?? .controlAccentColor
        view.style = reminder.style
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
    private enum Layout {
        static let minWidth: CGFloat = 330
        static let maxWidth: CGFloat = 460
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 14
        static let timeWidth: CGFloat = 56
        static let closeWidth: CGFloat = 20
        static let controlGap: CGFloat = 18
        static let progressHeight: CGFloat = 3
        static let progressTopGap: CGFloat = 8
        static let cornerRadius: CGFloat = 12
    }

    private let closeButton = NSButton()

    var message = "" {
        didSet { needsDisplay = true }
    }

    var accentColor: NSColor = .controlAccentColor {
        didSet { needsDisplay = true }
    }

    var style: ReminderStyle = .card {
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
        closeButton.frame = NSRect(x: bounds.maxX - 32, y: 12, width: Layout.closeWidth, height: Layout.closeWidth)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bodyRect = bounds.insetBy(dx: 6, dy: 5)
        let path = NSBezierPath(roundedRect: bodyRect, xRadius: Layout.cornerRadius, yRadius: Layout.cornerRadius)

        switch style {
        case .card:
            NSColor.windowBackgroundColor.withAlphaComponent(0.96).setFill()
            path.fill()
            accentColor.withAlphaComponent(0.35).setStroke()
            path.lineWidth = 1
            path.stroke()
        case .banner:
            accentColor.setFill()
            path.fill()
        case .outline:
            NSColor.windowBackgroundColor.withAlphaComponent(0.98).setFill()
            path.fill()
            accentColor.setStroke()
            path.lineWidth = 2
            path.stroke()
        }

        drawText(in: bodyRect)
        drawProgress(in: bodyRect)
    }

    private var bodyTextColor: NSColor {
        switch style {
        case .banner: return accentColor.readableForeground
        case .card, .outline: return .labelColor
        }
    }

    private var timeTextColor: NSColor {
        switch style {
        case .banner: return accentColor.readableForeground.withAlphaComponent(0.9)
        case .card, .outline: return accentColor
        }
    }

    private var progressFillColor: NSColor {
        switch style {
        case .banner: return accentColor.readableForeground.withAlphaComponent(0.9)
        case .card, .outline: return accentColor
        }
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
            .foregroundColor: bodyTextColor,
            .paragraphStyle: bodyParagraphStyle
        ]
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: timeTextColor
        ]

        let textRect = NSRect(
            x: rect.minX + Layout.horizontalPadding,
            y: rect.minY + 9,
            width: messageWidth(in: rect),
            height: rect.height - Layout.verticalPadding - Layout.progressTopGap - Layout.progressHeight
        )
        NSString(string: message).draw(
            in: textRect,
            withAttributes: bodyAttributes
        )
        NSString(string: formattedTime(remainingSeconds)).draw(
            in: NSRect(x: rect.maxX - 94, y: rect.minY + 9, width: 56, height: 18),
            withAttributes: timeAttributes
        )
    }

    private func drawProgress(in rect: NSRect) {
        let trackRect = NSRect(
            x: rect.minX + Layout.horizontalPadding,
            y: rect.maxY - 9,
            width: rect.width - Layout.horizontalPadding * 2,
            height: Layout.progressHeight
        )
        let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: 1.5, yRadius: 1.5)
        let trackColor: NSColor = style == .banner
            ? accentColor.readableForeground.withAlphaComponent(0.25)
            : .quaternaryLabelColor
        trackColor.setFill()
        trackPath.fill()

        let fillWidth = max(0, min(trackRect.width, trackRect.width * progress))
        let fillRect = NSRect(x: trackRect.minX, y: trackRect.minY, width: fillWidth, height: trackRect.height)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 3, yRadius: 3)
        progressFillColor.setFill()
        fillPath.fill()
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }

    static func preferredSize(for message: String) -> NSSize {
        let maxTextWidth = Layout.maxWidth
            - Layout.horizontalPadding * 2
            - Layout.timeWidth
            - Layout.closeWidth
            - Layout.controlGap * 2
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
        let textHeight = NSString(string: message).boundingRect(
            with: NSSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        ).height

        let width = Layout.maxWidth
        let height = max(
            46,
            ceil(textHeight) + Layout.verticalPadding * 2 + Layout.progressTopGap + Layout.progressHeight
        )
        return NSSize(width: max(Layout.minWidth, width), height: min(height, 116))
    }

    private var bodyParagraphStyle: NSParagraphStyle {
        Self.paragraphStyle
    }

    private static var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.maximumLineHeight = 17
        style.lineSpacing = 1
        return style
    }

    private func messageWidth(in rect: NSRect) -> CGFloat {
        rect.width
            - Layout.horizontalPadding * 2
            - Layout.timeWidth
            - Layout.closeWidth
            - Layout.controlGap * 2
    }

    @objc private func close() {
        onClose?()
    }
}
