import SwiftUI

struct NotifyMeView: View {
    @State private var fullName: String = ""
    @State private var emailAddress: String = ""
    @State private var mobileNumber: String = ""
    @State private var newsletterSubscription: Bool = true
    @State private var showPopup: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    @State private var showCountryPicker: Bool = false
    @State private var selectedCountry: Country?
    
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validateFields() -> Bool {
        if fullName.isEmpty {
            validationMessage = NSLocalizedString("please_enter_name", comment: "")
            return false
        }
        
        if emailAddress.isEmpty {
            validationMessage = NSLocalizedString("please_enter_email", comment: "")
            return false
        }
        
        if !isValidEmail(emailAddress) {
            validationMessage = NSLocalizedString("please_enter_valid_email", comment: "")
            return false
        }
        
        return true
    }
    
    private func handleAPIError(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .apiError(let message):
                if message.lowercased().contains("duplicate key") && message.lowercased().contains("email") {
                    return NSLocalizedString("email_already_registered", comment: "")
                }
                return message
            case .invalidURL:
                return NSLocalizedString("invalid_request", comment: "")
            case .invalidResponse:
                return NSLocalizedString("server_error", comment: "")
            case .noData:
                return NSLocalizedString("no_server_response", comment: "")
            case .decodingError:
                return NSLocalizedString("error_processing_response", comment: "")
            case .encodingError:
                return NSLocalizedString("error_processing_encode", comment: "")
            }
        }
        return error.localizedDescription
    }
    
    private func submitNotification() {
        if !validateFields() {
            showValidationAlert = true
            return
        }
        
        print("🚀 Starting notification submission...")
        print("📝 Input values - Full Name: \(fullName), Email: \(emailAddress), Mobile: \(mobileNumber), Newsletter: \(newsletterSubscription)")
        
        isLoading = true
        errorMessage = nil
        
        let formattedPhone = mobileNumber.isEmpty ? nil : formatPhoneNumber(mobileNumber)
        
        let request = NotifyUserRequest(
            id: UUID().uuidString,
            name: fullName,
            email: emailAddress,
            mobileNumber: formattedPhone,
            newsletterSubscription: newsletterSubscription
        )
        
        guard let jsonData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode request data")
            errorMessage = "Failed to process request data"
            isLoading = false
            return
        }
        
        print("📡 Making network request to /match/addNotifyUser...")
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/addNotifyUser",
            method: .POST,
            body: jsonData
        ) { (result: Result<EmptyResponse, Error>) in
            print("📨 Received API response")
            
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    print("✅ API call successful")
                    withAnimation(.spring()) {
                        showPopup = true
                        errorMessage = nil
                    }
                case .failure(let error):
                    print("❌ API call failed with error: \(error.localizedDescription)")
                    let errorMsg = handleAPIError(error)
                    errorMessage = errorMsg
                    
                    if errorMsg.lowercased().contains("already registered") {
                        emailAddress = ""
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)

                Text(NSLocalizedString("enter_your_details", comment: ""))
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(NSLocalizedString("let_us_know", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                VStack(alignment: .leading) {
                    HStack {
                        Text(NSLocalizedString("full_name", comment: ""))
                            .font(.caption)
                        Text("*")
                            .foregroundColor(.red)
                    }
                    TextField(NSLocalizedString("full_name", comment: ""), text: $fullName)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .disabled(isLoading)
                        .onChange(of: fullName) { newValue in
                            errorMessage = nil
                            print("📝 Name field updated: \(newValue)")
                        }
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    HStack {
                        Text(NSLocalizedString("email_address", comment: ""))
                            .font(.caption)
                        Text("*")
                            .foregroundColor(.red)
                    }
                    TextField(NSLocalizedString("email_address", comment: ""), text: $emailAddress)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .disabled(isLoading)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: emailAddress) { newValue in
                            errorMessage = nil
                            print("📝 Email field updated: \(newValue)")
                        }
                }
                .padding(.horizontal)
                    
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("mobile_number", comment: ""))
                        .font(.caption)
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
                            
                            TextField(NSLocalizedString("mobile_number_optional", comment: ""), text: $mobileNumber)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                                .foregroundColor(.primary)
                                .onChange(of: mobileNumber) { newValue in
                                    // Only allow numbers and limit to 15 digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 15 {
                                        mobileNumber = String(filtered.prefix(15))
                                    } else {
                                        mobileNumber = filtered
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
                }
                .padding(.horizontal)
                
                Toggle(isOn: $newsletterSubscription) {
                    Text(NSLocalizedString("subscribe_newsletter", comment: ""))
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .disabled(isLoading)
                .tint(Color.primaryButton)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .transition(.opacity)
                        .animation(.easeInOut, value: error)
                        .multilineTextAlignment(.center)
                }

                Button(action: submitNotification) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        Text(NSLocalizedString("notify_me", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isButtonEnabled ? Color.primaryButton : Color.gray
                    )
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .disabled(!isButtonEnabled)
                .onChange(of: isLoading) { newValue in
                    print("🔄 Loading state changed: \(newValue)")
                }

                Spacer()
            }
            
            if showPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color.primaryButton)
                        .transition(.scale)
                    
                    Text(NSLocalizedString("thank_you", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .transition(.opacity)
                    
                    Text(NSLocalizedString("notify_area_message", comment: ""))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .transition(.opacity)

                    Button(action: {
                        withAnimation(.spring()) {
                            showPopup = false
                            fullName = ""
                            emailAddress = ""
                            mobileNumber = ""
                            newsletterSubscription = false
                        }
                    }) {
                        Text(NSLocalizedString("ok", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryButton)
                            .cornerRadius(8)
                            .padding(.horizontal, 40)
                    }
                    .transition(.scale)
                }
                .frame(width: 300, height: 350)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
                .transition(.scale)
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
        }
        .alert("Validation Error", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .withCustomBackButton(showBackButton: true)
    }
    
    private var isButtonEnabled: Bool {
        !isLoading && !fullName.isEmpty && !emailAddress.isEmpty
    }
}

struct NotifyMeView_Previews: PreviewProvider {
    static var previews: some View {
        NotifyMeView()
    }
}
