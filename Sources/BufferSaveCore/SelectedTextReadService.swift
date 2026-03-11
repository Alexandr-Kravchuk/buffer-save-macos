import ApplicationServices
import Foundation

public struct AccessibilitySelectionSnapshot {
    public let selectedText: String?
    public let selectedRange: CFRange?
    public let value: String?

    public init(selectedText: String?, selectedRange: CFRange?, value: String?) {
        self.selectedText = selectedText
        self.selectedRange = selectedRange
        self.value = value
    }
}

public enum SelectedTextReadResult: Equatable {
    case text(String)
    case unavailable
    case permissionRequired(String)
}

public final class SelectedTextReadService: SelectedTextReading {
    let snapshotReader: AccessibilitySelectionSnapshotReading
    let permissionMessage: String

    public init(
        snapshotReader: AccessibilitySelectionSnapshotReading = SystemAccessibilitySelectionSnapshotReader(),
        permissionMessage: String = "Enable Buffer Save in System Settings > Privacy & Security > Accessibility to save selected text."
    ) {
        self.snapshotReader = snapshotReader
        self.permissionMessage = permissionMessage
    }

    public func readSelectedText() -> SelectedTextReadResult {
        guard snapshotReader.isProcessTrusted() else {
            return .permissionRequired(permissionMessage)
        }
        guard let snapshot = snapshotReader.readSnapshot(), let text = extractText(from: snapshot) else {
            return .unavailable
        }
        return .text(text)
    }

    func extractText(from snapshot: AccessibilitySelectionSnapshot) -> String? {
        if let selectedText = normalizedText(snapshot.selectedText) {
            return selectedText
        }
        guard let selectedRange = snapshot.selectedRange,
              let value = snapshot.value,
              selectedRange.location != kCFNotFound,
              selectedRange.length > 0 else {
            return nil
        }
        let range = NSRange(location: selectedRange.location, length: selectedRange.length)
        guard let substringRange = Range(range, in: value) else {
            return nil
        }
        return normalizedText(String(value[substringRange]))
    }

    func normalizedText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public final class SystemAccessibilitySelectionSnapshotReader: AccessibilitySelectionSnapshotReading {
    public init() {
    }

    public func isProcessTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    public func readSnapshot() -> AccessibilitySelectionSnapshot? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedValue)
        guard focusedStatus == .success, let focusedValue else {
            return nil
        }
        let focusedElement = unsafeDowncast(focusedValue, to: AXUIElement.self)
        return AccessibilitySelectionSnapshot(
            selectedText: copyStringAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement),
            selectedRange: copyRangeAttribute(kAXSelectedTextRangeAttribute as CFString, from: focusedElement),
            value: copyStringAttribute(kAXValueAttribute as CFString, from: focusedElement)
        )
    }

    func copyStringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard status == .success, let value else {
            return nil
        }
        if let stringValue = value as? String {
            return stringValue
        }
        if let attributedStringValue = value as? NSAttributedString {
            return attributedStringValue.string
        }
        return nil
    }

    func copyRangeAttribute(_ attribute: CFString, from element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard status == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        let axValue = unsafeDowncast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cfRange else {
            return nil
        }
        var range = CFRange()
        return AXValueGetValue(axValue, .cfRange, &range) ? range : nil
    }
}
