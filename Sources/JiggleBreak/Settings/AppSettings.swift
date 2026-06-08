import Foundation

final class AppSettings {
    private enum Key {
        static let reminderEnabled = "reminderEnabled"
        static let reminderIntervalMinutes = "reminderIntervalMinutes"
        static let reminderMessage = "reminderMessage"
        static let reminderBubbleDurationSeconds = "reminderBubbleDurationSeconds"
        static let jigglerEnabled = "jigglerEnabled"
        static let jiggleIntervalSeconds = "jiggleIntervalSeconds"
        static let jiggleDistancePoints = "jiggleDistancePoints"
        static let awakeEnabled = "awakeEnabled"
        static let hideDockIcon = "hideDockIcon"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    var reminderEnabled: Bool {
        get { defaults.bool(forKey: Key.reminderEnabled) }
        set { defaults.set(newValue, forKey: Key.reminderEnabled) }
    }

    var reminderIntervalMinutes: Int {
        get { clamped(defaults.integer(forKey: Key.reminderIntervalMinutes), min: 1, max: 240) }
        set { defaults.set(clamped(newValue, min: 1, max: 240), forKey: Key.reminderIntervalMinutes) }
    }

    var reminderMessage: String {
        get {
            let value = defaults.string(forKey: Key.reminderMessage) ?? Defaults.reminderMessage
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Defaults.reminderMessage : value
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            defaults.set(trimmed.isEmpty ? Defaults.reminderMessage : trimmed, forKey: Key.reminderMessage)
        }
    }

    var reminderBubbleDurationSeconds: Int {
        get { clamped(defaults.integer(forKey: Key.reminderBubbleDurationSeconds), min: 3, max: 120) }
        set { defaults.set(clamped(newValue, min: 3, max: 120), forKey: Key.reminderBubbleDurationSeconds) }
    }

    var jigglerEnabled: Bool {
        get { defaults.bool(forKey: Key.jigglerEnabled) }
        set { defaults.set(newValue, forKey: Key.jigglerEnabled) }
    }

    var jiggleIntervalSeconds: Double {
        get { clamped(defaults.double(forKey: Key.jiggleIntervalSeconds), min: 1, max: 120) }
        set { defaults.set(clamped(newValue, min: 1, max: 120), forKey: Key.jiggleIntervalSeconds) }
    }

    var jiggleDistancePoints: Double {
        get { clamped(defaults.double(forKey: Key.jiggleDistancePoints), min: 0.5, max: 12) }
        set { defaults.set(clamped(newValue, min: 0.5, max: 12), forKey: Key.jiggleDistancePoints) }
    }

    var awakeEnabled: Bool {
        get { defaults.bool(forKey: Key.awakeEnabled) }
        set { defaults.set(newValue, forKey: Key.awakeEnabled) }
    }

    var hideDockIcon: Bool {
        get { defaults.bool(forKey: Key.hideDockIcon) }
        set { defaults.set(newValue, forKey: Key.hideDockIcon) }
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Key.reminderEnabled: false,
            Key.reminderIntervalMinutes: Defaults.reminderIntervalMinutes,
            Key.reminderMessage: Defaults.reminderMessage,
            Key.reminderBubbleDurationSeconds: Defaults.reminderBubbleDurationSeconds,
            Key.jigglerEnabled: false,
            Key.jiggleIntervalSeconds: Defaults.jiggleIntervalSeconds,
            Key.jiggleDistancePoints: Defaults.jiggleDistancePoints,
            Key.awakeEnabled: false,
            Key.hideDockIcon: false
        ])
    }

    private func clamped<T: Comparable>(_ value: T, min lowerBound: T, max upperBound: T) -> T {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

enum Defaults {
    static let reminderIntervalMinutes = 30
    static let reminderMessage = "该活动/休息一下了"
    static let reminderBubbleDurationSeconds = 12
    static let jiggleIntervalSeconds = 15.0
    static let jiggleDistancePoints = 6.0
}
