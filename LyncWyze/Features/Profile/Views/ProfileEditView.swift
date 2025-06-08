import SwiftUI
import PhotosUI
import UIKit

struct ProfileEditView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    
    // Form Fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var landmark: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var pincode: String = ""
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country?
    
    // Validation Errors
    @State private var firstNameError: String = ""
    @State private var lastNameError: String = ""
    @State private var emailError: String = ""
    @State private var mobileNumberError: String = ""
    @State private var addressLine1Error: String = ""
    @State private var cityError: String = ""
    @State private var stateError: String = ""
    @State private var pincodeError: String = ""
    
    // Image Handling
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showImageOptions = false
    
    // Geocoding state
    @State private var isGeocodingLoading = false
    @State private var geocodingError: String?
    @State private var coordinates: [Double] = [0.0, 0.0]
    
    // Location suggestion state
    @State private var locations: [Location] = []
    @State private var showLocationsList = false
    @State private var selectedLocation: Location?
    @FocusState private var isAddressLine1Focused: Bool
    @State private var sessionToken: String = ""
    @State private var isSelectionInProgress = false
    @State private var hasEditedAddressLine1 = false
    
    // Alert handling
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isUpdating = false
    
    // Get country code from environment
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
        }
        return nil
    }()
    
    private let countries: [Country]
    
    init(profile: UserProfile) {
        self.profile = profile
        
        // Load countries from JSON
        if let url = Bundle.main.url(forResource: "countryCode", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loadedCountries = try? JSONDecoder().decode([Country].self, from: data) {
            countries = loadedCountries
            
            // Parse the phone number if it exists
            if let existingNumber = profile.mobileNumber {
                let components = existingNumber.split(separator: "-")
                if components.count == 2 {
                    let countryCode = String(components[0].dropFirst()) // Remove the "+" prefix
                    if let defaultCountry = loadedCountries.first(where: { $0.dialCode == "+" + countryCode }) {
                        _selectedCountry = State(initialValue: defaultCountry)
                    }
                }
            } else if let defaultCountry = loadedCountries.first(where: { $0.dialCode == Bundle.main.object(
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
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove any non-digit characters
        let digits = number.filter { $0.isNumber }
        let effectiveCountryCode = countryCode ?? selectedCountry?.dialCode.replacingOccurrences(of: "+", with: "") ?? "1"
        return "+\(effectiveCountryCode)-\(digits)"
    }
    
    private func parsePhoneNumber(_ fullNumber: String) -> (countryCode: String, number: String) {
        let components = fullNumber.split(separator: "-")
        if components.count == 2 {
            let countryCode = String(components[0].dropFirst()) // Remove the "+" prefix
            let number = String(components[1])
            return (countryCode, number)
        }
        return ("1", fullNumber) // Default fallback
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Image Section
                profileImageSection
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showImageOptions = true
                    }
                    .confirmationDialog(
                        NSLocalizedString("profile_image_options", comment: ""),
                        isPresented: $showImageOptions,
                        titleVisibility: .automatic
                    ) {
                        Button(NSLocalizedString("upload_new_image", comment: "")) {
                            showImagePicker = true
                        }
                        .disabled(profileManager.isLoading)
                        
                        if profile.image != nil {
                            Button(NSLocalizedString("delete_image", comment: ""), role: .destructive) {
                                Task {
                                    await deleteProfileImage()
                                }
                            }
                            .disabled(profileManager.isLoading)
                        }
                        Button(NSLocalizedString("cancel_button", comment: ""), role: .cancel) {}.disabled(profileManager.isLoading)
                    }

                // Name Section
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("first_name", comment: ""))
                                .foregroundColor(.primary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        MaterialTextField(
                            placeholder: NSLocalizedString("first_name", comment: ""),
                            text: $firstName,
                            error: firstNameError,
                            textAlignment: .center,
                            fontSize: 20,
                            isBold: true
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("last_name", comment: ""))
                                .foregroundColor(.primary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        MaterialTextField(
                            placeholder: NSLocalizedString("last_name", comment: ""),
                            text: $lastName,
                            error: lastNameError,
                            textAlignment: .center,
                            fontSize: 20,
                            isBold: true
                        )
                    }
                }
                
                // Basic Info Section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("email", comment: ""))
                                .foregroundColor(.primary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        MaterialTextField(
                            placeholder: NSLocalizedString("email", comment: ""),
                            text: $email,
                            error: emailError
                        )
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
                                
                                TextField(NSLocalizedString("mobile_number", comment: ""), text: $mobileNumber)
                                    .keyboardType(.numberPad)
                                    .textContentType(.telephoneNumber)
                                    .onChange(of: mobileNumber) { newValue in
                                        // Only allow numbers and limit to 15 digits
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered.count > 15 {
                                            mobileNumber = String(filtered.prefix(15))
                                        } else {
                                            mobileNumber = filtered
                                        }
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.leading, 12)
                            }
                            .padding(.vertical, 14)
                            .padding(.trailing, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        if !mobileNumberError.isEmpty {
                            Text(mobileNumberError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Divider()
                    .background(Color(.systemGray3))
                    .padding(.vertical, 8)
                
                // Address Section
                Text(NSLocalizedString("address", comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("address_line_1", comment: ""))
                                .foregroundColor(.primary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        MaterialTextField(
                            placeholder: NSLocalizedString("address_line_1", comment: ""),
                            text: $addressLine1,
                            error: addressLine1Error
                        )
                        .focused($isAddressLine1Focused)
                        .onChange(of: addressLine1) { newValue in
                            if isAddressLine1Focused {
                                hasEditedAddressLine1 = true
                                searchLocations()
                            }
                        }
                        .onChange(of: isAddressLine1Focused) { isFocused in
                            if !isFocused {
                                showLocationsList = false
                            }
                        }
                        
                        if isGeocodingLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if showLocationsList {
                            LocationSelectionView(
                                locations: locations,
                                onLocationSelected: { location in
                                    fillSuggestedLocation(location)
                                    isAddressLine1Focused = false
                                    hasEditedAddressLine1 = false // Reset edit flag after selection
                                }
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("address_line_2", comment: ""))
                            .foregroundColor(.primary)
                        MaterialTextField(
                            placeholder: NSLocalizedString("address_line_2", comment: ""),
                            text: $addressLine2
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("landmark", comment: ""))
                            .foregroundColor(.primary)
                        MaterialTextField(
                            placeholder: NSLocalizedString("landmark", comment: ""),
                            text: $landmark
                        )
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("city", comment: ""))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            MaterialTextField(
                                placeholder: NSLocalizedString("city", comment: ""),
                                text: $city,
                                error: cityError
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("state", comment: ""))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            MaterialTextField(
                                placeholder: NSLocalizedString("state", comment: ""),
                                text: $state,
                                error: stateError
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("zip_code", comment: ""))
                                .foregroundColor(.primary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        MaterialTextField(
                            placeholder: NSLocalizedString("zip_code", comment: ""),
                            text: $pincode,
                            error: pincodeError
                        )
                    }
                }
                
                // Save Button
                Button(action: { Task { await updateProfile() } }) {
                    if profileManager.isLoading || isGeocodingLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(NSLocalizedString("save", comment: ""))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 40)
                .padding(.bottom, 20)
                .disabled(profileManager.isLoading || isGeocodingLoading)
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("edit_profile_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .withCustomBackButton(showBackButton: true)
        .onAppear {
            loadProfileData()
            hasEditedAddressLine1 = false
            isUpdating = false
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button(NSLocalizedString("ok", comment: "")) {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: profileManager.isLoading) { loading in
            if !loading && profileManager.error == nil && isUpdating {
                isUpdating = false
                // Profile was updated successfully
                Task {
                    await profileManager.fetchUserProfile()
                    alertTitle = NSLocalizedString("success", comment: "")
                    alertMessage = NSLocalizedString("profile_updated_successfully", comment: "")
                    isSuccess = true
                    showAlert = true
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            PHPickerView(image: $selectedImage)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 100, height: 100)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
                    .frame(width: 100, height: 100)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadProfileData() {
        firstName = profile.firstName
        lastName = profile.lastName
        email = profile.email
        
        if let phoneNumber = profile.mobileNumber {
            // Parse the phone number to separate country code and number
            let (parsedCountryCode, number) = parsePhoneNumber(phoneNumber)
            mobileNumber = number // Show only the number part in text field
            
            // Set the selected country based on the parsed country code
            if let country = countries.first(where: { $0.dialCode == "+" + parsedCountryCode }) {
                selectedCountry = country
            }
        }
        
        if let address = profile.addresses.first {
            addressLine1 = address.addressLine1
            addressLine2 = address.addressLine2 ?? ""
            landmark = address.landMark ?? ""
            city = address.city ?? ""
            state = address.state ?? ""
            pincode = address.pincode.map(String.init) ?? ""
        }
        
        // Load profile image
        if let imagePath = profile.image {
            Task {
                do {
                    let imageData = try await profileManager.loadProfileImage(path: imagePath)
                    if let image = UIImage(data: imageData) {
                        selectedImage = image
                    }
                } catch {
                    print("Failed to load profile image: \(error)")
                }
            }
        }
    }
    
    private func validate() -> Bool {
        var isValid = true
        
        // Reset errors
        firstNameError = ""
        lastNameError = ""
        emailError = ""
        mobileNumberError = ""
        addressLine1Error = ""
        cityError = ""
        stateError = ""
        pincodeError = ""
        
        // Validate fields
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            firstNameError = NSLocalizedString("first_name_required", comment: "")
            isValid = false
        }
        
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastNameError = NSLocalizedString("last_name_required", comment: "")
            isValid = false
        }
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = NSLocalizedString("email_required", comment: "")
            isValid = false
        }
        
        if mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mobileNumberError = NSLocalizedString("mobile_number_required", comment: "")
            isValid = false
        }
        
        if addressLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressLine1Error = NSLocalizedString("address_line_1_required", comment: "")
            isValid = false
        }
        
        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cityError = NSLocalizedString("city_required", comment: "")
            isValid = false
        }
        
        if state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            stateError = NSLocalizedString("state_required", comment: "")
            isValid = false
        }
        
        if pincode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pincodeError = NSLocalizedString("pin_code_required", comment: "")
            isValid = false
        } else if !pincode.allSatisfy({ $0.isNumber }) {
            pincodeError = NSLocalizedString("invalid_pin_code", comment: "")
            isValid = false
        }
        
        return isValid
    }
    
    private func fetchLocation() async throws {
        isGeocodingLoading = true
        geocodingError = nil
        
        let fullAddress = "\(addressLine1), \(addressLine2), \(city), \(state), \(pincode)"
        
        return try await withCheckedThrowingContinuation { continuation in
            NetworkManager.shared.makeRequest(
                endpoint: "/match/getGeoCode",
                method: .GET,
                parameters: ["address": fullAddress]
            ) { (result: Result<[GeoCode], Error>) in
                DispatchQueue.main.async {
                    self.isGeocodingLoading = false
                    
                    switch result {
                    case .success(let response):
                        if let firstLocation = response.first {
                            self.coordinates = firstLocation.location.coordinates
                            continuation.resume()
                        } else {
                            self.geocodingError = "Invalid address"
                            continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid address"]))
                        }
                    case .failure(let error):
                        self.geocodingError = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func updateProfile() async {
        guard validate() else { return }
        
        isUpdating = true
        
        // Format the phone number with country code before sending to API
        let formattedPhoneNumber = formatPhoneNumber(mobileNumber)
        
        // Otherwise, try to fetch coordinates from the address
        do {
            try await fetchLocation()
        } catch {
            isUpdating = false
            // Show geocoding error alert
            alertTitle = NSLocalizedString("error", comment: "")
            alertMessage = geocodingError ?? NSLocalizedString("invalid_address", comment: "")
            isSuccess = false
            showAlert = true
            return
        }
        
        let updatedData: [String: Any] = [
            "id": profile.id,
            "firstName": firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            "lastName": lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "mobileNumber": formattedPhoneNumber,
            "addresses": [
                [
                    "addressLine1": addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
                    "addressLine2": addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
                    "landMark": landmark.trimmingCharacters(in: .whitespacesAndNewlines),
                    "city": city.trimmingCharacters(in: .whitespacesAndNewlines),
                    "state": state.trimmingCharacters(in: .whitespacesAndNewlines),
                    "pincode": Int(pincode) ?? 0,
                    "location": [
                        "type": "Point",
                        "coordinates": self.coordinates
                    ]
                ]
            ],
            // Preserve existing fields
            "middleName": profile.middleName as Any,
            "image": profile.image as Any,
            "imei": profile.imei as Any,
            "dateOfBirth": profile.dateOfBirth as Any,
            "gender": profile.gender as Any,
            "active": profile.active,
            "locked": profile.locked,
            "forcePasswordChange": profile.forcePasswordChange,
            "pwdExpiryDate": profile.pwdExpiryDate as Any,
            "lastSuccessfulLogin": profile.lastSuccessfulLogin as Any,
            "lockedTill": profile.lockedTill as Any,
            "failedLoginAttempt": profile.failedLoginAttempt as Any,
            "expiryNotifyCount": profile.expiryNotifyCount as Any,
            "forgetPwdToken": profile.forgetPwdToken as Any,
            "activatePwdToken": profile.activatePwdToken as Any,
            "status": profile.status as Any,
            "ssnLast4": profile.ssnLast4 as Any,
            "community": profile.community as Any,
            "consentForBackgroundCheck": profile.consentForBackgroundCheck as Any,
            "referralCode": profile.referralCode as Any,
            "rideRole": profile.rideRole as Any,
            "pointsBalance": profile.pointsBalance as Any,
            "comment": profile.comment as Any,
            "createdBy": profile.createdBy as Any,
            "createdDate": profile.createdDate,
            "modifiedBy": profile.modifiedBy as Any,
            "modifiedDate": profile.modifiedDate
        ]
        
        do {
            try await profileManager.updateProfile(updatedData: updatedData)
            
            if let _ = selectedImage {
                do {
                    await uploadProfileImage()
                } catch {
                    isUpdating = false
                    alertTitle = NSLocalizedString("error", comment: "")
                    alertMessage = NSLocalizedString("failed_to_upload_image", comment: "")
                    isSuccess = false
                    showAlert = true
                }
            }
        } catch {
            isUpdating = false
            alertTitle = NSLocalizedString("error", comment: "")
            alertMessage = error.localizedDescription
            isSuccess = false
            showAlert = true
        }
    }
    
    private func uploadProfileImage() async {
        guard let image = selectedImage,
              let imageData = compressImage(image, maxSizeInMB: 0.5) else {
            return
        }

        do {
            try await profileManager.uploadProfileImage(imageData: imageData)
        } catch {
            // Error is already handled by ProfileManager
        }
    }
    
    private func deleteProfileImage() async {
        isUpdating = true
        do {
            try await profileManager.deleteProfileImage()
            selectedImage = nil
            // Update the profile data to reflect image deletion
            await profileManager.fetchUserProfile()
            alertTitle = NSLocalizedString("success", comment: "")
            alertMessage = NSLocalizedString("profile_image_deleted", comment: "")
            isSuccess = true
            showAlert = true
        } catch {
            isUpdating = false
            alertTitle = NSLocalizedString("error", comment: "")
            alertMessage = error.localizedDescription
            isSuccess = false
            showAlert = true
        }
    }
    
    private func searchLocations() {
        // Don't search if we're in the middle of filling a selected location
        guard !isSelectionInProgress else { return }
        
        // Only search if user has edited the field
        guard hasEditedAddressLine1 else { return }
        
        guard !addressLine1.isEmpty else {
            locations = []
            showLocationsList = false
            return
        }
        
        Task {
            await performSearch()
        }
    }
    
    private func performSearch() async {
        isGeocodingLoading = true
        showLocationsList = false
        
        // Only use addressLine1 for the search query
        let query = addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        var params = ["address": query]
        if !sessionToken.isEmpty {
            params["sessionToken"] = sessionToken
        }
        
        do {
            let response: [Location] = try await withCheckedThrowingContinuation { continuation in
                NetworkManager.shared.makeRequest(
                    endpoint: "/match/getSuggestions",
                    method: .GET,
                    parameters: params
                ) { (result: Result<[Location], Error>) in
                    continuation.resume(with: result)
                }
            }
            
            await MainActor.run {
                isGeocodingLoading = false
                locations = response
                showLocationsList = !response.isEmpty
                geocodingError = nil
                if let firstSessionToken = response.first?.sessionToken {
                    sessionToken = firstSessionToken
                }
            }
        } catch {
            await MainActor.run {
                isGeocodingLoading = false
                geocodingError = error.localizedDescription
                locations = []
                showLocationsList = false
            }
        }
    }
    
    private func fillSuggestedLocation(_ location: Location) {
        isSelectionInProgress = true
        
        let addressComponents = location.description!.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        
        switch addressComponents.count {
        case 0:
            break
        case 1:
            addressLine1 = String(addressComponents[0])
        case 2:
            addressLine1 = String(addressComponents[0])
            city = String(addressComponents[1])
        case 3:
            addressLine1 = String(addressComponents[0])
            city = String(addressComponents[1])
            state = String(addressComponents[2])
        case 4:
            addressLine1 = String(addressComponents[0])
            city = String(addressComponents[1])
            state = String(addressComponents[2])
            landmark = String(addressComponents[3])
        default:
            addressLine1 = String(addressComponents[0])
            city = String(addressComponents[addressComponents.count - 2])
            landmark = String(addressComponents[4])
            state = String(addressComponents[addressComponents.count - 3])
        }
        
        if let pincode = addressComponents.last?.filter({ $0.isNumber }) {
            self.pincode = pincode
        }
        
        showLocationsList = false
        selectedLocation = location
        
        // Reset the flag after a short delay to allow the UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSelectionInProgress = false
        }
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
} 

#Preview {
    NavigationView {
        let mockProfile = UserProfile(
            id: "1",
            firstName: "John",
            middleName: nil,
            lastName: "Doe",
            image: nil,
            email: "john@example.com",
            mobileNumber: "1234567890",
            imei: nil,
            dateOfBirth: nil,
            gender: nil,
            active: true,
            locked: false,
            forcePasswordChange: false,
            pwdExpiryDate: nil,
            lastSuccessfulLogin: nil,
            lockedTill: nil,
            failedLoginAttempt: nil,
            expiryNotifyCount: nil,
            forgetPwdToken: nil,
            activatePwdToken: nil,
            status: nil,
            oldPassword: nil,
            password: nil,
            confirmPassword: nil,
            addresses: [],
            ssnLast4: nil,
            community: nil,
            consentForBackgroundCheck: nil,
            backgroundCheck: nil,
            membership: nil,
            referralCode: nil,
            child: nil,
            vehicles: nil,
            rideRole: nil,
            pointsBalance: nil,
            comment: nil,
            createdBy: nil,
            createdDate: "2024-03-21T00:00:00.000Z",
            modifiedBy: nil,
            modifiedDate: "2024-03-21T00:00:00.000Z"
        )
        Group {
            ProfileEditView(profile: mockProfile)
                .previewDisplayName("Light Mode")
            
            ProfileEditView(profile: mockProfile)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
