import SwiftUI
import CoreLocation

struct AddressSearchView: View {
    @Binding var checkZone: String
    @ObservedObject var viewModel: AddressSelectionViewModel
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var providers: [Provider] = []
    @State private var selectedProvider: Provider?
    @State private var isLoading = false
    @State private var errorMessage: String?
    let isProviderMode: Bool = true  // Set to false for address search
    let isEditMode: Bool
    let type: String?
    let subType: String?
    
    init(checkZone: Binding<String>, viewModel: AddressSelectionViewModel, isEditMode: Bool = false, type: String?, subType: String?) {
        self._checkZone = checkZone
        self.viewModel = viewModel
        self.isEditMode = isEditMode
        self.type = type
        self.subType = subType
    }
    
    private func populateDropdown() {
        print("🔄 Starting populateDropdown")
        isLoading = true
        NetworkManager.shared.makeRequest(
            endpoint: "/user/getProviders",
            method: .GET
        ) { (result: Result<PageableResponse<Provider>, Error>) in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    print("📥 Received providers: \(response.data.count)")
                    providers = response.data
                    errorMessage = nil
                    
                    // If in edit mode and we have providers, select the matching provider
                    if isEditMode, let type = self.type, let subType = self.subType {
                        print("🔍 Searching for provider with type: \(type), subType: \(subType)")
                        if let matchingProvider = providers.first(where: { provider in
                            let typeMatch = provider.type.uppercased() == type.uppercased()
                            let subTypeMatch = provider.subType.uppercased() == subType.uppercased()
                            return typeMatch && subTypeMatch
                        }) {
                            print("✅ Found matching provider: \(matchingProvider.name)")
                            selectProvider(matchingProvider)
                        } else {
                            print("⚠️ No matching provider found")
                        }
                    }
                case .failure(let error):
                    print("❌ Error loading providers: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    providers = []
                }
            }
        }
    }
    
    private func selectProvider(_ provider: Provider) {
        print("🔍 Selecting provider: \(provider.name)")
        selectedProvider = provider
        
        let address = [
            provider.address.addressLine1,
            provider.address.city,
            provider.address.state,
        ].compactMap { $0 }.joined(separator: ", ")
        print("📍 Generated address: \(address)")

        Task {
            do {
                let coordinates = try await locationManager.getCurrentCoordinates()
                let location = Location(
                    sessionToken: "",
                    description: address,
                    placeId: provider.id,
                    x: coordinates[1], // longitude
                    y: coordinates[0], // latitude
                    coordinates: coordinates,
                    type: "Point"
                )

                // Update viewModel state
                await MainActor.run {
                    print("🔄 Updating viewModel state")
                    viewModel.selectedLocation = location
                    viewModel.selectedProvider = provider
                    viewModel.isFromProvider = true
                    checkZone = address
                    print("✅ Provider selection completed")
                    print("Selected provider in viewModel: \(String(describing: viewModel.selectedProvider?.name))")
                }
            } catch {
                print("❌ Error getting coordinates: \(error.localizedDescription)")
                // Fallback to default coordinates if location access fails
                let location = Location(
                    sessionToken: "",
                    description: address,
                    placeId: provider.id,
                    x: 0.0,
                    y: 0.0,
                    coordinates: [0.0, 0.0],
                    type: "Point"
                )
                
                await MainActor.run {
                    viewModel.selectedLocation = location
                    viewModel.selectedProvider = provider
                    viewModel.isFromProvider = true
                    checkZone = address
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {            
            if isProviderMode {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Menu {
                        Button(NSLocalizedString("select_provider", comment: "")) {
                            selectedProvider = nil
                            viewModel.selectedLocation = nil
                            viewModel.selectedProvider = nil
                            viewModel.isFromProvider = false
                            checkZone = ""
                        }
                        
                        ForEach(providers, id: \.id) { provider in
                            Button("\(provider.name) - \(provider.address.city ?? ""), \(provider.address.state ?? "")") {
                                selectProvider(provider)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedProvider?.name ?? NSLocalizedString("select_provider", comment: ""))
                                .foregroundColor(selectedProvider == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            } else {
                HStack {
                    TextField(NSLocalizedString("select_home_address", comment: ""), text: $checkZone)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: checkZone) { newValue in
                            viewModel.searchLocations(address: newValue)
                        }
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if !isProviderMode && viewModel.isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
            else if !isProviderMode && viewModel.showLocationsList {
                LocationListView(
                    locations: viewModel.locations,
                    checkZone: $checkZone,
                    viewModel: viewModel
                )
            }
        }
        .onAppear {
            populateDropdown()
        }
    }
}

struct AddressSearchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddressSearchView(
                checkZone: .constant(""),
                viewModel: AddressSelectionViewModel(),
                type: "School",
                subType: "Gymnastics"
            )
            .preferredColorScheme(.light)
            
            AddressSearchView(
                checkZone: .constant(""),
                viewModel: AddressSelectionViewModel(),
                type: "School",
                subType: "Gymnastics"
            )
            .preferredColorScheme(.dark)
        }
    }
}
