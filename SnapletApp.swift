import SwiftUI
import AppKit

@main
struct SnapletApp: App {
    init() {
            _ = AppState.shared   // ✅ starts tracking app activation
        }
    var body: some Scene {
        MenuBarExtra("Snaplet", systemImage: "square.grid.2x2") {
            Button("Settings") {
                SettingsWindowController.shared.show()
            }
            Divider()
            Button("Quit Snaplet") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
