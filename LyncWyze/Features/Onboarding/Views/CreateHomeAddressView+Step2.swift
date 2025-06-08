import SwiftUI

// MARK: - Models
struct GeoCode: Codable {
    let placeId: String
    let formattedAddress: String
    let location: GeoCodeLocation
}

struct GeoCodeLocation: Codable {
    let x: Double
    let y: Double
    let coordinates: [Double]
    let type: String
}

class CreateHomeAddressViewModel: ObservableObject {
    @EnvironmentObject var locationUtils: LocationUtils
    @Published var addressLine1: String = ""
    @Published var addressLine2: String = ""
    @Published var landmark: String = ""
    @Published var state: String = ""
    @Published var city: String = ""
    @Published var pinCode: String = ""
    @Published var locations: [Location] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLocationsList = false
    @Published var selectedLocation: Location?
    @Published var shouldNavigateToPhotoVerification = false
    @Published var coordinates: [Double] = [0.0, 0.0]
    private var searchTask: DispatchWorkItem?
    private var sessionToken: String = ""
    private var isSelectionInProgress = false
    
    @MainActor
    func fetchLocation() async {
        isLoading = true
        errorMessage = nil
        
        let fullAddress = "\(addressLine1), \(addressLine2), \(city), \(state), \(pinCode)"
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/getGeoCode",
            method: .GET,
            parameters: ["address": fullAddress]
        ) { [weak self] (result: Result<[GeoCode], Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if let firstLocation = response.first {
                        self.coordinates = firstLocation.location.coordinates
                        // After getting coordinates, proceed with saving the address
                        self.saveHomeAddress()
                    } else {
                        self.errorMessage = "Invalid address"
                    }
                case .failure(let error):
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            self.errorMessage = "Error: \(message)"
                        case .invalidResponse:
                            self.errorMessage = "Invalid response from server"
                        case .noData:
                            self.errorMessage = "No data received"
                        case .decodingError:
                            self.errorMessage = "Error processing response"
                        case .invalidURL:
                            self.errorMessage = "Invalid URL"
                        case .encodingError:
                            self.errorMessage = "Error encoding request"
                        }
                    } else {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func searchLocations() {
        // Don't search if we're in the middle of filling a selected location
        guard !isSelectionInProgress else { return }
        
        searchTask?.cancel()
        
        guard !addressLine1.isEmpty else {
            locations = []
            showLocationsList = false
            return
        }
        
        let task = DispatchWorkItem { [weak self] in
            self?.performSearch()
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: task)
    }
    
    private func performSearch() {
        isLoading = true
        showLocationsList = false
        
        // Only use addressLine1 for the search query
        let query = addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        var params = ["address": query]
        if !sessionToken.isEmpty {
            params["sessionToken"] = sessionToken
        }
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/getSuggestions",
            method: .GET,
            parameters: params
        ) { [weak self] (result: Result<[Location], Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.locations = response
                    self.showLocationsList = !response.isEmpty
                    self.errorMessage = nil
                    if let firstSessionToken = response.first?.sessionToken {
                        self.sessionToken = firstSessionToken
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.locations = []
                    self.showLocationsList = false
                }
            }
        }
    }
    
    func fillSuggestedLocation(_ location: Location) {
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
            self.pinCode = pincode
        }
        
        showLocationsList = false
        selectedLocation = location
        
