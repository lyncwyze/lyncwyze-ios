import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = ProfileManager()
    
    private init() {}
    
    @MainActor
    func fetchUserProfile() async {
        isLoading = true
        error = nil
        
        guard let decodedToken = TokenManager.shared.getDecodedAccessToken(),
              !decodedToken.userId.isEmpty else {
            isLoading = false
            error = "User ID not found in token"
            return
        }
        
        print("User Id:", decodedToken.userId)
        print(decodedToken)
        
        let endpoint = "/user/getUserById"
        let parameters = ["id": decodedToken.userId]
        
        do {
            let response: UserProfile = try await withCheckedThrowingContinuation { continuation in
                NetworkManager.shared.makeRequest(
                    endpoint: endpoint,
                    method: .GET,
                    parameters: parameters
                ) { (result: Result<UserProfile, Error>) in
                    switch result {
                    case .success(let profile):
                        continuation.resume(returning: profile)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            print("profile ==>", response)
            userProfile = response
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    @MainActor
    func updateProfile(updatedData: [String: Any]) async throws {
        isLoading = true
        error = nil
        
        guard let decodedToken = TokenManager.shared.getDecodedAccessToken(),
              let username = decodedToken.userName else {
            throw NetworkError.apiError("Failed to get user information")
        }
        
        guard let profileData = try? JSONSerialization.data(withJSONObject: updatedData) else {
            throw NetworkError.apiError("Failed to encode profile data")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            NetworkManager.shared.makeRequest(
                endpoint: "/user/updateUser",
                method: .PUT,
                body: profileData,
                parameters: ["username": username]
            ) { (result: Result<UserProfile, Error>) in
                switch result {
                case .success(let profile):
                    self.userProfile = profile
                    self.isLoading = false
                    continuation.resume()
                case .failure(let error):
                    self.isLoading = false
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    func uploadProfileImage(imageData: Data) async throws {
        isLoading = true
        error = nil
        
        var formData = NetworkManager.MultipartFormData()
        formData.append(imageData, name: "file", fileName: "profile.jpg")
        
        let requestData = formData.finalize()
        let headers = ["Content-Type": formData.contentType]
        
        return try await withCheckedThrowingContinuation { continuation in
            NetworkManager.shared.makeRequest(
                endpoint: "/user/addProfileImage",
                method: .POST,
                headers: headers,
                body: requestData
            ) { (result: Result<Data, Error>) in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    func deleteProfileImage() async throws {
        isLoading = true
        error = nil
        
        guard let decodedToken = TokenManager.shared.getDecodedAccessToken() else {
            throw NetworkError.apiError("Failed to get user information")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            NetworkManager.shared.makeRequest(
                endpoint: "/user/deleteProfileImage",
                method: .DELETE,
                parameters: ["userId": decodedToken.userId]
            ) { (result: Result<EmptyResponse, Error>) in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func loadProfileImage(path: String) async throws -> Data {
        return try await NetworkManager.shared.loadImageAsync(path: path)
    }
    
    // MARK: - Helper Methods
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .apiError(let message):
                self.error = message
            case .decodingError:
                self.error = "Failed to decode response"
            case .invalidResponse:
                self.error = "Invalid server response"
            case .invalidURL:
                self.error = "Invalid URL"
            case .noData:
                self.error = "No data received"
            @unknown default:
                self.error = "Unknown error occurred"
            }
        } else {
            self.error = error.localizedDescription
        }
    }
    
    func formatDateTime(_ dateString: String, format: String = "dd/MM/yyyy hh:mm a") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
} 
