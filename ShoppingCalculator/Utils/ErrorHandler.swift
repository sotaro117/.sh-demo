import Foundation

enum AppError: LocalizedError {
    case network(String)
    case auth(String)
    case camera(String)
    case database(String)
    case api(String)
    case unknown(String)

    var errorDescription: String? { userMessage }

    var userMessage: String {
        switch self {
        case .network:
            return "A network error occurred. Please check your connection and try again."
        case .auth(let detail):
            return "Authentication failed: \(detail)"
        case .camera:
            return "Camera is unavailable. Please check your camera permissions."
        case .database:
            return "Failed to save data. Please try again."
        case .api:
            return "The service is temporarily unavailable. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}
