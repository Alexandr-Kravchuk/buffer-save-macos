import AppKit
@testable import BufferSaveCore
import XCTest

final class ClipboardSaveCoordinatorTests: XCTestCase {
    func testSelectedTextIsSavedBeforeClipboardContent() {
        let coordinator = ClipboardSaveCoordinator(
            selectedTextReader: SelectedTextReaderStub(result: .text("selected text")),
            clipboardReader: ClipboardReaderStub(payload: .image(makeImage()), error: nil),
            fileSaver: FileSaverSpy(result: SaveResult(fileURL: URL(fileURLWithPath: "/tmp/selected.txt"), payloadKind: .text), error: nil),
            clipboardWriter: ClipboardWriterSpy()
        )
        let response = coordinator.saveBestAvailableContent()
        let result = try? response.result.get()
        XCTAssertEqual(result?.source, .selectedText)
        XCTAssertEqual(result?.saveResult.fileURL.path, "/tmp/selected.txt")
    }

    func testSuccessfulClipboardImageSaveWritesPathToClipboard() {
        let writer = ClipboardWriterSpy()
        let coordinator = ClipboardSaveCoordinator(
            selectedTextReader: SelectedTextReaderStub(result: .unavailable),
            clipboardReader: ClipboardReaderStub(payload: .image(makeImage()), error: nil),
            fileSaver: FileSaverSpy(result: SaveResult(fileURL: URL(fileURLWithPath: "/tmp/2026-03-11_image.png"), payloadKind: .image), error: nil),
            clipboardWriter: writer
        )
        let response = coordinator.saveBestAvailableContent()
        let result = try? response.result.get()
        XCTAssertEqual(result?.source, .clipboardImage)
        XCTAssertEqual(writer.values, ["/tmp/2026-03-11_image.png"])
    }

    func testPermissionWarningFallsBackToClipboardText() {
        let coordinator = ClipboardSaveCoordinator(
            selectedTextReader: SelectedTextReaderStub(result: .permissionRequired("Enable Accessibility")),
            clipboardReader: ClipboardReaderStub(payload: .text("clipboard text"), error: nil),
            fileSaver: FileSaverSpy(result: SaveResult(fileURL: URL(fileURLWithPath: "/tmp/clipboard.txt"), payloadKind: .text), error: nil),
            clipboardWriter: ClipboardWriterSpy()
        )
        let response = coordinator.saveBestAvailableContent()
        let result = try? response.result.get()
        XCTAssertEqual(result?.source, .clipboardText)
        XCTAssertEqual(response.warningMessage, "Enable Accessibility")
    }

    func testUnsupportedContentDoesNotWritePathToClipboard() {
        let writer = ClipboardWriterSpy()
        let coordinator = ClipboardSaveCoordinator(
            selectedTextReader: SelectedTextReaderStub(result: .unavailable),
            clipboardReader: ClipboardReaderStub(payload: nil, error: .unsupportedClipboard),
            fileSaver: FileSaverSpy(result: nil, error: nil),
            clipboardWriter: writer
        )
        let response = coordinator.saveBestAvailableContent()
        XCTAssertThrowsError(try response.result.get()) { error in
            XCTAssertEqual(error as? AppError, .unsupportedClipboard)
        }
        XCTAssertTrue(writer.values.isEmpty)
    }

    func testSaveFailureDoesNotWritePathToClipboard() {
        let writer = ClipboardWriterSpy()
        let coordinator = ClipboardSaveCoordinator(
            selectedTextReader: SelectedTextReaderStub(result: .unavailable),
            clipboardReader: ClipboardReaderStub(payload: .text("hello"), error: nil),
            fileSaver: FileSaverSpy(result: nil, error: .fileSystemError("Disk full")),
            clipboardWriter: writer
        )
        let response = coordinator.saveBestAvailableContent()
        XCTAssertThrowsError(try response.result.get()) { error in
            XCTAssertEqual(error as? AppError, .fileSystemError("Disk full"))
        }
        XCTAssertTrue(writer.values.isEmpty)
    }

    func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.systemGreen.drawSwatch(in: NSRect(x: 0, y: 0, width: 4, height: 4))
        image.unlockFocus()
        return image
    }
}

final class SelectedTextReaderStub: SelectedTextReading {
    let result: SelectedTextReadResult

    init(result: SelectedTextReadResult) {
        self.result = result
    }

    func readSelectedText() -> SelectedTextReadResult {
        result
    }
}

final class ClipboardReaderStub: ClipboardReading {
    let payload: ClipboardPayload?
    let error: AppError?

    init(payload: ClipboardPayload?, error: AppError?) {
        self.payload = payload
        self.error = error
    }

    func readClipboard() throws -> ClipboardPayload {
        if let error {
            throw error
        }
        return payload!
    }
}

final class FileSaverSpy: FileSaving {
    let result: SaveResult?
    let error: AppError?
    var savedKinds: [ClipboardPayloadKind] = []

    init(result: SaveResult?, error: AppError?) {
        self.result = result
        self.error = error
    }

    func save(_ payload: ClipboardPayload) throws -> SaveResult {
        savedKinds.append(payload.kind)
        if let error {
            throw error
        }
        return result!
    }
}

final class ClipboardWriterSpy: ClipboardWriting {
    var values: [String] = []
    var error: AppError?

    func writeText(_ value: String) throws {
        if let error {
            throw error
        }
        values.append(value)
    }
}
