import Foundation

public final class ClipboardSaveCoordinator: CapturedContentSaving {
    let selectedTextReader: SelectedTextReading
    let clipboardReader: ClipboardReading
    let fileSaver: FileSaving
    let clipboardWriter: ClipboardWriting

    public init(
        selectedTextReader: SelectedTextReading,
        clipboardReader: ClipboardReading,
        fileSaver: FileSaving,
        clipboardWriter: ClipboardWriting
    ) {
        self.selectedTextReader = selectedTextReader
        self.clipboardReader = clipboardReader
        self.fileSaver = fileSaver
        self.clipboardWriter = clipboardWriter
    }

    public func saveBestAvailableContent() -> SaveOperationResponse {
        let capture = bestAvailableContent()
        switch capture.result {
        case let .success((payload, source)):
            do {
                let saveResult = try fileSaver.save(payload)
                try clipboardWriter.writeText(saveResult.fileURL.path)
                return SaveOperationResponse(result: .success(SaveOperationResult(saveResult: saveResult, source: source)), warningMessage: capture.warningMessage)
            } catch let error as AppError {
                return SaveOperationResponse(result: .failure(error), warningMessage: capture.warningMessage)
            } catch {
                return SaveOperationResponse(result: .failure(.fileSystemError(error.localizedDescription)), warningMessage: capture.warningMessage)
            }
        case let .failure(error):
            return SaveOperationResponse(result: .failure(error), warningMessage: capture.warningMessage)
        }
    }

    func bestAvailableContent() -> (result: Result<(ClipboardPayload, CapturedContentSource), AppError>, warningMessage: String?) {
        switch selectedTextReader.readSelectedText() {
        case let .text(text):
            return (.success((.text(text), .selectedText)), nil)
        case let .permissionRequired(message):
            return (clipboardContentResult(), message)
        case .unavailable:
            return (clipboardContentResult(), nil)
        }
    }

    func clipboardContentResult() -> Result<(ClipboardPayload, CapturedContentSource), AppError> {
        do {
            let payload = try clipboardReader.readClipboard()
            switch payload.kind {
            case .image:
                return .success((payload, .clipboardImage))
            case .text:
                return .success((payload, .clipboardText))
            }
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.fileSystemError(error.localizedDescription))
        }
    }
}
