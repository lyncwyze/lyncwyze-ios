import SwiftUI

// Add this struct before the OngoingRidesView
private struct RideParticipant {
    let name: String
    let completedRides: Int
    let mobileNumber: String?
    let distance: Int
    let favorite: Bool
    
    init(from ride: EachRide) {
        self.name = ride.fullName
        self.completedRides = ride.noOfCompletedRides
        self.mobileNumber = ride.mobileNumber
        self.distance = ride.rideTakers.first?.distance ?? 0
        self.favorite = false
    }
    
    init(from rideTaker: RideTaker) {
        self.name = rideTaker.fullName
        self.completedRides = rideTaker.noOfCompletedRides
        self.mobileNumber = rideTaker.mobileNumber
        self.distance = rideTaker.distance
        self.favorite = rideTaker.favorite
    }
}

struct OngoingRidesView: View {
    @StateObject private var viewModel = OngoingRidesViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAlert = false
    @State private var navigateToRideTracking = false
    @State private var selectedRide: EachRide?
    @State private var selectedRiderImage: UIImage?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
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
        .navigationTitle(NSLocalizedString("in_progress_rides_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .withCustomBackButton(showBackButton: true)
        .onAppear {
            viewModel.fetchOngoingRides()
        }
        .onChange(of: viewModel.error) { error in
            if error != nil {
                showAlert = true
            }
        }
        .alert(viewModel.error ?? NSLocalizedString("error_alert_title", comment: ""), isPresented: $showAlert) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {
                viewModel.error = nil
            }
        }
        .navigationDestination(isPresented: $navigateToRideTracking) {
            if let ride = selectedRide {
                if viewModel.isCurrentUserRideTaker(in: ride) {
                    RideTakerTrackingView(
                        rideId: ride.id,
                        childName: ride.fullName,
                        vehicleNumber: ride.vehicle?.licensePlate ?? "N/A",
                        riderImage: selectedRiderImage,
                        pickupAddress: ride.pickupAddress.addressLine1 ?? "N/A",
                        dropoffAddress: ride.dropoffAddress.addressLine1 ?? "N/A",
                        rideType: ride.rideTakers[0].role,
                        riderId: ride.rideTakers[0].userId,
                        date: ride.date,
                        onCall: {
                            viewModel.makePhoneCall(number: ride.mobileNumber)
                        },
                        onMessage: {
                            viewModel.sendMessage(number: ride.mobileNumber)
                        },
                        isFromOngoing: true
                    )
                } else {
                    RideGiverTrackingView(
                        rideId: ride.id,
                        riderName: ride.rideTakers[0].fullName,
                        takerId: ride.rideTakers[0].userId,
                        caption: ride.pickupAddress.addressLine1 ?? "N/A",
                        pickupAddress: ride.pickupAddress.addressLine1 ?? "N/A",
                        dropoffAddress: ride.dropoffAddress.addressLine1 ?? "N/A",
                        dropoffLatitude: ride.dropoffAddress.location.coordinates[1],
                        dropoffLongitude: ride.dropoffAddress.location.coordinates[0],
                        riderImage: selectedRiderImage,
                        date: ride.date,
                        onCall: {
                            viewModel.makePhoneCall(number: ride.rideTakers[0].mobileNumber)
                        },
                        onMessage: {
                            viewModel.sendMessage(number: ride.rideTakers[0].mobileNumber)
                        },
                        onStartRide: {
                            // Start ride functionality is handled by the tracking view itself
                        },
                        isFromOngoing: true,
                        rideType: ride.rideTakers[0].role
                    )
                }
            }
        }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
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
            Text(NSLocalizedString("no_ongoing_rides", comment: ""))
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Ride List View
private struct RideListView: View {
    let rides: [EachRide]
    let viewModel: OngoingRidesViewModel
    @Binding var selectedRide: EachRide?
    @Binding var navigateToRideTracking: Bool
    @Binding var selectedRiderImage: UIImage?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(rides) { ride in
                    RideCardView(
                        ride: ride,
                        viewModel: viewModel,
                        selectedRide: $selectedRide,
                        navigateToRideTracking: $navigateToRideTracking,
                        selectedRiderImage: $selectedRiderImage
                    )
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.fetchOngoingRides()
        }
    }
}

// MARK: - Ride Card View
private struct RideCardView: View {
    let ride: EachRide
    let viewModel: OngoingRidesViewModel
    @Binding var selectedRide: EachRide?
    @Binding var navigateToRideTracking: Bool
    @Binding var selectedRiderImage: UIImage?
    
    var body: some View {
        let isRideTaker = viewModel.isCurrentUserRideTaker(in: ride)
        let participant = isRideTaker ? 
            RideParticipant(from: ride) : 
            RideParticipant(from: ride.rideTakers[0])
        
        RideUserCard(
            personImage: "person.circle.fill",
            imagePath: viewModel.getDisplayImage(for: ride),
            name: participant.name,
            successRecord: String(format: NSLocalizedString("successfully_completed_rides", comment: ""), participant.completedRides),
            distance: viewModel.convertToMiles(participant.distance),
            fromLocation: ride.pickupAddress.addressLine1 ?? "--",
            toLocation: ride.dropoffAddress.addressLine1 ?? "--",
            showFavorite: participant.favorite,
            onCallTapped: {
                viewModel.makePhoneCall(number: participant.mobileNumber)
            },
            onMessageTapped: {
                viewModel.sendMessage(number: participant.mobileNumber)
            },
            onImageLoaded: { image in
                selectedRiderImage = image
            }
        )
        .padding(.horizontal)
        .onTapGesture {
            if let rideData = try? JSONEncoder().encode(ride) {
                saveUserDefaultObject(rideData, forKey: Constants.UserDefaultsKeys.rideData)
                selectedRide = ride
                navigateToRideTracking = true
            }
        }
    }
}

// MARK: - Preview
struct OngoingRidesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                OngoingRidesView()
            }
            .previewDisplayName("Light Mode")
            
            NavigationView {
                OngoingRidesView()
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
} 
