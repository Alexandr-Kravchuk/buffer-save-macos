import BufferSaveCore
import Carbon
import Foundation

protocol HotkeyManaging: AnyObject {
    var currentShortcut: HotkeyShortcut? { get }
    func register(shortcut: HotkeyShortcut) throws
    func unregister()
}

enum HotkeyServiceError: LocalizedError, Equatable {
    case registrationFailed(HotkeyShortcut, OSStatus)

    var errorDescription: String? {
        switch self {
        case let .registrationFailed(shortcut, status):
            return "Global hotkey \(shortcut.displayString) could not be registered. OSStatus: \(status)."
        }
    }
}

final class HotkeyService: HotkeyManaging {
    let action: () -> Void
    let hotKeySignature: OSType = 0x42534156
    var hotKeyRef: EventHotKeyRef?
    var eventHandlerRef: EventHandlerRef?
    var currentShortcut: HotkeyShortcut?

    init(action: @escaping () -> Void) throws {
        self.action = action
        try installEventHandler()
    }

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func register(shortcut: HotkeyShortcut) throws {
        try installEventHandler()
        var newHotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: UInt32(shortcut.keyCode))
        let registrationStatus = RegisterEventHotKey(UInt32(shortcut.keyCode), shortcut.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &newHotKeyRef)
        guard registrationStatus == noErr, let newHotKeyRef else {
            throw HotkeyServiceError.registrationFailed(shortcut, registrationStatus)
        }
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = newHotKeyRef
        currentShortcut = shortcut
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        currentShortcut = nil
    }

    func installEventHandler() throws {
        guard eventHandlerRef == nil else {
            return
        }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else {
                    return OSStatus(eventNotHandledErr)
                }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                return service.handle(event: event)
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
        guard handlerStatus == noErr else {
            throw HotkeyServiceError.registrationFailed(.defaultShortcut, handlerStatus)
        }
    }

    func handle(event: EventRef?) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let parameterStatus = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard parameterStatus == noErr, hotKeyID.signature == hotKeySignature else {
            return parameterStatus
        }
        action()
        return noErr
    }
}