        // Reset the flag after a short delay to allow the UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isSelectionInProgress = false
        }
    }
    
    func getGeocodeAndSave() {
        isLoading = true
        let fullAddress = "\(addressLine1), \(addressLine2), \(city), \(state), \(pinCode)"
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/getGeoCode",
            method: .GET,
            parameters: ["address": fullAddress]
        ) { [weak self] (result: Result<[GeoCode], Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if let firstLocation = response.first {
                        // Here you would typically save the address with coordinates
                        // For now, we'll just print it
                        print("Geocoded location: \(firstLocation.location.coordinates)")
                    } else {
                        self.errorMessage = "No location found"
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveHomeAddress() {
        guard selectedLocation != nil else {
            errorMessage = "Please select a valid address"
            return
        }
        
        guard !coordinates.isEmpty else {
            Task {
                await fetchLocation()
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let address = Address2(
            userId: nil as String?,
            addressLine1: addressLine1,
            addressLine2: addressLine2.isEmpty ? nil : addressLine2,
            landMark: landmark.isEmpty ? nil : landmark,
            pincode: Int(pinCode) ?? 0,
            state: state,
            city: city,
            location: Location2(
                coordinates: coordinates,
                type: "Point"
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(address)
            print("📤 Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert to string")")
            
            NetworkManager.shared.makeRequest(
                endpoint: "/user/addAddress",
                method: .POST,
                body: jsonData
            ) { (result: Result<Address2, Error>) in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        print("✅ Address saved successfully")
                        print("📥 Response: \(response)")
                        
                        // Update profile status and navigate to next screen
                        if var loginResponse: AuthResponse? = getUserDefaultObject(
                            forKey: Constants.UserDefaultsKeys.loggedInDataKey
                        ) {
                            print("📝 Current profile status: \(String(describing: loginResponse?.profileStatus))")
                            loginResponse?.profileStatus = ProfileStatus.photo
                            saveUserDefaultObject(
                                loginResponse,
                                forKey: Constants.UserDefaultsKeys.loggedInDataKey
                            )
                            print("✅ Profile status updated to photo")
                            self.shouldNavigateToPhotoVerification = true
                        } else {
                            print("❌ Failed to get login response from UserDefaults")
                            self.errorMessage = "Failed to update profile status. Please try again."
                        }
                        
                    case .failure(let error):
                        print("❌ API Error: \(error)")
                        if let networkError = error as? NetworkError {
                            switch networkError {
                            case .apiError(let message):
                                self.errorMessage = "API Error: \(message)"
                            case .invalidURL:
                                self.errorMessage = "Invalid URL. Please try again."
                            case .invalidResponse:
                                self.errorMessage = "Invalid response from server. Please try again."
                            case .noData:
                                self.errorMessage = "No data received from server. Please try again."
                            case .decodingError(let decodingError):
                                self.errorMessage = "Error processing response: \(decodingError.localizedDescription)"
                            case .encodingError:
                                self.errorMessage = "Error processing encode response. Please try again."
                            }
                        } else {
                            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                        }
                    }
                }
            }
        } catch {
            isLoading = false
            print("❌ Request Encoding Error: \(error)")
            errorMessage = "Failed to prepare address data: \(error.localizedDescription)"
        }
    }
}

struct LocationSelectionView: View {
    let locations: [Location]
    let onLocationSelected: (Location) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(locations, id: \.placeId) { location in
                    Text(location.description ?? "")
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            onLocationSelected(location)
                        }
                }
            }
        }
        .frame(maxHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct CreateHomeAddressView: View {
    @StateObject private var viewModel = CreateHomeAddressViewModel()
    @FocusState private var isAddressLine1Focused: Bool
    @State private var navigateToAppLanding = false
    @Environment(\.colorScheme) private var colorScheme
    let showBackButton: Bool
    
    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }
    
    private var isFormValid: Bool {
        !viewModel.addressLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.pinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(NSLocalizedString("home_address", comment: ""))
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
                    .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(NSLocalizedString("address_line_1", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            TextField(NSLocalizedString("address_line_1", comment: ""), text: $viewModel.addressLine1)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .focused($isAddressLine1Focused)
                                .onChange(of: viewModel.addressLine1) { _ in
                                    viewModel.searchLocations()
                                }
                                .onChange(of: isAddressLine1Focused) { isFocused in
                                    if !isFocused {
                                        viewModel.showLocationsList = false
                                    }
                                }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if viewModel.showLocationsList {
                                LocationSelectionView(
                                    locations: viewModel.locations,
                                    onLocationSelected: { location in
                                        viewModel.fillSuggestedLocation(location)
                                        isAddressLine1Focused = false
                                    }
                                )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("address_line_2", comment: ""))
                                .font(.caption)
                                .foregroundColor(.primary)
                            TextField(NSLocalizedString("address_line_2", comment: ""), text: $viewModel.addressLine2)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(NSLocalizedString("landmark", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            TextField(NSLocalizedString("landmark", comment: ""), text: $viewModel.landmark)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(NSLocalizedString("state", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField(NSLocalizedString("state", comment: ""), text: $viewModel.state)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(NSLocalizedString("city", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField(NSLocalizedString("city", comment: ""), text: $viewModel.city)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(NSLocalizedString("zip_code", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            TextField(NSLocalizedString("zip_code", comment: ""), text: $viewModel.pinCode)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.top, 16)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.fetchLocation()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(isFormValid ? Color.primaryButton : Color.gray)
                                .cornerRadius(8)
                                .disabled(!isFormValid || viewModel.isLoading)
                                .padding(.top, 16)

                        } else {
                            Text(NSLocalizedString("next_profile_picture", comment: ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(isFormValid ? Color.primaryButton : Color.gray)
                                .cornerRadius(8)
                                .disabled(!isFormValid || viewModel.isLoading)
                                .padding(.top, 16)

                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationDestination(
            isPresented: $viewModel.shouldNavigateToPhotoVerification) {
                ProfilePhotoVerification_Step3(showBackButton: true)
            }
        .fullScreenCover(isPresented: $navigateToAppLanding) {
            AppLanding()
                .navigationBarBackButtonHidden(true)
        }
        .withCustomBackButton(showBackButton: showBackButton)
    }
}

struct CreateHomeAddressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateHomeAddressView()
                .preferredColorScheme(.light)
            
            CreateHomeAddressView()
                .preferredColorScheme(.dark)
        }
    }
}
