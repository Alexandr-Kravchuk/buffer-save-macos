import BufferSaveCore
@testable import BufferSave
import XCTest

@MainActor
final class ApplicationControllerTests: XCTestCase {
    func testMenuBarIconResetsToDefaultAfterDelay() async {
        let notificationSpy = NotificationSpy()
        let controller = ApplicationController(
            coordinator: CapturedContentSavingStub(
                response: SaveOperationResponse(
                    result: .success(
                        SaveOperationResult(
                            saveResult: SaveResult(fileURL: URL(fileURLWithPath: "/tmp/file.txt"), payloadKind: .text),
                            source: .clipboardText
                        )
                    ),
                    warningMessage: nil
                )
            ),
            saveDirectoryProvider: SaveDirectoryProvidingStub(),
            clipboardWriter: ClipboardWritingStub(),
            notificationScheduler: notificationSpy,
            launchAtLoginService: nil,
            hotkeyStore: HotkeyStore(userDefaults: UserDefaults(suiteName: "BufferSave.ApplicationControllerTests.1")!, keyPrefix: "BufferSave.test"),
            hotkeyManagerFactory: { _ in HotkeyManagerStub() },
            workspace: WorkspaceStub(),
            menuBarResetDelayNanoseconds: 1_000_000
        )
        controller.saveClipboard()
        XCTAssertEqual(controller.menuBarIconState, .success)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(controller.menuBarIconState, .default)
    }

    func testAccessibilityWarningIsShownOnlyOncePerSession() {
        let notificationSpy = NotificationSpy()
        let response = SaveOperationResponse(
            result: .success(
                SaveOperationResult(
                    saveResult: SaveResult(fileURL: URL(fileURLWithPath: "/tmp/file.txt"), payloadKind: .text),
                    source: .clipboardText
                )
            ),
            warningMessage: "Enable Accessibility"
        )
        let controller = ApplicationController(
            coordinator: CapturedContentSavingStub(response: response),
            saveDirectoryProvider: SaveDirectoryProvidingStub(),
            clipboardWriter: ClipboardWritingStub(),
            notificationScheduler: notificationSpy,
            launchAtLoginService: nil,
            hotkeyStore: HotkeyStore(userDefaults: UserDefaults(suiteName: "BufferSave.ApplicationControllerTests.2")!, keyPrefix: "BufferSave.test"),
            hotkeyManagerFactory: { _ in HotkeyManagerStub() },
            workspace: WorkspaceStub(),
            sleep: { _ in },
            menuBarResetDelayNanoseconds: 1
        )
        controller.saveClipboard()
        controller.saveClipboard()
        XCTAssertEqual(notificationSpy.warningMessages, ["Enable Accessibility"])
    }
}

final class CapturedContentSavingStub: CapturedContentSaving {
    let response: SaveOperationResponse

    init(response: SaveOperationResponse) {
        self.response = response
    }

    func saveBestAvailableContent() -> SaveOperationResponse {
        response
    }
}

final class SaveDirectoryProvidingStub: SaveDirectoryProviding {
    func resolvedSaveDirectory() throws -> URL {
        URL(fileURLWithPath: "/tmp")
    }
}

final class ClipboardWritingStub: ClipboardWriting {
    func writeText(_ value: String) throws {
    }
}

final class WorkspaceStub: WorkspaceOpening {
    func open(_ url: URL) -> Bool {
        true
    }
}

final class NotificationSpy: NotificationScheduling {
    var didRequestAuthorization = false
    var successFiles: [String] = []
    var warningMessages: [String] = []
    var errorMessages: [String] = []

    func requestAuthorization() {
        didRequestAuthorization = true
    }

    func notifySuccess(fileName: String) {
        successFiles.append(fileName)
    }

    func notifyWarning(message: String) {
        warningMessages.append(message)
    }

    func notifyError(message: String) {
        errorMessages.append(message)
    }
}

final class HotkeyManagerStub: HotkeyManaging {
    var currentShortcut: HotkeyShortcut?

    func register(shortcut: HotkeyShortcut) throws {
        currentShortcut = shortcut
    }

    func unregister() {
        currentShortcut = nil
    }
}
