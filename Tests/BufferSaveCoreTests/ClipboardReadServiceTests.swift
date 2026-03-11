import AppKit
@testable import BufferSaveCore
import XCTest

final class ClipboardReadServiceTests: XCTestCase {
    func testReadClipboardReturnsImageWhenImageExists() throws {
        let service = ClipboardReadService(pasteboard: PasteboardStub(image: makeImage(), string: nil))
        let payload = try service.readClipboard()
        XCTAssertEqual(payload.kind, .image)
    }

    func testReadClipboardReturnsTextWhenOnlyTextExists() throws {
        let service = ClipboardReadService(pasteboard: PasteboardStub(image: nil, string: "hello"))
        let payload = try service.readClipboard()
        XCTAssertEqual(payload.kind, .text)
    }

    func testReadClipboardPrioritizesImageOverText() throws {
        let service = ClipboardReadService(pasteboard: PasteboardStub(image: makeImage(), string: "hello"))
        let payload = try service.readClipboard()
        XCTAssertEqual(payload.kind, .image)
    }

    func testReadClipboardThrowsUnsupportedClipboardForEmptyPasteboard() {
        let service = ClipboardReadService(pasteboard: PasteboardStub(image: nil, string: nil))
        XCTAssertThrowsError(try service.readClipboard()) { error in
            XCTAssertEqual(error as? AppError, .unsupportedClipboard)
        }
    }

    func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.systemRed.drawSwatch(in: NSRect(x: 0, y: 0, width: 4, height: 4))
        image.unlockFocus()
        return image
    }
}

final class PasteboardStub: PasteboardReadingSource {
    let image: NSImage?
    let string: String?

    init(image: NSImage?, string: String?) {
        self.image = image
        self.string = string
    }
}
