import Foundation

// MARK: - UserDefaults Keys
enum UserDefaultsKeys {
    static let accessToken = "accessToken"
    static let accessTokenExpTime = "accessTokenExpTime"
    static let refreshToken = "refreshToken"
    static let phoneNumber = "phoneNumber"
    static let emailAddress = "emailAddress"
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    // MARK: - String Operations
    func saveString(value: String, forKey key: String) {
        set(value, forKey: key)
        synchronize()
    }
    
    func getString(forKey key: String) -> String? {
        return string(forKey: key)
    }
    
    // MARK: - Integer Operations
    func saveInt(value: Int, forKey key: String) {
        set(value, forKey: key)
        synchronize()
    }
    
    func getInt(forKey key: String) -> Int {
        return integer(forKey: key)
    }
    
    // MARK: - Custom Object Operations
    func saveObject<T: Encodable>(_ object: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            set(encoded, forKey: key)
            synchronize()
        }
    }
    
    func getObject<T: Decodable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Access Token Operations
    func saveAccessToken(value: String, expiresIn: Int, refreshToken: String?) {
        let expirationTimestamp = Date().timeIntervalSince1970 + Double(expiresIn)
        saveString(value: value, forKey: UserDefaultsKeys.accessToken)
        set(expirationTimestamp, forKey: UserDefaultsKeys.accessTokenExpTime)
        if let refreshToken = refreshToken {
            saveString(value: refreshToken, forKey: UserDefaultsKeys.refreshToken)
        }
        synchronize()
    }
    
    func getAccessToken() -> String? {
        let expirationTimestamp = double(forKey: UserDefaultsKeys.accessTokenExpTime)
        let currentTime = Date().timeIntervalSince1970
        
        if expirationTimestamp > currentTime {
            return getString(forKey: UserDefaultsKeys.accessToken)
        }
        return nil
    }
    
    func getRefreshToken() -> String? {
        return getString(forKey: UserDefaultsKeys.refreshToken)
    }
    
    // MARK: - Deletion Operations
    func deleteValue(forKey key: String) {
        removeObject(forKey: key)
        synchronize()
    }
    
    func logout() {
        // Call invalidate API first
        NetworkManager.shared.invalidateToken { result in
            switch result {
            case .success:
                print("✅ Token invalidated successfully")
            case .failure(let error):
                print("❌ Failed to invalidate token: \(error)")
            }
            
            // Clear UserState
            UserState.shared.clearUserData()
            
            // Clear all specific keys regardless of API response
            print("Clearing all specific keys")
            self.deleteValue(forKey: UserDefaultsKeys.accessToken)
            self.deleteValue(forKey: UserDefaultsKeys.accessTokenExpTime)
            self.deleteValue(forKey: UserDefaultsKeys.refreshToken)
            self.deleteValue(forKey: Constants.UserDefaultsKeys.loggedInDataKey)
            self.deleteValue(forKey: Constants.UserDefaultsKeys.isLoggedIn)
            self.deleteValue(forKey: Constants.UserDefaultsKeys.userToken)
            self.deleteValue(forKey: Constants.UserDefaultsKeys.userProfile)
            self.deleteValue(forKey: Constants.UserDefaultsKeys.lastSyncTimestamp)
            self.deleteValue(forKey: UserDefaultsKeys.emailAddress)
            self.deleteValue(forKey: UserDefaultsKeys.phoneNumber)
            
            // Remove all data from UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            UserDefaults.standard.synchronize()
        }
    }
}

// MARK: - Global Helper Functions
// These functions provide a simpler interface to UserDefaults operations
func saveUserDefaultKeyData(value: String, forKey key: String) {
    UserDefaults.standard.saveString(value: value, forKey: key)
}

func saveUserDefaultKeyData(value: Int, forKey key: String) {
    UserDefaults.standard.saveInt(value: value, forKey: key)
}

func getUserDefaultKeyData(forKey key: String) -> String? {
    return UserDefaults.standard.getString(forKey: key)
}

func getUserDefaultKeyData(forKey key: String) -> Int {
    return UserDefaults.standard.getInt(forKey: key)
}

func deleteUserDefaultKeyData(forKey key: String) {
    UserDefaults.standard.deleteValue(forKey: key)
}

// MARK: - Custom Object Helper Functions
func saveUserDefaultObject<T: Encodable>(_ object: T, forKey key: String) {
    print("Saved Data")
    UserDefaults.standard.saveObject(object, forKey: key)
}

func getUserDefaultObject<T: Decodable>(forKey key: String) -> T? {
    return UserDefaults.standard.getObject(forKey: key)
}

func saveAccessToken(value: String, expiresIn: Int, refreshToken: String?) {
    UserDefaults.standard.saveAccessToken(value: value, expiresIn: expiresIn, refreshToken: refreshToken)
}

func getAccessToken(completion: @escaping (String?) -> Void) {
    if let token = UserDefaults.standard.getAccessToken() {
        completion(token)
    } else if let _ = getRefreshToken() {
        AuthenticationService.shared.refreshAccessToken { result in
            switch result {
            case .success(let response):
                completion(response.access_token)
            case .failure:
                completion(nil)
            }
        }
    } else {
        completion(nil)
    }
}

// Synchronous version for backward compatibility
func getAccessToken() -> String? {
    return UserDefaults.standard.getAccessToken()
}

func getRefreshToken() -> String? {
    return UserDefaults.standard.getRefreshToken()
}

func logout() {
    UserDefaults.standard.logout()
} 
