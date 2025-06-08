//
//  SceneDelegate.swift
//  LyncWyze
//
//  Created by Ujjwal Pandey on 17/12/24.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        // Set the home view
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Set the initial root view controller
        setInitialRootViewController()
        
        // Setup notification observers for navigation
        setupNotificationObservers()
        
        if #available(iOS 16.6, *) {
            // Check for updates when app launches
            Task {
                await AppUpdateChecker.checkForUpdate()
            }
        }
    }

    private func setInitialRootViewController() {
        // Your existing logic to set the initial root view controller
        let contentView = SplashScreen()
        let hostingController = UIHostingController(rootView: contentView)
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
    }
    
    private func setupNotificationObservers() {
        // Observer for opening activity confirmation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenActivityConfirmation"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let activityId = userInfo["activityId"] as? String,
                  let dayOfWeek = userInfo["dayOfWeek"] as? String,
                  let isValidDay = userInfo["isValidDay"] as? Bool else { return }
            
            let confirmView = ScheduleRideConfirmActivity(
                activityId: activityId,
                activityDay: dayOfWeek,
                isValidDay: isValidDay
            )
            
            // Find the topmost view controller
            guard let rootViewController = self?.window?.rootViewController else { return }
            let topmostController = self?.findTopmostViewController(rootViewController)
            
            // If we're already showing a ScheduleRideConfirmActivity, dismiss it first
            if topmostController?.presentedViewController is UIHostingController<ScheduleRideConfirmActivity> {
                topmostController?.presentedViewController?.dismiss(animated: false) {
                    let hostingController = UIHostingController(rootView: confirmView)
                    hostingController.modalPresentationStyle = .fullScreen
                    topmostController?.present(hostingController, animated: true)
                }
                return
            }
            
            // Present over the current view controller
            let hostingController = UIHostingController(rootView: confirmView)
            hostingController.modalPresentationStyle = .fullScreen
            topmostController?.present(hostingController, animated: true)
        }
        
        // Observer for opening ongoing rides
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenOngoingRides"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Find the topmost view controller
            guard let rootViewController = self?.window?.rootViewController else { return }
            let topmostController = self?.findTopmostViewController(rootViewController)
            
            // If we already have a dashboard presented, just trigger navigation
            if topmostController?.presentedViewController is UIHostingController<DashboardView> {
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToOngoingRides"),
                    object: nil
                )
                return
            }
            
            // Otherwise, present a new dashboard with navigation flag
            let dashboardView = DashboardView(shouldNavigateToOngoingRides: true)
            let hostingController = UIHostingController(rootView: dashboardView)
            hostingController.modalPresentationStyle = .fullScreen
            topmostController?.present(hostingController, animated: true)
        }
        
        // Observer for opening dashboard
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenDashboard"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let dashboardView = DashboardView()
            self?.presentView(dashboardView)
        }
    }
    
    // Helper method to find the topmost view controller
    private func findTopmostViewController(_ controller: UIViewController) -> UIViewController {
        if let presentedController = controller.presentedViewController {
            return findTopmostViewController(presentedController)
        }
        
        switch controller {
        case let navigationController as UINavigationController:
            guard let topController = navigationController.topViewController else {
                return navigationController
            }
            return findTopmostViewController(topController)
            
        case let tabController as UITabBarController:
            guard let selectedController = tabController.selectedViewController else {
                return tabController
            }
            return findTopmostViewController(selectedController)
            
        default:
            return controller
        }
    }
    
    private func presentView<Content: View>(_ view: Content) {
        guard let rootViewController = window?.rootViewController else { return }
        let topmostController = findTopmostViewController(rootViewController)
        
        // If there's already a presented view controller, dismiss it first
        if let presentedViewController = topmostController.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                self.presentNewView(view, on: topmostController)
            }
        } else {
            presentNewView(view, on: topmostController)
        }
    }
    
    private func presentNewView<Content: View>(_ view: Content, on viewController: UIViewController) {
        let hostingController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: hostingController)
        navigationController.modalPresentationStyle = .fullScreen
        viewController.present(navigationController, animated: true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        if #available(iOS 16.6, *) {
            // Check for updates when app becomes active
            Task {
                await AppUpdateChecker.checkForUpdate()
            }
        }
    }


    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
}
