import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings()
        NSApp.setActivationPolicy(settings.hideDockIcon ? .accessory : .regular)
        menuController = StatusMenuController(settings: settings)
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuController?.stop()
    }
}
