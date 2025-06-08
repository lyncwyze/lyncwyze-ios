import Foundation
import UIKit
import SwiftDate

// MARK: - App Utility Class
final class AppUtility {
    // MARK: - Properties
    static var exitWarningShown = false
    
    // MARK: - Navigation Methods
    public static func goBack(animated: Bool = true) {
        if let topViewController = getTopViewController() {
            if topViewController.presentingViewController != nil {
                self.exitWarningShown = false
                topViewController.dismiss(animated: animated, completion: nil)
            } else {
                showExitWarning(msg: "Press one more time to exit app")
            }
        }
    }
    
    public static func openViewController(_ viewController: UIViewController, animated: Bool = true, rightToLeft: Bool = false) {
        if let topViewController = getTopViewController() {
            viewController.modalPresentationStyle = .fullScreen
            if rightToLeft {
                viewController.modalTransitionStyle = .coverVertical
                if animated {
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = .push
                    transition.subtype = .fromRight
                    topViewController.view.window?.layer.add(transition, forKey: kCATransition)
                }
                topViewController.present(viewController, animated: false, completion: nil)
            } else {
                topViewController.present(viewController, animated: animated, completion: nil)
            }
        }
    }
    
    public static func presentFromRight(viewController: UIViewController, presentingViewController: UIViewController) {
        viewController.view.transform = CGAffineTransform(translationX: presentingViewController.view.frame.width, y: 0)
        presentingViewController.present(viewController, animated: true) {
            UIView.animate(withDuration: 0.5) {
                viewController.view.transform = CGAffineTransform.identity
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private static func showExitWarning(msg: String) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }
        
        if exitWarningShown {
            exit(0)
        }
        
        let warningLabel = UILabel()
        warningLabel.text = msg
        warningLabel.textAlignment = .center
        warningLabel.textColor = .white
        warningLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        warningLabel.layer.cornerRadius = 10
        warningLabel.clipsToBounds = true
        warningLabel.font = UIFont.systemFont(ofSize: 14)
        warningLabel.alpha = 0
        
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(warningLabel)
        
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            warningLabel.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            warningLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            warningLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, animations: {
            warningLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                warningLabel.alpha = 0
            }, completion: { _ in
                warningLabel.removeFromSuperview()
                exitWarningShown = false
            })
        })
        
        exitWarningShown = true
    }
    
    private static func getTopViewController(base: UIViewController? = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController {
            return getTopViewController(base: tab.selectedViewController)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
    
    // MARK: - Date Formatting Methods
    public static func formatDate(_ dateString: String, format: String) -> String? {
        if let date = dateString.toDate(region: SwiftDate.defaultRegion) {
            return date.toFormat(format)
        } else {
            return "---"
        }
    }
    
    // MARK: - Utility Methods
    public static func roundOffDouble(number: Double, decimals: Int) -> Double {
        return Double((number * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals)))
    }
    
    public static func mapDayToAPIFormat(_ day: String) -> String {
        switch day {
        case "Mon": return "MONDAY"
        case "Tue": return "TUESDAY"
        case "Wed": return "WEDNESDAY"
        case "Thu": return "THURSDAY"
        case "Fri": return "FRIDAY"
        case "Sat": return "SATURDAY"
        case "Sun": return "SUNDAY"
        default: return day
        }
    }
    
    public static func mapAPIFormatToDay(_ day: String) -> String {
        switch day {
        case "MONDAY": return "Mon"
        case "TUESDAY": return "Tue"
        case "WEDNESDAY": return "Wed"
        case "THURSDAY": return "Thu"
        case "FRIDAY": return "Fri"
        case "SATURDAY": return "Sat"
        case "SUNDAY": return "Sun"
        default: return day
        }
    }
}


func compressImage(_ image: UIImage, maxSizeInMB: Double = 0.8) -> Data? {
    let maxSizeInBytes = Int(maxSizeInMB * 1024 * 1024)
    var compression: CGFloat = 0.9
    let minCompression: CGFloat = 0.1

    guard var imageData = image.jpegData(compressionQuality: compression) else { return nil }

    while imageData.count > maxSizeInBytes && compression > minCompression {
        compression -= 0.1
        if let compressedData = image.jpegData(compressionQuality: compression) {
            imageData = compressedData
        } else {
            break
        }
    }

    // Optional: Resize image if still too big
    if imageData.count > maxSizeInBytes {
        let resizedImage = resizeImage(image, targetWidth: 800)
        return resizedImage.jpegData(compressionQuality: compression)
    }

    return imageData
}

func resizeImage(_ image: UIImage, targetWidth: CGFloat) -> UIImage {
    let size = image.size
    let scale = targetWidth / size.width
    let targetHeight = size.height * scale

    let newSize = CGSize(width: targetWidth, height: targetHeight)
    let renderer = UIGraphicsImageRenderer(size: newSize)

    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
