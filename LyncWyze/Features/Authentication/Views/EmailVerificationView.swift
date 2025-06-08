//
//  EmailVerificationView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//

import SwiftUI
struct EmailVerificationView: View {
    @StateObject private var userState = UserState.shared
    @State private var otpFields: [String] = Array(repeating: "", count: 4)
    @State private var currentField: Int = 0
    @FocusState private var focusedField: Int?
    @State private var showAlert = false
    @State private var isSuccess = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToCreateProfile = false

    let email: String

    var body: some View {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text(NSLocalizedString("enter_verification_code", comment: ""))
                            .font(.system(size: 24, weight: .semibold))
                       
                        Text(String(format: NSLocalizedString("sent_to_email", comment: ""), email))
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 40)
                   
                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            OTPTextField(text: $otpFields[index],
                                       isFocused: focusedField == index,
                                       onCommit: { moveToNextField(from: index) })
                            .focused($focusedField, equals: index)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                   
                    Button(action: {
                        Task {
                            do {
                                isLoading = true
                                let success = try await NetworkManager.shared.resendEmailOtpAsync(email: email)
                                isLoading = false
                                isSuccess = success
                                alertMessage = success ? NSLocalizedString("verification_code_sent", comment: "") : NSLocalizedString("error_sending_code", comment: "")
                                showAlert = true
                            } catch {
                                isLoading = false
                                isSuccess = false
                                alertMessage = String(format: NSLocalizedString("error_prefix", comment: ""), error.localizedDescription)
                                showAlert = true
                            }
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("did_not_receive_code", comment: ""))
                                .foregroundColor(.gray)
                            Text(NSLocalizedString("resend_verification_code", comment: ""))
                                .foregroundColor(Color(red: 76/255, green: 187/255, blue: 149/255))
                        }
                    }
                    .disabled(isLoading)
                    .padding(.bottom, 40)
                   
                    Spacer()
                   
                    Button(action: {
                        Task {
                            await verifyOTP()
                        }
                    }) {
                        ZStack {
                            Text(NSLocalizedString("submit", comment: ""))
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
                        .background(
                            otpFields.joined().count == 4 ?
                            Color(red: 76/255, green: 187/255, blue: 149/255) :
                                Color(red: 76/255, green: 187/255, blue: 149/255).opacity(0.5)
                        )
                        .cornerRadius(8)
                    }
                    .disabled(otpFields.joined().count != 4 || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .alert(isSuccess ? NSLocalizedString("success", comment: "") : NSLocalizedString("error", comment: ""), isPresented: $showAlert) {
                    Button(NSLocalizedString("ok", comment: "")) {
                        if isSuccess && !alertMessage.contains(NSLocalizedString("sent successfully", comment: "")) {
                            navigateToCreateProfile = true
                        } else if !isSuccess {
                            resetOTPFields()
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                .fullScreenCover(isPresented: $navigateToCreateProfile) {
                    DashboardView()
                }
                .withCustomBackButton()
    }

    private func moveToNextField(from currentIndex: Int) {
        if currentIndex < 3 {
            focusedField = currentIndex + 1
        } else {
            focusedField = nil
        }
    }

    private func resetOTPFields() {
        otpFields = Array(repeating: "", count: 4)
        focusedField = 0
    }

    private func verifyOTP() async {
        let otp = otpFields.joined()
        guard !otp.isEmpty else { return }
       
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
            endpoint: "/user/verifyEmailOtpAndCreateUser/\(otp)/\(encodedEmail)",
            method: .GET,
            headers: [
                "token": fcmToken,
                "type": "mobile",
                "platform": "iOS",
                "version": osVersionString
            ]
        ) { (result: Result<AuthResponse, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    UserDefaults.standard.saveAccessToken(value: response.access_token, expiresIn: response.expires_in,
                        refreshToken: response.refresh_token)
                    UserDefaults.standard
                        .saveString(
                            value: email,
                            forKey: UserDefaultsKeys.emailAddress
                        )
                    saveUserDefaultObject(response, forKey: Constants.UserDefaultsKeys.loggedInDataKey)
                    UserState.shared.setUserData(userId: response.userId)
                    self.isSuccess = true
                    self.alertMessage = NSLocalizedString("email_verified_successfully", comment: "")
                    self.showAlert = true

                   
                case .failure(let error):
                    self.isSuccess = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            self.alertMessage = message
                        case .invalidURL:
                            self.alertMessage = NSLocalizedString("invalid_url", comment: "")
                        case .invalidResponse:
                            self.alertMessage = NSLocalizedString("invalid_response", comment: "")
                        case .noData:
                            self.alertMessage = NSLocalizedString("no_data", comment: "")
                        case .decodingError(let decodingError):
                            self.alertMessage = String(format: NSLocalizedString("error_processing_response", comment: ""), decodingError.localizedDescription)
                        case .encodingError:
                            alertMessage = NSLocalizedString("error_processing_encode", comment: "")
                        }
                    } else {
                        self.alertMessage = NSLocalizedString("unknown_error", comment: "")
                    }
                   
                    self.showAlert = true
                    self.resetOTPFields()
                    print("Error: \(error)") // Debug print
                }
            }
        }
    }
}

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationView(email: "abc@gmail.com")
    }
}
