import Foundation
import SwiftUI
import DateToolsSwift

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

// MARK: - NetworkManager Implementation
final class NetworkManager {
    // MARK: - Properties
    static let shared = NetworkManager()
    private let baseURL = Bundle.main.object(
        forInfoDictionaryKey: "BASE_URL"
    ) as! String? ?? ""
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Network Request Method
    func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil,
        parameters: [String: String]? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var urlString = baseURL + endpoint
        
        // Handle query parameters
        if let parameters = parameters {
            var components = URLComponents(string: urlString)!
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components.url?.absoluteString ?? urlString
        }
        
        print("🌐 Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        func performRequest(withToken token: String?) {
            // Create and configure URLRequest
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            // Set default headers
            var defaultHeaders: [String: String] = [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "X-BM-CLIENT": "iOS"
            ]
            
            // Add access token if available (except for authentication endpoints)
            if !endpoint.contains("/auth/") {
                if let token = token {
                    defaultHeaders["Authorization"] = "Bearer \(token)"
                }
            }
            
            // Merge custom headers with default headers (custom headers take precedence)
            if let customHeaders = headers {
                defaultHeaders.merge(customHeaders) { (_, new) in new }
            }
            
            // Apply all headers
            for (key, value) in defaultHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            // Print final headers for debugging
            print("📤 Request Headers:")
            request.allHTTPHeaderFields?.forEach { key, value in
                print("\(key): \(value)")
            }
            
            // Set request body if provided
            if let body = body {
                request.httpBody = body
                if let bodyString = String(data: body, encoding: .utf8) {
                    print("📤 Request Body: \(bodyString)")
                }
            }
            
            // Create and start data task
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                print("📥 Response Status Code: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    if endpoint != "/user/loadImage"{
                        print("📥 Response Data: \(responseString)")
                    }
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        let errorMessage = errorResponse.error_description ??
                        errorResponse.errorInformation?.errorDescription ??
                        "Unknown error occurred"
                        
                        if httpResponse.statusCode == 401 {
                            DispatchQueue.main.async {
                                // Clear any stored credentials
                                UserDefaults.standard.removeObject(forKey: "accessToken")
                                // Show toast message
                                ToastState.shared.show("Session expired. Please sign in again.")
                                // Post notification for unauthorized access
                                NotificationCenter.default.post(name: NSNotification.Name("UnauthorizedAccess"), object: nil)
                            }
                        }
                        
                        completion(.failure(NetworkError.apiError(errorMessage)))
                    } catch {
                        print("❌ Error Response Decoding Failed: \(error)")
                        completion(.failure(NetworkError.decodingError(error)))
                    }
                    return
                }
                
                // Special handling for Data type (string response)
                if T.self == Data.self {
                    DispatchQueue.main.async {
                        completion(.success(data as! T))
                    }
                    return
                }
                
                // Handle JSON responses
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(decodedResponse))
                    }
                } catch {
                    print("🔄 Response Decoding Error: \(error)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            }
            task.resume()
        }
        
        // If it's not an auth endpoint, try to get a fresh token first
        if !endpoint.contains("/auth/") {
            getAccessToken { token in
                performRequest(withToken: token)
            }
        } else {
            performRequest(withToken: nil)
        }
    }
}

// MARK: - Image Loading Methods
extension NetworkManager {
    func loadImage(path: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let endpoint = "/user/loadImage"
        let parameters = ["path": path]
        
        makeRequest(endpoint: endpoint,
                   method: .GET,
                   parameters: parameters) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                // Try to decode base64 string to Data
                if let base64String = String(data: data, encoding: .utf8),
                   let imageData = Data(base64Encoded: base64String) {
                    completion(.success(imageData))
                } else {
                    completion(.failure(NetworkError.decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data"]))))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func loadImageAsync(path: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            loadImage(path: path) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - Multipart Form Helper
extension NetworkManager {
    struct MultipartFormData {
        private var data = Data()
        private let boundary: String
        
        init(boundary: String = "Boundary-\(UUID().uuidString)") {
            self.boundary = boundary
        }
        
        mutating func append(_ value: Data, name: String, fileName: String) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            data.append(value)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        mutating func append<T: Encodable>(_ value: T, name: String) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            
            if let jsonData = try? JSONEncoder().encode(value) {
                data.append(jsonData)
            }
            data.append("\r\n".data(using: .utf8)!)
        }
        
        mutating func append(_ image: UIImage, name: String, fileName: String) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            append(imageData, name: name, fileName: fileName)
        }
        
        mutating func finalize() -> Data {
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            return data
        }
        
        var contentType: String {
            return "multipart/form-data; boundary=\(boundary)"
        }
    }
}

// MARK: - Authentication Methods
extension NetworkManager {
    func invalidateToken(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        Task {
            var headers = [
                "accept": "*/*",
                "Content-Type": "application/json"
            ]

            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                headers["Authorization"] = "Bearer \(token)"
            }

            let fcmTokenResult = await FCMUtilities.shared.getFCMToken()
            var fcmToken: String = ""
            if case .success(let token) = fcmTokenResult {
                fcmToken = token
            }
            
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
            
            let endpoint = "/auth/invalidate"
            let deviceInfo = [
                "id": UUID().uuidString,
                "userId": UserState.shared.getUserId() ?? "",
                "token": fcmToken,
                "platform": "iOS",
                "version": osVersionString,
                "type": "mobile"
            ]
            
            guard let jsonData = try? JSONEncoder().encode(deviceInfo) else {
                completion(.failure(NetworkError.encodingError))
                return
            }
            
            makeRequest(
                endpoint: endpoint,
                method: .POST,
                headers: headers,
                body: jsonData,
                completion: completion
            )
        }
    }
    
    // Async version of invalidateToken
    func invalidateTokenAsync() async throws -> EmptyResponse {
        return try await withCheckedThrowingContinuation { continuation in
            invalidateToken { result in
                continuation.resume(with: result)
            }
        }
    }

    func resendEmailOtp(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let endpoint = "/user/retryEmailOtp/\(email)"
        makeRequest(endpoint: endpoint,
                   method: .GET) { (result: Result<Bool, Error>) in
            completion(result)
        }
    }
    
    func resendPhoneOtp(phoneNumber: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let endpoint = "/user/retryOtp/\(phoneNumber)"
        makeRequest(endpoint: endpoint,
                   method: .GET) { (result: Result<Bool, Error>) in
            completion(result)
        }
    }
    
    func resendPhoneOtpAsync(phoneNumber: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            resendPhoneOtp(phoneNumber: phoneNumber) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // Async version of resendEmailOtp
    func resendEmailOtpAsync(email: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            resendEmailOtp(email: email) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // Ignore schedule API call
    func ignoreSchedule(activityId: String, dayOfWeek: String, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(
            endpoint: "/match/ignoreSchedule",
            method: .GET,
            parameters: [
                "activityId": activityId,
                "dayOfWeek": dayOfWeek
            ]
        ) { (result: Result<Data, Error>) in
            completion(result)
        }
    }
    
    // Async version of ignoreSchedule
    func ignoreScheduleAsync(activityId: String, dayOfWeek: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            ignoreSchedule(activityId: activityId, dayOfWeek: dayOfWeek) { result in
                continuation.resume(with: result)
            }
        }
    }
} 
