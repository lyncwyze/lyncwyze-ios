import SwiftUI

struct SplashScreen: View {
    @State private var navigateToDashboard = false
    @State private var navigateToAppLanding = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // Logo
            VStack {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 198, height: 140)
            }
        }
        .onAppear {
            checkProfileStatus()
        }
        .fullScreenCover(isPresented: $navigateToDashboard) {
            DashboardView()
                .installToast()
        }
        .fullScreenCover(isPresented: $navigateToAppLanding) {
            AppLanding()
                .installToast()
        }
    }
    
    private func checkProfileStatus() {
        // Add a small delay to show the splash screen
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            if let accessToken = getAccessToken() {
                navigateToDashboard = true
            } else if let refreshToken = getRefreshToken() {
                // Try to refresh the token
                do {
                    let result = try await withCheckedThrowingContinuation { continuation in
                        AuthenticationService.shared.refreshAccessToken { result in
                            continuation.resume(with: result)
                        }
                    }
                    
                    // Save the new tokens and navigate to dashboard
                    saveAccessToken(
                        value: result.access_token,
                        expiresIn: result.expires_in,
                        refreshToken: result.refresh_token
                    )
                    navigateToDashboard = true
                } catch {
                    // If refresh fails, logout and go to landing
                    logout()
                    navigateToAppLanding = true
                }
            } else {
                // No tokens available, logout and go to landing
                navigateToAppLanding = true
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
} 
