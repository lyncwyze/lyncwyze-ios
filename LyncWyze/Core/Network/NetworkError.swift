import Foundation

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let error: String?
    let error_description: String?
    let errorInformation: ErrorInformation?
    
    struct ErrorInformation: Codable {
        let errorCode: String?
        let errorDescription: String?
    }
}

// MARK: - Network Error Types
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case apiError(String)
    case decodingError(Error)
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .apiError(let message):
            return message
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError:
            return "Failed to encode request data"
        }
    }
}

// MARK: - Toast State Manager
class ToastState: ObservableObject {
    static let shared = ToastState()
    @Published var isShowing = false
    @Published var message = ""
    
    func show(_ message: String, duration: Double = 2.0) {
        self.message = message
        self.isShowing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isShowing = false
        }
    }
} 