import SwiftUI

@main
struct BufferSaveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var controller = ApplicationController()

    var body: some Scene {
        MenuBarExtra("Buffer Save", systemImage: controller.menuBarIconSymbolName) {
            MenuBarContentView(controller: controller)
        }
        .menuBarExtraStyle(.window)
    }
}
