import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var controller: ApplicationController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buffer Save")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                Label(controller.statusText, systemImage: controller.statusSymbolName)
                    .foregroundStyle(controller.statusColor)
                Text("Hotkey: \(controller.hotkeyDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(controller.hotkeyRecordingDescription)
                    .font(.caption2)
                    .foregroundStyle(controller.isRecordingHotkey ? .orange : .secondary)
                if let lastSavedPath = controller.lastSavedPath {
                    Text(lastSavedPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
            Divider()
            Button("Save Clipboard Now", action: controller.saveClipboard)
            Button(controller.isRecordingHotkey ? "Cancel Hotkey Recording" : "Record Hotkey") {
                controller.isRecordingHotkey ? controller.stopHotkeyRecording() : controller.startHotkeyRecording()
            }
            Button("Reset Hotkey to Default", action: controller.resetHotkey)
                .disabled(!controller.canResetHotkey)
            Button("Open Save Folder", action: controller.openSaveFolder)
            Button("Copy Last Path", action: controller.copyLastPath)
                .disabled(!controller.canCopyLastPath)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 340)
        .onDisappear {
            controller.stopHotkeyRecording()
        }
    }
}
