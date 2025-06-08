//
//  CreateProfileView+Step1.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 08/03/25.
//
import SwiftUI

struct CreateProfileView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var phoneNumberWithCountryCode = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showAlert = false
    @State private var navigateToHomeAddressStep2 = false
    @State private var navigateToAppLanding = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @StateObject private var userState = UserState.shared
    @State private var isEmailDisabled = false
    @State private var isPhoneDisabled = false
    @State private var showEmailField = true
    @State private var selectedCountry: Country?
    @State private var showCountryPicker = false
    @Environment(\.colorScheme) private var colorScheme

    private let countries: [Country]
    
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
        }
        return nil
    }()
    
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
    
    let showBackButton: Bool
    
    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
        
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
    
    private let profileService = ProfileService()
    
    private var containsUppercase: Bool {
        password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    private var containsNumberOrSpecialCharacter: Bool {
        password.rangeOfCharacter(from: .decimalDigits) != nil ||
        password.rangeOfCharacter(from: .symbols) != nil
    }
    
    private var isAtLeast8Characters: Bool {
        password.count >= 8
    }
    
    private var passwordsMatch: Bool {
        return password == confirmPassword && !password.isEmpty
    }
    
    private var passwordStrength: String {
        if isAtLeast8Characters && containsUppercase && containsNumberOrSpecialCharacter {
            return "Strong"
        } else if isAtLeast8Characters {
            return "Medium"
        } else {
            return "Weak"
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
//        !ssn.isEmpty &&
//        ssn.count == 4 &&
        password.count >= 8 &&
        containsUppercase &&
        containsNumberOrSpecialCharacter &&
        passwordsMatch &&
        passwordStrength == "Strong"
    }
    
    private func handleCreateProfile() {
        var loginResponse:AuthResponse? = getUserDefaultObject(
            forKey: Constants.UserDefaultsKeys.loggedInDataKey
        ) ?? nil
        if(loginResponse != nil){
            userState.setUserData(userId: loginResponse?.userId ?? "")
        }
        guard let userId = userState.userId else {
            showAlert = true
            errorMessage = "User ID not found. Please try again."
            return
        }
        
        guard isFormValid else {
            showAlert = true
            errorMessage = "Please fill all fields correctly"
            return
        }
        
        if showEmailField {
            phoneNumberWithCountryCode = UserDefaults.standard
                .getString(forKey: UserDefaultsKeys.phoneNumber) ?? ""
        } else {
            email = UserDefaults.standard
                .getString(forKey: UserDefaultsKeys.emailAddress) ?? ""
            phoneNumberWithCountryCode = formatPhoneNumber(phoneNumber)
        }
        
        isLoading = true
        print("🚀 Starting profile creation...")
        
        if showEmailField {
            let request = CreateProfileRequestFromEmail(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
            profileService.createProfileFromEmail(request: request) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        print("✅ Profile Creation Successful!")
                        print("Created Profile Details:")
                        print("ID: \(response.id)")
                        print("Name: \(response.firstName) \(response.lastName)")
                        print("Email: \(response.email)")
                        if(loginResponse != nil) {
                            loginResponse!.profileStatus = ProfileStatus.background
                            saveUserDefaultObject(
                                loginResponse,
                                forKey: Constants.UserDefaultsKeys
                                    .loggedInDataKey)
                        }
                        
                        self.navigateToHomeAddressStep2 = true
                        
                    case .failure(let error):
                        print("❌ Profile Creation Failed:")
                        print(error.localizedDescription)
                        self.errorMessage = "Failed to create profile: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
        else {
            let request = CreateProfileRequestFromMobile(
                firstName: firstName,
                lastName: lastName,
                mobileNumber: phoneNumberWithCountryCode,
                password: password,
                confirmPassword: confirmPassword
            )
            profileService.createProfileFromMobile(request: request) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        print("✅ Profile Creation Successful!")
                        print("Created Profile Details:")
                        print("ID: \(response.id)")
                        print("Name: \(response.firstName) \(response.lastName)")
                        print("Email: \(response.email)")
                        if(loginResponse != nil) {
                            loginResponse!.profileStatus = ProfileStatus.background
                            saveUserDefaultObject(
                                loginResponse,
                                forKey: Constants.UserDefaultsKeys
                                    .loggedInDataKey)
                        }
                        
                        self.navigateToHomeAddressStep2 = true
                        
                    case .failure(let error):
                        print("❌ Profile Creation Failed:")
                        print(error.localizedDescription)
                        self.errorMessage = "Failed to create profile: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
        
        
    }
    
    var body: some View {
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("create_profile", comment: ""))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                logout()
                                navigateToAppLanding = true
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                        }

                        Text(NSLocalizedString("let_us_know", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        Group {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(NSLocalizedString("first_name", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField(NSLocalizedString("first_name", comment: ""), text: $firstName)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(NSLocalizedString("last_name", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField(NSLocalizedString("last_name", comment: ""), text: $lastName)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)

                            }
                            
                            if showEmailField {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(NSLocalizedString("email", comment: ""))
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                        Text("*")
                                            .foregroundColor(.red)
                                    }
                                    TextField(NSLocalizedString("email", comment: ""), text: $email)
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(8)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disabled(isEmailDisabled)
                                        .foregroundColor(.primary)
                                }
                            }
                            else {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(NSLocalizedString("mobile_number", comment: ""))
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
                                            if countryCode != nil {
                                                Text("+" + countryCode!)
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 12)
                                            }
                                            
                                            TextField(NSLocalizedString("mobile_number", comment: ""), text: $phoneNumber)
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
                                                .padding(.leading, 12)
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.trailing, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .disabled(isPhoneDisabled)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(NSLocalizedString("password", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                HStack {
                                    Group {
                                        if isPasswordVisible {
                                            TextField(NSLocalizedString("password", comment: ""), text: $password)
                                                .foregroundColor(.primary)
                                        } else {
                                            SecureField(NSLocalizedString("password", comment: ""), text: $password)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    
                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(NSLocalizedString("confirm_password", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                HStack {
                                    Group {
                                        if isConfirmPasswordVisible {
                                            TextField(NSLocalizedString("confirm_password", comment: ""), text: $confirmPassword)
                                                .foregroundColor(.primary)
                                        } else {
                                            SecureField(NSLocalizedString("confirm_password", comment: ""), text: $confirmPassword)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    
                                    Button(action: {
                                        isConfirmPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PasswordRequirementView(
                                isValid: passwordStrength == "Strong",
                                text: NSLocalizedString("password_strength", comment: "") + ": \(passwordStrength)"
                            )
                            
                            PasswordRequirementView(
                                isValid: containsUppercase,
                                text: NSLocalizedString("contains_uppercase", comment: "")
                            )
                            
                            PasswordRequirementView(
                                isValid: isAtLeast8Characters,
                                text: NSLocalizedString("min_8_chars", comment: "")
                            )
                            
                            PasswordRequirementView(
                                isValid: containsNumberOrSpecialCharacter,
                                text: NSLocalizedString("contains_number_special", comment: "")
                            )
                            
                            PasswordRequirementView(
                                isValid: passwordsMatch,
                                text: NSLocalizedString("passwords_match", comment: "")
                            )
                        }
                        .padding(.top, 8)
                        
                        // Submit Button
                        Button(action: handleCreateProfile) {
                            ZStack {
                                Text(NSLocalizedString("next_home_address", comment: ""))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color.primaryButton : Color.gray)
                                    .cornerRadius(8)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16) // Keeps content below the status bar
                }
                .safeAreaInset(edge: .top) { EmptyView().frame(height: 0) } // Prevents scrolling into status bar
                .safeAreaInset(edge: .bottom) { EmptyView().frame(height: 20) } // Prevents overlap with home indicator
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(NSLocalizedString("error_alert_title", comment: "")),
                    message: Text(errorMessage),
                    dismissButton: .default(Text(NSLocalizedString("ok_button", comment: "")))
                )
            }
            .navigationDestination(
                isPresented: $navigateToHomeAddressStep2
            ) {
                CreateHomeAddressView(showBackButton: true)
            }
            .fullScreenCover(isPresented: $navigateToAppLanding) {
                AppLanding()
                    .navigationBarBackButtonHidden(true)
            }
            .withCustomBackButton(showBackButton: showBackButton)
            .onAppear {
                let loginResponse:AuthResponse? = getUserDefaultObject(
                    forKey: Constants.UserDefaultsKeys.loggedInDataKey
                ) ?? nil

                if(loginResponse != nil){
                    if let emailId = loginResponse?.emailId {
                        email = emailId
                        isEmailDisabled = true
                        showEmailField = false
                    }
                    if let name = loginResponse?.name {
                        // Check if name contains only numbers and optional + prefix
                        if name.trimmingCharacters(in: .whitespaces).range(of: "^\\+?\\d+$", options: .regularExpression) != nil {
                            // Name is a phone number
                            phoneNumber = name
                            isPhoneDisabled = true
                            showEmailField = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
            }
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateProfileView()
                .preferredColorScheme(.light)
            
            CreateProfileView()
                .preferredColorScheme(.dark)
        }
    }
}
