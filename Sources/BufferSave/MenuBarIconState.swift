import Foundation

enum MenuBarIconState: Equatable {
    case `default`
    case success
    case warning
    case error
    case persistentError

    var symbolName: String {
        switch self {
        case .default:
            return "doc.on.clipboard"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .persistentError:
            return "exclamationmark.triangle.fill"
        }
    }
}
