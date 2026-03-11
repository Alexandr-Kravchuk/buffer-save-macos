import Foundation

public enum AppStatus: Equatable {
    case idle
    case success(String)
    case warning(String)
    case error(String)

    public var message: String {
        switch self {
        case .idle:
            return "Ready to save clipboard."
        case let .success(message), let .warning(message), let .error(message):
            return message
        }
    }
}
