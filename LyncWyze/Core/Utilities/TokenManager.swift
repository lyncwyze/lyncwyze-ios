import Foundation

// MARK: - DecodedUserDetails Model
struct DecodedUserDetails: Codable {
    let userName: String?
    let fullName: String?
    let profileComplete: Bool?
    let clientId: String?
    let emailId: String?
    let userId: String
    let authorities: [String]?
    let client_id: String?
    let changePassword: Bool?
    let scope: [String]?
    let name: String?
    let exp: Int?
    let acceptTermsAndPrivacyPolicy: Bool?
    let jti: String?
    let profileStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case fullName
        case profileComplete
        case clientId
        case emailId
        case userId
        case authorities
        case client_id
        case changePassword
        case scope
        case name
        case exp
        case acceptTermsAndPrivacyPolicy
        case jti
        case profileStatus
    }
}

// MARK: - TokenManager
class TokenManager {
    static let shared = TokenManager()
    
    private init() {}
    
    // MARK: - Constants
//    enum Keys {
//        static let accessToken = "accessToken"
//        static let accessTokenExpTime = "accessTokenExpTime"
//    }
//    
//    // MARK: - Token Management
//    func saveAccessToken(value: String, expiresIn: Int) {
//        let expirationTimestamp = Date().timeIntervalSince1970 + Double(expiresIn)
//        UserDefaults.standard.set(value, forKey: Keys.accessToken)
//        UserDefaults.standard.set(expirationTimestamp, forKey: Keys.accessTokenExpTime)
//        UserDefaults.standard.synchronize()
//    }
//    
//    func getAccessToken() -> String? {
//        let expirationTimestamp = UserDefaults.standard.double(forKey: Keys.accessTokenExpTime)
//        let currentTime = Date().timeIntervalSince1970
//        
//        if expirationTimestamp > currentTime {
//            return UserDefaults.standard.string(forKey: Keys.accessToken)
//        }
//        return nil
//    }
//    
//    func clearAccessToken() {
//        UserDefaults.standard.removeObject(forKey: Keys.accessToken)
//        UserDefaults.standard.removeObject(forKey: Keys.accessTokenExpTime)
//        UserDefaults.standard.synchronize()
//    }
    
    // MARK: - JWT Decoding
    func getDecodedAccessToken() -> DecodedUserDetails? {
        guard let token = getAccessToken() else { return nil }
        
        // Split the token into its components
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        // Get the payload (second part of the token)
        let base64Payload = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let padded = base64Payload.padding(toLength: ((base64Payload.count + 3) / 4) * 4,
                                         withPad: "=",
                                         startingAt: 0)
        
        guard let payloadData = Data(base64Encoded: padded),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }
        
        // Extract claims from JSON
        return DecodedUserDetails(
            userName: json["user_name"] as? String,
            fullName: json["fullName"] as? String,
            profileComplete: json["profileComplete"] as? Bool,
            clientId: json["clientId"] as? String,
            emailId: json["emailId"] as? String,
            userId: json["userId"] as? String ?? "",
            authorities: (json["authorities"] as? [String]) ?? [],
            client_id: json["client_id"] as? String,
            changePassword: json["changePassword"] as? Bool,
            scope: (json["scope"] as? [String]) ?? [],
            name: json["name"] as? String,
            exp: json["exp"] as? Int,
            acceptTermsAndPrivacyPolicy: json["acceptTermsAndPrivacyPolicy"] as? Bool,
            jti: json["jti"] as? String,
            profileStatus: json["profileStatus"] as? String
        )
    }
    
    // MARK: - Logout
//    func logout() {
//        // Clear token related data
//        clearAccessToken()
//        
//        // Clear other user related data
//        let keysToRemove = [
//            Constants.UserDefaultsKeys.loggedInDataKey,
//            Constants.UserDefaultsKeys.isLoggedIn,
//            Constants.UserDefaultsKeys.userToken,
//            Constants.UserDefaultsKeys.userProfile,
//            Constants.UserDefaultsKeys.lastSyncTimestamp
//        ]
//        
//        keysToRemove.forEach { key in
//            UserDefaults.standard.removeObject(forKey: key)
//        }
//        
//        // Optional: Remove all data for the app
//        if let bundleID = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: bundleID)
//        }
//        
//        UserDefaults.standard.synchronize()
//    }
} 
