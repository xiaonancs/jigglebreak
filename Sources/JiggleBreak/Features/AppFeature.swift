import Foundation

protocol AppFeature: AnyObject {
    var isRunning: Bool { get }

    func start()
    func stop()
}
