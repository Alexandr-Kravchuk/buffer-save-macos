import AppKit
import BufferSaveCore
import Carbon
import SwiftUI

protocol WorkspaceOpening {
    func open(_ url: URL) -> Bool
}

struct SystemWorkspace: WorkspaceOpening {
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}

enum HotkeyState: Equatable {
    case active
    case error(String)
}

@MainActor
final class ApplicationController: ObservableObject {
    typealias HotkeyManagerFactory = (@escaping () -> Void) throws -> HotkeyManaging
    typealias SleepFunction = @Sendable (UInt64) async -> Void
    @Published var status: AppStatus = .idle
    @Published var lastSavedFileURL: URL?
    @Published var hotkeyState: HotkeyState = .active
    @Published var currentShortcut: HotkeyShortcut
    @Published var isRecordingHotkey = false
    @Published var menuBarIconState: MenuBarIconState = .default
    let coordinator: CapturedContentSaving
    let saveDirectoryProvider: SaveDirectoryProviding
    let clipboardWriter: ClipboardWriting
    let notificationScheduler: NotificationScheduling
    let launchAtLoginService: LaunchAtLoginService?
    let hotkeyStore: HotkeyStore
    let hotkeyManagerFactory: HotkeyManagerFactory
    let workspace: WorkspaceOpening
    let sleep: SleepFunction
    let menuBarResetDelayNanoseconds: UInt64
    var hotkeyService: HotkeyManaging?
    var hotkeyRecordingMonitor: Any?
    var menuBarResetTask: Task<Void, Never>?
    var didShowAccessibilityWarning = false

