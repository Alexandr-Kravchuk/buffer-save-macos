import AppKit
import Foundation

public final class SystemPasteboardReader: PasteboardReadingSource {
    let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public var image: NSImage? {
        NSImage(pasteboard: pasteboard)
    }

    public var string: String? {
        pasteboard.string(forType: .string)
    }
}

public final class SystemPasteboardWriter: PasteboardWritingTarget {
    let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func replaceContents(with string: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(string, forType: .string)
    }
}
