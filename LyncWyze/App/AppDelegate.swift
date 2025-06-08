//  AppDelegate.swift
//  LyncWyze
//
//  Created by Ujjwal Pandey on 17/12/24.


import UIKit
import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var apnsTokenReceived = false

    // App launch
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase first
        FirebaseApp.configure()
        
        // Configure Push Notifications
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Set messaging delegate
        Messaging.messaging().delegate = MessagingService.shared
        
        // Request authorization for notifications
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                print("Push notification authorization granted: \(granted)")
                if let error = error {
                    print("Push notification authorization error: \(error)")
                }
                
                // Only register for remote notifications if authorization was granted
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        )
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // Called when the app enters the background
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
        // Example: Save app state or data
    }

    // Called when the app is about to terminate
    func applicationWillTerminate(_ application: UIApplication) {
       print("App will terminate")
       // Clean up or save final data
        cleanUpApp()
    }
    // Custom function to simulate data saving
    func cleanUpApp() {
        print("Saving data...")
        // Code to save data or app state goes here
        UserDefaults.standard.set("Some Important Data", forKey: "SavedData")
    }

    // MARK: - Push Notification Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for notifications with token: \(deviceToken)")
        
        // Convert token to string for logging
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNS token: \(token)")
        
        // Set the APNS token
        Messaging.messaging().apnsToken = deviceToken
        apnsTokenReceived = true
        
        // Request FCM token using FCMUtilities
        Task {
            let result = await FCMUtilities.shared.getFCMToken()
            switch result {
            case .success(let token):
                print("FCM registration token after APNS: \(token)")
                let dataDict: [String: String] = ["token": token]
                NotificationCenter.default.post(
                    name: Notification.Name("FCMToken"),
                    object: nil,
                    userInfo: dataDict
                )
            case .failure(let error):
                print("Error fetching FCM registration token: \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        apnsTokenReceived = false
    }
    
    // MARK: - Remote Notification Handling
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 Received remote notification: \(userInfo)")
        
        // Check notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Notification authorization status: \(settings.authorizationStatus.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                // Handle the notification
                MessagingService.shared.handleRemoteMessage(userInfo)
                completionHandler(.newData)
            } else {
                print("⚠️ Notifications not authorized")
                completionHandler(.failed)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📱 Received notification in foreground: \(userInfo)")
        
        // Show banner, play sound, and update badge for foreground notifications
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification when user taps on it
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped on notification: \(userInfo)")
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("Firebase registration token: \(fcmToken)")
            
            // Store this token in your server for sending push notifications
            let dataDict: [String: String] = ["token": fcmToken]
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"),
                object: nil,
                userInfo: dataDict
            )
        } else {
            print("FCM token is nil, will retry after APNS token is received")
            if apnsTokenReceived {
                // If we have APNS token but FCM token is nil, try refreshing
                Task {
                    let result = await FCMUtilities.shared.getFCMToken()
                    switch result {
                    case .success(let token):
                        print("FCM registration token after retry: \(token)")
                        let dataDict: [String: String] = ["token": token]
                        NotificationCenter.default.post(
                            name: Notification.Name("FCMToken"),
                            object: nil,
                            userInfo: dataDict
                        )
                    case .failure(let error):
                        print("Error fetching FCM registration token: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