    init(
        coordinator: CapturedContentSaving? = nil,
        saveDirectoryProvider: SaveDirectoryProviding? = nil,
        clipboardWriter: ClipboardWriting? = nil,
        notificationScheduler: NotificationScheduling? = nil,
        launchAtLoginService: LaunchAtLoginService? = nil,
        hotkeyStore: HotkeyStore = HotkeyStore(),
        hotkeyManagerFactory: @escaping HotkeyManagerFactory = { try HotkeyService(action: $0) },
        workspace: WorkspaceOpening = SystemWorkspace(),
        sleep: @escaping SleepFunction = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        },
        menuBarResetDelayNanoseconds: UInt64 = 5_000_000_000
    ) {
        let resolvedNotificationScheduler = notificationScheduler ?? Self.makeNotificationScheduler()
        let resolvedSaveDirectoryProvider = saveDirectoryProvider ?? FileSaveService()
        let resolvedClipboardWriter = clipboardWriter ?? ClipboardWriteService()
        let resolvedCoordinator = coordinator ?? ClipboardSaveCoordinator(
            selectedTextReader: SelectedTextReadService(),
            clipboardReader: ClipboardReadService(),
            fileSaver: FileSaveService(),
            clipboardWriter: resolvedClipboardWriter
        )
        let loadedShortcut = hotkeyStore.load()
        self.coordinator = resolvedCoordinator
        self.saveDirectoryProvider = resolvedSaveDirectoryProvider
        self.clipboardWriter = resolvedClipboardWriter
        self.notificationScheduler = resolvedNotificationScheduler
        self.launchAtLoginService = launchAtLoginService ?? Self.makeLaunchAtLoginService()
        self.hotkeyStore = hotkeyStore
        self.hotkeyManagerFactory = hotkeyManagerFactory
        self.workspace = workspace
        self.sleep = sleep
        self.menuBarResetDelayNanoseconds = menuBarResetDelayNanoseconds
        currentShortcut = loadedShortcut
        resolvedNotificationScheduler.requestAuthorization()
        configureLaunchAtLogin()
        registerInitialHotkey()
    }

    static func makeNotificationScheduler() -> NotificationScheduling {
        guard Bundle.main.bundleURL.pathExtension == "app", Bundle.main.bundleIdentifier != nil else {
            return NoopNotificationService()
        }
        return NotificationService()
    }

    static func makeLaunchAtLoginService() -> LaunchAtLoginService? {
        guard Bundle.main.bundleURL.pathExtension == "app",
              isInstalledApplication(Bundle.main.bundleURL),
              let bundleIdentifier = Bundle.main.bundleIdentifier,
              let executableURL = Bundle.main.executableURL else {
            return nil
        }
        return LaunchAtLoginService(bundleIdentifier: bundleIdentifier, executableURL: executableURL)
    }

    static func isInstalledApplication(_ bundleURL: URL) -> Bool {
        let resolvedPath = bundleURL.resolvingSymlinksInPath().path
        return resolvedPath.hasPrefix("/Applications/") || resolvedPath.hasPrefix(NSHomeDirectory() + "/Applications/")
    }

    var statusText: String {
        switch hotkeyState {
        case .active:
            return status.message
        case let .error(message):
            return message
        }
    }

    var statusSymbolName: String {
        switch hotkeyState {
        case .error:
            return "exclamationmark.triangle.fill"
        case .active:
            switch status {
            case .idle:
                return "doc.on.clipboard"
            case .success:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            }
        }
    }

    var statusColor: Color {
        switch hotkeyState {
        case .error:
            return .orange
        case .active:
            switch status {
            case .idle:
                return .secondary
            case .success:
                return .green
            case .warning:
                return .orange
            case .error:
                return .red
            }
        }
    }

    var menuBarIconSymbolName: String {
        menuBarIconState.symbolName
    }

    var hotkeyDescription: String {
        currentShortcut.displayString
    }

    var hotkeyRecordingDescription: String {
        isRecordingHotkey ? "Press a new shortcut. Esc cancels." : "Record a new global hotkey."
    }

    var lastSavedPath: String? {
        lastSavedFileURL?.path
    }

    var canCopyLastPath: Bool {
        lastSavedFileURL != nil
    }

    var canResetHotkey: Bool {
        currentShortcut != .defaultShortcut
    }

    func configureLaunchAtLogin() {
        guard let launchAtLoginService else {
            return
        }
        do {
            _ = try launchAtLoginService.installLaunchAgent()
        } catch let error as AppError {
            handleErrorStatus(error.message, persistent: false)
        } catch {
            handleErrorStatus(error.localizedDescription, persistent: false)
        }
    }

    func saveClipboard() {
        let response = coordinator.saveBestAvailableContent()
        handleAccessibilityWarningIfNeeded(response.warningMessage)
        switch response.result {
        case let .success(result):
            lastSavedFileURL = result.saveResult.fileURL
            let message = "\(result.source.successMessage) to \(result.saveResult.fileURL.lastPathComponent)"
            status = .success(message)
            notificationScheduler.notifySuccess(fileName: result.saveResult.fileURL.lastPathComponent)
            showTemporaryMenuBarIcon(.success)
        case let .failure(error):
            handleErrorStatus(error.message, persistent: false)
        }
    }

    func openSaveFolder() {
        do {
            let directoryURL = try saveDirectoryProvider.resolvedSaveDirectory()
            guard workspace.open(directoryURL) else {
                throw AppError.fileSystemError("Save folder could not be opened.")
            }
            status = .success("Opened save folder.")
            showTemporaryMenuBarIcon(.success)
        } catch let error as AppError {
            handleErrorStatus(error.message, persistent: false)
        } catch {
            handleErrorStatus(error.localizedDescription, persistent: false)
        }
    }

    func copyLastPath() {
        guard let lastSavedFileURL else {
            handleErrorStatus("No saved file available yet.", persistent: false)
            return
        }
        do {
            try clipboardWriter.writeText(lastSavedFileURL.path)
            status = .success("Copied \(lastSavedFileURL.lastPathComponent)")
            showTemporaryMenuBarIcon(.success)
        } catch let error as AppError {
            handleErrorStatus(error.message, persistent: false)
        } catch {
            handleErrorStatus(error.localizedDescription, persistent: false)
        }
    }

    func startHotkeyRecording() {
        guard !isRecordingHotkey else {
            return
        }
        isRecordingHotkey = true
        status = .warning("Press a new shortcut.")
        showTemporaryMenuBarIcon(.warning)
        hotkeyRecordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkeyRecording(event: event) ?? event
        }
    }

    func stopHotkeyRecording() {
        isRecordingHotkey = false
        if let hotkeyRecordingMonitor {
            NSEvent.removeMonitor(hotkeyRecordingMonitor)
            self.hotkeyRecordingMonitor = nil
        }
        if status == .warning("Press a new shortcut.") {
            status = .idle
        }
    }

    func resetHotkey() {
        updateHotkey(.defaultShortcut)
    }

    func handleHotkeyRecording(event: NSEvent) -> NSEvent? {
        if event.keyCode == UInt16(kVK_Escape) {
            stopHotkeyRecording()
            return nil
        }
        guard let shortcut = HotkeyShortcut.from(event: event) else {
            status = .error("Hotkey must include at least one modifier.")
            showTemporaryMenuBarIcon(.error)
            return nil
        }
        stopHotkeyRecording()
        updateHotkey(shortcut)
        return nil
    }

    func registerInitialHotkey() {
        do {
            if hotkeyService == nil {
                hotkeyService = try hotkeyManagerFactory { [weak self] in
                    Task { @MainActor in
                        self?.saveClipboard()
                    }
                }
            }
            try hotkeyService?.register(shortcut: currentShortcut)
            hotkeyState = .active
            if menuBarIconState == .persistentError {
                menuBarIconState = .default
            }
        } catch {
            hotkeyState = .error(error.localizedDescription)
            status = .error(error.localizedDescription)
            menuBarResetTask?.cancel()
            menuBarIconState = .persistentError
            notificationScheduler.notifyError(message: error.localizedDescription)
        }
    }

    func updateHotkey(_ shortcut: HotkeyShortcut) {
        do {
            if hotkeyService == nil {
                hotkeyService = try hotkeyManagerFactory { [weak self] in
                    Task { @MainActor in
                        self?.saveClipboard()
                    }
                }
            }
            try hotkeyService?.register(shortcut: shortcut)
            hotkeyStore.save(shortcut)
            currentShortcut = shortcut
            hotkeyState = .active
            if menuBarIconState == .persistentError {
                menuBarIconState = .default
            }
            status = .success("Hotkey updated to \(shortcut.displayString)")
            showTemporaryMenuBarIcon(.success)
        } catch {
            let hasActiveHotkey = hotkeyService?.currentShortcut != nil
            if hasActiveHotkey {
                handleErrorStatus(error.localizedDescription, persistent: false)
            } else {
                handleErrorStatus(error.localizedDescription, persistent: true)
            }
        }
    }

    func handleAccessibilityWarningIfNeeded(_ message: String?) {
        guard let message, !didShowAccessibilityWarning else {
            return
        }
        didShowAccessibilityWarning = true
        notificationScheduler.notifyWarning(message: message)
    }

    func handleErrorStatus(_ message: String, persistent: Bool) {
        status = .error(message)
        notificationScheduler.notifyError(message: message)
        if persistent {
            hotkeyState = .error(message)
            menuBarResetTask?.cancel()
            menuBarIconState = .persistentError
        } else {
            showTemporaryMenuBarIcon(.error)
        }
    }

    func showTemporaryMenuBarIcon(_ state: MenuBarIconState) {
        switch hotkeyState {
        case .error:
            return
        case .active:
            break
        }
        menuBarResetTask?.cancel()
        menuBarIconState = state
        menuBarResetTask = Task { [sleep, menuBarResetDelayNanoseconds] in
            await sleep(menuBarResetDelayNanoseconds)
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                self.menuBarIconState = .default
            }
        }
    }
}
