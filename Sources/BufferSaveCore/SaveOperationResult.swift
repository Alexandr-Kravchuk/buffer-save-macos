import Foundation

public struct SaveOperationResult: Equatable {
    public let saveResult: SaveResult
    public let source: CapturedContentSource

    public init(saveResult: SaveResult, source: CapturedContentSource) {
        self.saveResult = saveResult
        self.source = source
    }
}

public struct SaveOperationResponse: Equatable {
    public let result: Result<SaveOperationResult, AppError>
    public let warningMessage: String?

    public init(result: Result<SaveOperationResult, AppError>, warningMessage: String?) {
        self.result = result
        self.warningMessage = warningMessage
    }
}
