@testable import BufferSaveCore
import XCTest

final class LaunchAtLoginServiceTests: XCTestCase {
    func testInstallLaunchAgentCreatesExpectedPlist() throws {
        let temporaryLibraryURL = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryLibraryURL) }
        let executableURL = URL(fileURLWithPath: "/Users/test/Applications/BufferSave.app/Contents/MacOS/BufferSave")
        let service = LaunchAtLoginService(
            bundleIdentifier: "local.buffer-save",
            executableURL: executableURL,
            libraryDirectoryProvider: { temporaryLibraryURL }
        )
        let plistURL = try service.installLaunchAgent()
        XCTAssertEqual(plistURL.path, temporaryLibraryURL.appendingPathComponent("LaunchAgents/local.buffer-save.plist").path)
        let plistData = try Data(contentsOf: plistURL)
        let propertyList = try XCTUnwrap(PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any])
        XCTAssertEqual(propertyList["Label"] as? String, "local.buffer-save")
        XCTAssertEqual(propertyList["ProgramArguments"] as? [String], [executableURL.path])
        XCTAssertEqual(propertyList["RunAtLoad"] as? Bool, true)
        XCTAssertEqual(propertyList["KeepAlive"] as? Bool, false)
        XCTAssertEqual(propertyList["ProcessType"] as? String, "Interactive")
    }

    func testResolvedLaunchAgentsDirectoryCreatesFolder() throws {
        let temporaryLibraryURL = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryLibraryURL) }
        let service = LaunchAtLoginService(
            bundleIdentifier: "local.buffer-save",
            executableURL: URL(fileURLWithPath: "/Users/test/Applications/BufferSave.app/Contents/MacOS/BufferSave"),
            libraryDirectoryProvider: { temporaryLibraryURL }
        )
        let directoryURL = try service.resolvedLaunchAgentsDirectory()
        XCTAssertEqual(directoryURL.lastPathComponent, "LaunchAgents")
        XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.path))
    }

    func makeTemporaryDirectory() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        return directoryURL
    }
}
