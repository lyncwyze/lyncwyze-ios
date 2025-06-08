import SwiftUI

struct HandleEmergencyContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var contactsManager: EmergencyContactsManager
    @State private var contact: EmergencyContact
    var onDismiss: (() -> Void)?
    @State private var isLoading = false
    @State private var showDeleteConfirmation = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDeletingContact = false
    @State private var navigateToAppLanding = false
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country?
    let showBackButton: Bool
    let isOnboardingComplete: Bool
    @State private var navigateToDashboard: Bool = false
    
    // Get country code from environment
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
        }
        return nil
    }()
    
    private let countries: [Country]
    
    private func parsePhoneNumber(_ fullNumber: String) -> (countryCode: String, number: String) {
        let components = fullNumber.split(separator: "-")
        if components.count == 2 {
            let countryCode = String(components[0].dropFirst()) // Remove the "+" prefix
            let number = String(components[1])
            return (countryCode, number)
        }
        return ("1", fullNumber) // Default fallback
    }
    
    init(
        contactsManager: EmergencyContactsManager,
        contact: EmergencyContact? = nil,
        showBackButton: Bool = true,
        isOnboardingComplete: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        self.contactsManager = contactsManager
        self._contact = State(initialValue: contact ?? EmergencyContact())
        self.showBackButton = showBackButton
        self.isOnboardingComplete = isOnboardingComplete
        self.onDismiss = onDismiss
        
        // Load countries from JSON
        if let url = Bundle.main.url(forResource: "countryCode", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loadedCountries = try? JSONDecoder().decode([Country].self, from: data) {
            countries = loadedCountries
            
            // Parse the phone number if it exists
            if let existingContact = contact {
                let (parsedCountryCode, _) = parsePhoneNumber(existingContact.mobileNumber)
                if let defaultCountry = loadedCountries.first(where: { $0.dialCode == "+" + parsedCountryCode }) {
                    _selectedCountry = State(initialValue: defaultCountry)
                } else if let defaultCountry = loadedCountries.first(where: { $0.dialCode == Bundle.main.object(
                    forInfoDictionaryKey: "COUNTRY_CODE"
                ) as! String? ?? "" }) {
                    _selectedCountry = State(initialValue: defaultCountry)
                } else {
                    // Set United States as default
                    _selectedCountry = State(initialValue: loadedCountries.first(where: { $0.code == "US" }))
                }
            } else {
                if let defaultCountry = loadedCountries.first(where: { $0.dialCode == Bundle.main.object(
                    forInfoDictionaryKey: "COUNTRY_CODE"
                ) as! String? ?? "" }) {
                    _selectedCountry = State(initialValue: defaultCountry)
                } else {
                    // Set United States as default
                    _selectedCountry = State(initialValue: loadedCountries.first(where: { $0.code == "US" }))
                }
            }
        } else {
            countries = []
        }
        
        // Set the initial phone number without country code
        if let existingContact = contact {
            let (_, number) = parsePhoneNumber(existingContact.mobileNumber)
            self._contact = State(initialValue: {
                var contact = existingContact
                contact.mobileNumber = number
                return contact
            }())
        }
    }
    
    // Validation states
    @State private var firstNameError = ""
    @State private var lastNameError = ""
    @State private var phoneError = ""
    @State private var emailError = ""
    
    private func validatePhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{7,}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove any non-digit characters
        let digits = number.filter { $0.isNumber }
        let effectiveCountryCode = countryCode ?? selectedCountry?.dialCode.replacingOccurrences(of: "+", with: "") ?? "1"
        return "+\(effectiveCountryCode)-\(digits)"
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validateField() -> Bool {
        var isValid = true
        
        // Reset errors
        firstNameError = ""
        lastNameError = ""
        phoneError = ""
        emailError = ""
        
        // Validate first name
        if contact.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            firstNameError = "First name is required"
            isValid = false
        }
        
        // Validate last name
        if contact.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastNameError = "Last name is required"
            isValid = false
        }
        
        // Validate phone number
        if contact.mobileNumber.isEmpty {
            phoneError = "Phone number is required"
            isValid = false
        } else if !validatePhoneNumber(contact.mobileNumber) {
            phoneError = "Please enter a valid phone number"
            isValid = false
        }
        
        // Validate email if provided
        if let email = contact.email, !email.isEmpty {
            if !validateEmail(email) {
                emailError = "Please enter a valid email address"
                isValid = false
            }
        }
        
        return isValid
    }
    
    private func saveContact() {
        if validateField() {
            isLoading = true
            contact.mobileNumber = formatPhoneNumber(contact.mobileNumber)
            if contact.id != nil {
                contactsManager.updateContact(contact)
            } else {
                contactsManager.addContact(contact)
            }
            isLoading = false
            if isOnboardingComplete == false {
                Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                navigateToDashboard = true
            } else {
                onDismiss?()
                dismiss()
            }
//            onDismiss?()
//            dismiss()
        }
    }
    
    private func deleteContact() {
        guard let id = contact.id else { return }
        isDeletingContact = true
        
        contactsManager.deleteContact(id: id)
        isDeletingContact = false
        onDismiss?()
        dismiss()
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("first_name", comment: ""))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            CustomTextFieldWithIcon(
                                placeholder: NSLocalizedString("first_name", comment: ""),
                                text: $contact.firstName,
                                icon: "person.fill",
                                isError: !firstNameError.isEmpty
                            )
                            .disabled(isLoading || isDeletingContact)
                            
                            if !firstNameError.isEmpty {
                                Text(firstNameError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("last_name", comment: ""))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            CustomTextFieldWithIcon(
                                placeholder: NSLocalizedString("last_name", comment: ""),
                                text: $contact.lastName,
                                icon: "person.fill",
                                isError: !lastNameError.isEmpty
                            )
                            .disabled(isLoading || isDeletingContact)
                            
                            if !lastNameError.isEmpty {
                                Text(lastNameError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("mobile_number", comment: ""))
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
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 16)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                HStack(spacing: 0) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                        .padding(.leading, 12)

                                    if countryCode != nil {
                                        Text("+" + countryCode!)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 12)
                                    }
                                    
                                    TextField(NSLocalizedString("mobile_number", comment: ""), text: $contact.mobileNumber)
                                        .keyboardType(.numberPad)
                                        .textContentType(.telephoneNumber)
                                        .foregroundColor(.primary)
                                        .onChange(of: contact.mobileNumber) { newValue in
                                            // Only allow numbers and limit to 15 digits
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count > 15 {
                                                contact.mobileNumber = String(filtered.prefix(15))
                                            } else {
                                                contact.mobileNumber = filtered
                                            }
                                        }
                                        .padding(.leading, 4)
                                }
                                .padding(.vertical, 10)
                                .padding(.trailing, 12)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(!phoneError.isEmpty ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .disabled(isLoading || isDeletingContact)
                            }
                            
                            if !phoneError.isEmpty {
                                Text(phoneError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("email_optional", comment: ""))
                                .foregroundColor(.primary)
                            CustomTextFieldWithIcon(
                                placeholder: NSLocalizedString("email_optional", comment: ""),
                                text: Binding(
                                    get: { contact.email ?? "" },
                                    set: { contact.email = $0.isEmpty ? nil : $0 }
                                ),
                                icon: "envelope.fill",
                                isError: !emailError.isEmpty
                            )
                            .keyboardType(.emailAddress)
                            .disabled(isLoading || isDeletingContact)
                            
                            if !emailError.isEmpty {
                                Text(emailError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
                
                if contact.id != nil {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("delete_contact", comment: ""))
                            Spacer()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .disabled(isLoading || isDeletingContact)
                }
                
                Button(action: saveContact) {
                    HStack {
                        Text(
                            isOnboardingComplete ? (contact.id == nil ? NSLocalizedString("save_contact", comment: "") : NSLocalizedString("update_contact", comment: "")) : NSLocalizedString("next_ready_schedule_ride", comment: "")
                        )
                            .bold()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.leading, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || isDeletingContact)
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isOnboardingComplete {
                    Text(contact.id == nil ? NSLocalizedString("add_contact", comment: "") : NSLocalizedString("edit_contact", comment: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 16)
                } else {
                    Text(NSLocalizedString("emergency_contacts", comment: ""))
                        .font(.title)
                        .foregroundColor(.primary)
                        .bold()
                }
            }
            
            if !isOnboardingComplete {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        logout()
                        navigateToAppLanding = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .withCustomBackButton(showBackButton: showBackButton)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $navigateToDashboard){
            DashboardView()
        }
        .fullScreenCover(isPresented: $navigateToAppLanding) {
            AppLanding()
                .navigationBarBackButtonHidden(true)
        }
        .confirmationDialog(
            NSLocalizedString("delete_contact", comment: ""),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("delete_button", comment: ""), role: .destructive) {
                deleteContact()
            }
            Button(NSLocalizedString("cancel_button", comment: ""), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("delete_contact_confirmation", comment: ""))
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
        }
    }
}

struct HandleEmergencyContactView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HandleEmergencyContactView(contactsManager: EmergencyContactsManager())
                .preferredColorScheme(.light)
            
            HandleEmergencyContactView(contactsManager: EmergencyContactsManager())
                .preferredColorScheme(.dark)
        }
    }
}
