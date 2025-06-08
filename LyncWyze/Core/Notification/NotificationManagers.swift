import Foundation
import UserNotifications
import UIKit

enum NotificationActionType: String {
    case rideScheduling = "ride_scheduling"
    case riderArrived = "rider_arrived"
    case returnedHome = "returned_home"
}

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        setupNotificationCategories()
        requestAuthorization()
    }
    
    private func setupNotificationCategories() {
        // Create actions for schedule options
        let scheduleAction = UNNotificationAction(
            identifier: "SCHEDULE_NOW",
            title: "Schedule Now",
            options: .foreground
        )
        
        let maybeLaterAction = UNNotificationAction(
            identifier: "MAYBE_LATER",
            title: "Maybe Later",
            options: .destructive
        )
        
        let notThisOneAction = UNNotificationAction(
            identifier: "NOT_THIS_ONE",
            title: "Not This One",
            options: .destructive
        )
        
        // Create categories
        let scheduleCategory = UNNotificationCategory(
            identifier: "SCHEDULE_OPTIONS",
            actions: [scheduleAction, maybeLaterAction, notThisOneAction],
            intentIdentifiers: [],
            options: []
        )
        
        let ongoingRideCategory = UNNotificationCategory(
            identifier: "ONGOING_RIDE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let simpleCategory = UNNotificationCategory(
            identifier: "SIMPLE_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            scheduleCategory,
            ongoingRideCategory,
            simpleCategory
        ])
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification authorization granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("❌ Error requesting notification authorization: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification authorization denied")
            }
            
            // Check current authorization status
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("🔔 Current notification authorization status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    func scheduleActivityNotification(activityName: String, startTime: String, pickupTime: String, day: String) {
        // Create a unique identifier for this notification
        let notificationId = "\(activityName)_\(day)_\(startTime)"
        
        // Convert pickup time string to date components
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let pickupTimeDate = dateFormatter.date(from: pickupTime) else {
            print("Invalid pickup time format")
            return
        }
        
        // Create date components for the notification
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: pickupTimeDate)
        
        // Set the day of week
        switch day.lowercased() {
        case "mon": components.weekday = 2
        case "tue": components.weekday = 3
        case "wed": components.weekday = 4
        case "thu": components.weekday = 5
        case "fri": components.weekday = 6
        case "sat": components.weekday = 7
        case "sun": components.weekday = 1
        default: break
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Activity Reminder"
        content.body = "Your \(activityName) activity starts at \(startTime). Time to prepare!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: notificationId,
                                          content: content,
                                          trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for \(activityName) on \(day)")
            }
        }
    }
    
    func cancelNotification(activityName: String, day: String, startTime: String) {
        let notificationId = "\(activityName)_\(day)_\(startTime)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // Show notification with schedule options (equivalent to withScheduleOptions)
    func showScheduleOptionsNotification(title: String, message: String, activityId: String?, dayOfWeek: String?) {
        print("🔔 Showing schedule options notification")
        print("📝 Activity ID: \(activityId ?? "nil"), Day: \(dayOfWeek ?? "nil")")
        
        let notificationId = String(Date().timeIntervalSince1970)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Create actions
        let scheduleAction = UNNotificationAction(
            identifier: "SCHEDULE_NOW",
            title: "Schedule Now",
            options: .foreground
        )
        
        let maybeLaterAction = UNNotificationAction(
            identifier: "MAYBE_LATER",
            title: "Maybe Later",
            options: .destructive
        )
        
        let notThisOneAction = UNNotificationAction(
            identifier: "NOT_THIS_ONE",
            title: "Not This One",
            options: .destructive
        )
        
        // Create category with actions
        let category = UNNotificationCategory(
            identifier: "SCHEDULE_OPTIONS",
            actions: [scheduleAction, maybeLaterAction, notThisOneAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register category
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Add category identifier and custom data
        content.categoryIdentifier = "SCHEDULE_OPTIONS"
        content.userInfo = [
            "activityId": activityId ?? "",
            "dayOfWeek": dayOfWeek ?? "",
            "notificationId": notificationId
        ]
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error showing notification: \(error.localizedDescription)")
            } else {
                print("✅ Schedule options notification scheduled successfully")
            }
        }
    }
    
    // Show notification to open ongoing rides
    func showOngoingRideNotification(title: String, message: String) {
        print("🔔 Showing ongoing ride notification")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "ONGOING_RIDE"
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create unique identifier
        let identifier = "ongoing_ride_\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error showing notification: \(error.localizedDescription)")
            } else {
                print("✅ Ongoing ride notification scheduled successfully")
            }
        }
    }
    
    // Show simple notification
    func showSimpleNotification(title: String, message: String) {
        print("🔔 Showing simple notification")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "SIMPLE_NOTIFICATION"
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create unique identifier
        let identifier = "simple_notification_\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error showing notification: \(error.localizedDescription)")
            } else {
                print("✅ Simple notification scheduled successfully")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Handling notification response: \(response.actionIdentifier)")
        print("📱 UserInfo: \(userInfo)")
        
        // Delay the notification handling slightly to ensure any existing presentations are completed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch response.actionIdentifier {
            case "SCHEDULE_NOW":
                if let activityId = userInfo["activityId"] as? String,
                   let dayOfWeek = userInfo["dayOfWeek"] as? String {
                    print("📱 Opening dashboard and then activity confirmation for activityId: \(activityId), day: \(dayOfWeek)")
                    // First post notification to open dashboard
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenDashboard"),
                        object: nil
                    )
                    
                    // Then after a short delay, open the activity confirmation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenActivityConfirmation"),
                            object: nil,
                            userInfo: [
                                "activityId": activityId,
                                "dayOfWeek": dayOfWeek,
                                "isValidDay": true
                            ]
                        )
                    }
                }
                
            case "MAYBE_LATER":
                if let notificationId = userInfo["notificationId"] as? String {
                    print("📱 Dismissing notification: \(notificationId)")
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
                }
                
            case "NOT_THIS_ONE":
                if let activityId = userInfo["activityId"] as? String,
                   let dayOfWeek = userInfo["dayOfWeek"] as? String {
                    print("📱 Ignoring schedule for activityId: \(activityId), day: \(dayOfWeek)")
                    // Call the ignore schedule API
                    NetworkManager.shared.ignoreSchedule(activityId: activityId, dayOfWeek: dayOfWeek) { result in
                        switch result {
                        case .success(_):
                            print("✅ Successfully ignored schedule")
                        case .failure(let error):
                            print("❌ Failed to ignore schedule: \(error.localizedDescription)")
                        }
                    }
                    // Remove the notification
                    if let notificationId = userInfo["notificationId"] as? String {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
                    }
                }
                
            case UNNotificationDefaultActionIdentifier:
                // Handle notification tap based on category
                switch response.notification.request.content.categoryIdentifier {
                case "ONGOING_RIDE":
                    print("📱 Opening ongoing rides screen")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenOngoingRides"),
                        object: nil
                    )
                    
                case "SIMPLE_NOTIFICATION":
                    print("📱 Opening dashboard")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenDashboard"),
                        object: nil
                    )
                    
                default:
                    break
                }
                
            default:
                break
            }
        }
        
        completionHandler()
    }
}
