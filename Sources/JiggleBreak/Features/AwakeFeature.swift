import Foundation
import IOKit.pwr_mgt

final class AwakeFeature: AppFeature {
    private let settings: AppSettings
    private var assertionIDs: [IOPMAssertionID] = []

    private(set) var isRunning = false
    private(set) var lastError: String?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        stop(persistEnabled: false)
        lastError = nil

        let reason = "JiggleBreak keeps the Mac awake while enabled" as CFString
        let assertionTypes = [
            kIOPMAssertionTypeNoIdleSleep,
            kIOPMAssertionTypeNoDisplaySleep
        ]

        for assertionType in assertionTypes {
            var assertionID = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                assertionType as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &assertionID
            )

            if result == kIOReturnSuccess {
                assertionIDs.append(assertionID)
            } else {
                lastError = "保持唤醒失败：\(result)"
            }
        }

        isRunning = !assertionIDs.isEmpty
        settings.awakeEnabled = isRunning
    }

    func stop() {
        stop(persistEnabled: true)
    }

    func suspend() {
        stop(persistEnabled: false)
    }

    private func stop(persistEnabled: Bool) {
        for assertionID in assertionIDs {
            IOPMAssertionRelease(assertionID)
        }
        assertionIDs.removeAll()
        isRunning = false

        if persistEnabled {
            settings.awakeEnabled = false
        }
    }
}
