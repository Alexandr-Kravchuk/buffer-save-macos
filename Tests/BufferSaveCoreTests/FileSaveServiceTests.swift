import AppKit
@testable import BufferSaveCore
import XCTest

final class FileSaveServiceTests: XCTestCase {
    func testResolvedSaveDirectoryCreatesExpectedFolder() throws {
        let temporaryDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let service = FileSaveService(
            baseDirectoryProvider: { temporaryDirectory },
            nowProvider: { Date(timeIntervalSince1970: 0) },
            timestampProvider: { _ in "2026-03-11_11-34-00" }
        )
        let directoryURL = try service.resolvedSaveDirectory()
        XCTAssertEqual(directoryURL.lastPathComponent, "Buffer Save")
        XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.path))
    }

    func testTextSaveCreatesFolderAndWritesUTF8Text() throws {
        let temporaryDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let service = FileSaveService(
            baseDirectoryProvider: { temporaryDirectory },
            nowProvider: { Date(timeIntervalSince1970: 0) },
            timestampProvider: { _ in "2026-03-11_11-34-00" }
        )
        let result = try service.save(.text("Hello Swift clipboard"))
        XCTAssertEqual(result.payloadKind, .text)
        XCTAssertEqual(result.fileURL.lastPathComponent, "2026-03-11_11-34-00_hello-swift-clipboard.txt")
        let content = try String(contentsOf: result.fileURL, encoding: .utf8)
        XCTAssertEqual(content, "Hello Swift clipboard")
    }

    func testImageSaveWritesPNGData() throws {
        let temporaryDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let service = FileSaveService(
            baseDirectoryProvider: { temporaryDirectory },
            nowProvider: { Date(timeIntervalSince1970: 0) },
            timestampProvider: { _ in "2026-03-11_11-34-00" }
        )
        let image = makeImage(color: .systemBlue)
        let result = try service.save(.image(image))
        XCTAssertEqual(result.payloadKind, .image)
        XCTAssertEqual(result.fileURL.lastPathComponent, "2026-03-11_11-34-00_image.png")
        let data = try Data(contentsOf: result.fileURL)
        XCTAssertEqual(Array(data.prefix(8)), [137, 80, 78, 71, 13, 10, 26, 10])
    }

    func testSlugRemovesUnsupportedCharactersAndFallsBackToText() {
        let service = FileSaveService(
            baseDirectoryProvider: { URL(fileURLWithPath: "/tmp") },
            nowProvider: { Date(timeIntervalSince1970: 0) },
            timestampProvider: { _ in "2026-03-11_11-34-00" }
        )
        XCTAssertEqual(service.slug(for: "Hello,    Swift! @2026"), "hello-swift-2026")
        XCTAssertEqual(service.slug(for: "!!!"), "text")
    }

    func testSaveReturnsFileSystemErrorWhenBaseDirectoryCannotBeResolved() {
        let service = FileSaveService(
            baseDirectoryProvider: { throw AppError.failedToResolveSaveDirectory },
            nowProvider: { Date(timeIntervalSince1970: 0) },
            timestampProvider: { _ in "2026-03-11_11-34-00" }
        )
        XCTAssertThrowsError(try service.save(.text("Value"))) { error in
            XCTAssertEqual(error as? AppError, .failedToResolveSaveDirectory)
        }
    }

    func makeTemporaryDirectory() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        return directoryURL
    }

    func makeImage(color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 8, height: 8))
        image.lockFocus()
        color.drawSwatch(in: NSRect(x: 0, y: 0, width: 8, height: 8))
        image.unlockFocus()
        return image
    }
}
