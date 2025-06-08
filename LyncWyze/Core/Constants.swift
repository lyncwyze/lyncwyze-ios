import Foundation

/// App-wide constants
enum Constants {

    /// API related constants
    enum API {
        // static let baseURL = "https://api.lyncwyze.com"
        static let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") ?? ""
        static let timeoutInterval: TimeInterval = 30
        static let maxRetries = 3
    }
    
    enum URLStrings {
        static let privacyPolicy = "https://lyncwyze.com/privacy"
        static let accountDeletion = "https://lyncwyze.com/contact"
        static let appStoreUrl = "https://apps.apple.com/in/app/lyncwyze/id6744105650"
    }
    
    /// UserDefaults keys
    enum UserDefaultsKeys {
        static let isLoggedIn = "isLoggedIn"
        static let userToken = "userToken"
        static let UserRequiredDataCount = "UserRequiredDataCount"
        static let userProfile = "userProfile"
        static let lastSyncTimestamp = "lastSyncTimestamp"
        static let loggedInDataKey = "loggedInData"
        static let rideData = "RideData"
        static let feedBackRequired = "feedBackRequired"
    }
    
    /// UI related constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 50
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
    }
    
    /// Animation durations
    enum Animation {
        static let shortDuration: TimeInterval = 0.2
        static let mediumDuration: TimeInterval = 0.3
        static let longDuration: TimeInterval = 0.5
    }
    
    /// Date format strings
    enum DateFormat {
        static let standard = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        static let display = "MMM d, yyyy"
        static let timeOnly = "HH:mm"
    }
    
    /// Error messages
    enum ErrorMessages {
        static let networkError = "Please check your internet connection and try again"
        static let serverError = "Something went wrong. Please try again later"
        static let invalidInput = "Please check your input and try again"
        static let unauthorized = "Your session has expired. Please login again"
    }
    
    /// Validation constants
    enum Validation {
        static let minimumPasswordLength = 8
        static let maximumPasswordLength = 32
        static let phoneNumberLength = 10
    }
    
    /// Cache related constants
    enum Cache {
        static let maxAge: TimeInterval = 3600 // 1 hour
        static let maxSize: Int = 50 * 1024 * 1024 // 50 MB
    }
} 
