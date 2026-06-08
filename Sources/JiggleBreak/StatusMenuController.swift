import AppKit

final class StatusMenuController: NSObject {
    private let statusItem: NSStatusItem
    private let settings: AppSettings
    private let reminderFeature: ReminderFeature
    private let mouseJigglerFeature: MouseJigglerFeature
    private let awakeFeature: AwakeFeature
    private let reminderBubbleController: ReminderBubbleController
    private var settingsWindowController: SettingsWindowController?
    private var remindersWindowController: RemindersWindowController?
    private var loginItemError: String?
    private var accessibilityWarning: String?

    init(settings: AppSettings) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let bubbleController = ReminderBubbleController(statusItem: statusItem, settings: settings)

        self.statusItem = statusItem
        self.settings = settings
        self.reminderBubbleController = bubbleController
        self.reminderFeature = ReminderFeature(settings: settings) { reminder in
            bubbleController.show(reminder)
        }
        self.mouseJigglerFeature = MouseJigglerFeature(settings: settings)
        self.awakeFeature = AwakeFeature(settings: settings)
        super.init()

        configureStatusItem()
        rebuildMenu()
        restoreEnabledFeatures()
    }

    func stop() {
        reminderFeature.suspend()
        mouseJigglerFeature.suspend()
        awakeFeature.suspend()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.motionlines", accessibilityDescription: "JiggleBreak")
            button.image?.isTemplate = true
            button.toolTip = "JiggleBreak"
        }
    }

    private func restoreEnabledFeatures() {
        let shouldRestoreReminder = settings.reminderEnabled
        let shouldRestoreJiggler = settings.jigglerEnabled
        let shouldRestoreAwake = settings.awakeEnabled

        if shouldRestoreReminder {
            reminderFeature.start()
        }

        if shouldRestoreAwake {
            awakeFeature.start()
        }

        if shouldRestoreJiggler {
            mouseJigglerFeature.start()
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "JiggleBreak", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        let reminderTitle = reminderFeature.isRunning ? "停止定时提醒" : "开启定时提醒"
        let reminderItem = NSMenuItem(title: reminderTitle, action: #selector(toggleReminder), keyEquivalent: "r")
        reminderItem.target = self
        menu.addItem(reminderItem)

        let testReminderItem = NSMenuItem(title: "立即提醒一次", action: #selector(sendReminderNow), keyEquivalent: "")
        testReminderItem.target = self
        menu.addItem(testReminderItem)

        let jigglerTitle = mouseJigglerFeature.isRunning ? "停止鼠标微动" : "开启鼠标微动"
        let jigglerItem = NSMenuItem(title: jigglerTitle, action: #selector(toggleJiggler), keyEquivalent: "j")
        jigglerItem.target = self
        menu.addItem(jigglerItem)

        let awakeTitle = awakeFeature.isRunning ? "停止保持唤醒" : "开启保持唤醒"
        let awakeItem = NSMenuItem(title: awakeTitle, action: #selector(toggleAwake), keyEquivalent: "a")
        awakeItem.target = self
        menu.addItem(awakeItem)

        if let awakeError = awakeFeature.lastError {
            let errorItem = NSMenuItem(title: awakeError, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        if let accessibilityWarning {
            let warningItem = NSMenuItem(title: accessibilityWarning, action: nil, keyEquivalent: "")
            warningItem.isEnabled = false
            menu.addItem(warningItem)
        }

        menu.addItem(.separator())

        let manageRemindersItem = NSMenuItem(title: "管理提醒", action: #selector(openReminders), keyEquivalent: "")
        manageRemindersItem.target = self
        menu.addItem(manageRemindersItem)

        let settingsItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let dockItem = NSMenuItem(title: "隐藏 Dock 图标", action: #selector(toggleDockIcon), keyEquivalent: "")
        dockItem.target = self
        dockItem.state = settings.hideDockIcon ? .on : .off
        menu.addItem(dockItem)

        let loginItem = NSMenuItem(title: "开机自动启动", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        if let loginItemError {
            let errorItem = NSMenuItem(title: "自启动设置失败：\(loginItemError)", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        let permissionItem = NSMenuItem(title: "打开辅助功能权限设置", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleReminder() {
        if reminderFeature.isRunning {
            reminderFeature.stop()
        } else {
            reminderFeature.start()
        }
        rebuildMenu()
    }

    @objc private func sendReminderNow() {
        reminderFeature.sendNow()
    }

    @objc private func toggleJiggler() {
        if mouseJigglerFeature.isRunning {
            mouseJigglerFeature.stop()
            accessibilityWarning = nil
        } else {
            mouseJigglerFeature.start()
            accessibilityWarning = AccessibilityPermission.isTrusted ? nil : "辅助功能未确认：已用系统光标移动兜底"
        }
        rebuildMenu()
    }

    @objc private func toggleAwake() {
        if awakeFeature.isRunning {
            awakeFeature.stop()
        } else {
            awakeFeature.start()
        }
        rebuildMenu()
    }

    @objc private func openReminders() {
        if remindersWindowController == nil {
            remindersWindowController = RemindersWindowController(
                settings: settings,
                onSave: { [weak self] in
                    self?.reminderFeature.restartIfNeeded()
                    self?.rebuildMenu()
                },
                onPreview: { [weak self] reminder in
                    self?.reminderBubbleController.show(reminder)
                }
            )
        }

        remindersWindowController?.showWindow(nil)
        remindersWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settings: settings) { [weak self] in
                self?.reminderFeature.restartIfNeeded()
                self?.mouseJigglerFeature.restartIfNeeded()
                if self?.settings.awakeEnabled == true {
                    self?.awakeFeature.start()
                } else {
                    self?.awakeFeature.stop()
                }
                self?.rebuildMenu()
            }
        }

        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAccessibilitySettings() {
        AccessibilityPermission.openSettings()
    }

    @objc private func toggleDockIcon() {
        settings.hideDockIcon.toggle()
        NSApp.setActivationPolicy(settings.hideDockIcon ? .accessory : .regular)
        rebuildMenu()
    }

    @objc private func toggleLoginItem() {
        do {
            try LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
