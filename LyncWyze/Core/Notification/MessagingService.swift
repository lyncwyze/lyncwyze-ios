import Foundation
import FirebaseMessaging
import UserNotifications

class MessagingService: NSObject {
    static let shared = MessagingService()
    
    private override init() {
        super.init()
    }
    
    func handleRemoteMessage(_ message: [AnyHashable: Any]) {
        print("📱 Processing remote message: \(message)")
        
        // Extract notification data from the message
        let title = message["title"] as? String ?? ""
        let body = message["body"] as? String ?? ""
        let actionType = message["actionType"] as? String ?? ""
        
        print("📱 Notification details - Title: \(title), Body: \(body), Action: \(actionType)")
        print("📱 Expected action types: \(NotificationActionType.rideScheduling.rawValue), \(NotificationActionType.riderArrived.rawValue), \(NotificationActionType.returnedHome.rawValue)")
        print("📱 Raw message content: \(message)")
        print("📱 Action type before normalization: '\(actionType)'")
        
        // Check notification authorization before showing
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Cannot show notification: Notifications not authorized")
                return
            }
            
            DispatchQueue.main.async {
                // Make the comparison case-insensitive
                let normalizedActionType = actionType.lowercased()
                print("📱 Normalized action type: '\(normalizedActionType)'")
                print("📱 Comparing against ride_scheduling: '\(NotificationActionType.rideScheduling.rawValue.lowercased())'")
                print("📱 Do they match? \(normalizedActionType == NotificationActionType.rideScheduling.rawValue.lowercased())")
                
                switch normalizedActionType {
                case NotificationActionType.rideScheduling.rawValue.lowercased():
                    let dayOfWeek = message["dayOfWeek"] as? String
                    let activityId = message["activityId"] as? String
                    print("📱 Showing schedule options notification with activityId: \(activityId ?? "nil"), dayOfWeek: \(dayOfWeek ?? "nil")")
                    NotificationManager.shared.showScheduleOptionsNotification(
                        title: title,
                        message: body,
                        activityId: activityId,
                        dayOfWeek: dayOfWeek
                    )
                    
                case NotificationActionType.riderArrived.rawValue.lowercased():
                    print("📱 Showing rider arrived notification")
                    NotificationManager.shared.showOngoingRideNotification(title: title, message: body)
                    
                case NotificationActionType.returnedHome.rawValue.lowercased():
                    print("📱 Showing returned home notification")
                    NotificationManager.shared.showOngoingRideNotification(title: title, message: body)
                    
                default:
                    print("📱 No matching action type found, showing simple notification")
                    NotificationManager.shared.showSimpleNotification(title: title, message: body)
                }
            }
        }
    }
}

// MARK: - MessagingDelegate
extension MessagingService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            
            // Post notification for token updates
            let dataDict: [String: String] = ["token": token]
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"),
                object: nil,
                userInfo: dataDict
            )
        }
    }
} 