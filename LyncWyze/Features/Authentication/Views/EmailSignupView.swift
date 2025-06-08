//
//  EmailSignupView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//
import SwiftUI

struct EmailSignupView: View {
    @State private var email = ""
    @State private var navigateToVerification = false
    @State private var navigateToEmailSignIn = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var navigateToCreateProfile = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private let isVerifyOtp: String? = {
        if let otpShow = Bundle.main.object(forInfoDictionaryKey: "IsVerifyOtp") as? String, !otpShow.isEmpty {
            return otpShow
        }
        return nil
    }()

    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(NSLocalizedString("signup_with_email", comment: ""))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                if (isVerifyOtp == "true") {
                    Text(NSLocalizedString("otp_verification_message", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                }

                // Email Input Field
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(NSLocalizedString("email", comment: ""))
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("*")
                            .foregroundColor(.red)
                    }
                    TextField(NSLocalizedString("enter_your_email", comment: ""), text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.bottom, 24)

                Button(action: {
                    if isValidEmail(email) {
                        if isVerifyOtp == nil {
                            Task {
                                await signupUser()
                            }
                        } else if (isVerifyOtp == "true") {
                            generateEmailOTP()
                        } else {
                            Task {
                                await signupUser()
                            }
                        }
                    } else {
                        showAlert = true
                        alertMessage = NSLocalizedString("please_enter_valid_email", comment: "")
                    }
                }) {
                    ZStack {
                        Text(NSLocalizedString("continue", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(isLoading ? 0 : 1)
                       
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primaryButton)
                    .cornerRadius(8)
                }
                .disabled(isLoading)

                HStack {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)
                    
                    Text(NSLocalizedString("or", comment: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)
                }
                .padding(.vertical, 24)

                NavigationLink(destination: PhoneSignupView()) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.primary)
                        Text(NSLocalizedString("signup_with_mobile_number", comment: ""))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()

                // Create Account Link
                HStack {
                    Spacer()
                    Button(action: {
                        navigateToEmailSignIn = true
                    }) {
                        Text(NSLocalizedString("already_have_account", comment: ""))
                            .foregroundColor(.secondary) +
                        Text(NSLocalizedString("lets_sign_in", comment: ""))
                            .foregroundColor(Color.primaryButton)
                    }
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(NSLocalizedString("notice", comment: "")),
                    message: Text(alertMessage),
                    dismissButton: .default(Text(NSLocalizedString("ok", comment: "")))
                )
            }
            .navigationDestination(isPresented: $navigateToVerification) {
                EmailVerificationView(email: email)
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $navigateToEmailSignIn) {
                EmailSignInView()
            }
            .fullScreenCover(isPresented: $navigateToCreateProfile) {
                DashboardView()
            }
            .withCustomBackButton()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func generateEmailOTP() {
        isLoading = true
       
        NetworkManager.shared.makeRequest(
            endpoint: "/user/generateEmailOtp/\(email)",
            method: .GET
        ) { (result: Result<EmptyResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    isLoading = false
                    navigateToVerification = true
                case .failure(let error):
                    isLoading = false
                    showAlert = true
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            alertMessage = message
                        case .invalidURL:
                            alertMessage = NSLocalizedString("invalid_url", comment: "")
                        case .invalidResponse:
                            alertMessage = NSLocalizedString("invalid_response", comment: "")
                        case .noData:
                            alertMessage = NSLocalizedString("no_data", comment: "")
                        case .decodingError:
                            alertMessage = NSLocalizedString("error_processing_response", comment: "")
                        case .encodingError:
                            alertMessage = NSLocalizedString("error_processing_encode", comment: "")
                        }
                    } else {
                        alertMessage = NSLocalizedString("unknown_error", comment: "")
                    }
                }
            }
        }
    }
    
    private func signupUser() async {
        isLoading = true
        
        // URL encode the email address
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let fcmResult = await FCMUtilities.shared.getFCMToken()
        var fcmToken = ""
        if case .success(let token) = fcmResult {
            fcmToken = token
        }
       
        NetworkManager.shared.makeRequest(
            endpoint: "/user/createEmailUser/\(encodedEmail)",
            method: .GET,
            headers: [
                "token": fcmToken,
                "type": "mobile",
                "platform": "iOS",
                "version": osVersionString
            ]
        ) { (result: Result<AuthResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    navigateToCreateProfile = true
                    UserDefaults.standard.saveAccessToken(value: response.access_token, expiresIn: response.expires_in,
                        refreshToken: response.refresh_token)
                    UserDefaults.standard
                        .saveString(
                            value: email,
                            forKey: UserDefaultsKeys.emailAddress
                        )
                    saveUserDefaultObject(response, forKey: Constants.UserDefaultsKeys.loggedInDataKey)
                    UserState.shared.setUserData(userId: response.userId)
                    isLoading = false
                    
                case .failure(let error):
                    isLoading = false
                    showAlert = true
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            alertMessage = message
                        case .invalidURL:
                            alertMessage = NSLocalizedString("invalid_url", comment: "")
                        case .invalidResponse:
                            alertMessage = NSLocalizedString("invalid_response", comment: "")
                        case .noData:
                            alertMessage = NSLocalizedString("no_data", comment: "")
                        case .decodingError:
                            alertMessage = NSLocalizedString("error_processing_response", comment: "")
                        case .encodingError:
                            alertMessage = NSLocalizedString("error_processing_encode", comment: "")
                        }
                    } else {
                        alertMessage = NSLocalizedString("unknown_error", comment: "")
                    }
                }
            }
        }
    }

}

struct EmailSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmailSignupView()
                .preferredColorScheme(.light)
            
            EmailSignupView()
                .preferredColorScheme(.dark)
        }
    }
}
