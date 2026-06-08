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

    private func makeSettings() -> AppSettings {
        let suiteName = "local.jigglebreak.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return AppSettings(defaults: defaults)
    }
}
