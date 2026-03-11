import Foundation

public final class ClipboardReadService: ClipboardReading {
    let pasteboard: PasteboardReadingSource

    public init(pasteboard: PasteboardReadingSource = SystemPasteboardReader()) {
        self.pasteboard = pasteboard
    }

    public func readClipboard() throws -> ClipboardPayload {
        if let image = pasteboard.image {
            return .image(image)
        }
        if let string = pasteboard.string {
            return .text(string)
        }
        throw AppError.unsupportedClipboard
    }
}
