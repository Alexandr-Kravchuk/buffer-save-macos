import AppKit
import Carbon
import Foundation

public struct HotkeyShortcut: Codable, Equatable, Sendable {
    public static let defaultShortcut = HotkeyShortcut(keyCode: UInt16(kVK_F1), modifiers: UInt32(cmdKey), key: "F1")!
    public let keyCode: UInt16
    public let modifiers: UInt32
    public let key: String

    public init?(keyCode: UInt16, modifiers: UInt32, key: String) {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard modifiers != 0, !normalizedKey.isEmpty else {
            return nil
        }
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = normalizedKey
    }

    public var displayString: String {
        modifierSymbols + key
    }

    public var modifierSymbols: String {
        var value = ""
        if modifiers & UInt32(controlKey) != 0 {
            value += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            value += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            value += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            value += "⌘"
        }
        return value
    }

    public static func from(event: NSEvent) -> HotkeyShortcut? {
        let modifiers = carbonModifiers(from: event.modifierFlags)
        let key = keyDisplay(for: event)
        return HotkeyShortcut(keyCode: UInt16(event.keyCode), modifiers: modifiers, key: key)
    }

    public static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        let normalizedFlags = flags.intersection([.command, .option, .control, .shift])
        var value: UInt32 = 0
        if normalizedFlags.contains(.command) {
            value |= UInt32(cmdKey)
        }
        if normalizedFlags.contains(.option) {
            value |= UInt32(optionKey)
        }
        if normalizedFlags.contains(.control) {
            value |= UInt32(controlKey)
        }
        if normalizedFlags.contains(.shift) {
            value |= UInt32(shiftKey)
        }
        return value
    }

    public static func keyDisplay(for event: NSEvent) -> String {
        keyDisplay(for: UInt16(event.keyCode), characters: event.charactersIgnoringModifiers)
    }

    public static func keyDisplay(for keyCode: UInt16, characters: String? = nil) -> String {
        switch Int(keyCode) {
        case kVK_F1:
            return "F1"
        case kVK_F2:
            return "F2"
        case kVK_F3:
            return "F3"
        case kVK_F4:
            return "F4"
        case kVK_F5:
            return "F5"
        case kVK_F6:
            return "F6"
        case kVK_F7:
            return "F7"
        case kVK_F8:
            return "F8"
        case kVK_F9:
            return "F9"
        case kVK_F10:
            return "F10"
        case kVK_F11:
            return "F11"
        case kVK_F12:
            return "F12"
        case kVK_Return:
            return "RETURN"
        case kVK_Tab:
            return "TAB"
        case kVK_Space:
            return "SPACE"
        case kVK_Delete:
            return "DELETE"
        case kVK_Escape:
            return "ESC"
        case kVK_LeftArrow:
            return "LEFT"
        case kVK_RightArrow:
            return "RIGHT"
        case kVK_DownArrow:
            return "DOWN"
        case kVK_UpArrow:
            return "UP"
        default:
            break
        }
        if let characters {
            let normalizedCharacters = characters.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if !normalizedCharacters.isEmpty {
                return normalizedCharacters
            }
        }
        return "KEY\(keyCode)"
    }
}
