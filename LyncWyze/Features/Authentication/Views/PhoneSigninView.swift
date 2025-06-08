//
//  PhoneSigninView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//

import SwiftUI

struct PhoneSigninView: View {
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToDashboard = false
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country?
    @Environment(\.colorScheme) private var colorScheme
    
    // Get country code from environment
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
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
    
    private func loginUser() {
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
        
        guard !password.isEmpty else {
            alertMessage = NSLocalizedString("please_enter_password", comment: "")
            showAlert = true
            return
        }
        
        isLoading = true
        let formattedPhone = formatPhoneNumber(phoneNumber)
        print(phoneNumber)
        print(formattedPhone)
        AuthenticationService.shared.login(
            identifier: formattedPhone,
            password: password,
            authType: .phone
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // Clear input fields
                    phoneNumber = ""
                    password = ""
                    // Navigate to dashboard
                    navigateToDashboard = true
                    
                case .failure(let error):
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
                        case .decodingError(let decodingError):
                            alertMessage = String(format: NSLocalizedString("error_processing_response", comment: ""), decodingError.localizedDescription)
                            print("🔍 Decoding Error Details: \(decodingError)")
                        case .encodingError:
                            alertMessage = NSLocalizedString("error_processing_encode", comment: "")
                        }
                    } else {
                        alertMessage = NSLocalizedString("unknown_error", comment: "")
                    }
                    showAlert = true
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(NSLocalizedString("sign_in_with_phone", comment: ""))
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
           
            Text(NSLocalizedString("sign_in_with_registered_phone", comment: ""))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
           
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
                        Button {
                            showCountryPicker = true
                        } label: {
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
                .padding(.bottom, 16)
            }
           
            // Password Field
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(NSLocalizedString("password", comment: ""))
                        .font(.caption)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                }
                HStack {
                    if isPasswordVisible {
                        TextField(NSLocalizedString("password", comment: ""), text: $password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .foregroundColor(.primary)
                    } else {
                        SecureField(NSLocalizedString("password", comment: ""), text: $password)
                            .textContentType(.password)
                            .foregroundColor(.primary)
                    }
                   
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.bottom, 24)
                .disabled(isLoading)
            }
           
            // Continue Button
            Button {
                loginUser()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(NSLocalizedString("sign_in", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.primaryButton)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
            
            // Or Divider
            HStack {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
                
                Text(NSLocalizedString("or", comment: ""))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
            }
            .padding(.vertical, 24)
            
            // Sign in with Email Button
            NavigationLink(destination: EmailSignInView()) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.primary)
                    Text(NSLocalizedString("sign_in_with_email", comment: ""))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .disabled(isLoading)
       
            Spacer()
            
            // Create Account Link
            HStack {
                Spacer()
                NavigationLink(destination: PhoneSignupView()) {
                    HStack {
                        Text(NSLocalizedString("dont_have_account", comment: ""))
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("lets_create", comment: ""))
                            .foregroundColor(Color.primaryButton)
                    }
                    .padding(.vertical, 8)
                }
                Spacer()
            }
            .padding(.bottom, 16)
            .disabled(isLoading)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
        }
        .withCustomBackButton()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(NSLocalizedString("error", comment: "")),
                message: Text(alertMessage),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: "")))
            )
        }
        .fullScreenCover(isPresented: $navigateToDashboard) {
            DashboardView()
        }
    }
}

struct PhoneSigninView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PhoneSigninView()
                .preferredColorScheme(.light)
            
            PhoneSigninView()
                .preferredColorScheme(.dark)
        }
    }
}
