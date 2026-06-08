import Foundation
import XCTest
@testable import JiggleBreak

final class AppSettingsTests: XCTestCase {
    func testDefaultsAreRegistered() {
        let settings = makeSettings()

        XCTAssertEqual(settings.reminderIntervalMinutes, Defaults.reminderIntervalMinutes)
        XCTAssertEqual(settings.reminderMessage, Defaults.reminderMessage)
        XCTAssertEqual(settings.jiggleIntervalSeconds, Defaults.jiggleIntervalSeconds)
        XCTAssertEqual(settings.jiggleDistancePoints, Defaults.jiggleDistancePoints)
    }

    func testIntervalValuesAreClamped() {
        let settings = makeSettings()

        settings.reminderIntervalMinutes = 0
        settings.jiggleIntervalSeconds = 0
        settings.jiggleDistancePoints = 0

        XCTAssertEqual(settings.reminderIntervalMinutes, 1)
        XCTAssertEqual(settings.jiggleIntervalSeconds, 1)
        XCTAssertEqual(settings.jiggleDistancePoints, 0.5)
    }

    func testBlankReminderMessageFallsBackToDefault() {
        let settings = makeSettings()

        settings.reminderMessage = "   "

        XCTAssertEqual(settings.reminderMessage, Defaults.reminderMessage)
    }

    func testRemindersMigratesFromLegacySingleReminder() {
        let settings = makeSettings()

        settings.reminderIntervalMinutes = 20
        settings.reminderMessage = "起来走走"
        settings.reminderBubbleDurationSeconds = 15

        let reminders = settings.reminders
        XCTAssertEqual(reminders.count, 1)
        let first = reminders[0]
        XCTAssertEqual(first.type, .interval)
        XCTAssertEqual(first.intervalSeconds, 20 * 60)
        XCTAssertEqual(first.message, "起来走走")
        XCTAssertEqual(first.durationSeconds, 15)
    }

    func testRemindersPersistAndRoundTrip() {
        let settings = makeSettings()

        let custom = [
            Reminder(message: "喝水", type: .interval, intervalSeconds: 90),
            Reminder(message: "周会", type: .weekly, weekday: 4, hour: 10, minute: 0, style: .banner)
        ]
        settings.reminders = custom

        XCTAssertEqual(settings.reminders, custom)
        XCTAssertEqual(settings.enabledReminders.count, 2)
    }

    private func makeSettings() -> AppSettings {
        let suiteName = "local.jigglebreak.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return AppSettings(defaults: defaults)
    }
}
