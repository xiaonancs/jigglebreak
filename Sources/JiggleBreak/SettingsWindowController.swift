import AppKit

final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings, onSave: @escaping () -> Void) {
        let viewController = SettingsViewController(settings: settings, onSave: onSave)
        let window = NSWindow(contentViewController: viewController)
        window.title = "JiggleBreak 设置"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 360))
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

private final class SettingsViewController: NSViewController {
    private let settings: AppSettings
    private let onSave: () -> Void

    private let jiggleIntervalField = NSTextField()
    private let jiggleDistanceField = NSTextField()
    private let awakeCheckbox = NSButton(checkboxWithTitle: "保持系统和显示器唤醒", target: nil, action: nil)
    private let hideDockIconCheckbox = NSButton(checkboxWithTitle: "隐藏 Dock 图标", target: nil, action: nil)
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "开机自动启动", target: nil, action: nil)

    init(settings: AppSettings, onSave: @escaping () -> Void) {
        self.settings = settings
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "设置")
        titleLabel.font = .boldSystemFont(ofSize: 17)

        let grid = NSGridView(views: [
            [label("鼠标微动间隔（秒）"), jiggleIntervalField],
            [label("移动幅度（点）"), jiggleDistanceField],
            [label("保持唤醒"), awakeCheckbox],
            [label("Dock"), hideDockIconCheckbox],
            [label("启动项"), launchAtLoginCheckbox]
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 190

        let saveButton = NSButton(title: "保存", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        let buttonStack = NSStackView(views: [saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .trailing
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [titleLabel, grid, buttonStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -24),
            buttonStack.widthAnchor.constraint(equalTo: grid.widthAnchor)
        ])

        populateFields()
    }

    private func populateFields() {
        jiggleIntervalField.doubleValue = settings.jiggleIntervalSeconds
        jiggleDistanceField.doubleValue = settings.jiggleDistancePoints
        awakeCheckbox.state = settings.awakeEnabled ? .on : .off
        hideDockIconCheckbox.state = settings.hideDockIcon ? .on : .off
        launchAtLoginCheckbox.state = LoginItemManager.isEnabled ? .on : .off
    }

    private func label(_ text: String) -> NSTextField {
        NSTextField(labelWithString: text)
    }

    @objc private func save() {
        settings.jiggleIntervalSeconds = max(1, jiggleIntervalField.doubleValue)
        settings.jiggleDistancePoints = max(0.5, jiggleDistanceField.doubleValue)
        settings.awakeEnabled = awakeCheckbox.state == .on
        settings.hideDockIcon = hideDockIconCheckbox.state == .on
        NSApp.setActivationPolicy(settings.hideDockIcon ? .accessory : .regular)
        do {
            try LoginItemManager.setEnabled(launchAtLoginCheckbox.state == .on)
        } catch {
            presentError(error)
            return
        }
        onSave()
        view.window?.close()
    }
}
