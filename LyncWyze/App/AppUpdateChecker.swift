import Foundation
import UIKit
import StoreKit

@available(iOS 16.6, *)
class AppUpdateChecker {
    // Singleton instance for alert window management
    private static var alertWindow: UIWindow?
    
    static func checkForUpdate() async {
        do {
            let bundleId = Bundle.main.bundleIdentifier ?? ""
            let appStoreURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)")!

            let (data, _) = try await URLSession.shared.data(from: appStoreURL)

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let appStoreVersion = results.first?["version"] as? String {
                
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                if compareVersions(currentVersion, appStoreVersion) == .orderedAscending {
                    await MainActor.run {
                        showUpdateAlert(newVersion: appStoreVersion)
                    }
                }
            }
        } catch {
            print("Error checking for app update: \(error)")
        }
    }
    
    private static func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let v1Components = version1.components(separatedBy: ".")
        let v2Components = version2.components(separatedBy: ".")
        
        let length = max(v1Components.count, v2Components.count)
        
        for i in 0..<length {
            let v1 = i < v1Components.count ? (Int(v1Components[i]) ?? 0) : 0
            let v2 = i < v2Components.count ? (Int(v2Components[i]) ?? 0) : 0
            
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
    
    private static func showUpdateAlert(newVersion: String) {
        // Check if alert is already being shown
        if alertWindow != nil {
            return
        }
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            
            // Create a new window at a higher level
            alertWindow = UIWindow(windowScene: windowScene)
            alertWindow?.windowLevel = .alert + 1
            alertWindow?.backgroundColor = .clear
            
            // Create a transparent view controller
            let alertViewController = UIViewController()
            alertViewController.view.backgroundColor = .clear
            alertWindow?.rootViewController = alertViewController
            alertWindow?.makeKeyAndVisible()
            
            let alert = UIAlertController(
                title: "Update Available",
                message: "A new version (\(newVersion)) of LyncWyze is available on the App Store. Would you like to update now?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
                if let url = URL(string: Constants.URLStrings.appStoreUrl) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                cleanupAlert()
            })
            
            alert.addAction(UIAlertAction(title: "Later", style: .cancel) { _ in
                cleanupAlert()
            })
            
            alertViewController.present(alert, animated: true)
        }
    }
    
    private static func cleanupAlert() {
        alertWindow?.isHidden = true
        alertWindow = nil
    }
    
    private static func findTopmostViewController(_ controller: UIViewController) -> UIViewController {
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
} 
