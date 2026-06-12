import AppKit
import CoreGraphics
import Foundation

final class MouseJigglerFeature: AppFeature {
    private let settings: AppSettings
    private let onPermissionStatusChanged: (Bool) -> Void
    private var timer: Timer?
    private var direction: CGFloat = 1

    private(set) var isRunning = false

    init(settings: AppSettings, onPermissionStatusChanged: @escaping (Bool) -> Void = { _ in }) {
        self.settings = settings
        self.onPermissionStatusChanged = onPermissionStatusChanged
    }

    func start() {
        stop()
        isRunning = true
        settings.jigglerEnabled = true
        onPermissionStatusChanged(AccessibilityPermission.isTrusted)
        scheduleTimer()
        jiggleOnce()
    }

    func stop() {
        stop(persistEnabled: true)
    }

    func suspend() {
        stop(persistEnabled: false)
    }

    private func stop(persistEnabled: Bool) {
        timer?.invalidate()
        timer = nil
        isRunning = false

        if persistEnabled {
            settings.jigglerEnabled = false
        }
    }

    func restartIfNeeded() {
        guard isRunning else {
            return
        }

        stop()
        start()
    }

    func jiggleOnce() {
        guard let event = CGEvent(source: nil) else {
            return
        }

        let current = event.location
        let next = nextCursorPosition(from: current)
        direction *= -1

        CGWarpMouseCursorPosition(next)

        // The warp moves the cursor; posting a matching event makes more apps notice it
        // when Accessibility has been granted.
        let movedEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: next,
            mouseButton: .left
        )
        if AccessibilityPermission.isTrusted {
            movedEvent?.post(tap: .cghidEventTap)
        }
    }

    private func nextCursorPosition(from current: CGPoint) -> CGPoint {
        let distance = CGFloat(settings.jiggleDistancePoints)
        let visibleFrame = NSScreen.screens
            .first { $0.frame.contains(current) }?
            .visibleFrame ?? NSScreen.main?.visibleFrame

        guard let frame = visibleFrame else {
            return CGPoint(x: current.x + distance * direction, y: current.y)
        }

        let insetFrame = frame.insetBy(dx: 2, dy: 2)
        let primary = CGPoint(x: current.x + distance * direction, y: current.y)
        let clampedPrimary = primary.clamped(to: insetFrame)
        if clampedPrimary != current {
            return clampedPrimary
        }

        return CGPoint(x: current.x - distance * direction, y: current.y).clamped(to: insetFrame)
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: settings.jiggleIntervalSeconds, repeats: true) { [weak self] _ in
            self?.jiggleOnce()
        }
        timer?.tolerance = min(settings.jiggleIntervalSeconds * 0.1, 2)
    }
}

private extension CGPoint {
    func clamped(to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(x, rect.minX), rect.maxX),
            y: min(max(y, rect.minY), rect.maxY)
        )
    }
}
