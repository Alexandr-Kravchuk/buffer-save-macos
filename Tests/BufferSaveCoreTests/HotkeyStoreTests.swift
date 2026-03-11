@testable import BufferSaveCore
import XCTest

final class HotkeyStoreTests: XCTestCase {
    func testLoadReturnsDefaultShortcutWhenStoreIsEmpty() {
        let defaults = makeUserDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let store = HotkeyStore(userDefaults: defaults, keyPrefix: "BufferSave.test")
        XCTAssertEqual(store.load(), .defaultShortcut)
    }

    func testSaveAndLoadCustomShortcut() {
        let defaults = makeUserDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let store = HotkeyStore(userDefaults: defaults, keyPrefix: "BufferSave.test")
        let shortcut = HotkeyShortcut(keyCode: 1, modifiers: 768, key: "S")!
        store.save(shortcut)
        XCTAssertEqual(store.load(), shortcut)
    }

    func testResetRestoresDefaultShortcut() {
        let defaults = makeUserDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let store = HotkeyStore(userDefaults: defaults, keyPrefix: "BufferSave.test")
        store.save(HotkeyShortcut(keyCode: 1, modifiers: 768, key: "S")!)
        store.reset()
        XCTAssertEqual(store.load(), .defaultShortcut)
    }

    var defaultsSuiteName: String {
        "BufferSave.HotkeyStoreTests"
    }

    func makeUserDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: defaultsSuiteName)!
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        return defaults
    }
}
