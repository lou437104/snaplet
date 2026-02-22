import SwiftUI

struct SettingsView: View {
    @StateObject private var ax = AccessibilityManager()
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Snaplet Settings")
                .font(.title2)
                .bold()

            HStack(spacing: 10) {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(ax.isTrusted ? .green : .red)

                Text(ax.isTrusted ? "Accessibility: Enabled" : "Accessibility: Not Enabled")
                    .font(.headline)
            }

            Text("Snaplet needs Accessibility permission to move and resize other apps’ windows.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Request Permission") {
                    ax.requestPermission()
                    ax.openAccessibilitySettings()
                }

                Button("Refresh") {
                    ax.refreshStatus()
                }
            }

            Divider().padding(.vertical, 6)

            Text("Target: \(appState.lastAppName)")
                .foregroundStyle(.secondary)

            Button("Snap Last App Left") {
                WindowSnapper.snapLastActiveAppLeft()
            }
            .disabled(!ax.isTrusted)

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 320)
        .onAppear { ax.refreshStatus() }
    }
}
