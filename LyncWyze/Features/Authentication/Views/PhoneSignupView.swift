//
//  PhoneSignupView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//

import SwiftUI

struct PhoneSignupView: View {
    @State private var phoneNumber = ""
    @State private var navigateToVerification = false
    @State private var navigateToEmailSignUp = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCountryPicker = false
    @State private var navigateToCreateProfile = false
    @State private var selectedCountry: Country?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Get country code from environment
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
        }
        return nil
    }()
    
    private let isVerifyOtp: String? = {
        if let otpShow = Bundle.main.object(forInfoDictionaryKey: "IsVerifyOtp") as? String, !otpShow.isEmpty {
            return otpShow
        }
        return nil
    }()
    
    private let countries: [Country]
    
    init() {
        // Load countries from JSON
        if let url = Bundle.main.url(forResource: "countryCode", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loadedCountries = try? JSONDecoder().decode([Country].self, from: data) {
            countries = loadedCountries
            if let defaultCountry = loadedCountries.first(where: { $0.dialCode == Bundle.main.object(
                forInfoDictionaryKey: "COUNTRY_CODE"
            ) as! String? ?? "" }) {
                _selectedCountry = State(initialValue: defaultCountry)
            } else {
                // Set United States as default
                _selectedCountry = State(initialValue: loadedCountries.first(where: { $0.code == "US" }))
            }
        } else {
            countries = []
        }
    }
    
    private var effectiveCountryCode: String {
        if let code = countryCode {
            return code
        }
        return selectedCountry?.dialCode.replacingOccurrences(of: "+", with: "") ?? ""
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove any non-digit characters
        let digits = number.filter { $0.isNumber }
        return "+\(effectiveCountryCode)-\(digits)"
    }
    
    private func validatePhoneNumber(_ number: String) -> Bool {
        let formattedNumber = formatPhoneNumber(number)
        return formattedNumber.count >= 7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(NSLocalizedString("signup_with_mobile_number", comment: ""))
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            if (isVerifyOtp == "true") {
                Text(NSLocalizedString("otp_verification_message", comment: ""))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            
            // Phone Number Input with Country Code
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(NSLocalizedString("phone_number", comment: ""))
                        .font(.caption)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                }
                HStack(spacing: 8) {
                    if countryCode == nil {
                        Button(action: {
                            showCountryPicker = true
                        }) {
                            HStack(spacing: 4) {
                                if let country = selectedCountry {
                                    Text(country.flag)
                                        .font(.system(size: 16))
                                    Text(country.dialCode)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                } else {
                                    Text("🇺🇸")
                                        .font(.system(size: 16))
                                    Text("+1")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    HStack(spacing: 0) {
                        Text(countryCode != nil ? "+" + countryCode! : "")
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                        
                        TextField(NSLocalizedString("phone_number", comment: ""), text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                            .foregroundColor(.primary)
                            .onChange(of: phoneNumber) { newValue in
                                // Only allow numbers and limit to 15 digits
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 15 {
                                    phoneNumber = String(filtered.prefix(15))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                            .padding(.leading, 4)
                    }
                    .padding(.vertical, 14)
                    .padding(.trailing, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .disabled(isLoading)
                }
                .padding(.bottom, 24)
            }

            Button(action: {
                if isVerifyOtp == nil {
                    Task {
                        await signupUser()
                    }
                } else if (isVerifyOtp == "true") {
                    generatePhoneOTP()
                } else {
                    Task {
                        await signupUser()
                    }
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

            Button(action: {
                navigateToEmailSignUp = true
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.primary)
                    Text(NSLocalizedString("signup_with_email", comment: ""))
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
                NavigationLink(destination: EmailSignInView()) {
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
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(NSLocalizedString("notice", comment: "")),
                message: Text(alertMessage),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: "")))
            )
        }
        .navigationDestination(isPresented: $navigateToVerification) {
            PhoneVerificationView(mobileNumber: formatPhoneNumber(phoneNumber))
        }
        .navigationDestination(isPresented: $navigateToEmailSignUp) {
            EmailSignupView()
        }
        .fullScreenCover(isPresented: $navigateToCreateProfile) {
            DashboardView()
        }
        .withCustomBackButton()
    }

    private func generatePhoneOTP() {
        if countryCode == nil && selectedCountry == nil {
            alertMessage = NSLocalizedString("please_select_country", comment: "")
            showAlert = true
            return
        }
        
        guard validatePhoneNumber(phoneNumber) else {
            alertMessage = NSLocalizedString("please_enter_valid_phone", comment: "")
            showAlert = true
            return
        }
        
        let formattedPhone = formatPhoneNumber(phoneNumber)
        isLoading = true

        NetworkManager.shared.makeRequest(
            endpoint: "/user/generateOtp/\(formattedPhone)",
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
        
        if countryCode == nil && selectedCountry == nil {
            alertMessage = NSLocalizedString("please_select_country", comment: "")
            showAlert = true
            return
        }
        
        guard validatePhoneNumber(phoneNumber) else {
            alertMessage = NSLocalizedString("please_enter_valid_phone", comment: "")
            showAlert = true
            return
        }
        
        let formattedPhone = formatPhoneNumber(phoneNumber)

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let fcmResult = await FCMUtilities.shared.getFCMToken()
        var fcmToken = ""
        if case .success(let token) = fcmResult {
            fcmToken = token
        }
       
        NetworkManager.shared.makeRequest(
            endpoint: "/user/createMobileNumberUser/\(formattedPhone)",
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
                    UserDefaults.standard
                        .saveAccessToken(
                            value: response.access_token,
                            expiresIn: response.expires_in,
                            refreshToken: response.refresh_token
                        )
                    UserDefaults.standard
                        .saveString(
                            value: formattedPhone,
                            forKey: UserDefaultsKeys
                                .phoneNumber)
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

struct PhoneSignupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PhoneSignupView()
                .preferredColorScheme(.light)
            
            PhoneSignupView()
                .preferredColorScheme(.dark)
        }
    }
}
