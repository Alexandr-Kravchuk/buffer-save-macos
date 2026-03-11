import Foundation

public final class LaunchAtLoginService {
    let bundleIdentifier: String
    let executableURL: URL
    let fileManager: FileManager
    let libraryDirectoryProvider: () throws -> URL

    public init(
        bundleIdentifier: String,
        executableURL: URL,
        fileManager: FileManager = .default,
        libraryDirectoryProvider: @escaping () throws -> URL = LaunchAtLoginService.defaultLibraryDirectory
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.executableURL = executableURL
        self.fileManager = fileManager
        self.libraryDirectoryProvider = libraryDirectoryProvider
    }

    public func installLaunchAgent() throws -> URL {
        let launchAgentsDirectoryURL = try resolvedLaunchAgentsDirectory()
        let plistURL = launchAgentsDirectoryURL.appendingPathComponent("\(bundleIdentifier).plist", isDirectory: false)
        let plistData = try PropertyListSerialization.data(fromPropertyList: launchAgentPlist(), format: .xml, options: 0)
        do {
            try plistData.write(to: plistURL, options: .atomic)
        } catch {
            throw AppError.fileSystemError(error.localizedDescription)
        }
        return plistURL
    }

    public func resolvedLaunchAgentsDirectory() throws -> URL {
        do {
            let libraryDirectoryURL = try libraryDirectoryProvider()
            let launchAgentsDirectoryURL = libraryDirectoryURL.appendingPathComponent("LaunchAgents", isDirectory: true)
            try fileManager.createDirectory(at: launchAgentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            return launchAgentsDirectoryURL
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.fileSystemError(error.localizedDescription)
        }
    }

    public func launchAgentPlist() -> [String: Any] {
        [
            "Label": bundleIdentifier,
            "ProgramArguments": [executableURL.path],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive",
        ]
    }

    public static func defaultLibraryDirectory() throws -> URL {
        do {
            return try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            throw AppError.fileSystemError(error.localizedDescription)
        }
    }
}
