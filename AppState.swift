import AppKit
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var lastAppName: String = "None"
    private(set) var lastNonSnapletPID: pid_t?

    private init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func appActivated(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

        // Ignore Snaplet itself
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return }

        lastNonSnapletPID = app.processIdentifier
        lastAppName = app.localizedName ?? "Unknown App"
    }
}
