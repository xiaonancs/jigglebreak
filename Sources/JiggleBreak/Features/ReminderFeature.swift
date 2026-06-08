import Foundation

final class ReminderFeature: AppFeature {
    private let settings: AppSettings
    private let onReminder: () -> Void
    private var timer: Timer?

    private(set) var isRunning = false

    init(settings: AppSettings, onReminder: @escaping () -> Void) {
        self.settings = settings
        self.onReminder = onReminder
    }

    func start() {
        stop()
        isRunning = true
        settings.reminderEnabled = true
        scheduleTimer()
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
            settings.reminderEnabled = false
        }
    }

    func restartIfNeeded() {
        guard isRunning else {
            return
        }

        stop()
        start()
    }

    func sendNow() {
        deliverReminder()
    }

    private func scheduleTimer() {
        let interval = TimeInterval(settings.reminderIntervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.deliverReminder()
        }
        timer?.tolerance = min(interval * 0.1, 30)
    }

    private func deliverReminder() {
        DispatchQueue.main.async {
            self.onReminder()
        }
    }
}
