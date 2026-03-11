import Foundation

public final class ClipboardWriteService: ClipboardWriting {
    let pasteboard: PasteboardWritingTarget

    public init(pasteboard: PasteboardWritingTarget = SystemPasteboardWriter()) {
        self.pasteboard = pasteboard
    }

    public func writeText(_ value: String) throws {
        guard pasteboard.replaceContents(with: value) else {
            throw AppError.failedToWriteClipboard
        }
    }
}
