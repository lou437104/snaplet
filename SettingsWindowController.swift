import AppKit
import SwiftUI

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        // If it already exists, just bring it to the front
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Snaplet Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: settingsView)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
