import Foundation
import UIKit

enum AuthType {
    case email
    case phone
}

class AuthenticationService {
    static let shared = AuthenticationService()
    
    private init() {}
    
    func login(identifier: String, password: String, authType: AuthType, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        // Create Base64 encoded auth string
        let authString = "\(identifier.trimmingCharacters(in: .whitespaces)):\(password.trimmingCharacters(in: .whitespaces))"
        guard let authData = authString.data(using: .utf8) else {
            completion(.failure(NetworkError.apiError("Error encoding credentials")))
            return
        }
        let base64Auth = authData.base64EncodedString(options: [])
        
        // Debug prints
        print("🔐 Auth String before encoding: \(authString)")
        print("🔑 Base64 encoded auth: \(base64Auth)")
        
        // Get FCM token
        Task {
            let fcmResult = await FCMUtilities.shared.getFCMToken()
            var fcmToken = ""
            if case .success(let token) = fcmResult {
                fcmToken = token
            }
            
            print("📱 Device version: \(UIDevice.current.systemVersion)")
            print("🔔 FCM Token: \(fcmToken)")
            
            // Create headers dictionary
            let headers: [String: String] = [
                "Authorization": "Basic \(base64Auth)",
                "token": fcmToken,
                "platform": "iOS",
                "version": UIDevice.current.systemVersion,
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
            
            print("📤 Request Headers: \(headers)")
            
            NetworkManager.shared.makeRequest(
                endpoint: "/auth/authenticate",
                method: .POST,
                headers: headers,
                parameters: ["authType": "app"]
            ) { (result: Result<AuthResponse, Error>) in
                switch result {
                case .success(let response):
                    print("✅ Login successful")
                    print("📦 Response: \(response)")
                    // Save access token and refresh token
                    UserDefaults.standard
                        .saveAccessToken(
                            value: response.access_token,
                            expiresIn: response.expires_in,
                            refreshToken: response.refresh_token
                        )
                    saveUserDefaultObject(response, forKey: Constants.UserDefaultsKeys.loggedInDataKey)
                    UserState.shared.setUserData(userId: response.userId)
                    completion(.success(response))
                    
                case .failure(let error):
                    print("❌ Login failed: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func refreshAccessToken(completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        guard let refreshToken = getRefreshToken() else {
            completion(.failure(NetworkError.apiError("No refresh token available")))
            return
        }
        
        let headers: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        let parameters: [String: String] = [
            "refresh_token": refreshToken
        ]
        
        NetworkManager.shared.makeRequest(
            endpoint: "/auth/getAccessToken",
            method: .POST,
            headers: headers,
            parameters: parameters
        ) { (result: Result<AuthResponse, Error>) in
            switch result {
            case .success(let response):
                print("✅ Token refresh successful")
                // Save new tokens
                UserDefaults.standard
                    .saveAccessToken(
                        value: response.access_token,
                        expiresIn: response.expires_in,
                        refreshToken: response.refresh_token
                    )
                completion(.success(response))
                
            case .failure(let error):
                print("❌ Token refresh failed: \(error)")
                completion(.failure(error))
            }
        }
    }
} 
