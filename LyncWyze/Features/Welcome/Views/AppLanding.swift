import SwiftUI
import Toasts

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LocationRow: View {
    let location: Location
    
    var body: some View {
        Text(location.description ?? "")
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LocationListView: View {
    let locations: [Location]
    @Binding var checkZone: String
    @ObservedObject var viewModel: AddressSelectionViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(locations, id: \.placeId) { location in
                    LocationRow(location: location)
                        .onTapGesture {
                            viewModel.selectedLocation = location
                            viewModel.showLocationsList = false
                            viewModel.locations = []
                            checkZone = location.description ?? ""
                        }
                }
            }
        }
        .frame(maxHeight: 200)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.1), radius: 2)
    }
}

struct WelcomeHeaderView: View {
    let hasReferralName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if !hasReferralName.isEmpty {
                Text(String(format: NSLocalizedString("referral_from", comment: ""), hasReferralName))
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatisticItem: View {
    let icon: String
    let value: String
    let description: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(Color.primaryButton)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AppLanding: View {
    @State private var hasReferralName = ""
    @State private var checkZone = ""
    @State private var shouldNavigate = false
    @StateObject private var viewModel = AddressSelectionViewModel()
    @State private var showAlert = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                    Image("carsTravelingTransparent")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(
                            colorScheme == .dark ? Color.white
                                .opacity(0.6) : Color.clear
                                )
                }
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    VStack(spacing: 32) {
                        WelcomeHeaderView(hasReferralName: hasReferralName)
                        
                        VStack(spacing: 16) {
                            AddressSearchView(
                                checkZone: $checkZone,
                                viewModel: viewModel,
                                type: nil,
                                subType: nil
                            )
                            
                            // Continue Button
                            Button {
                                if let selectedLocation = viewModel.selectedLocation {
                                    if viewModel.isFromProvider {
                                        shouldNavigate = true
                                    } else {
                                        viewModel.checkServiceAvailability(
                                            placeId: selectedLocation.placeId ?? ""
                                        )
                                        shouldNavigate = false
                                    }
                                } else {
                                    showAlert = true
                                }
                            } label: {
                                Text(NSLocalizedString("continue", comment: ""))
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color("ColorSubmitButton"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .alert(NSLocalizedString("selection_required", comment: ""), isPresented: $showAlert) {
                                Button(NSLocalizedString("ok", comment: ""), role: .cancel) { }
                            } message: {
                                Text(NSLocalizedString("please_select_provider", comment: ""))
                            }

                            NavigationLink(
                                NSLocalizedString("provider_not_found", comment: ""),
                                destination: NotifyMeView()
                            )
                            .font(.footnote)
                            .foregroundColor(Color.blue)
                            .padding(.top, 4)
                            
                            NavigationLink(destination: EmailSignInView()) {
                                HStack {
                                    Text(NSLocalizedString("already_have_account", comment: ""))
                                        .foregroundColor(.primary)
                                    Text(NSLocalizedString("lets_sign_in", comment: ""))
                                        .foregroundColor(Color.blue)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemBackground))
            .navigationDestination(isPresented: $shouldNavigate) {
                PhoneSignupView()
            }
        }
    }
}

struct AppLanding_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppLanding()
                .preferredColorScheme(.light)
            
            AppLanding()
                .preferredColorScheme(.dark)
        }
    }
}
