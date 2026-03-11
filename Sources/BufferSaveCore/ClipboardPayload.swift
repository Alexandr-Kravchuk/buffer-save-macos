import AppKit
import Foundation

public enum ClipboardPayload {
    case image(NSImage)
    case text(String)
}

public enum ClipboardPayloadKind: Equatable {
    case image
    case text
}

public extension ClipboardPayload {
    var kind: ClipboardPayloadKind {
        switch self {
        case .image:
            return .image
        case .text:
            return .text
        }
    }
}
