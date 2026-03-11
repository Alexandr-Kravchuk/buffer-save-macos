import Foundation

public struct SaveResult: Equatable {
    public let fileURL: URL
    public let payloadKind: ClipboardPayloadKind

    public init(fileURL: URL, payloadKind: ClipboardPayloadKind) {
        self.fileURL = fileURL
        self.payloadKind = payloadKind
    }
}
