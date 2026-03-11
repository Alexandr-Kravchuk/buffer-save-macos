import Foundation

public enum AppError: Error, Equatable, LocalizedError {
    case unsupportedClipboard
    case failedToEncodeImage
    case failedToResolveSaveDirectory
    case failedToWriteClipboard
    case fileSystemError(String)

    public var errorDescription: String? {
        message
    }

    public var message: String {
        switch self {
        case .unsupportedClipboard:
            return "No supported selected text or clipboard content was found."
        case .failedToEncodeImage:
            return "Clipboard image could not be encoded as PNG."
        case .failedToResolveSaveDirectory:
            return "Save folder could not be resolved."
        case .failedToWriteClipboard:
            return "Saved file path could not be copied to the clipboard."
        case let .fileSystemError(message):
            return message
        }
    }
}
