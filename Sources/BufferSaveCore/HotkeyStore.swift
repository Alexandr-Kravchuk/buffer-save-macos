import Foundation

public final class HotkeyStore {
    let userDefaults: UserDefaults
    let keyPrefix: String

    public init(userDefaults: UserDefaults = .standard, keyPrefix: String = "BufferSave.hotkey") {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }

    public func load() -> HotkeyShortcut {
        let keyCodeKey = "\(keyPrefix).keyCode"
        let modifiersKey = "\(keyPrefix).modifiers"
        let keyLabelKey = "\(keyPrefix).key"
        guard userDefaults.object(forKey: keyCodeKey) != nil,
              userDefaults.object(forKey: modifiersKey) != nil else {
            return .defaultShortcut
        }
        let keyCode = UInt16(userDefaults.integer(forKey: keyCodeKey))
        let modifiers = UInt32(userDefaults.integer(forKey: modifiersKey))
        let keyLabel = userDefaults.string(forKey: keyLabelKey) ?? HotkeyShortcut.keyDisplay(for: keyCode)
        return HotkeyShortcut(keyCode: keyCode, modifiers: modifiers, key: keyLabel) ?? .defaultShortcut
    }

    public func save(_ shortcut: HotkeyShortcut) {
        userDefaults.set(Int(shortcut.keyCode), forKey: "\(keyPrefix).keyCode")
        userDefaults.set(Int(shortcut.modifiers), forKey: "\(keyPrefix).modifiers")
        userDefaults.set(shortcut.key, forKey: "\(keyPrefix).key")
    }

    public func reset() {
        save(.defaultShortcut)
    }
}
