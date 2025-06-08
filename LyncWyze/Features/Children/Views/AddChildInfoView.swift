//
//  AddChildInfoView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI
import _PhotosUI_SwiftUI

struct AddChildInfoView: View {
    @ObservedObject var childrenManager: ChildrenManager = ChildrenManager()
    let isOnboardingComplete: Bool
    let showBackButton: Bool
    var onDismiss: (() -> Void)?
    @State private var child: Child = Child()
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var displayImage: UIImage? = nil
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showGenderPicker = false
    @State private var navigateToAppLanding = false
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country?
    
    // Validation States
    @State private var showFirstNameError = false
    @State private var showLastNameError = false
    @State private var showGenderError = false
    @State private var showDOBError = false
    @State private var navigateToActivity: Bool = false
    @State private var newChild: Child = Child()
    
    // Get country code from environment
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
        }
        return nil
    }()
    
    private let countries: [Country]
    
    init(
        childrenManager: ChildrenManager,
        isOnboardingComplete: Bool = true,
        showBackButton: Bool = true,
        shouldUpdate: Binding<Bool> = .constant(false),
        onDismiss: (() -> Void)? = nil
    ){
        self.childrenManager = childrenManager
        self.isOnboardingComplete = isOnboardingComplete
        self.showBackButton = showBackButton
        self.onDismiss = onDismiss
        
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
    
    // Date formatter for API
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private func validateForm() -> Bool {
        // Reset all error states
        showFirstNameError = false
        showLastNameError = false
        showGenderError = false
        showDOBError = false
        
        var isValid = true
        
        if child.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showFirstNameError = true
            isValid = false
        }
        
        if child.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showLastNameError = true
            isValid = false
        }
        
        if child.gender.isEmpty {
            showGenderError = true
            isValid = false
        }
        
        // Check if date is not today or future date
        if child.birthDate >= Date() {
            showDOBError = true
            isValid = false
        }
        
        if !isValid {
            errorMessage = NSLocalizedString("required_fields_error", comment: "")
            showError = true
        }
        
        return isValid
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var navigateBack = false
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove any non-digit characters
        let digits = number.filter { $0.isNumber }
        let effectiveCountryCode = countryCode ?? selectedCountry?.dialCode.replacingOccurrences(of: "+", with: "") ?? "1"
        return "+\(effectiveCountryCode)-\(digits)"
    }
    
    private func saveChild() {
        if !validateForm() {
            return
        }
        
        isLoading = true
        
        // Format phone number with country code if provided
        let formattedPhoneNumber = child.phoneNumber.isEmpty ? nil : formatPhoneNumber(child.phoneNumber)
        
        let childRequest = SaveChildRequest(
            id: nil,
            firstName: child.firstName,
            lastName: child.lastName,
            dateOfBirth: dateFormatter.string(from: child.birthDate),
            gender: child.gender.uppercased(),
            mobileNumber: formattedPhoneNumber ?? "",
            rideInFront: child.rideInFront,
            boosterSeatRequired: child.boosterSeatRequired
        )
        
        // Create multipart form data
        var formData = NetworkManager.MultipartFormData()
        
        // Add child data
        formData.append(childRequest, name: "child")
        
        // Add image if available
        if let image = displayImage,
           let compressedData = compressImage(image, maxSizeInMB: 0.5) {
            formData
                .append(
                    compressedData,
                    name: "file",
                    fileName: "image.jpg"
                )
        }
        
        // Prepare request data
        let requestData = formData.finalize()
        let headers = ["Content-Type": formData.contentType]
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/addChild",
            method: .POST,
            headers: headers,
            body: requestData
        ) { (result: Result<SaveChildResponse, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.newChild = Child(
                        id: UUID(),
                        apiId: response.id,
                        firstName: self.child.firstName,
                        lastName: self.child.lastName,
                        birthDate: self.child.birthDate,
                        gender: self.child.gender,
                        phoneNumber: self.child.phoneNumber,
                        imageData: self.displayImage?.jpegData(compressionQuality: 0.8),
                        rideInFront: self.child.rideInFront,
                        boosterSeatRequired: self.child.boosterSeatRequired
                    )
                    
                    self.childrenManager.addChild(self.newChild)
                    if isOnboardingComplete == false{
                        if let dataCount: DataCountResponse = getUserDefaultObject(
                            forKey: Constants.UserDefaultsKeys.UserRequiredDataCount
                        ) {
                            if dataCount.activity < 1 {
                                navigateToActivity =  true
                            } else {
                                self.onDismiss?()
                                self.dismiss()
                            }
                        } else {
                            navigateToActivity = true
                        }
                    } else {
                        onDismiss?()
                        dismiss()
                    }

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    var horizontalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text(NSLocalizedString("provide_children_details", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isOnboardingComplete {
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
                .padding(.horizontal, horizontalPadding)

                // Profile Photo Section
                VStack(spacing: 12) {
                    ZStack {
                        if let displayImage = displayImage {
                            Image(uiImage: displayImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 100, height: 100)
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(Color(.systemGray3))
                                .frame(width: 90, height: 90)
                        }
                    }

                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Text(NSLocalizedString("add_photo", comment: ""))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.primaryButton)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)

                // Form Fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("first_name", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        CustomTextField(placeholder: NSLocalizedString("first_name", comment: ""), text: $child.firstName)
                            .foregroundColor(.primary)
                            .onChange(of: child.firstName) { _ in
                                showFirstNameError = false
                            }
                        if showFirstNameError {
                            Text(NSLocalizedString("first_name_required", comment: ""))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("last_name", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        CustomTextField(placeholder: NSLocalizedString("last_name", comment: ""), text: $child.lastName)
                            .foregroundColor(.primary)
                            .onChange(of: child.lastName) { _ in
                                showLastNameError = false
                            }
                        if showLastNameError {
                            Text(NSLocalizedString("last_name_required", comment: ""))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("gender", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        HStack {
                            Text(child.gender.isEmpty ? NSLocalizedString("select_gender", comment: "") : child.gender)
                                .foregroundColor(child.gender.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                showGenderPicker.toggle()
                                showGenderError = false
                            }
                        }
                        if showGenderError {
                            Text(NSLocalizedString("select_gender_required", comment: ""))
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(showGenderError ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .confirmationDialog(NSLocalizedString("select_gender", comment: ""), isPresented: $showGenderPicker, titleVisibility: .visible) {
                        Button(NSLocalizedString("male", comment: "")) { child.gender = "Male" }
                        Button(NSLocalizedString("female", comment: "")) { child.gender = "Female" }
                        Button(NSLocalizedString("other", comment: "")) { child.gender = "Other" }
                        Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("date_of_birth", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        DatePicker(
                            "",
                            selection: $child.birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accentColor(Color.primaryButton)
                            .onChange(of: child.birthDate) { _ in
                                showDOBError = false
                            }
                        if showDOBError {
                            Text(NSLocalizedString("valid_dob_required", comment: ""))
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(showDOBError ? Color.red : Color.clear, lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("phone_number", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
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
                                    .cornerRadius(12)
                                }
                            }
                            
                            HStack(spacing: 0) {
                                if countryCode != nil {
                                    Text("+" + countryCode!)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 12)
                                }
                                
                                TextField(NSLocalizedString("phone_number_optional", comment: ""), text: $child.phoneNumber)
                                    .keyboardType(.numberPad)
                                    .textContentType(.telephoneNumber)
                                    .foregroundColor(.primary)
                                    .onChange(of: child.phoneNumber) { newValue in
                                        // Only allow numbers and limit to 15 digits
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered.count > 15 {
                                            child.phoneNumber = String(filtered.prefix(15))
                                        } else {
                                            child.phoneNumber = filtered
                                        }
                                    }
                                    .padding(.leading, 4)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryButton)
                        .cornerRadius(12)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 30)
                } else {
                    Button {
                        saveChild()
                        isLoading = false
                    } label: {
                        Text(isOnboardingComplete ? NSLocalizedString("save", comment: "") : NSLocalizedString("next_add_child_activity", comment: ""))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryButton)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .bold()
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 30)
                    .disabled(isLoading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("error", comment: ""), isPresented: $showError) {
            Button(NSLocalizedString("ok", comment: "")) { }
        } message: {
            Text(errorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isOnboardingComplete {
                    Text(NSLocalizedString("children_info", comment: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.leading, 16)
                } else {
                    Text(NSLocalizedString("children_info", comment: ""))
                        .font(.title)
                        .bold()
                }
            }
        }
        .withCustomBackButton(showBackButton: showBackButton)
        .navigationDestination(isPresented: $navigateToActivity, destination: {
            AddUpdateActivityView(child: self.newChild, isOnboardingComplete: false)
        })
        .fullScreenCover(isPresented: $navigateToAppLanding) {
            AppLanding()
                .navigationBarBackButtonHidden(true)
        }
        .onChange(of: selectedImage) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    displayImage = uiImage
                }
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
        }
    }
}

struct AddChildInfoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddChildInfoView(childrenManager: ChildrenManager(), showBackButton: false)
                .preferredColorScheme(.light)
            
            AddChildInfoView(childrenManager: ChildrenManager(), showBackButton: false)
                .preferredColorScheme(.dark)
        }
    }
}
