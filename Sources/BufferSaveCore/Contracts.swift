import AppKit
import Foundation

public protocol ClipboardReading {
    func readClipboard() throws -> ClipboardPayload
}

public protocol CapturedContentSaving {
    func saveBestAvailableContent() -> SaveOperationResponse
}

public protocol ClipboardWriting {
    func writeText(_ value: String) throws
}

public protocol FileSaving {
    func save(_ payload: ClipboardPayload) throws -> SaveResult
}

public protocol SaveDirectoryProviding {
    func resolvedSaveDirectory() throws -> URL
}

public protocol NotificationScheduling {
    func requestAuthorization()
    func notifySuccess(fileName: String)
    func notifyWarning(message: String)
    func notifyError(message: String)
}

public protocol SelectedTextReading {
    func readSelectedText() -> SelectedTextReadResult
}

public protocol PasteboardReadingSource {
    var image: NSImage? { get }
    var string: String? { get }
}

public protocol PasteboardWritingTarget {
    func replaceContents(with string: String) -> Bool
}

public protocol AccessibilitySelectionSnapshotReading {
    func isProcessTrusted() -> Bool
    func readSnapshot() -> AccessibilitySelectionSnapshot?
}
