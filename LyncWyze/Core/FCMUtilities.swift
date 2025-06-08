import Foundation
import FirebaseMessaging
import FirebaseCore

final class FCMUtilities {
    static let shared = FCMUtilities()
    
    private init() {}
    
    /// Retrieves the FCM token for the device
    /// - Returns: A Result type containing either the FCM token or an error
    func getFCMToken() async -> Result<String, Error> {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                    return
                }
                
                guard let token = token else {
                    continuation.resume(returning: .failure(NSError(domain: "FCMUtilities", code: -1, userInfo: [NSLocalizedDescriptionKey: "FCM token is nil"])))
                    return
                }
                
                continuation.resume(returning: .success(token))
            }
        }
    }
    
    /// Deletes the FCM token
    /// - Returns: A Result type indicating success or failure
    func deleteFCMToken() async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().deleteToken { error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                    return
                }
                continuation.resume(returning: .success(()))
            }
        }
    }
    
    /// Subscribes to a specific FCM topic
    /// - Parameter topic: The topic name to subscribe to
    /// - Returns: A Result type indicating success or failure
    func subscribeToTopic(_ topic: String) async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                    return
                }
                continuation.resume(returning: .success(()))
            }
        }
    }
    
    /// Unsubscribes from a specific FCM topic
    /// - Parameter topic: The topic name to unsubscribe from
    /// - Returns: A Result type indicating success or failure
    func unsubscribeFromTopic(_ topic: String) async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                    return
                }
                continuation.resume(returning: .success(()))
            }
        }
    }
} 
