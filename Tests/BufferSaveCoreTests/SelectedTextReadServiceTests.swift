@testable import BufferSaveCore
import XCTest

final class SelectedTextReadServiceTests: XCTestCase {
    func testReturnsPermissionRequiredWhenAccessibilityIsDisabled() {
        let service = SelectedTextReadService(
            snapshotReader: AccessibilitySelectionSnapshotReaderStub(isTrusted: false, snapshot: nil),
            permissionMessage: "Enable Accessibility"
        )
        XCTAssertEqual(service.readSelectedText(), .permissionRequired("Enable Accessibility"))
    }

    func testReturnsSelectedTextWhenDirectAttributeExists() {
        let service = SelectedTextReadService(
            snapshotReader: AccessibilitySelectionSnapshotReaderStub(
                isTrusted: true,
                snapshot: AccessibilitySelectionSnapshot(selectedText: "  selected text  ", selectedRange: nil, value: nil)
            )
        )
        XCTAssertEqual(service.readSelectedText(), .text("selected text"))
    }

    func testReturnsSelectedTextFromRangeWhenDirectAttributeIsMissing() {
        let service = SelectedTextReadService(
            snapshotReader: AccessibilitySelectionSnapshotReaderStub(
                isTrusted: true,
                snapshot: AccessibilitySelectionSnapshot(selectedText: nil, selectedRange: CFRange(location: 6, length: 4), value: "hello world")
            )
        )
        XCTAssertEqual(service.readSelectedText(), .text("worl"))
    }

    func testReturnsUnavailableWhenNothingIsSelected() {
        let service = SelectedTextReadService(
            snapshotReader: AccessibilitySelectionSnapshotReaderStub(
                isTrusted: true,
                snapshot: AccessibilitySelectionSnapshot(selectedText: "   ", selectedRange: nil, value: nil)
            )
        )
        XCTAssertEqual(service.readSelectedText(), .unavailable)
    }
}

final class AccessibilitySelectionSnapshotReaderStub: AccessibilitySelectionSnapshotReading {
    let isTrusted: Bool
    let snapshot: AccessibilitySelectionSnapshot?

    init(isTrusted: Bool, snapshot: AccessibilitySelectionSnapshot?) {
        self.isTrusted = isTrusted
        self.snapshot = snapshot
    }

    func isProcessTrusted() -> Bool {
        isTrusted
    }

    func readSnapshot() -> AccessibilitySelectionSnapshot? {
        snapshot
    }
}
