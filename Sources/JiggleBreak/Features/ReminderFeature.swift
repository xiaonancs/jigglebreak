import Foundation

final class ReminderFeature: AppFeature {
    private let settings: AppSettings
    private let onReminder: (Reminder) -> Void
    private var timers: [Timer] = []

    private(set) var isRunning = false

    init(settings: AppSettings, onReminder: @escaping (Reminder) -> Void) {
        self.settings = settings
        self.onReminder = onReminder
    }

    func start() {
        stop()
        isRunning = true
        settings.reminderEnabled = true
        scheduleAll()
    }

    func stop() {
        stop(persistEnabled: true)
    }

    func suspend() {
        stop(persistEnabled: false)
    }

    private func stop(persistEnabled: Bool) {
        timers.forEach { $0.invalidate() }
        timers.removeAll()
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

    /// 立即触发一次提醒（用于菜单的“立即提醒一次”/预览）。
    func sendNow(_ reminder: Reminder? = nil) {
        let target = reminder ?? settings.enabledReminders.first ?? settings.reminders.first ?? Reminder()
        deliver(target)
    }

    private func scheduleAll() {
        for reminder in settings.enabledReminders {
            switch reminder.type {
            case .interval:
                scheduleInterval(reminder)
            case .weekly:
                scheduleWeekly(reminder)
            }
        }
    }

    private func scheduleInterval(_ reminder: Reminder) {
        let interval = TimeInterval(max(1, reminder.intervalSeconds))
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.deliver(reminder)
        }
        timer.tolerance = min(interval * 0.1, 30)
        timers.append(timer)
    }

    private func scheduleWeekly(_ reminder: Reminder) {
        guard let fireDate = reminder.nextFireDate(after: Date()) else {
            return
        }

        let delay = max(1, fireDate.timeIntervalSinceNow)
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] firedTimer in
            guard let self else { return }
            self.timers.removeAll { $0 === firedTimer }
            self.deliver(reminder)
            // 触发后重新排程到下一周的同一时间。
            if self.isRunning {
                self.scheduleWeekly(reminder)
            }
        }
        timer.tolerance = min(delay * 0.05, 60)
        timers.append(timer)
    }

    private func deliver(_ reminder: Reminder) {
        DispatchQueue.main.async {
            self.onReminder(reminder)
        }
    }
}
