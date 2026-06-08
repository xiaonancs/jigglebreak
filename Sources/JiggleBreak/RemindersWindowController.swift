import AppKit

final class RemindersWindowController: NSWindowController {
    init(settings: AppSettings, onSave: @escaping () -> Void, onPreview: @escaping (Reminder) -> Void) {
        let viewController = RemindersViewController(settings: settings, onSave: onSave, onPreview: onPreview)
        let window = NSWindow(contentViewController: viewController)
        window.title = "提醒管理"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 620, height: 460))
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

private final class RemindersViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let settings: AppSettings
    private let onSave: () -> Void
    private let onPreview: (Reminder) -> Void

    private var reminders: [Reminder]
    private var editingIndex: Int?

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    private let enabledCheckbox = NSButton(checkboxWithTitle: "启用此提醒", target: nil, action: nil)
    private let messageField = NSTextField()
    private let typePopup = NSPopUpButton()

    private let intervalValueField = NSTextField()
    private let intervalUnitPopup = NSPopUpButton()
    private lazy var intervalRow = formRow("间隔", control: intervalControlStack())

    private let weekdayPopup = NSPopUpButton()
    private let hourField = NSTextField()
    private let minuteField = NSTextField()
    private lazy var weeklyRow = formRow("时间", control: weeklyControlStack())

    private let colorWell = NSColorWell()
    private let stylePopup = NSPopUpButton()
    private let durationField = NSTextField()
    private let previewButton = NSButton(title: "预览", target: nil, action: nil)

    private let editorStack = NSStackView()
    private let emptyHintLabel = NSTextField(labelWithString: "请选择左侧的提醒，或点击 + 新增")

    private let intervalUnits: [(title: String, multiplier: Int)] = [
        ("秒", 1), ("分钟", 60), ("小时", 3600)
    ]

    init(settings: AppSettings, onSave: @escaping () -> Void, onPreview: @escaping (Reminder) -> Void) {
        self.settings = settings
        self.onSave = onSave
        self.onPreview = onPreview
        self.reminders = settings.reminders
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = NSView()

        configureTable()
        configureEditor()

        let addRemoveControl = NSSegmentedControl(
            labels: ["+", "−"],
            trackingMode: .momentary,
            target: self,
            action: #selector(addOrRemove(_:))
        )
        addRemoveControl.segmentStyle = .smallSquare
        addRemoveControl.translatesAutoresizingMaskIntoConstraints = false

        let leftStack = NSStackView(views: [scrollView, addRemoveControl])
        leftStack.orientation = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 8
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        let saveButton = NSButton(title: "保存", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"

        let buttonStack = NSStackView(views: [NSView(), cancelButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 10
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let rightContainer = NSView()
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addSubview(editorStack)
        rightContainer.addSubview(emptyHintLabel)
        emptyHintLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyHintLabel.textColor = .secondaryLabelColor

        let columns = NSStackView(views: [leftStack, rightContainer])
        columns.orientation = .horizontal
        columns.alignment = .top
        columns.spacing = 18
        columns.translatesAutoresizingMaskIntoConstraints = false

        let root = NSStackView(views: [columns, buttonStack])
        root.orientation = .vertical
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            buttonStack.widthAnchor.constraint(equalTo: root.widthAnchor),

            scrollView.widthAnchor.constraint(equalToConstant: 210),
            scrollView.heightAnchor.constraint(equalToConstant: 340),
            leftStack.heightAnchor.constraint(equalTo: columns.heightAnchor),

            rightContainer.widthAnchor.constraint(equalToConstant: 320),

            editorStack.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            editorStack.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            editorStack.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),

            emptyHintLabel.centerXAnchor.constraint(equalTo: rightContainer.centerXAnchor),
            emptyHintLabel.topAnchor.constraint(equalTo: rightContainer.topAnchor, constant: 24)
        ])

        tableView.reloadData()
        if !reminders.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
        loadEditorFromSelection()
    }

    // MARK: - Table

    private func configureTable() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("reminder"))
        column.width = 200
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 38
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAutomaticRowHeights = false
        tableView.style = .inset

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        reminders.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let reminder = reminders[row]

        let toggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleEnabled(_:)))
        toggle.tag = row
        toggle.state = reminder.enabled ? .on : .off

        let swatch = NSView()
        swatch.wantsLayer = true
        swatch.layer?.backgroundColor = (NSColor(hex: reminder.colorHex) ?? .controlAccentColor).cgColor
        swatch.layer?.cornerRadius = 6
        swatch.translatesAutoresizingMaskIntoConstraints = false
        swatch.widthAnchor.constraint(equalToConstant: 12).isActive = true
        swatch.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let label = NSTextField(labelWithString: reminder.summary)
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 12)
        label.textColor = reminder.enabled ? .labelColor : .tertiaryLabelColor

        let stack = NSStackView(views: [toggle, swatch, label])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        return stack
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        commitEditor()
        loadEditorFromSelection()
    }

    // MARK: - Editor build

    private func configureEditor() {
        ReminderType.allCases.forEach { typePopup.addItem(withTitle: $0.displayName) }
        typePopup.target = self
        typePopup.action = #selector(typeChanged)

        intervalUnits.forEach { intervalUnitPopup.addItem(withTitle: $0.title) }
        intervalValueField.alignment = .right
        setNumberWidth(intervalValueField, 70)

        for symbol in Reminder.weekdaySymbols {
            weekdayPopup.addItem(withTitle: symbol)
        }
        setNumberWidth(hourField, 44)
        setNumberWidth(minuteField, 44)
        hourField.alignment = .center
        minuteField.alignment = .center

        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.widthAnchor.constraint(equalToConstant: 60).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 24).isActive = true

        ReminderStyle.allCases.forEach { stylePopup.addItem(withTitle: $0.displayName) }
        setNumberWidth(durationField, 60)

        previewButton.target = self
        previewButton.action = #selector(preview)
        previewButton.bezelStyle = .rounded

        messageField.placeholderString = Defaults.reminderMessage
        messageField.translatesAutoresizingMaskIntoConstraints = false
        messageField.widthAnchor.constraint(equalToConstant: 230).isActive = true

        editorStack.orientation = .vertical
        editorStack.alignment = .leading
        editorStack.spacing = 12
        editorStack.translatesAutoresizingMaskIntoConstraints = false
        editorStack.setViews([
            enabledCheckbox,
            formRow("提醒内容", control: messageField),
            formRow("触发方式", control: typePopup),
            intervalRow,
            weeklyRow,
            formRow("颜色", control: colorWell),
            formRow("样式", control: stylePopup),
            formRow("显示时长", control: durationControlStack()),
            previewButton
        ], in: .leading)
    }

    private func intervalControlStack() -> NSView {
        let stack = NSStackView(views: [intervalValueField, intervalUnitPopup])
        stack.orientation = .horizontal
        stack.spacing = 8
        return stack
    }

    private func weeklyControlStack() -> NSView {
        let colon = NSTextField(labelWithString: ":")
        let stack = NSStackView(views: [weekdayPopup, hourField, colon, minuteField])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        return stack
    }

    private func durationControlStack() -> NSView {
        let unit = NSTextField(labelWithString: "秒")
        let stack = NSStackView(views: [durationField, unit])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        return stack
    }

    private func formRow(_ title: String, control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 70).isActive = true

        let stack = NSStackView(views: [label, control])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 10
        return stack
    }

    private func setNumberWidth(_ field: NSTextField, _ width: CGFloat) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    // MARK: - Editor <-> model

    private var selectedIndex: Int? {
        let row = tableView.selectedRow
        return reminders.indices.contains(row) ? row : nil
    }

    private func loadEditorFromSelection() {
        guard let index = selectedIndex else {
            editingIndex = nil
            editorStack.isHidden = true
            emptyHintLabel.isHidden = false
            return
        }

        editorStack.isHidden = false
        emptyHintLabel.isHidden = true

        let reminder = reminders[index]
        enabledCheckbox.state = reminder.enabled ? .on : .off
        messageField.stringValue = reminder.message
        typePopup.selectItem(at: ReminderType.allCases.firstIndex(of: reminder.type) ?? 0)

        let (value, unitIndex) = decomposeInterval(reminder.intervalSeconds)
        intervalValueField.integerValue = value
        intervalUnitPopup.selectItem(at: unitIndex)

        weekdayPopup.selectItem(at: max(0, reminder.weekday - 1))
        hourField.integerValue = reminder.hour
        minuteField.integerValue = reminder.minute

        colorWell.color = NSColor(hex: reminder.colorHex) ?? .controlAccentColor
        stylePopup.selectItem(at: ReminderStyle.allCases.firstIndex(of: reminder.style) ?? 0)
        durationField.integerValue = reminder.durationSeconds

        updateTypeRowVisibility(for: reminder.type)
        editingIndex = index
    }

    private func commitEditor() {
        guard let index = editingIndex, reminders.indices.contains(index) else { return }
        reminders[index] = reminderFromEditor(base: reminders[index])
    }

    private func reminderFromEditor(base: Reminder) -> Reminder {
        let type = ReminderType.allCases[safe: typePopup.indexOfSelectedItem] ?? .interval
        let unit = intervalUnits[safe: intervalUnitPopup.indexOfSelectedItem]?.multiplier ?? 1
        let intervalSeconds = max(1, intervalValueField.integerValue) * unit
        let style = ReminderStyle.allCases[safe: stylePopup.indexOfSelectedItem] ?? .card

        return Reminder(
            id: base.id,
            enabled: enabledCheckbox.state == .on,
            message: messageField.stringValue,
            type: type,
            intervalSeconds: intervalSeconds,
            weekday: weekdayPopup.indexOfSelectedItem + 1,
            hour: hourField.integerValue,
            minute: minuteField.integerValue,
            colorHex: colorWell.color.hexString,
            style: style,
            durationSeconds: durationField.integerValue
        )
    }

    private func decomposeInterval(_ seconds: Int) -> (value: Int, unitIndex: Int) {
        if seconds >= 3600, seconds % 3600 == 0 { return (seconds / 3600, 2) }
        if seconds >= 60, seconds % 60 == 0 { return (seconds / 60, 1) }
        return (seconds, 0)
    }

    private func updateTypeRowVisibility(for type: ReminderType) {
        intervalRow.isHidden = type != .interval
        weeklyRow.isHidden = type != .weekly
    }

    // MARK: - Actions

    @objc private func typeChanged() {
        let type = ReminderType.allCases[safe: typePopup.indexOfSelectedItem] ?? .interval
        updateTypeRowVisibility(for: type)
    }

    @objc private func toggleEnabled(_ sender: NSButton) {
        guard reminders.indices.contains(sender.tag) else { return }
        reminders[sender.tag].enabled = sender.state == .on
        if sender.tag == selectedIndex {
            enabledCheckbox.state = sender.state
        }
        reloadRow(sender.tag)
    }

    @objc private func addOrRemove(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            commitEditor()
            editingIndex = nil
            reminders.append(Reminder())
            tableView.reloadData()
            let newIndex = reminders.count - 1
            tableView.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
            loadEditorFromSelection()
        } else {
            guard let index = selectedIndex else { return }
            editingIndex = nil
            reminders.remove(at: index)
            tableView.reloadData()
            let newSelection = min(index, reminders.count - 1)
            if reminders.indices.contains(newSelection) {
                tableView.selectRowIndexes(IndexSet(integer: newSelection), byExtendingSelection: false)
            }
            loadEditorFromSelection()
        }
    }

    @objc private func preview() {
        guard let index = selectedIndex else { return }
        commitEditor()
        onPreview(reminders[index])
    }

    @objc private func save() {
        commitEditor()
        settings.reminders = reminders
        onSave()
        view.window?.close()
    }

    @objc private func cancel() {
        view.window?.close()
    }

    private func reloadRow(_ row: Int) {
        guard reminders.indices.contains(row) else { return }
        tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
