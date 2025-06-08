import SwiftUI

@main
struct LyncWyzeApp: App {
    // Keep AppDelegate for backward compatibility and existing functionality
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
        }
    }
}
