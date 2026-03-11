import AppKit
import Foundation

public final class FileSaveService: FileSaving, SaveDirectoryProviding {
    let fileManager: FileManager
    let baseDirectoryProvider: () throws -> URL
    let nowProvider: () -> Date
    let timestampProvider: (Date) -> String

    public init(
        fileManager: FileManager = .default,
        baseDirectoryProvider: @escaping () throws -> URL = FileSaveService.defaultBaseDirectory,
        nowProvider: @escaping () -> Date = Date.init,
        timestampProvider: @escaping (Date) -> String = FileSaveService.defaultTimestamp
    ) {
        self.fileManager = fileManager
        self.baseDirectoryProvider = baseDirectoryProvider
        self.nowProvider = nowProvider
        self.timestampProvider = timestampProvider
    }

    public func save(_ payload: ClipboardPayload) throws -> SaveResult {
        let date = nowProvider()
        let directoryURL = try resolvedSaveDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName(for: payload, at: date), isDirectory: false)
        do {
            switch payload {
            case let .text(text):
                try text.write(to: fileURL, atomically: true, encoding: .utf8)
            case let .image(image):
                let data = try pngData(from: image)
                try data.write(to: fileURL, options: .atomic)
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.fileSystemError(error.localizedDescription)
        }
        return SaveResult(fileURL: fileURL, payloadKind: payload.kind)
    }

    public func resolvedSaveDirectory() throws -> URL {
        do {
            let baseDirectoryURL = try baseDirectoryProvider()
            let directoryURL = baseDirectoryURL.appendingPathComponent("Buffer Save", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            return directoryURL
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.fileSystemError(error.localizedDescription)
        }
    }

    func fileName(for payload: ClipboardPayload, at date: Date) -> String {
        let timestamp = timestampProvider(date)
        switch payload {
        case let .text(text):
            return "\(timestamp)_\(slug(for: text)).txt"
        case .image:
            return "\(timestamp)_image.png"
        }
    }

    func slug(for text: String) -> String {
        let prefix = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        let folded = prefix.folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: .current)
        let normalized = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }.joined()
        let slug = normalized.split(whereSeparator: \.isWhitespace).map(String.init).joined(separator: "-").lowercased()
        let finalSlug = String(slug.prefix(40))
        return finalSlug.isEmpty ? "text" : finalSlug
    }

    func pngData(from image: NSImage) throws -> Data {
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            return pngData
        }
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = bitmap.representation(using: .png, properties: [:]) {
                return pngData
            }
        }
        throw AppError.failedToEncodeImage
    }

    public static func defaultBaseDirectory() throws -> URL {
        do {
            return try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            throw AppError.failedToResolveSaveDirectory
        }
    }

    public static func defaultTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
}
