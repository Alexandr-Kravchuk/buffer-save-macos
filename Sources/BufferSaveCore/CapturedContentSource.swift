import Foundation

public enum CapturedContentSource: Equatable {
    case selectedText
    case clipboardImage
    case clipboardText

    public var successMessage: String {
        switch self {
        case .selectedText:
            return "Saved selected text"
        case .clipboardImage:
            return "Saved clipboard image"
        case .clipboardText:
            return "Saved clipboard text"
        }
    }
}
