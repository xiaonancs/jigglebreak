import Foundation
import XCTest
@testable import JiggleBreak

final class ReminderTests: XCTestCase {
    func testInitClampsOutOfRangeValues() {
        let reminder = Reminder(
            intervalSeconds: 0,
            weekday: 99,
            hour: 48,
            minute: -5,
            durationSeconds: 999
        )

        XCTAssertEqual(reminder.intervalSeconds, 1)
        XCTAssertEqual(reminder.weekday, 7)
        XCTAssertEqual(reminder.hour, 23)
        XCTAssertEqual(reminder.minute, 0)
        XCTAssertEqual(reminder.durationSeconds, 120)
    }

    func testResolvedMessageFallsBackToDefault() {
        let reminder = Reminder(message: "   ")
        XCTAssertEqual(reminder.resolvedMessage, Defaults.reminderMessage)
    }

    func testFormattedIntervalChoosesReadableUnit() {
        XCTAssertEqual(Reminder(intervalSeconds: 45).formattedInterval, "45 秒")
        XCTAssertEqual(Reminder(intervalSeconds: 600).formattedInterval, "10 分钟")
        XCTAssertEqual(Reminder(intervalSeconds: 7200).formattedInterval, "2 小时")
        XCTAssertEqual(Reminder(intervalSeconds: 90).formattedInterval, "90 秒")
    }

    func testWeeklySummaryFormatting() {
        let reminder = Reminder(
            message: "喝水",
            type: .weekly,
            weekday: 2,
            hour: 9,
            minute: 5
        )
        XCTAssertEqual(reminder.summary, "周一 09:05 · 喝水")
    }

    func testNextFireDateMatchesWeekdayAndTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))

        // 2026-06-08 是周一。
        let reference = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 8, hour: 12, minute: 0))
        )

        // 下一个周三 09:30。
        let reminder = Reminder(type: .weekly, weekday: 4, hour: 9, minute: 30)
        let next = try XCTUnwrap(reminder.nextFireDate(after: reference, calendar: calendar))

        let components = calendar.dateComponents([.weekday, .hour, .minute], from: next)
        XCTAssertEqual(components.weekday, 4)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 30)
        XCTAssertGreaterThan(next, reference)
    }

    func testNextFireDateRollsToNextWeekWhenTimePassed() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))

        // 周一 12:00，目标是周一 09:00（已过），应排到下周一。
        let reference = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 8, hour: 12, minute: 0))
        )
        let reminder = Reminder(type: .weekly, weekday: 2, hour: 9, minute: 0)
        let next = try XCTUnwrap(reminder.nextFireDate(after: reference, calendar: calendar))

        let days = try XCTUnwrap(calendar.dateComponents([.day], from: reference, to: next).day)
        XCTAssertEqual(days, 6) // 6 天后的周一 09:00（再过约 21 小时到第 7 天）
        let components = calendar.dateComponents([.weekday, .hour], from: next)
        XCTAssertEqual(components.weekday, 2)
        XCTAssertEqual(components.hour, 9)
    }

    func testCodableRoundTrip() throws {
        let reminder = Reminder(
            enabled: false,
            message: "站起来走走",
            type: .weekly,
            intervalSeconds: 1800,
            weekday: 6,
            hour: 18,
            minute: 45,
            colorHex: "#FF3B30",
            style: .banner,
            durationSeconds: 20
        )

        let data = try JSONEncoder().encode(reminder)
        let decoded = try JSONDecoder().decode(Reminder.self, from: data)

        XCTAssertEqual(decoded, reminder)
    }
}
