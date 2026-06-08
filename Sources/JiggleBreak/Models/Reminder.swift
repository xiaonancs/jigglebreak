import Foundation

enum ReminderType: String, Codable, CaseIterable {
    case interval
    case weekly

    var displayName: String {
        switch self {
        case .interval: return "按间隔重复"
        case .weekly: return "每周定时"
        }
    }
}

enum ReminderStyle: String, Codable, CaseIterable {
    case card
    case banner
    case outline

    var displayName: String {
        switch self {
        case .card: return "卡片"
        case .banner: return "彩色横幅"
        case .outline: return "描边"
        }
    }
}

struct Reminder: Codable, Equatable, Identifiable {
    var id: UUID
    var enabled: Bool
    var message: String
    var type: ReminderType
    var intervalSeconds: Int
    /// 1 = Sunday ... 7 = Saturday（与 Calendar 的 weekday 一致）
    var weekday: Int
    var hour: Int
    var minute: Int
    var colorHex: String
    var style: ReminderStyle
    var durationSeconds: Int

    init(
        id: UUID = UUID(),
        enabled: Bool = true,
        message: String = Defaults.reminderMessage,
        type: ReminderType = .interval,
        intervalSeconds: Int = Defaults.reminderIntervalMinutes * 60,
        weekday: Int = 2,
        hour: Int = 9,
        minute: Int = 0,
        colorHex: String = Defaults.reminderColorHex,
        style: ReminderStyle = .card,
        durationSeconds: Int = Defaults.reminderBubbleDurationSeconds
    ) {
        self.id = id
        self.enabled = enabled
        self.message = message
        self.type = type
        self.intervalSeconds = Reminder.clampInterval(intervalSeconds)
        self.weekday = Reminder.clampWeekday(weekday)
        self.hour = Reminder.clamp(hour, min: 0, max: 23)
        self.minute = Reminder.clamp(minute, min: 0, max: 59)
        self.colorHex = colorHex
        self.style = style
        self.durationSeconds = Reminder.clamp(durationSeconds, min: 3, max: 120)
    }

    static let weekdaySymbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    var resolvedMessage: String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Defaults.reminderMessage : trimmed
    }

    var weekdaySymbol: String {
        let index = weekday - 1
        guard index >= 0, index < Reminder.weekdaySymbols.count else { return "周一" }
        return Reminder.weekdaySymbols[index]
    }

    var formattedInterval: String {
        if intervalSeconds >= 3600, intervalSeconds % 3600 == 0 {
            return "\(intervalSeconds / 3600) 小时"
        }
        if intervalSeconds >= 60, intervalSeconds % 60 == 0 {
            return "\(intervalSeconds / 60) 分钟"
        }
        return "\(intervalSeconds) 秒"
    }

    var summary: String {
        switch type {
        case .interval:
            return "每 \(formattedInterval) · \(resolvedMessage)"
        case .weekly:
            return String(format: "%@ %02d:%02d · %@", weekdaySymbol, hour, minute, resolvedMessage)
        }
    }

    /// 计算下一次触发时间（仅对每周定时有意义）。
    func nextFireDate(after date: Date, calendar: Calendar = .current) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }

    private static func clampInterval(_ value: Int) -> Int {
        clamp(value, min: 1, max: 24 * 60 * 60)
    }

    private static func clampWeekday(_ value: Int) -> Int {
        clamp(value, min: 1, max: 7)
    }

    private static func clamp(_ value: Int, min lowerBound: Int, max upperBound: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
