//
//  EditChildView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI
import _PhotosUI_SwiftUI

class ToastManager: ObservableObject {
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastIsError = false
    
    func showToastMessage(_ message: String, isError: Bool = false) {
        toastMessage = message
        toastIsError = isError
        showToast = true
        
        // Hide toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showToast = false
            }
        }
    }
}

struct SuccessDialogView: View {
    let title: String
    let buttonText: String
    let onConfirm: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.primaryButton)
                .font(.system(size: 60))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Button(action: onConfirm) {
                Text(buttonText)
                    .fontWeight(.medium)
                    .frame(width: 100)
                    .padding(.vertical, 12)
                    .background(Color.primaryButton)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct EditChildView: View {
    let child: Child
    @ObservedObject var childrenManager: ChildrenManager
    @Binding var isPresented: Bool
    @StateObject private var toastManager = ToastManager()
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var birthDate: Date
    @State private var gender: String
    @State private var phoneNumber: String
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var displayImage: UIImage?
    @State private var isLoading = false
    @State private var error: String?
    @State private var rideInFront: Bool
    @State private var boosterSeatRequired: Bool
    @State private var showSuccessDialog = false
    @State private var showGenderPicker = false
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country?
    
    private let countries: [Country]
    
    // Get country code from environment
    private let countryCode: String? = {
        if let code = Bundle.main.object(forInfoDictionaryKey: "COUNTRY_CODE") as? String, !code.isEmpty {
            return code
        }
        return nil
    }()
    
    @Environment(\.colorScheme) private var colorScheme
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove any non-digit characters and trim leading '1' if present
        var digits = number.filter { $0.isNumber }
        if digits.hasPrefix("1") {
            digits = String(digits.dropFirst())
        }
        
        let effectiveCountryCode = countryCode ?? selectedCountry?.dialCode.replacingOccurrences(of: "+", with: "") ?? "1"
        return "+\(effectiveCountryCode)-\(digits)"
    }

    init(child: Child, childrenManager: ChildrenManager, isPresented: Binding<Bool>) {
        self.child = child
        self.childrenManager = childrenManager
        self._isPresented = isPresented
        
        _firstName = State(initialValue: child.firstName)
        _lastName = State(initialValue: child.lastName)
        _birthDate = State(initialValue: child.birthDate)
        _gender = State(initialValue: child.gender)
        _phoneNumber = State(initialValue: child.phoneNumber)
        _rideInFront = State(initialValue: child.rideInFront)
        _boosterSeatRequired = State(initialValue: child.boosterSeatRequired)
        
        if let imageData = child.imageData,
           let uiImage = UIImage(data: imageData) {
            _displayImage = State(initialValue: uiImage)
        }
        
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
    
    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else if let error = error {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.largeTitle)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button(NSLocalizedString("retry", comment: "")) {
                            fetchChildDetails()
                        }
                        .foregroundColor(Color.primaryButton)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
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
                                    Text(NSLocalizedString("change_photo", comment: ""))
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
                                    CustomTextField(placeholder: NSLocalizedString("first_name", comment: ""), text: $firstName)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(NSLocalizedString("last_name", comment: ""))
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                        Text("*")
                                            .foregroundColor(.red)
                                    }
                                    CustomTextField(placeholder: NSLocalizedString("last_name", comment: ""), text: $lastName)
                                        .foregroundColor(.primary)
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
                                        selection: $birthDate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .accentColor(Color.primaryButton)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text(NSLocalizedString("gender", comment: ""))
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                        Text("*")
                                            .foregroundColor(.red)
                                    }
                                    HStack {
                                        Text(gender.isEmpty ? NSLocalizedString("select_gender", comment: "") : gender)
                                            .foregroundColor(gender.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation {
                                            showGenderPicker.toggle()
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .confirmationDialog(NSLocalizedString("select_gender", comment: ""), isPresented: $showGenderPicker, titleVisibility: .visible) {
                                    Button(NSLocalizedString("male", comment: "")) { gender = "Male" }
                                    Button(NSLocalizedString("female", comment: "")) { gender = "Female" }
                                    Button(NSLocalizedString("other", comment: "")) { gender = "Other" }
                                    Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
                                }
                                
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
                                            
                                            TextField(NSLocalizedString("phone_number_optional", comment: ""), text: $phoneNumber)
                                                .keyboardType(.numberPad)
                                                .textContentType(.telephoneNumber)
                                                .foregroundColor(.primary)
                                                .onChange(of: phoneNumber) { newValue in
                                                    let filtered = newValue.filter { $0.isNumber }
                                                    if filtered.count > 15 {
                                                        phoneNumber = String(filtered.prefix(15))
                                                    } else {
                                                        phoneNumber = filtered
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
                            .padding(.horizontal)

                            // Save and Delete Buttons
                            VStack(spacing: 12) {
                                Button(action: deleteChild) {
                                    Text(NSLocalizedString("delete_child", comment: ""))
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: saveChanges) {
                                    Text(NSLocalizedString("save_changes", comment: ""))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.primaryButton)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(NSLocalizedString("edit_child_details", comment: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 16)
                }
            }
            .withCustomBackButton(showBackButton: true)
            .overlay(
                ToastView(message: toastManager.toastMessage, isError: toastManager.toastIsError)
                    .opacity(toastManager.showToast ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: toastManager.showToast)
                , alignment: .top
            )
            
            if showSuccessDialog {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { }
                
                SuccessDialogView(
                    title: NSLocalizedString("details_updated", comment: ""),
                    buttonText: NSLocalizedString("ok", comment: "")
                ) {
                    showSuccessDialog = false
                    isPresented = false
                }
            }
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
            NavigationView {
                List(countries, id: \.code) { country in
                    Button(action: {
                        selectedCountry = country
                        showCountryPicker = false
                    }) {
                        HStack {
                            Text(country.flag)
                            Text(country.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(country.dialCode)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle(NSLocalizedString("select_country", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("cancel", comment: "")) {
                            showCountryPicker = false
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchChildDetails()
        }
    }
    
    private func fetchChildDetails() {
        guard let apiId = child.apiId else { return }
        
        isLoading = true
        error = nil
        
        childrenManager.fetchChildById(childId: apiId) { result in
            isLoading = false
            
            switch result {
            case .success(let updatedChild):
                firstName = updatedChild.firstName
                lastName = updatedChild.lastName
                birthDate = updatedChild.birthDate
                gender = updatedChild.gender
                
                // Split phone number into country code and number
                if !updatedChild.phoneNumber.isEmpty {
                    let components = updatedChild.phoneNumber.split(separator: "-")
                    if components.count == 2 {
                        // Remove the '+' from country code
                        let countryCodeStr = String(components[0].dropFirst())
                        phoneNumber = String(components[1])
                        
                        // Update selected country based on country code
                        if countryCode == nil {
                            selectedCountry = countries.first(where: { $0.dialCode == "+" + countryCodeStr })
                        }
                    } else {
                        // If phone number is not in expected format, just set it as is
                        phoneNumber = updatedChild.phoneNumber
                    }
                } else {
                    phoneNumber = ""
                }
                
                rideInFront = updatedChild.rideInFront
                boosterSeatRequired = updatedChild.boosterSeatRequired
                
                if let imageData = updatedChild.imageData,
                   let uiImage = UIImage(data: imageData) {
                    displayImage = uiImage
                }
                
            case .failure(let error):
                self.error = error.localizedDescription
            }
        }
    }
    
    private func showToastMessage(_ message: String, isError: Bool = false) {
        toastManager.showToastMessage(message, isError: isError)
    }
    
    private func saveChanges() {
        // Validate data
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showToastMessage(NSLocalizedString("fill_required_fields", comment: ""), isError: true)
            return
        }
        
        isLoading = true
        
        let formattedPhoneNumber = phoneNumber.isEmpty ? "" : formatPhoneNumber(phoneNumber)
        
        var updatedChild = Child(
            id: child.id,
            apiId: child.apiId,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate,
            gender: gender.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: formattedPhoneNumber,
            rideInFront: rideInFront,
            boosterSeatRequired: boosterSeatRequired
        )
        
        var compressedImage: UIImage? = nil
        if let image = displayImage,
           let compressedData = compressImage(image, maxSizeInMB: 0.01) {
            compressedImage = UIImage(data: compressedData)
        }

        
        childrenManager
            .updateChildWithAPI(
                child: updatedChild,
                image: compressedImage
            ) { result in
            isLoading = false
            
            switch result {
            case .success(let child):
                updatedChild = child
                if let imageData = displayImage?.jpegData(compressionQuality: 0.8) {
                    updatedChild.imageData = imageData
                }
                childrenManager.updateChild(updatedChild)
                showSuccessDialog = true
                
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .apiError(let message):
                        showToastMessage(String(format: NSLocalizedString("error_prefix", comment: ""), message), isError: true)
                    default:
                        showToastMessage(String(format: NSLocalizedString("error_prefix", comment: ""), networkError.localizedDescription), isError: true)
                    }
                } else {
                    showToastMessage(String(format: NSLocalizedString("exception_prefix", comment: ""), error.localizedDescription), isError: true)
                }
            }
        }
    }
    
    private func deleteChild() {
        guard let apiId = child.apiId else {
            showToastMessage(NSLocalizedString("cannot_delete_child", comment: ""), isError: true)
            return
        }
        
        isLoading = true
        
        if let index = childrenManager.children.firstIndex(where: { $0.id == child.id }) {
            childrenManager.deleteChild(at: IndexSet([index]))
            isPresented = false
        }
    }
}

struct ToastView: View {
    let message: String
    let isError: Bool
    
    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isError ? Color.red : Color.primaryButton)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            .padding(.top, 50)
    }
}

struct EditChildView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditChildView(
                child: Child(
                    id: UUID(),
                    apiId: "12345",
                    firstName: "Abhi",
                    lastName: "Nag",
                    birthDate: Date(),
                    gender: "Male",
                    phoneNumber: "8797878678",
                    imageData: Data(),
                    rideInFront: false,
                    boosterSeatRequired: false
                ),
                childrenManager: ChildrenManager(),
                isPresented: .constant(true)
            )
            .preferredColorScheme(.light)
            
            EditChildView(
                child: Child(
                    id: UUID(),
                    apiId: "12345",
                    firstName: "Abhi",
                    lastName: "Nag",
                    birthDate: Date(),
                    gender: "Male",
                    phoneNumber: "8797878678",
                    imageData: Data(),
                    rideInFront: false,
                    boosterSeatRequired: false
                ),
                childrenManager: ChildrenManager(),
                isPresented: .constant(true)
            )
            .preferredColorScheme(.dark)
        }
    }
}
