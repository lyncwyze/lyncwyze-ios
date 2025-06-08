import SwiftUI

struct UpcomingRidesView: View {
    @StateObject private var viewModel = UpcomingRidesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToRideTracking = false
    @State private var selectedRide: EachRide?
    @State private var selectedRiderImage: UIImage?
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.rides.isEmpty {
                EmptyStateView()
            } else {
                RideListView(
                    rides: viewModel.rides,
                    viewModel: viewModel,
                    selectedRide: $selectedRide,
                    navigateToRideTracking: $navigateToRideTracking,
                    selectedRiderImage: $selectedRiderImage
                )
            }
        }
        .navigationTitle(NSLocalizedString("upcoming_rides_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchUpcomingRides()
        }
        .alert(viewModel.error ?? NSLocalizedString("error_alert_title", comment: ""), isPresented: $viewModel.showError) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {
                viewModel.error = nil
            }
        }
        .withCustomBackButton(showBackButton: true)
        .navigationDestination(isPresented: $navigateToRideTracking) {
            if let ride = selectedRide {
                if viewModel.isCurrentUserRideTaker(in: ride) {
                    RideTakerTrackingView(
                        rideId: ride.id,
                        childName: viewModel.getDisplayName(for: ride),
                        vehicleNumber: ride.vehicle?.licensePlate ?? "N/A",
                        riderImage: selectedRiderImage,
                        pickupAddress: ride.pickupAddress.addressLine1 ?? "N/A",
                        dropoffAddress: ride.dropoffAddress.addressLine1 ?? "N/A",
                        rideType: ride.rideTakers[0].role,
                        riderId: ride.rideTakers[0].userId,
                        date: ride.date,
                        onCall: {
                            viewModel.makePhoneCall(number: viewModel.getPhoneNumber(for: ride))
                        },
                        onMessage: {
                            viewModel.sendMessage(number: viewModel.getPhoneNumber(for: ride))
                        },
                        isFromOngoing: false
                    )
                } else {
                    RideGiverTrackingView(
                        rideId: ride.id,
                        riderName: viewModel.getDisplayName(for: ride),
                        takerId: ride.rideTakers[0].userId,
                        caption: ride.pickupAddress.addressLine1 ?? "N/A",
                        pickupAddress: ride.pickupAddress.addressLine1 ?? "N/A",
                        dropoffAddress: ride.dropoffAddress.addressLine1 ?? "N/A",
                        dropoffLatitude: ride.dropoffAddress.location.coordinates[1],
                        dropoffLongitude: ride.dropoffAddress.location.coordinates[0],
                        riderImage: selectedRiderImage,
                        date: ride.date,
                        onCall: {
                            viewModel.makePhoneCall(number: viewModel.getPhoneNumber(for: ride))
                        },
                        onMessage: {
                            viewModel.sendMessage(number: viewModel.getPhoneNumber(for: ride))
                        },
                        onStartRide: {
                            // Start ride functionality is handled by the tracking view itself
                        },
                        isFromOngoing: false,
                        rideType: ride.rideTakers[0].role
                    )
                    .onAppear {
                        RideGiverWebSocketManager.shared.connect(with: ride)
                    }
                }
            }
        }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text(NSLocalizedString("loading_text", comment: ""))
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.circle")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)
            Text(NSLocalizedString("no_upcoming_rides", comment: ""))
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Ride List View
private struct RideListView: View {
    let rides: [EachRide]
    let viewModel: UpcomingRidesViewModel
    @Binding var selectedRide: EachRide?
    @Binding var navigateToRideTracking: Bool
    @Binding var selectedRiderImage: UIImage?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(rides) { ride in
                    RideUserCard(
                        personImage: "person.circle.fill",
                        imagePath: viewModel.getDisplayImage(for: ride),
                        name: viewModel.getDisplayName(for: ride),
                        successRecord: viewModel.getSuccessRecord(for: ride),
                        distance: viewModel.convertToMiles(ride.rideTakers[0].distance),
                        fromLocation: ride.pickupAddress.addressLine1 ?? "--",
                        toLocation: ride.dropoffAddress.addressLine1 ?? "--",
                        showFavorite: ride.rideTakers[0].favorite,
                        onCallTapped: {
                            viewModel.makePhoneCall(number: viewModel.getPhoneNumber(for: ride))
                        },
                        onMessageTapped: {
                            viewModel.sendMessage(number: viewModel.getPhoneNumber(for: ride))
                        },
                        onImageLoaded: { image in
                            selectedRiderImage = image
                        }
                    )
                    .padding(.horizontal)
                    .onTapGesture {
                        viewModel.saveRideData(ride: ride)
                        selectedRide = ride
                        navigateToRideTracking = true
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.fetchUpcomingRides()
        }
    }
}

// MARK: - Preview
struct UpcomingRidesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                UpcomingRidesView()
            }
            .previewDisplayName("Light Mode")
            
            NavigationView {
                UpcomingRidesView()
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
} 
